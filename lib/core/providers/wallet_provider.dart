import 'dart:async';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xeris_wallet/core/config/network_config.dart';
import 'package:xeris_wallet/core/providers/network_provider.dart';
import 'package:solana/solana.dart';
import 'package:xeris_wallet/core/services/storage_service.dart';
import 'package:xeris_wallet/core/services/wallet_service.dart';
import 'package:xeris_wallet/core/services/widget_service.dart';
import 'package:xeris_wallet/core/services/xeris_api_service.dart';
import 'package:xeris_wallet/core/services/app_lock.dart';
import 'package:xeris_wallet/core/models/asset_model.dart';
import 'package:xeris_wallet/core/models/wallet_meta.dart';
import 'package:xeris_wallet/core/models/xeris_api_models.dart';

// HTTP services already bound their attempts and timeouts. Repeating failed
// provider builds would leave the dashboard loading for over a minute.
Duration? _noAutomaticRetry(int retryCount, Object error) => null;

// Trigger migration on app start or provider read?
// Better handled in main.dart or a startup provider.
final walletMigrationProvider = FutureProvider<void>((ref) async {
  await StorageService.checkAndMigrate();
});

final walletListProvider = FutureProvider<List<WalletMeta>>((ref) async {
  // Ensure migration runs first
  await ref.watch(walletMigrationProvider.future);

  final wallets = await StorageService.getWallets();

  // Sync active ID state
  final activeId = await StorageService.getActiveWalletId();
  if (activeId != null) {
    // Defer state update to next frame to avoid build conflicts if needed,
    // but inside provider initialization it's tricky.
    // Instead, we just let UI read StorageService or we initialize the StateProvider.
    // Actually, let's make activeWalletIdProvider a FutureProvider or similar?
    // Simpler: Just rely on StorageService for source of truth and invalidate on change.
  }
  return wallets;
});

// Provides the current active wallet metadata
final activeWalletProvider = FutureProvider<WalletMeta?>((ref) async {
  final wallets = await ref.watch(walletListProvider.future);
  final activeId = await StorageService.getActiveWalletId();

  if (activeId == null && wallets.isNotEmpty) {
    return wallets.first; // Fallback
  }

  final index = wallets.indexWhere((w) => w.id == activeId);
  if (index != -1) {
    return wallets[index];
  }
  return wallets.isNotEmpty
      ? wallets.first
      : throw Exception('No wallets found');
});

