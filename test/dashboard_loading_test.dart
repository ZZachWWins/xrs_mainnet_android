import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xeris_wallet/core/config/network_config.dart';
import 'package:xeris_wallet/core/models/xeris_api_models.dart';
import 'package:xeris_wallet/core/providers/network_provider.dart';
import 'package:xeris_wallet/core/providers/wallet_provider.dart';
import 'package:xeris_wallet/features/dashboard/widgets/asset_list.dart';
import 'package:xeris_wallet/l10n/app_localizations.dart';

class _TestNetwork extends NetworkNotifier {
  @override
  XerisNetwork build() => XerisNetwork.testnet;

  void select(XerisNetwork value) => state = value;
}

class _TestAddress extends Notifier<String> {
  @override
  String build() => 'wallet-a';

  void select(String value) => state = value;
}

final _testAddressProvider =
    NotifierProvider<_TestAddress, String>(_TestAddress.new);

class _TestPrivacy extends PrivacyModeNotifier {
  @override
  bool build() => false;
}

AccountBalances _holdings({bool stale = false}) => AccountBalances(
      nativeXrs: 12,
      isStale: stale,
      tokenBalances: [
        XerisTokenBalance(
          address: 'wallet-a',
          tokenId: 'sample_token',
          balance: 2500000,
          balanceXrs: 2.5,
          decimals: 6,
          symbol: 'SAMPLE',
        ),
      ],
    );

Widget _dashboard(ProviderContainer container) => UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(body: SingleChildScrollView(child: AssetList())),
      ),
    );

