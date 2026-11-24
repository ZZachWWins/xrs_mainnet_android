import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xeris_wallet/core/models/asset_model.dart';
import 'package:xeris_wallet/core/models/xeris_api_models.dart';
import 'package:xeris_wallet/core/providers/wallet_provider.dart';
import 'package:xeris_wallet/core/services/storage_service.dart';
import 'package:xeris_wallet/core/services/auth_service.dart';
import 'package:xeris_wallet/core/services/xeris_api_service.dart';
import 'package:xeris_wallet/features/wallet_actions/services/swap_service.dart';
import 'package:xeris_wallet/core/utils/amount_utils.dart';

// State class for the Swap feature
class SwapState {
  final AssetModel fromAsset;
  final AssetModel toAsset;
  final String fromAmount;
  final String toAmount;
  final bool isLoading;
  final String? error;
  final double? exchangeRate;
  final String? routePath; // e.g. "XRS → xUSDC → MOON" for multi-hop, null for direct

  // Limit order fields
  final bool isLimitOrder;
  final String limitPrice;
  final String? status; // "Wrapping...", "Swapping...", etc.

  const SwapState({
    required this.fromAsset,
    required this.toAsset,
    this.fromAmount = '',
    this.toAmount = '',
    this.isLoading = false,
    this.error,
    this.exchangeRate,
    this.routePath,
    this.isLimitOrder = false,
    this.limitPrice = '',
    this.status,
  });

  SwapState copyWith({
    AssetModel? fromAsset,
    AssetModel? toAsset,
    String? fromAmount,
    String? toAmount,
    bool? isLoading,
    String? error,
    double? exchangeRate,
    String? routePath,
    bool? isLimitOrder,
    String? limitPrice,
    String? status,
  }) {
    return SwapState(
      fromAsset: fromAsset ?? this.fromAsset,
      toAsset: toAsset ?? this.toAsset,
      fromAmount: fromAmount ?? this.fromAmount,
      toAmount: toAmount ?? this.toAmount,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      exchangeRate: exchangeRate ?? this.exchangeRate,
      routePath: routePath,
      isLimitOrder: isLimitOrder ?? this.isLimitOrder,
      limitPrice: limitPrice ?? this.limitPrice,
      status: status ?? this.status,
    );
  }
}

final swapServiceProvider = Provider<SwapService>((ref) => SwapService());

// Controller
class SwapNotifier extends Notifier<SwapState> {
  Timer? _debounceTimer;

  @override
  SwapState build() {
    final assetsState = ref.read(assetsProvider);
    final assets = assetsState.value ?? [];

    AssetModel from = AssetModel.empty();
    AssetModel to = AssetModel.empty();

    if (assets.isNotEmpty) {
      from = assets.firstWhere((a) => a.symbol == 'XRS', orElse: () => assets[0]);
      to = assets.firstWhere((a) => a.symbol.toUpperCase().contains('USDC'),
          orElse: () => assets.firstWhere((a) => a.id != from.id, orElse: () => assets.last));
    }

    ref.listen(assetsProvider, (previous, next) {
      final newAssets = next.value ?? [];
      if (newAssets.isNotEmpty) {
        final newFrom = newAssets.firstWhere((a) => a.id == state.fromAsset.id, orElse: () => state.fromAsset);
        final newTo = newAssets.firstWhere((a) => a.id == state.toAsset.id, orElse: () => state.toAsset);
        state = state.copyWith(fromAsset: newFrom, toAsset: newTo);
      }
    });

    return SwapState(fromAsset: from, toAsset: to);
  }

  SwapService get _swapService => ref.read(swapServiceProvider);

  void setFromAsset(AssetModel asset) {
    if (asset.id == state.toAsset.id) {
      switchAssets();
    } else {
      state = state.copyWith(fromAsset: asset);
      _recalculateQuote();
    }
  }

  void setToAsset(AssetModel asset) {
    if (asset.id == state.fromAsset.id) {
      switchAssets();
    } else {
      state = state.copyWith(toAsset: asset);
      _recalculateQuote();
    }
  }

  void switchAssets() {
    state = state.copyWith(
      fromAsset: state.toAsset,
      toAsset: state.fromAsset,
      fromAmount: state.toAmount,
    );
    _recalculateQuote();
  }

  void updateFromAmount(String amount) {
    state = state.copyWith(fromAmount: amount, error: null);

    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();

    if (amount.isEmpty) {
      state = state.copyWith(toAmount: '');
      return;
    }

    if (state.isLimitOrder) {
      _recalculateLimitOrderToAmount();
    } else {
      _debounceTimer = Timer(const Duration(milliseconds: 1000), () {
        _fetchQuote(amount);
      });
    }
  }

  void toggleLimitOrder(bool isLimit) {
    state = state.copyWith(isLimitOrder: isLimit, toAmount: '', error: null);
    if (!isLimit) {
      _recalculateQuote();
    } else {
      _recalculateLimitOrderToAmount();
    }
  }

  void updateLimitPrice(String price) {
    state = state.copyWith(limitPrice: price, error: null);
    _recalculateLimitOrderToAmount();
  }

