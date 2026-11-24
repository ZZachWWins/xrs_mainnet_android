import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:xeris_wallet/core/config/network_config.dart';
import 'package:xeris_wallet/core/services/base_api_service.dart';
import 'package:xeris_wallet/core/services/xeris_api_service.dart';

http.Response _json(Object body, [int status = 200]) =>
    http.Response(jsonEncode(body), status);

http.Response _wallet() => _json({
      'address': 'test-wallet',
      'balance': 12000000000,
      'tokens': <String, Object>{},
    });

void main() {
  late XerisNetwork previousNetwork;
  late http.Client client;

  void mock(Future<http.Response> Function(http.Request) handler) {
    client = MockClient(handler);
    BaseApiService.clientOverride = client;
  }

  setUp(() {
    previousNetwork = NetworkConfig.currentNetwork;
    NetworkConfig.currentNetwork = XerisNetwork.testnet;
    mock((request) async =>
        throw StateError('Unexpected mocked request: ${request.url}'));
  });
  tearDown(() {
    BaseApiService.clientOverride = null;
    NetworkConfig.currentNetwork = previousNetwork;
    client.close();
  });

  test(
      'missing REST stake falls back to authoritative RPC, including legitimate zero',
      () async {
    for (final stake in [3000000000, 0]) {
      var rpcRequests = 0;
      mock((request) async {
        if (request.method == 'POST') {
          rpcRequests++;
          expect(jsonDecode(request.body)['method'], 'getAccountInfo');
          return _json({
            'jsonrpc': '2.0',
            'result': {
              'value': {
                'lamports': 999,
                'stake': stake,
              }
            }
          });
        }
        if (request.url.path == '/wallet/test-wallet') return _wallet();
        expect(request.url.path, '/stake/test-wallet');
        return _json({'error': 'stake endpoint unavailable'}, 400);
      });
      final account = await XerisApiService.getAccount('test-wallet');
      expect(account, isNotNull);
      expect(account!.stake, stake);
      expect(
          account.balance, 12000000000); // Preserve successful REST metadata.
      expect(rpcRequests, 1);
    }
  });

  test('RPC account without stake remains unavailable rather than zero',
      () async {
    mock((request) async {
      if (request.method == 'POST') {
        return _json({
          'jsonrpc': '2.0',
          'result': {
            'value': {'lamports': 12000000000}
          }
        });
      }
      if (request.url.path == '/wallet/test-wallet') return _wallet();
      expect(request.url.path, '/stake/test-wallet');
      return _json({'error': 'stake endpoint unavailable'}, 400);
    });
    expect(await XerisApiService.getAccount('test-wallet'), isNull);
  });

  test('failed RPC fallback does not promote missing REST stake to zero',
      () async {
    mock((request) async {
      if (request.method == 'POST') {
        return _json({'error': 'RPC unavailable'}, 400);
      }
      if (request.url.path == '/wallet/test-wallet') return _wallet();
      expect(request.url.path, '/stake/test-wallet');
      return _json({'error': 'stake endpoint unavailable'}, 400);
    });
    expect(await XerisApiService.getAccount('test-wallet'), isNull);
  });

  test('authoritative REST zero stake is valid and needs no RPC fallback',
      () async {
    var rpcRequests = 0;
    mock((request) async {
      if (request.method == 'POST') {
        rpcRequests++;
        return _json({'error': 'RPC must not be required'}, 400);
      }
      if (request.url.path == '/wallet/test-wallet') return _wallet();
      expect(request.url.path, '/stake/test-wallet');
      return _json({'stake': 0});
    });
    final account = await XerisApiService.getAccount('test-wallet');
    expect(account, isNotNull);
    expect(account!.stake, 0);
    expect(rpcRequests, 0);
  });
}
