import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:xeris_wallet/core/config/network_config.dart';
import 'package:xeris_wallet/core/models/xeris_api_models.dart';
import 'package:xeris_wallet/core/providers/network_provider.dart';
import 'package:xeris_wallet/core/providers/wallet_provider.dart';
import 'package:xeris_wallet/core/services/base_api_service.dart';
import 'package:xeris_wallet/core/services/dex_service.dart';

class _PriceTestNetwork extends NetworkNotifier {
  @override
  XerisNetwork build() => XerisNetwork.testnet;
}

Map<String, Object> _pool(
        String id, String a, String b, double aInB, double bInA) =>
    {
      'pool_id': id,
      'token_a': a,
      'token_b': b,
      'price_a_in_b': aInB,
      'price_b_in_a': bInA,
    };

void main() {
  test(
      'held token decimals price direct, reverse and native pairs without a registry',
      () async {
    final previousNetwork = NetworkConfig.currentNetwork;
    NetworkConfig.currentNetwork = XerisNetwork.testnet;
    DexService.clearCache();
    var requests = 0;
    var holdingsReads = 0;
    final client = MockClient((request) async {
      requests++;
      expect(request.url.path, '/v2/pools');
      expect(request.url.queryParameters['limit'], '32');
      return http.Response(
          jsonEncode({
            'success': true,
            'pools': [
              // Six decimals on both sides: the raw ratio is already USD per token.
              _pool('direct', 'six_direct', 'xeris_usdc', 8, 0.125),
              _pool('reverse', 'xeris_usdc', 'six_reverse', 1 / 7, 7),
              // Native9 / stable6: 0.002 * 10^(9-6) = $2 per native XRS.
              _pool('native', 'xrs_native', 'xeris_usdc', 0.002, 500),
              // Token6 / native9: 4000 * 10^(6-9) = 4 XRS = $8 per token.
              _pool('indirect', 'six_indirect', 'xrs_native', 4000, 0.00025),
              // Unheld tokens have no authoritative scale; do not invent a price.
              _pool('unknown', 'unknown_scale', 'xeris_usdc', 2, 0.5),
            ],
            'next_after': null,
          }),
          200);
    });
    BaseApiService.clientOverride = client;
    final container = ProviderContainer(overrides: [
      networkProvider.overrideWith(_PriceTestNetwork.new),
      accountBalancesProvider.overrideWith((ref) async {
        holdingsReads++;
        return AccountBalances(nativeXrs: 12, tokenBalances: [
          for (final id in ['six_direct', 'six_reverse', 'six_indirect'])
            XerisTokenBalance(
              address: 'test-wallet',
              tokenId: id,
              balance: 2500000,
              balanceXrs: 2.5,
              decimals: 6,
            ),
        ]);
      }),
    ]);
    addTearDown(() {
      container.dispose();
      BaseApiService.clientOverride = null;
      client.close();
      DexService.clearCache();
      NetworkConfig.currentNetwork = previousNetwork;
    });

    final prices = await container.read(tokenPricesProvider.future);
    expect(prices['six_direct'], 8);
    expect(prices['six_direct']! * 2.5, 20); // Previously reported $20,000.
    expect(prices['six_reverse'], 7);
    expect(prices['xrs'], 2);
    expect(prices['six_indirect'], 8);
    expect(prices, isNot(contains('unknown_scale')));
    expect(holdingsReads, 1);
    expect(requests, 1); // No /tokens registry or per-contract requests.
  });
}
