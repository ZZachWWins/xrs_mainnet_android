import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:xeris_wallet/core/config/network_config.dart';
import 'package:xeris_wallet/core/services/base_api_service.dart';
import 'package:xeris_wallet/core/services/dex_service.dart';

http.Response jsonResponse(Object body, [int status = 200]) => http.Response(
      jsonEncode(body),
      status,
      headers: {'content-type': 'application/json'},
    );

Map<String, Object> poolRow(String id) => {
      'pool_id': id,
      'token_a': 'xrs_native',
      'token_b': 'xeris_usdc',
      'price_a_in_b': '0.00125000',
      'price_b_in_a': '800.00000000',
    };

Map<String, Object?> poolPage(List<String> ids, {String? next}) => {
      'success': true,
      // This is a total, not the number of rows on the current page.
      'count': 200,
      'pools': ids.map(poolRow).toList(),
      'next_after': next,
    };

Map<String, Object> poolDetail(String id) => {
      'success': true,
      'contract': {
        'contract_id': id,
        'state': {
          'Swap': {
            'token_a': 'xrs_native',
            'token_b': 'xeris_usdc',
            'reserve_a': 6400,
            'reserve_b': 8,
            'limit_orders': [
              {'order_id': 'limit-$id', 'owner': 'owner'},
            ],
            'dca_orders': [
              {'order_id': 'dca-$id', 'owner': 'owner'},
            ],
          },
        },
      },
    };