// Notifies when wallet changes
// Notifies when wallet changes
class WalletController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {
    return null;
  }

  Future<void> switchWallet(String id) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      WalletService.clearKeyPairCache();
      XerisApiService.clearBalanceCache();
      await StorageService.setActiveWalletId(id);

      // We use a small delay or microtask to ensure all listeners see the loading state
      // if we were to emit it. But since we are already in AsyncLoading,
      // UI watching ref.watch(walletControllerProvider).isLoading will be true.

      ref.invalidate(walletListProvider);
      ref.invalidate(activeWalletProvider);
      ref.invalidate(accountBalancesProvider);
      ref.invalidate(tokenPricesProvider);
      ref.invalidate(walletAddressProvider);
      ref.invalidate(walletKeyPairProvider);
      ref.invalidate(assetsProvider);
      ref.invalidate(totalBalanceUsdProvider);

      // Kick off both in parallel so UI updates as soon as both resolve
      await Future.wait([
        ref.read(activeWalletProvider.future),
        ref.read(walletAddressProvider.future),
      ]);
    });
  }

  Future<String?> addWallet(String name, String mnemonic) async {
    state = const AsyncValue.loading();
    String? newId;
    state = await AsyncValue.guard(() async {
      final id = await StorageService.saveWallet(name, mnemonic);
      newId = id;
      ref.invalidate(walletListProvider);
      ref.invalidate(activeWalletProvider);
      ref.invalidate(accountBalancesProvider);
      ref.invalidate(tokenPricesProvider);
      ref.invalidate(walletAddressProvider);
      ref.invalidate(walletKeyPairProvider);
      ref.invalidate(assetsProvider);
      ref.invalidate(totalBalanceUsdProvider);
    });
    return newId;
  }

  Future<void> renameWallet(String id, String newName) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await StorageService.renameWallet(id, newName);
      ref.invalidate(walletListProvider);
      ref.invalidate(activeWalletProvider);
    });
  }

  Future<void> deleteWallet(String id) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      WalletService.clearKeyPairCache();
      XerisApiService.clearBalanceCache();
      await StorageService.deleteWallet(id);
      ref.invalidate(walletListProvider);
      ref.invalidate(activeWalletProvider);
      ref.invalidate(accountBalancesProvider);
      ref.invalidate(tokenPricesProvider);
      ref.invalidate(walletAddressProvider);
      ref.invalidate(walletKeyPairProvider);
      ref.invalidate(assetsProvider);
      ref.invalidate(totalBalanceUsdProvider);
    });
  }

  /// Full account deletion (App Store account-deletion requirement): erases every
  /// wallet, the recovery phrase, private keys, PIN, and all locally-stored data,
  /// then resets in-memory caches, the lock guard, and the home-screen widget.
  Future<void> deleteAllData() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      WalletService.clearKeyPairCache();
      XerisApiService.clearNetworkCaches();
      await StorageService.clearAll();
      // Nothing remains to lock; clear the guard so onboarding is reachable.
      await AppLock.refreshSecurityEnabled();
      AppLock.unlock();
      try {
        await WidgetService.updateBalance(xrsBalance: 0, usdValue: 0);
      } catch (_) {}
      ref.invalidate(walletListProvider);
      ref.invalidate(activeWalletProvider);
      ref.invalidate(accountBalancesProvider);
      ref.invalidate(tokenPricesProvider);
      ref.invalidate(walletAddressProvider);
      ref.invalidate(walletKeyPairProvider);
      ref.invalidate(assetsProvider);
      ref.invalidate(totalBalanceUsdProvider);
    });
  }
}

final walletControllerProvider =
    AsyncNotifierProvider<WalletController, void>(() {
  return WalletController();
});

// Single provider that fetches /token/accounts/{address} once and provides
// both native XRS and token balances. Derived providers watch this to avoid
// duplicate network calls on every refresh cycle.
final accountBalancesProvider = FutureProvider<AccountBalances>((ref) async {
  ref.watch(networkProvider);
  final address = await ref.watch(walletAddressProvider.future);

  final timer = Timer.periodic(const Duration(seconds: 20), (_) {
    ref.invalidateSelf();
  });
  ref.onDispose(timer.cancel);

  if (address == 'No Wallet' || address.isEmpty) return AccountBalances.empty;

  return XerisApiService.getAccountBalances(address);
}, retry: _noAutomaticRetry);

final walletBalanceProvider = FutureProvider<double>((ref) async {
  final balances = await ref.watch(accountBalancesProvider.future);
  return balances.nativeXrs;
});

final stakedBalanceProvider = FutureProvider<double>((ref) async {
  // Reuse stakingInfoProvider to avoid a duplicate getAccount() HTTP call
  final account = await ref.watch(stakingInfoProvider.future);
  if (account != null) {
    return account.stake / 1000000000;
  }
  throw Exception('Staking information is unavailable');
}, retry: _noAutomaticRetry);