void main() {
  test('holdings render without waiting for prices or staking, then enrich',
      () async {
    final prices = Completer<Map<String, double>>();
    final stake = Completer<double>();
    final container = ProviderContainer(overrides: [
      networkProvider.overrideWith(_TestNetwork.new),
      walletAddressProvider.overrideWith((ref) async => 'wallet-a'),
      accountBalancesProvider.overrideWith((ref) async => _holdings()),
      coinVisibilityProvider.overrideWith((ref) async => {}),
      tokenPricesProvider.overrideWith((ref) => prices.future),
      stakedBalanceProvider.overrideWith((ref) => stake.future),
    ]);
    addTearDown(container.dispose);

    final initial = await container
        .read(walletAssetsSnapshotProvider.future)
        .timeout(const Duration(seconds: 1));
    expect(initial.assets.singleWhere((a) => a.id == 'xrs').balance, 12);
    expect(
        initial.assets.singleWhere((a) => a.id == 'sample_token').decimals, 6);
    expect(initial.hasValuation, isFalse);
    expect(initial.assets.singleWhere((a) => a.id == 'xrs').price, 0);

    prices.complete({'xrs': 2, 'sample_token': 4});
    stake.complete(3);
    await container.pump();
    final enriched = await container.read(walletAssetsSnapshotProvider.future);
    expect(enriched.assets.singleWhere((a) => a.id == 'xrs').balance, 15);
    expect(enriched.totalBalanceUsd, 40);
    expect(enriched.hasValuation, isTrue);
  });

  testWidgets(
      'ancillary failures do not retry or replace loaded coins with a spinner',
      (tester) async {
    var priceAttempts = 0;
    var stakeAttempts = 0;
    final container = ProviderContainer(overrides: [
      networkProvider.overrideWith(_TestNetwork.new),
      walletAddressProvider.overrideWith((ref) async => 'wallet-a'),
      accountBalancesProvider.overrideWith((ref) async => _holdings()),
      coinVisibilityProvider.overrideWith((ref) async => {}),
      tokenPricesProvider.overrideWith((ref) async {
        priceAttempts++;
        throw Exception('Price service offline');
      }),
      stakedBalanceProvider.overrideWith((ref) async {
        stakeAttempts++;
        throw Exception('Stake service offline');
      }),
      privacyModeProvider.overrideWith(_TestPrivacy.new),
    ]);
    addTearDown(container.dispose);
    await tester.pumpWidget(_dashboard(container));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('12 XRS'), findsOneWidget);
    expect(find.text('2.5 SAMPLE'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text(r'$0.00'), findsNothing);
    await tester.pump(const Duration(seconds: 90));
    expect(priceAttempts, 1);
    expect(stakeAttempts, 1);
  });

  testWidgets('cold holdings failure shows retry rather than an empty wallet',
      (tester) async {
    final container = ProviderContainer(overrides: [
      networkProvider.overrideWith(_TestNetwork.new),
      walletAddressProvider.overrideWith((ref) async => 'wallet-a'),
      accountBalancesProvider
          .overrideWith((ref) async => throw Exception('Offline')),
      coinVisibilityProvider.overrideWith((ref) async => {}),
      tokenPricesProvider
          .overrideWith((ref) => Completer<Map<String, double>>().future),
      stakedBalanceProvider.overrideWith((ref) => Completer<double>().future),
    ]);
    addTearDown(container.dispose);
    await tester.pumpWidget(_dashboard(container));
    await tester.pump();
    await tester.pump();
    expect(find.text('Unable to load balances. Please try again.'),
        findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    expect(find.textContaining('No assets found'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets(
      'same-wallet refresh keeps holdings and marks a failed refresh stale',
      (tester) async {
    final refresh = Completer<AccountBalances>();
    var attempts = 0;
    final container = ProviderContainer(overrides: [
      networkProvider.overrideWith(_TestNetwork.new),
      walletAddressProvider.overrideWith((ref) async => 'wallet-a'),
      accountBalancesProvider.overrideWith((ref) {
        return attempts++ == 0 ? Future.value(_holdings()) : refresh.future;
      }),
      coinVisibilityProvider.overrideWith((ref) async => {}),
      tokenPricesProvider
          .overrideWith((ref) => Completer<Map<String, double>>().future),
      stakedBalanceProvider.overrideWith((ref) => Completer<double>().future),
      privacyModeProvider.overrideWith(_TestPrivacy.new),
    ]);
    addTearDown(container.dispose);
    await tester.pumpWidget(_dashboard(container));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    container.invalidate(accountBalancesProvider);
    await tester.pump();
    expect(find.text('12 XRS'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);

    refresh.completeError(Exception('Offline'));
    await tester.pump();
    await tester.pump();
    expect(find.text('12 XRS'), findsOneWidget);
    expect(find.text('Showing previous balances. They may be out of date.'),
        findsOneWidget);
  });

  testWidgets('wallet or network change hides retained balances immediately',
      (tester) async {
    final container = ProviderContainer(overrides: [
      networkProvider.overrideWith(_TestNetwork.new),
      walletAddressProvider
          .overrideWith((ref) async => ref.watch(_testAddressProvider)),
      accountBalancesProvider.overrideWith((ref) {
        final address = ref.watch(_testAddressProvider);
        final network = ref.watch(networkProvider);
        return address == 'wallet-a' && network == XerisNetwork.testnet
            ? Future.value(_holdings())
            : Completer<AccountBalances>().future;
      }),
      coinVisibilityProvider.overrideWith((ref) async => {}),
      tokenPricesProvider
          .overrideWith((ref) => Completer<Map<String, double>>().future),
      stakedBalanceProvider.overrideWith((ref) => Completer<double>().future),
      privacyModeProvider.overrideWith(_TestPrivacy.new),
    ]);
    addTearDown(container.dispose);
    await tester.pumpWidget(_dashboard(container));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('12 XRS'), findsOneWidget);

    container.read(_testAddressProvider.notifier).select('wallet-b');
    await tester.pump();
    expect(find.text('12 XRS'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    container.read(_testAddressProvider.notifier).select('wallet-a');
    await tester.pump();
    await tester.pump();
    expect(find.text('12 XRS'), findsOneWidget);
    (container.read(networkProvider.notifier) as _TestNetwork)
        .select(XerisNetwork.mainnet);
    await tester.pump();
    expect(find.text('12 XRS'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    // Drain row animation delays from the brief return to the first wallet.
    await tester.pump(const Duration(seconds: 1));
  });
}
