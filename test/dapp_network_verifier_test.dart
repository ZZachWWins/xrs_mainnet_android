import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:xeris_wallet/core/config/network_config.dart';
import 'package:xeris_wallet/core/services/dapp_network_verifier.dart';

void main() {
  const clock = 2000000000000;
  final blockhash = 'a' * 64;
  late Map<String, dynamic> point, feed;
  setUp(() {
    NetworkConfig.currentNetwork = XerisNetwork.mainnet;
    point = {
      'success': true,
      'data': {'slot': 27201, 'hash': DAppMainnetVerifier.checkpointHash},
      'attestation': {
        'chain_id': 'xeris-mainnet-v4',
        'generation': 'b' * 64,
        'prefix_verified_at_ms': clock,
        'observed_at_ms': clock
      }
    };
    feed = {
      'success': true,
      'data': [
        {'slot': 27202, 'hash': blockhash, 'poh_timestamp': clock}
      ]
    };
    DAppMainnetVerifier.readOverride =
        (path) async => path.contains('/slot/') ? point : feed;
  });
  tearDown(() {
    NetworkConfig.currentNetwork = NetworkConfig.defaultNetwork;
    DAppMainnetVerifier.readOverride = null;
    DAppMainnetVerifier.clientOverride = null;
  });
  test('exact pinned chain and recent transaction blockhash pass', () async {
    await DAppMainnetVerifier.verify(blockhash, now: () => clock);
  });
  test('wrong checkpoint, chain, generation and stale archive never pass',
      () async {
    final mutations = <void Function()>[
      () => point['data']['hash'] = 'c' * 64,
      () => point['attestation']['chain_id'] = 'testnet',
      () => point['attestation']['generation'] = 'bad',
      () => point['attestation']['observed_at_ms'] = clock - 15001,
      () => point['attestation']['prefix_verified_at_ms'] = clock - 120001,
      () => point['attestation']['observed_at_ms'] = clock + 2001,
    ];
    for (final mutate in mutations) {
      final saved = jsonDecode(jsonEncode(point)) as Map<String, dynamic>;
      mutate();
      await expectLater(DAppMainnetVerifier.verify(blockhash, now: () => clock),
          throwsStateError);
      point = saved;
    }
  });
  test(
      'old, absent, duplicate and timestamp-free recent block evidence fail closed',
      () async {
    for (final blocks in [
      [],
      [
        {'slot': 27202, 'hash': 'c' * 64, 'poh_timestamp': clock}
      ],
      [
        {'slot': 27202, 'hash': blockhash, 'poh_timestamp': clock - 120001}
      ],
      [
        {'slot': 27202, 'hash': blockhash}
      ],
      [feed['data'][0], feed['data'][0]]
    ]) {
      feed['data'] = blocks;
      await expectLater(DAppMainnetVerifier.verify(blockhash, now: () => clock),
          throwsStateError);
      feed['data'] = [
        {'slot': 27202, 'hash': blockhash, 'poh_timestamp': clock}
      ];
    }
  });
  test('network switch while identity request is pending revokes signing',
      () async {
    DAppMainnetVerifier.readOverride = (path) async {
      if (!path.contains('/slot/')) {
        NetworkConfig.currentNetwork = XerisNetwork.testnet;
      }
      return path.contains('/slot/') ? point : feed;
    };
    await expectLater(DAppMainnetVerifier.verify(blockhash, now: () => clock),
        throwsStateError);
  });
  test('attestation must remain fresh after the second bounded read', () async {
    var now = clock;
    DAppMainnetVerifier.readOverride = (path) async {
      if (!path.contains('/slot/')) now += 15001;
      return path.contains('/slot/') ? point : feed;
    };
    await expectLater(DAppMainnetVerifier.verify(blockhash, now: () => now),
        throwsStateError);
  });
  test(
      'production reader uses only fixed mainnet origins and disallows redirects',
      () async {
    DAppMainnetVerifier.readOverride = null;
    final urls = <String>[];
    DAppMainnetVerifier.clientOverride = MockClient((request) async {
      expect(request.followRedirects, false);
      urls.add(request.url.toString());
      return http.Response(
          jsonEncode(request.url.path.contains('/slot/') ? point : feed), 200);
    });
    await DAppMainnetVerifier.verify(blockhash, now: () => clock);
    expect(urls, [
      '${DAppMainnetVerifier.origin}/v2/block/slot/27201',
      '${DAppMainnetVerifier.origin}/v2/blocks?page=1&page_size=100'
    ]);
  });
  test('redirect and oversized bodies are rejected before any signing',
      () async {
    DAppMainnetVerifier.readOverride = null;
    for (final response in [
      http.Response('', 302, headers: {'location': 'https://evil.example'}),
      http.Response('x' * 524289, 200)
    ]) {
      DAppMainnetVerifier.clientOverride = MockClient((_) async => response);
      await expectLater(DAppMainnetVerifier.verify(blockhash, now: () => clock),
          throwsStateError);
    }
  });
}