final tokenPricesProvider = FutureProvider<Map<String, double>>((ref) async {
  ref.watch(networkProvider);
  // The small holdings response carries authoritative token decimals. Prices
  // may await it, while the dashboard's holdings path remains independent.
  final responses = await Future.wait<dynamic>([
    ref.watch(accountBalancesProvider.future),
    XerisApiService.getPools(),
  ]);
  final balances = responses[0] as AccountBalances;
  final pools = responses[1] as List<XerisPool>?;
  if (pools == null) throw Exception('Price data is unavailable');
  final decimals = <String, int>{
    for (final token in balances.tokenBalances) token.tokenId: token.decimals,
    'xrs': 9,
    'xrs_native': 9,
    'xeris_usdc': 6,
  };
  final prices = <String, double>{
    'xeris_usdc': 1.0, // Stablecoin reference
  };

  // Raw reserve ratios need both token scales. Unknown metadata must leave a
  // price unavailable rather than guess a scale and misstate its USD value.
  double? adjustPrice(double rawPrice, String tokenA, String tokenB) {
    final decA = decimals[tokenA];
    final decB = decimals[tokenB];
    if (decA == null || decB == null || !rawPrice.isFinite || rawPrice <= 0) {
      return null;
    }
    final adjusted = rawPrice * pow(10, decA - decB);
    return adjusted.isFinite && adjusted > 0 ? adjusted : null;
  }

  // Pass 1: direct USDC pools — establish USD prices for anything paired with USDC
  for (var pool in pools) {
    if (pool.tokenB == 'xeris_usdc') {
      final adjusted = adjustPrice(pool.priceAInB, pool.tokenA, pool.tokenB);
      if (adjusted == null) continue;
      prices[pool.tokenA] = adjusted;
      if (pool.tokenA == 'xrs_native') {
        prices['xrs'] = adjusted;
        prices['xrs_native'] = adjusted;
      }
    } else if (pool.tokenA == 'xeris_usdc') {
      final adjusted = adjustPrice(pool.priceBInA, pool.tokenB, pool.tokenA);
      if (adjusted == null) continue;
      prices[pool.tokenB] = adjusted;
      if (pool.tokenB == 'xrs_native') {
        prices['xrs'] = adjusted;
        prices['xrs_native'] = adjusted;
      }
    }
  }

  // Pass 2: XRS-paired pools — price tokens that have no direct USDC pool
  // token_USD = token_price_in_XRS * XRS_USD
  final xrsUsd = prices['xrs_native'] ?? 0.0;
  if (xrsUsd > 0) {
    for (var pool in pools) {
      if (pool.tokenA == 'xrs_native' && !prices.containsKey(pool.tokenB)) {
        final tokenPriceInXrs =
            adjustPrice(pool.priceBInA, pool.tokenB, 'xrs_native');
        if (tokenPriceInXrs == null) continue;
        prices[pool.tokenB] = tokenPriceInXrs * xrsUsd;
      } else if (pool.tokenB == 'xrs_native' &&
          !prices.containsKey(pool.tokenA)) {
        final tokenPriceInXrs =
            adjustPrice(pool.priceAInB, pool.tokenA, 'xrs_native');
        if (tokenPriceInXrs == null) continue;
        prices[pool.tokenA] = tokenPriceInXrs * xrsUsd;
      }
    }
  }

  return prices;
}, retry: _noAutomaticRetry);

final availableTokensProvider = FutureProvider<List<XerisToken>>((ref) async {
  ref.watch(networkProvider);
  return await XerisApiService.getTokens() ?? [];
}, retry: _noAutomaticRetry);

final tokenBalancesProvider = FutureProvider<Map<String, double>>((ref) async {
  final balances = await ref.watch(accountBalancesProvider.future);
  return {
    for (final tb in balances.tokenBalances)
      if (tb.balance > 0) tb.tokenId: tb.balanceXrs,
  };
});

final walletAddressProvider = FutureProvider<String>((ref) async {
  // Depend on wallet list to refresh when switched
  await ref.watch(walletListProvider.future);

  final mnemonic = await StorageService.getMnemonic();
  if (mnemonic == null) return 'No Wallet';

  final keyPair = await WalletService.getKeyPair(mnemonic);
  return keyPair.address;
});

final walletMnemonicProvider = FutureProvider<String>((ref) async {
  await ref.watch(walletListProvider.future);
  final mnemonic = await StorageService.getMnemonic();
  if (mnemonic == null) throw Exception('No wallet found');
  return mnemonic;
});

final walletKeyPairProvider = FutureProvider<Ed25519HDKeyPair>((ref) async {
  await ref.watch(walletListProvider.future);

  final mnemonic = await StorageService.getMnemonic();
  if (mnemonic == null) throw Exception('No wallet found');

  return WalletService.getKeyPair(mnemonic);
});

