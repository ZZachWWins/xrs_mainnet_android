import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:xeris_wallet/core/config/network_config.dart';
import 'package:xeris_wallet/core/models/xeris_api_models.dart';
import 'package:xeris_wallet/core/services/base_api_service.dart';
import 'package:xeris_wallet/core/services/xeris_api_service.dart';

http.Response _json(Object body, [int status = 200]) =>
    http.Response(jsonEncode(body), status,
        headers: {'content-type': 'application/json'});

http.Response _balance(int xrs) => _json({
      'native_xrs': xrs * 1000000000,
      'token_accounts': <Object>[],
    });

Map<String, Object> _token(String id) => {
      'token_id': id,
      'symbol': id.toUpperCase(),
      'name': id,
      'decimals': 9,
      'total_supply': 1000000000,
    };

void main() {
  late DateTime now;
  late XerisNetwork previousNetwork;
  late http.Client client;

  void mock(Future<http.Response> Function(http.Request) handler) {
    client = MockClient(handler);
    BaseApiService.clientOverride = client;
  }

  setUp(() {
    previousNetwork = NetworkConfig.currentNetwork;
    NetworkConfig.currentNetwork = XerisNetwork.testnet;
    XerisApiService.clearNetworkCaches();
    now = DateTime.utc(2026, 11, 22);
    XerisApiService.nowOverride = () => now;
    // Every request is intercepted, including unexpected fallback requests.
    mock((request) async =>
        throw StateError('Unexpected mocked request: ${request.url}'));
  });

  tearDown(() {
    XerisApiService.clearNetworkCaches();
    XerisApiService.nowOverride = null;
    BaseApiService.clientOverride = null;
    NetworkConfig.currentNetwork = previousNetwork;
    client.close();
  });

  test('concurrent same-address balance reads share a single request',
      () async {
    final response = Completer<http.Response>();
    var requests = 0;
    mock((request) {
      expect(request.url.path, '/token/accounts/wallet-a');
      requests++;
      return response.future;
    });
    final first = XerisApiService.getAccountBalances('wallet-a');
    final second = XerisApiService.getAccountBalances('wallet-a');
    await Future<void>.delayed(Duration.zero);
    expect(requests, 1);
    response.complete(_balance(12));
    final balances = await Future.wait([first, second]);
    expect(balances.map((value) => value.nativeXrs), [12, 12]);
    expect(identical(balances[0], balances[1]), isTrue);
    expect(
        (await XerisApiService.getAccountBalances('wallet-a')).nativeXrs, 12);
    expect(requests, 1);
  });

  test('a failed wallet B cannot receive wallet A cached balances', () async {
    mock((request) async => request.url.path.endsWith('/wallet-a')
        ? _balance(27)
        : _json({'error': 'unavailable'}, 400));
    expect(
        (await XerisApiService.getAccountBalances('wallet-a')).nativeXrs, 27);
    await expectLater(XerisApiService.getAccountBalances('wallet-b'),
        throwsA(isA<ApiException>()));
  });

  test('a failed first balance read throws instead of confirming zero',
      () async {
    mock((request) async => _json({'error': 'unavailable'}, 400));
    await expectLater(XerisApiService.getAccountBalances('new-wallet'),
        throwsA(isA<ApiException>()));
  });

  test('expired same-wallet cache is explicitly marked stale after failure',
      () async {
    var requests = 0;
    mock((request) async =>
        ++requests == 1 ? _balance(19) : _json({'error': 'unavailable'}, 400));
    final fresh = await XerisApiService.getAccountBalances('wallet-a');
    expect(fresh.isStale, isFalse);
    now = now.add(const Duration(seconds: 9));
    final stale = await XerisApiService.getAccountBalances('wallet-a');
    expect(stale.nativeXrs, 19);
    expect(stale.isStale, isTrue);
    expect(requests, 2);
  });

  test(
      'cleared in-flight response cannot repopulate or displace a newer request',
      () async {
    final oldResponse = Completer<http.Response>();
    final newResponse = Completer<http.Response>();
    var requests = 0;
    mock(
        (request) => ++requests == 1 ? oldResponse.future : newResponse.future);
    final oldRead = XerisApiService.getAccountBalances('wallet-a');
    await Future<void>.delayed(Duration.zero);
    XerisApiService.clearBalanceCache();
    final newRead = XerisApiService.getAccountBalances('wallet-a');
    await Future<void>.delayed(Duration.zero);
    expect(requests, 2);
    oldResponse.complete(_balance(3));
    expect((await oldRead).nativeXrs, 3);
    final joinedRead = XerisApiService.getAccountBalances('wallet-a');
    await Future<void>.delayed(Duration.zero);
    expect(requests, 2);
    newResponse.complete(_balance(41));
    expect((await newRead).nativeXrs, 41);
    expect((await joinedRead).nativeXrs, 41);
    expect(
        (await XerisApiService.getAccountBalances('wallet-a')).nativeXrs, 41);
    expect(requests, 2);
  });

  test('mainnet never reuses a same-address testnet cache', () async {
    expect(NetworkConfig.mainnetConfigured, isTrue,
        reason:
            'Mainnet endpoints must be configured for this mocked isolation test.');
    final hosts = <String>[];
    mock((request) async {
      hosts.add(request.url.host);
      return hosts.length == 1
          ? _balance(5)
          : _json({'error': 'unavailable'}, 400);
    });
    await XerisApiService.getAccountBalances('wallet-a');
    NetworkConfig.currentNetwork = XerisNetwork.mainnet;
    await expectLater(XerisApiService.getAccountBalances('wallet-a'),
        throwsA(isA<ApiException>()));
    expect(hosts, [
      Uri.parse(NetworkConfig.testnetControlUrl).host,
      Uri.parse(NetworkConfig.mainnetControlUrl).host
    ]);
  });

  test('token parsing preserves decimals and explicit display zero', () {
    final zero = XerisTokenBalance.fromJson({
      'token_id': 'zero',
      'balance': 1234567,
      'balance_display': 0,
      'decimals': 6,
    });
    expect(zero.balanceXrs, 0);
    expect(zero.balance, 1234567);
    expect(zero.decimals, 6);
    final scaled = XerisTokenBalance.fromJson({
      'token_id': 'scaled',
      'balance': 2500000,
      'token_info': {'decimals': '6'},
    });
    expect(scaled.balanceXrs, 2.5);
    expect(scaled.decimals, 6);
    final nested = XerisTokenBalance.fromJson({
      'token_id': 'nested',
      'balance': {'amount': '72500', 'decimals': 4},
    });
    expect(nested.balanceXrs, 7.25);
    expect(nested.decimals, 4);
  });

  test('control token registry follows cursor pages and deduplicates IDs',
      () async {
    final seenCursors = <String?>[];
    mock((request) async {
      if (request.url.path == '/v2/tokens') {
        return _json({'error': 'unsupported'}, 404);
      }
      expect(request.url.path, '/tokens');
      expect(request.url.queryParameters['limit'], '16');
      final cursor = request.url.queryParameters['after'];
      seenCursors.add(cursor);
      return cursor == null
          ? _json({
              'tokens': [_token('alpha')],
              'next_after': 'alpha'
            })
          : _json({
              'tokens': [_token('alpha'), _token('beta')],
              'next_after': null
            });
    });
    final tokens = await XerisApiService.getTokens();
    expect(tokens!.map((token) => token.id), ['alpha', 'beta']);
    expect(seenCursors, [null, 'alpha']);
  });

  test(
      'explorer v2 data registry wins after control failure and follows cursors',
      () async {
    final seenCursors = <String?>[];
    mock((request) async {
      if (request.url.path == '/tokens') {
        return _json({'error': 'unsupported'}, 404);
      }
      expect(request.url.path, '/v2/tokens');
      expect(request.url.queryParameters['limit'], '32');
      final cursor = request.url.queryParameters['after'];
      seenCursors.add(cursor);
      return cursor == null
          ? _json({
              'data': [_token('gamma')],
              'next_after': 'gamma'
            })
          : _json({
              'data': [_token('delta')],
              'next_after': null
            });
    });
    final tokens = await XerisApiService.getTokens();
    expect(tokens!.map((token) => token.id), ['gamma', 'delta']);
    expect(seenCursors, [null, 'gamma']);
  });

  test('healthy token registry finishes before a hanging fallback', () async {
    final fallback = Completer<http.Response>();
    var fallbackRequested = false;
    mock((request) {
      if (request.url.path == '/v2/tokens') {
        fallbackRequested = true;
        return fallback.future;
      }
      return Future.value(_json({
        'tokens': [_token('healthy')]
      }));
    });
    try {
      final tokens = await XerisApiService.getTokens()
          .timeout(const Duration(milliseconds: 500));
      expect(tokens!.single.id, 'healthy');
      expect(fallbackRequested, isTrue);
      expect(fallback.isCompleted, isFalse);
    } finally {
      fallback.complete(_json({'data': <Object>[]}));
      await Future<void>.delayed(Duration.zero);
    }
  });

  test('nested result.error RPC rejection throws an RPC ApiException',
      () async {
    mock((request) async {
      expect(request.method, 'POST');
      expect(jsonDecode(request.body)['method'], 'getLatestBlockhash');
      return _json({
        'jsonrpc': '2.0',
        'id': 1,
        'result': {
          'error': {'code': -32000, 'message': 'Mainnet domain rejected'},
        }
      });
    });
    await expectLater(
      BaseApiService.callRpc('getLatestBlockhash'),
      throwsA(isA<ApiException>()
          .having((error) => error.type, 'type', ApiErrorType.rpc)
          .having((error) => error.message, 'message',
              contains('domain rejected'))),
    );
  });
}
