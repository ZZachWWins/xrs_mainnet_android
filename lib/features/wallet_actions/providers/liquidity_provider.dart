import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xeris_wallet/core/models/asset_model.dart';
import 'package:xeris_wallet/core/models/xeris_api_models.dart';
import 'package:xeris_wallet/core/providers/wallet_provider.dart';
import 'package:xeris_wallet/core/services/storage_service.dart';
import 'package:xeris_wallet/features/wallet_actions/services/liquidity_service.dart';
import 'package:xeris_wallet/core/services/xeris_api_service.dart';
import 'package:xeris_wallet/core/utils/string_extensions.dart';
import 'package:xeris_wallet/core/services/liquidity_quote_service.dart';
import 'package:xeris_wallet/core/config/network_config.dart';
import 'package:xeris_wallet/core/services/pool_deployment_service.dart';
import 'package:xeris_wallet/core/services/dex_service.dart';

// Service Provider
final liquidityServiceProvider = Provider<LiquidityService>(
  (ref) => LiquidityService(),
);

// State for Add/Remove Liquidity
class LiquidityState {
  final bool isLoading;
  final String? error;
  final String? resultMessage;
  final List<XerisPool> pools;
  final PoolDeploymentResult? deployment;

  const LiquidityState({
    this.isLoading = false,
    this.error,
    this.resultMessage,
    this.pools = const [],
    this.deployment,
  });

  LiquidityState copyWith({
    bool? isLoading,
    String? error,
    String? resultMessage,
    List<XerisPool>? pools,
    PoolDeploymentResult? deployment,
  }) {
    return LiquidityState(
      isLoading: isLoading ?? this.isLoading,
      error:
          error, // Should clear if null not passed? usually we clear error explicitly
      resultMessage: resultMessage,
      pools: pools ?? this.pools,
      deployment: deployment ?? this.deployment,
    );
  }
}

class LiquidityNotifier extends Notifier<LiquidityState> {
  @override
  LiquidityState build() {
    // Initial fetch
    Future.microtask(() => refreshPools());
    return const LiquidityState();
  }

  LiquidityService get _service => ref.read(liquidityServiceProvider);

  Future<void> refreshPools() async {
    state = state.copyWith(isLoading: true);
    try {
      final pools = await XerisApiService.getPools();
      state = state.copyWith(isLoading: false, pools: pools ?? []);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Failed to fetch pools');
    }
  }

  /// Adds liquidity using exact displayed amounts and signed slippage bounds.
  Future<bool> addLiquidity({
    required XerisPool pool,
    required String amountA,
    required String amountB,
    required String expectedNetworkScope,
    required String expectedTokenA,
    required String expectedTokenB,
    int slippageBps = LiquidityQuoteService.defaultSlippageBps,
  }) async {
    state = state.copyWith(isLoading: true, error: null, resultMessage: null);
    try {
      if (expectedNetworkScope != NetworkConfig.cacheKey) {
        throw StateError(
          'The network changed. Close this form and review the deposit again.',
        );
      }
      final address = await ref.read(walletAddressProvider.future);
      final mnemonic = await StorageService.getMnemonic();
      if (address == 'No Wallet' || address.isEmpty || mnemonic == null) {
        state = state.copyWith(isLoading: false, error: 'Wallet not connected');
        return false;
      }
      final tx = await _service.addLiquidity(
        mnemonic: mnemonic,
        walletAddress: address,
        poolId: pool.poolId,
        amountA: amountA,
        amountB: amountB,
        expectedNetworkScope: expectedNetworkScope,
        expectedTokenA: expectedTokenA,
        expectedTokenB: expectedTokenB,
        slippageBps: slippageBps,
      );
      if (tx == null) {
        throw StateError('The deposit was not acknowledged by the node.');
      }
      XerisApiService.clearBalanceCache();
      ref.invalidate(accountBalancesProvider);
      ref.invalidate(assetsProvider);
      state = state.copyWith(
        isLoading: false,
        resultMessage:
            'Liquidity deposit submitted. Tx: ${tx.safeSubstring(0, 8)}...',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e is FormatException ? e.message : e.toString(),
      );
      return false;
    }
  }

  /// Initial amounts remain exact display strings, with a reviewed explicit ID.
  /// A pending deployment retains its signature and is checked, never resent.
  Future<PoolDeploymentResult?> deployPool({
    required String poolId,
    required String expectedWalletAddress,
    required AssetModel tokenA,
    required AssetModel tokenB,
    required String amountA,
    required String amountB,
    required String expectedNetworkScope,
    int feeBps = 30,
  }) async {
    state = state.copyWith(isLoading: true, error: null, resultMessage: null);
    try {
      if (expectedNetworkScope != NetworkConfig.cacheKey) {
        throw StateError('The network changed. Review the pool again.');
      }
      final address = await ref.read(walletAddressProvider.future);
      final mnemonic = await StorageService.getMnemonic();
      if (address.isEmpty || address == 'No Wallet' || mnemonic == null) {
        throw StateError('Wallet not connected');
      }
      if (address != expectedWalletAddress) {
        throw StateError(
          'The wallet changed. Review the pool and liquidity owner again.',
        );
      }
      final result = await _service.deployPool(
        mnemonic: mnemonic,
        walletAddress: address,
        expectedNetworkScope: expectedNetworkScope,
        poolId: poolId,
        tokenA: tokenA.id == 'xrs' ? 'xrs_native' : tokenA.id,
        tokenB: tokenB.id == 'xrs' ? 'xrs_native' : tokenB.id,
        amountA: amountA,
        amountB: amountB,
        feeBps: feeBps,
      );
      if (result.status == PoolDeploymentStatus.created) {
        DexService.clearCache();
        XerisApiService.clearBalanceCache();
        ref.invalidate(accountBalancesProvider);
        ref.invalidate(assetsProvider);
        await refreshPools();
      }
      state = state.copyWith(
        isLoading: false,
        deployment: result,
        resultMessage: '${result.message} Transaction: ${result.txSignature}',
      );
      return result;
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        error: error is FormatException ? error.message : error.toString(),
      );
      return null;
    }
  }
}

final liquidityProvider = NotifierProvider<LiquidityNotifier, LiquidityState>(
  () {
    return LiquidityNotifier();
  },
);