/// A completed dashboard value includes its wallet and network identity, so
/// Riverpod's retained refresh value can never appear under another account.
class WalletAssetsSnapshot {
  final String address;
  final XerisNetwork network;
  final List<AssetModel> assets;
  final Map<String, bool> visibility;
  final bool isStale;
  final bool hasPrices;
  final bool hasStake;

  const WalletAssetsSnapshot({
    required this.address,
    required this.network,
    required this.assets,
    required this.visibility,
    required this.isStale,
    required this.hasPrices,
    required this.hasStake,
  });

  Iterable<AssetModel> get visibleAssets => assets.where(
        (asset) => visibility[asset.id] ?? (asset.balance > 0),
      );

  bool get hasValuation => hasPrices && hasStake;

  double get totalBalanceUsd => visibleAssets.fold(
        0.0,
        (total, asset) => total + asset.valueUsd,
      );

  WalletAssetsSnapshot markStale() => WalletAssetsSnapshot(
        address: address,
        network: network,
        assets: assets,
        visibility: visibility,
        isStale: true,
        hasPrices: hasPrices,
        hasStake: hasStake,
      );
}

// Container-local enrichment cache retains only values from the same chain and
// address. Background refreshes must not temporarily subtract a known stake.
class _DashboardEnrichmentCache {
  final prices = <XerisNetwork, Map<String, double>>{};
  final stakes = <({String address, XerisNetwork network}), double>{};
}

final _dashboardEnrichmentCacheProvider =
    Provider((ref) => _DashboardEnrichmentCache());

final walletAssetsSnapshotProvider =
    FutureProvider<WalletAssetsSnapshot>((ref) async {
  final network = ref.watch(networkProvider);
  // Prices and staking enrich a loaded coin list. They must never block it.
  // A dependency reload can retain another wallet/network's old value; wait for
  // the new value in that case, while allowing same-scope manual refresh data.
  final pricesAsync = ref.watch(tokenPricesProvider);
  final stakeAsync = ref.watch(stakedBalanceProvider);
  final enrichmentCache = ref.watch(_dashboardEnrichmentCacheProvider);
  final results = await Future.wait<dynamic>([
    ref.watch(walletAddressProvider.future),
    ref.watch(accountBalancesProvider.future),
    ref.watch(coinVisibilityProvider.future),
  ]);
  final address = results[0] as String;
  if (!ref.mounted) throw StateError('Wallet data request was superseded');
  final scope = (address: address, network: network);
  if (pricesAsync.hasValue &&
      !pricesAsync.isReloading &&
      !pricesAsync.hasError) {
    enrichmentCache.prices[network] = pricesAsync.value!;
  }
  if (stakeAsync.hasValue && !stakeAsync.isReloading && !stakeAsync.hasError) {
    enrichmentCache.stakes[scope] = stakeAsync.value!;
  }
  final prices = enrichmentCache.prices[network] ?? <String, double>{};
  final stakedBalance = enrichmentCache.stakes[scope] ?? 0.0;
  final balances = results[1] as AccountBalances;
  final visibility = results[2] as Map<String, bool>;
  final nativeBalance = balances.nativeXrs;
  final heldTokens = {
    for (final token in balances.tokenBalances) token.tokenId: token
  };
  final tokenBalances = {
    for (final token in balances.tokenBalances)
      if (token.balanceXrs > 0) token.tokenId: token.balanceXrs,
  };
  final heldSymbols = {
    for (final token in balances.tokenBalances)
      if (token.symbol != null && token.symbol!.isNotEmpty)
        token.tokenId: token.symbol!,
  };

  final List<AssetModel> assets = [];

  // 1. Combined XRS Balance (Native + Wrapped + Staked)
  final double wrappedBalance = tokenBalances['xrs_native'] ?? 0.0;
  final double totalXrs = nativeBalance + wrappedBalance + stakedBalance;

  assets.add(AssetModel(
    id: 'xrs',
    symbol: 'XRS',
    name: 'Xeris',
    balance: totalXrs,
    price: prices['xrs'] ?? 0.0,
    changePercentage24h: 0.0,
    iconPath: 'assets/images/LogoSplash.png',
    decimals: 9,
  ));

  // 2. xeris_usdc is always shown (important stablecoin). Metadata is hardcoded
  //    so the dashboard never depends on the token registry.
  assets.add(AssetModel(
    id: 'xeris_usdc',
    symbol: 'xUSDC',
    name: 'Xeris USDC',
    balance: tokenBalances['xeris_usdc'] ?? 0.0,
    price: prices['xeris_usdc'] ?? 0.0,
    changePercentage24h: 0.0,
    decimals: 6,
  ));

  // 3. Every other held token, plus any token the user explicitly enabled via
  //    Manage Coins. Names come from the balances endpoint (heldSymbols); only
  //    when that has no symbol do we derive one from the contract ID
  //    (e.g. "moon_a3f7c2" → "MOON"). No token-registry fetch is involved.
  final shownIds = <String>{'xrs', 'xrs_native', 'xeris_usdc'};
  final candidateIds = <String>{
    ...tokenBalances.entries.where((e) => e.value > 0).map((e) => e.key),
    ...visibility.entries.where((e) => e.value).map((e) => e.key),
  };
  for (final id in candidateIds) {
    if (shownIds.contains(id)) continue;
    shownIds.add(id);

    final parts = id.split('_');
    final bool hasHexSuffix = parts.length >= 2 &&
        RegExp(r'^[0-9a-f]{6}$', caseSensitive: false).hasMatch(parts.last);
    final displaySymbol = heldSymbols[id] ??
        (hasHexSuffix
            ? parts.sublist(0, parts.length - 1).join('_').toUpperCase()
            : id.toUpperCase());

    assets.add(AssetModel(
      id: id,
      symbol: displaySymbol,
      name: displaySymbol,
      balance: tokenBalances[id] ?? 0.0,
      price: prices[id] ?? 0.0,
      changePercentage24h: 0.0,
      decimals: heldTokens[id]?.decimals ?? 9,
    ));
  }

  final hasPrices = assets
      .where(
        (asset) => visibility[asset.id] ?? (asset.balance > 0),
      )
      .every((asset) =>
          asset.balance == 0 ||
          (prices[asset.id]?.isFinite == true && prices[asset.id]! > 0));
  return WalletAssetsSnapshot(
    address: address,
    network: network,
    assets: assets,
    visibility: visibility,
    isStale: balances.isStale,
    hasPrices: hasPrices && !pricesAsync.hasError,
    hasStake: enrichmentCache.stakes.containsKey(scope) && !stakeAsync.hasError,
  );
}, retry: _noAutomaticRetry);