void main() {
  late XerisNetwork originalNetwork;

  setUp(() {
    originalNetwork = NetworkConfig.currentNetwork;
    NetworkConfig.currentNetwork = XerisNetwork.testnet;
    DexService.clearCache();
  });

  tearDown(() {
    BaseApiService.clientOverride?.close();
    BaseApiService.clientOverride = null;
    DexService.clearCache();
    NetworkConfig.currentNetwork = originalNetwork;
  });

  test('loads all aggregate pages and preserves raw string price ratios',
      () async {
    final requests = <Uri>[];
    const cursor = 'pool/first + beta';
    BaseApiService.clientOverride = MockClient((request) async {
      requests.add(request.url);
      expect(request.url.path, '/v2/pools');
      expect(request.url.queryParameters['limit'], '32');
      if (!request.url.queryParameters.containsKey('after')) {
        return jsonResponse(poolPage(['first'], next: cursor));
      }
      expect(request.url.queryParameters['after'], cursor);
      return jsonResponse(poolPage(['second']));
    });

    final pools = await DexService.getPools();

    expect(pools!.map((pool) => pool.poolId), ['first', 'second']);
    expect(pools.first.priceAInB, 0.00125);
    expect(pools.first.priceBInA, 800);
    expect(requests, hasLength(2));
    // Summaries do not launch a contract request for every pool.
    expect(pools.first.limitOrders, isNull);
  });

  test('rejects a repeated cursor without falling back to a detail fan-out',
      () async {
    var requests = 0;
    BaseApiService.clientOverride = MockClient((request) async {
      requests++;
      expect(request.url.path, '/v2/pools');
      return jsonResponse(poolPage(['first'], next: 'same-cursor'));
    });

    expect(await DexService.getPools(), isNull);
    expect(requests, 2);
  });

  for (final status in [404, 405]) {
    test('falls back for unsupported aggregate route ($status)', () async {
      final paths = <String>[];
      BaseApiService.clientOverride = MockClient((request) async {
        paths.add(request.url.path);
        switch (request.url.path) {
          case '/v2/pools':
            return jsonResponse({'error': 'Unsupported route'}, status);
          case '/contracts':
            return jsonResponse({
              'success': true,
              'contracts': [
                {'type': 'Swap', 'contract_id': 'legacy'},
              ],
            });
          case '/contract/legacy':
            return jsonResponse(poolDetail('legacy'));
          default:
            fail('Unexpected request: ${request.url}');
        }
      });

      final pools = await DexService.getPools();
      expect(pools!.single.poolId, 'legacy');
      expect(pools.single.priceAInB, 0.00125);
      expect(paths, ['/v2/pools', '/contracts', '/contract/legacy']);
    });
  }

  test('bounds legacy concurrency and keeps good pools when one detail fails',
      () async {
    var activeDetails = 0;
    var maxActiveDetails = 0;
    BaseApiService.clientOverride = MockClient((request) async {
      if (request.url.path == '/v2/pools') {
        return jsonResponse({}, 404);
      }
      if (request.url.path == '/contracts') {
        return jsonResponse({
          'success': true,
          'contracts': [
            for (var i = 0; i < 7; i++)
              {'type': 'Swap', 'contract_id': 'pool-$i'},
            {'type': 'Models', 'contract_id': 'not-a-pool'},
          ],
        });
      }
      expect(request.url.path, startsWith('/contract/pool-'));
      activeDetails++;
      if (activeDetails > maxActiveDetails) maxActiveDetails = activeDetails;
      await Future<void>.delayed(Duration.zero);
      activeDetails--;
      final id = request.url.pathSegments.last;
      if (id == 'pool-2') return jsonResponse({'error': 'Broken pool'}, 500);
      return jsonResponse(poolDetail(id));
    });

    final pools = await DexService.getPools();

    expect(pools, hasLength(6));
    expect(pools!.map((pool) => pool.poolId), isNot(contains('pool-2')));
    expect(maxActiveDetails, lessThanOrEqualTo(4));
    expect(maxActiveDetails, greaterThan(1));
  });

  for (final status in [400, 429, 500, 503]) {
    test('does not fan out after an aggregate HTTP $status error', () async {
      var requests = 0;
      BaseApiService.clientOverride = MockClient((request) async {
        requests++;
        expect(request.url.path, '/v2/pools');
        return jsonResponse({'error': 'Unavailable'}, status);
      });

      expect(await DexService.getPools(), isNull);
      expect(requests, 1);
    });
  }

  test('does not fan out after an aggregate connection failure', () async {
    var requests = 0;
    BaseApiService.clientOverride = MockClient((request) async {
      requests++;
      expect(request.url.path, '/v2/pools');
      throw http.ClientException('Network unavailable');
    });

    expect(await DexService.getPools(), isNull);
    expect(requests, 1);
  });

  test('coalesces concurrent refreshes and then serves its cache', () async {
    final started = Completer<void>();
    final response = Completer<http.Response>();
    var requests = 0;
    BaseApiService.clientOverride = MockClient((request) {
      requests++;
      started.complete();
      return response.future;
    });

    final first = DexService.getPools();
    await started.future;
    final second = DexService.getPools(forceRefresh: true);
    response.complete(jsonResponse(poolPage(['shared'])));

    expect((await first)!.single.poolId, 'shared');
    expect((await second)!.single.poolId, 'shared');
    expect((await DexService.getPools())!.single.poolId, 'shared');
    expect(requests, 1);
  });

  test('keeps same-network cached pools after a refresh failure', () async {
    var requests = 0;
    BaseApiService.clientOverride = MockClient((request) async {
      requests++;
      return requests == 1
          ? jsonResponse(poolPage(['cached']))
          : jsonResponse({'error': 'Unavailable'}, 503);
    });

    await DexService.getPools();
    expect((await DexService.getPools(forceRefresh: true))!.single.poolId,
        'cached');
    expect(requests, 2);
  });

  test(
      'cache clearing prevents an older in-flight response from repopulating it',
      () async {
    final started = Completer<void>();
    final oldResponse = Completer<http.Response>();
    var requests = 0;
    BaseApiService.clientOverride = MockClient((request) {
      requests++;
      if (requests == 1) {
        started.complete();
        return oldResponse.future;
      }
      return Future.value(jsonResponse(poolPage(['new'])));
    });

    final oldRequest = DexService.getPools();
    await started.future;
    DexService.clearCache();
    expect((await DexService.getPools())!.single.poolId, 'new');
    oldResponse.complete(jsonResponse(poolPage(['old'])));

    expect(await oldRequest, isNull);
    expect((await DexService.getPools())!.single.poolId, 'new');
    expect(requests, 2);
  });

  test(
      'network changes isolate pending responses even without explicit cache clearing',
      () async {
    final started = Completer<void>();
    final testnetResponse = Completer<http.Response>();
    var requests = 0;
    BaseApiService.clientOverride = MockClient((request) {
      requests++;
      if (requests == 1) {
        started.complete();
        return testnetResponse.future;
      }
      return Future.value(jsonResponse(poolPage(['mainnet'])));
    });

    final testnetRequest = DexService.getPools();
    await started.future;
    NetworkConfig.currentNetwork = XerisNetwork.mainnet;
    expect((await DexService.getPools())!.single.poolId, 'mainnet');
    testnetResponse.complete(jsonResponse(poolPage(['testnet'])));

    expect(await testnetRequest, isNull);
    expect((await DexService.getPools())!.single.poolId, 'mainnet');
    expect(requests, 2);
  });

  test(
      'hydrates orders only when requested and retains other summaries on a bad detail',
      () async {
    var detailRequests = 0;
    BaseApiService.clientOverride = MockClient((request) async {
      if (request.url.path == '/v2/pools') {
        return jsonResponse(poolPage(['valid', 'broken']));
      }
      detailRequests++;
      if (request.url.path == '/contract/broken') {
        return jsonResponse({'error': 'Unavailable'}, 500);
      }
      expect(request.url.path, '/contract/valid');
      return jsonResponse(poolDetail('valid'));
    });

    expect(await DexService.getPools(), hasLength(2));
    expect(detailRequests, 0);
    final pools = await DexService.getPools(includeOrders: true);

    expect(pools, hasLength(2));
    final valid = pools!.firstWhere((pool) => pool.poolId == 'valid');
    expect(valid.limitOrders!.single.id, 'limit-valid');
    expect(valid.dcaOrders!.single.id, 'dca-valid');
    expect(valid.priceAInB, 0.00125);
    expect(detailRequests, 2);
  });
}