  void _recalculateLimitOrderToAmount() {
    final amount = parseAmount(state.fromAmount);
    final limitPrice = parseAmount(state.limitPrice);
    if (amount != null && limitPrice != null && limitPrice > 0) {
      state = state.copyWith(
        toAmount: (amount * limitPrice).toStringAsFixed(4),
        exchangeRate: limitPrice,
      );
    } else {
      state = state.copyWith(toAmount: '', exchangeRate: null);
    }
  }

  void _recalculateQuote() {
    if (state.fromAmount.isNotEmpty && !state.isLimitOrder) {
      _fetchQuote(state.fromAmount);
    } else if (state.fromAmount.isNotEmpty && state.isLimitOrder) {
      _recalculateLimitOrderToAmount();
    }
  }

  Future<void> _fetchQuote(String amountStr) async {
    final amount = parseAmount(amountStr);
    if (amount == null || amount <= 0) {
      state = state.copyWith(toAmount: '');
      return;
    }

    try {
      final route = await _swapService.findBestRoute(
        fromAsset: state.fromAsset,
        toAsset: state.toAsset,
        amount: amount,
      );

      if (route == null) {
        state = state.copyWith(toAmount: '', error: 'No route found');
        return;
      }

      final outputAmount = route.totalOutputLamports / pow(10, state.toAsset.decimals);
      final routePath = route.isMultiHop
          ? _buildRoutePath(route, ref.read(assetsProvider).value ?? [])
          : null;

      state = state.copyWith(
        toAmount: outputAmount.toStringAsFixed(4),
        exchangeRate: outputAmount / amount,
        routePath: routePath,
      );
    } catch (e) {
      state = state.copyWith(error: 'Failed to get quote');
    }
  }

  /// Maps token IDs to readable symbols for the route display.
  String _buildRoutePath(SwapRoute route, List<AssetModel> assets) {
    String symbolFor(String tokenId) {
      if (tokenId == 'xrs_native') return 'XRS';
      if (tokenId == 'xeris_usdc') return 'xUSDC';
      final asset = assets.firstWhere((a) => a.id == tokenId, orElse: () => AssetModel.empty());
      return asset.symbol.isNotEmpty ? asset.symbol : tokenId;
    }

    final parts = route.hops.map((h) => symbolFor(h.fromToken)).toList()
      ..add(symbolFor(route.hops.last.toToken));
    return parts.join(' → ');
  }

  Future<String?> executeSwap(BuildContext context) async {
    // Reentry guard against double-tap: bail if a swap is already in flight.
    if (state.isLoading) return null;
    if (state.isLimitOrder && !SwapService.advancedOrdersSupported) {
      state = state.copyWith(error: SwapService.ordersUnavailableMessage);
      return null;
    }

    final amount = parseAmount(state.fromAmount);
    if (amount == null) return null;

    if (amount > state.fromAsset.balance) {
      state = state.copyWith(error: 'Insufficient Balance');
      return null;
    }

    // Set the loading flag synchronously BEFORE the async auth gap so a second
    // tap during authentication can't kick off a duplicate swap.
    state = state.copyWith(isLoading: true, error: null, status: 'Authenticating...');

    final isAuthenticated = await AuthService.authenticate(context);
    if (!isAuthenticated) {
      state = state.copyWith(isLoading: false, error: 'Authentication failed or canceled');
      return null;
    }

    state = state.copyWith(status: 'Initializing...');

    try {
      final address = await ref.read(walletAddressProvider.future);
      if (address == 'No Wallet' || address.isEmpty) throw Exception('No wallet connected');

      final mnemonic = await StorageService.getMnemonic();
      if (mnemonic == null) {
        state = state.copyWith(error: 'Wallet not configured properly');
        return null;
      }

      String? txHash;
      if (state.isLimitOrder) {
        final limitPrice = parseAmount(state.limitPrice);
        if (limitPrice == null || limitPrice <= 0) {
          state = state.copyWith(error: 'Invalid Limit Price', isLoading: false);
          return null;
        }
        state = state.copyWith(status: 'Placing order...');
        txHash = await _swapService.placeLimitOrder(
          walletAddress: address,
          mnemonic: mnemonic,
          fromAsset: state.fromAsset,
          toAsset: state.toAsset,
          amount: amount,
          limitPrice: limitPrice,
        );
      } else {
        txHash = await _swapService.executeSwap(
          walletAddress: address,
          mnemonic: mnemonic,
          fromAsset: state.fromAsset,
          toAsset: state.toAsset,
          amount: amount,
          slippagePct: 0.5,
          onStatus: (s) => state = state.copyWith(status: s),
        );
      }

      state = state.copyWith(isLoading: false, status: null);

      if (txHash == null) {
        state = state.copyWith(
          error: state.isLimitOrder ? 'Failed to place limit order.' : 'Swap failed or no route found.',
        );
      } else {
        await Future.delayed(const Duration(seconds: 4));
        // Clear the balance cache so the refetch reflects the post-swap state
        // instead of being served the pre-swap balance from the 8s cache.
        XerisApiService.clearBalanceCache();
        ref.invalidate(accountBalancesProvider);
        ref.invalidate(assetsProvider);
      }

      return txHash;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString(), status: null);
      return null;
    }
  }
}

final swapProvider = NotifierProvider.autoDispose<SwapNotifier, SwapState>(SwapNotifier.new);