// Preserve the existing provider API for send, swap, and asset detail screens.
final assetsProvider = FutureProvider<List<AssetModel>>((ref) async {
  return (await ref.watch(walletAssetsSnapshotProvider.future)).assets;
}, retry: _noAutomaticRetry);

/// Keep successful same-wallet holdings visible during refresh and errors, while
/// rejecting retained values as soon as the account or network changes.
final dashboardAssetsSnapshotProvider =
    Provider<AsyncValue<WalletAssetsSnapshot>>((ref) {
  final network = ref.watch(networkProvider);
  final address = ref.watch(walletAddressProvider);
  final snapshot = ref.watch(walletAssetsSnapshotProvider);
  final switching = ref.watch(walletControllerProvider).isLoading;
  if (switching || address.isLoading) return const AsyncLoading();
  if (address.hasError) return AsyncError(address.error!, address.stackTrace!);
  final value = snapshot.value;
  if (value != null &&
      value.address == address.value &&
      value.network == network) {
    return AsyncData(snapshot.hasError ? value.markStale() : value);
  }
  if (snapshot.hasError && !snapshot.isLoading) {
    return AsyncError(snapshot.error!, snapshot.stackTrace!);
  }
  return const AsyncLoading();
});

/// Pushes the current balance to the Android/iOS home screen widget whenever
/// balances or prices change.
final widgetSyncProvider = Provider<void>((ref) {
  ref.listen(totalBalanceUsdProvider, (_, next) {
    next.whenData((totalUsd) async {
      final xrsBalance = ref.read(walletBalanceProvider).asData?.value ?? 0.0;
      await WidgetService.updateBalance(
          xrsBalance: xrsBalance, usdValue: totalUsd);
    });
  });
});

/// Spendable XRS = native + wrapped (excludes staked, which is locked).
/// Used by the send flow to validate amounts and trigger auto-unwrap.
final spendableXrsProvider =
    FutureProvider<({double native, double wrapped, double spendable})>(
        (ref) async {
  final nativeBalance = await ref.watch(walletBalanceProvider.future);
  final tokenBalances = await ref.watch(tokenBalancesProvider.future);
  final wrappedBalance = tokenBalances['xrs_native'] ?? 0.0;
  return (
    native: nativeBalance,
    wrapped: wrappedBalance,
    spendable: nativeBalance + wrappedBalance,
  );
});

final coinVisibilityProvider = FutureProvider<Map<String, bool>>((ref) async {
  final wallet = await ref.watch(activeWalletProvider.future);
  if (wallet == null) return {};
  return await StorageService.getCoinVisibility(wallet.id);
});

class HiddenCoinsController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {
    return null;
  }

  Future<void> toggleCoinVisibility(String coinId, bool isVisible) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final activeId = await StorageService.getActiveWalletId();
      if (activeId == null) return;

      final visibility = await StorageService.getCoinVisibility(activeId);
      visibility[coinId] = isVisible;

      await StorageService.setCoinVisibility(activeId, visibility);
      ref.invalidate(coinVisibilityProvider);
    });
  }
}

final hiddenCoinsControllerProvider =
    AsyncNotifierProvider<HiddenCoinsController, void>(() {
  return HiddenCoinsController();
});

final totalBalanceUsdProvider = FutureProvider<double>((ref) async {
  final snapshot = await ref.watch(walletAssetsSnapshotProvider.future);
  if (!snapshot.hasValuation) {
    throw Exception('Portfolio valuation is unavailable');
  }
  return snapshot.totalBalanceUsd;
}, retry: _noAutomaticRetry);

final stakingInfoProvider = FutureProvider<XerisAccount?>((ref) async {
  ref.watch(networkProvider);
  final address = await ref.watch(walletAddressProvider.future);
  if (address == 'No Wallet' || address.isEmpty) return null;

  // Auto-refresh every 20s (replaces the timer that was in stakedBalanceProvider)
  final timer = Timer.periodic(const Duration(seconds: 20), (_) {
    ref.invalidateSelf();
  });
  ref.onDispose(timer.cancel);

  return await XerisApiService.getAccount(address);
}, retry: _noAutomaticRetry);

// Provides the selected fiat currency ('USD' or 'EUR')
class CurrencyNotifier extends Notifier<String> {
  @override
  String build() {
    _loadInitial();
    return 'USD';
  }

  Future<void> _loadInitial() async {
    state = await StorageService.getCurrency();
  }

  Future<void> setCurrency(String code) async {
    state = code;
    await StorageService.setCurrency(code);
  }
}

final currencyProvider = NotifierProvider<CurrencyNotifier, String>(() {
  return CurrencyNotifier();
});

/// Hardcoded EUR/USD rate. In a production app this would come from an API.
const double _eurUsdRate = 0.92;

/// Returns the fiat conversion multiplier for the selected currency.
/// Prices are stored in USD; multiply by this to get the selected fiat.
double fiatMultiplier(String currency) {
  if (currency == 'EUR') return _eurUsdRate;
  return 1.0;
}

/// Returns the currency symbol for the selected currency code.
String currencySymbol(String currency) {
  if (currency == 'EUR') return '€';
  return '\$';
}

// Provides the privacy mode state (obscured balances)
class PrivacyModeNotifier extends Notifier<bool> {
  @override
  bool build() {
    _loadInitial();
    return false;
  }

  Future<void> _loadInitial() async {
    state = await StorageService.getPrivacyMode();
  }

  Future<void> toggle() async {
    final next = !state;
    state = next;
    await StorageService.setPrivacyMode(next);
  }
}

final privacyModeProvider = NotifierProvider<PrivacyModeNotifier, bool>(() {
  return PrivacyModeNotifier();
});
