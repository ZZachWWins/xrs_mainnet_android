import 'dart:math';
import 'dart:convert';
import 'dart:typed_data';
import 'package:xeris_wallet/core/config/network_config.dart';
import 'package:xeris_wallet/core/models/asset_model.dart';
import 'package:xeris_wallet/core/services/transaction_confirmation_service.dart';
import 'package:xeris_wallet/core/services/xeris_api_service.dart';
import 'package:xeris_wallet/core/models/xeris_api_models.dart';
import 'package:xeris_wallet/core/services/wallet_service.dart';

class SwapService {
  final TransactionReceiptWaiter _waitForReceipt;

  SwapService({TransactionReceiptWaiter? waitForReceipt})
    : _waitForReceipt =
          waitForReceipt ?? TransactionConfirmationService.waitForReceipt;

  static bool get advancedOrdersSupported => false;
  static const ordersUnavailableMessage =
      'Limit and DCA order creation is unavailable on the current node '
      'because their execution is disabled. No order transaction was sent.';

  // Well-known routing hubs, checked first for 2-hop routes.
  static const _routingHubs = ['xrs_native', 'xeris_usdc'];

  /// Returns the best route for a swap, or null if none found.
  Future<SwapRoute?> findBestRoute({
    required AssetModel fromAsset,
    required AssetModel toAsset,
    required double amount,
  }) async {
    if (amount <= 0) return null;
    final fromId = _mapTokenId(fromAsset.id);
    final toId = _mapTokenId(toAsset.id);
    final int amountBase = (amount * pow(10, fromAsset.decimals)).round();
    return _findBestRoute(fromId, toId, amountBase);
  }

  /// Fetches a real quote from the best available route.
  Future<double> getQuote({
    required AssetModel fromAsset,
    required AssetModel toAsset,
    required double amount,
  }) async {
    final route = await findBestRoute(
      fromAsset: fromAsset,
      toAsset: toAsset,
      amount: amount,
    );
    if (route == null) return 0.0;
    return route.totalOutputLamports / pow(10, toAsset.decimals);
  }

  Future<String?> executeSwap({
    required String walletAddress,
    required String mnemonic,
    required AssetModel fromAsset,
    required AssetModel toAsset,
    required double amount,
    double slippagePct = 1.0,
    void Function(String status)? onStatus,
  }) async {
    final networkScope = NetworkConfig.cacheKey;
    final fromId = _mapTokenId(fromAsset.id);
    final toId = _mapTokenId(toAsset.id);
    final int amountBase = (amount * pow(10, fromAsset.decimals)).round();

    final route = await _findBestRoute(fromId, toId, amountBase);
    if (route == null) throw Exception('No route found for this swap');
    _checkNetwork(networkScope);

    final keyPair = await WalletService.getKeyPair(mnemonic);
    _checkNetwork(networkScope);
    if (keyPair.address != walletAddress) {
      throw StateError('The active wallet changed. Review this swap again.');
    }
    String? lastSig;

    try {
      // 1. Wrap native XRS → xrs_native if needed
      if (fromAsset.symbol == 'XRS') {
        onStatus?.call('Wrapping XRS...');
        lastSig = await _submitAndConfirm(
          () => XerisApiService.wrapXrs(
            keyPair: keyPair,
            amountLamports: amountBase,
            expectedNetworkScope: networkScope,
          ),
          networkScope,
          onStatus,
        );
      }

      // 2. Execute each hop sequentially. Each hop's input is EXACTLY what the
      //    previous hop produced (measured as the delta of the destination token
      //    balance), never the wallet's full balance of that token — otherwise a
      //    later hop would trade the user's pre-existing holdings of an
      //    intermediate token, with a slippage floor sized for the small planned
      //    amount.
      int?
      lastHopOutput; // base-unit amount the most recent hop actually produced
      for (int i = 0; i < route.hops.length; i++) {
        final hop = route.hops[i];

        if (route.isMultiHop) {
          onStatus?.call('Swapping (step ${i + 1}/${route.hops.length})...');
        } else {
          onStatus?.call('Swapping...');
        }

        final int hopInput = (i == 0) ? amountBase : (lastHopOutput ?? 0);
        if (hopInput <= 0) {
          throw Exception('No input available for step ${i + 1}');
        }
        _checkNetwork(networkScope);

        // Snapshot the destination-token balance so we can measure exactly what
        // this hop yields (independent of any pre-existing holdings).
        XerisApiService.clearBalanceCache();
        final beforeBal = _balanceOf(
          await XerisApiService.getAccountBalances(walletAddress),
          hop.toToken,
        );

        final minOutput = (hop.quote.outputAmount * (1 - slippagePct / 100))
            .round();

        _checkNetwork(networkScope);
        lastSig = await _submitAndConfirm(
          () => XerisApiService.swap(
            keyPair: keyPair,
            poolId: hop.pool.poolId,
            direction: hop.direction,
            inputAmount: hopInput,
            minOutput: minOutput,
            expectedNetworkScope: networkScope,
          ),
          networkScope,
          onStatus,
        );

        // Only a successful execution receipt permits the next dependent action.
        XerisApiService.clearBalanceCache();
        try {
          final afterBal = _balanceOf(
            await XerisApiService.getAccountBalances(walletAddress),
            hop.toToken,
          );
          if (NetworkConfig.cacheKey != networkScope) {
            throw StateError('Network changed while checking swap output.');
          }
          lastHopOutput = afterBal - beforeBal;
          if (lastHopOutput <= 0) {
            throw StateError('The swap output could not be measured.');
          }
        } catch (_) {
          throw TransactionConfirmationException(
            TransactionConfirmationResult(
              signature: lastSig,
              status: TransactionConfirmationStatus.pending,
              detail:
                  'Swap execution was confirmed, but its received amount could not be verified. Check the original transaction and balances before continuing.',
            ),
          );
        }
      }

      // 3. Unwrap xrs_native → native XRS if the user is swapping TO XRS. Unwrap
      //    exactly what the final hop produced so no dust is stranded as wrapped.
      if (toAsset.symbol == 'XRS' &&
          lastSig != null &&
          (lastHopOutput ?? 0) > 0) {
        onStatus?.call('Unwrapping...');
        final unwrapSig = await _submitAndConfirm(
          () => XerisApiService.unwrapXrs(
            keyPair: keyPair,
            amountLamports: lastHopOutput!,
            expectedNetworkScope: networkScope,
          ),
          networkScope,
          onStatus,
        );
        return unwrapSig;
      }

      return lastSig;
    } on TransactionConfirmationException {
      rethrow;
    } catch (_) {
      if (lastSig != null) {
        throw TransactionConfirmationException(
          TransactionConfirmationResult(
            signature: lastSig,
            status: TransactionConfirmationStatus.pending,
            detail:
                'The swap flow stopped after a submitted transaction. Check its ID and original balances before continuing or retrying.',
          ),
        );
      }
      rethrow;
    }
  }

  void _checkNetwork(String expectedScope) {
    if (NetworkConfig.cacheKey != expectedScope) {
      throw StateError(
        'Network changed. Review the swap on the original network.',
      );
    }
  }

  Future<String> _submitAndConfirm(
    Future<String?> Function() submit,
    String networkScope,
    void Function(String)? onStatus,
  ) async {
    _checkNetwork(networkScope);
    String? signature;
    try {
      signature = await submit();
    } on TransactionSubmissionUnknown catch (unknown) {
      // The existing signature is the only ID to poll. Never resubmit.
      signature = unknown.signature;
    }
    if (signature == null || signature.isEmpty) {
      throw StateError(
        'Submission did not return a transaction ID. No dependent transaction was sent.',
      );
    }
    TransactionConfirmationResult receipt;
    try {
      onStatus?.call('Waiting for execution receipt: $signature');
      receipt = await _waitForReceipt(
        signature: signature,
        expectedNetworkScope: networkScope,
      );
    } catch (_) {
      throw TransactionConfirmationException(
        TransactionConfirmationResult(
          signature: signature,
          status: TransactionConfirmationStatus.pending,
          detail:
              'Receipt confirmation is unavailable. Check this transaction before retrying.',
        ),
      );
    }
    var sameNetwork = false;
    try {
      sameNetwork = NetworkConfig.cacheKey == networkScope;
    } catch (_) {}
    if (!sameNetwork || receipt.signature != signature) {
      throw TransactionConfirmationException(
        TransactionConfirmationResult(
          signature: signature,
          status: TransactionConfirmationStatus.pending,
          detail:
              'The network or receipt identity changed. Check the original transaction before continuing.',
        ),
      );
    }
    if (!receipt.isConfirmed) throw TransactionConfirmationException(receipt);
    return signature;
  }

  /// Finds the best route (direct or 2-hop) by output amount.
  Future<SwapRoute?> _findBestRoute(
    String fromId,
    String toId,
    int amountBase,
  ) async {
    final pools = await XerisApiService.getPools();
    if (pools == null || pools.isEmpty) return null;

    SwapRoute? bestRoute;

    // — Pass 1: Direct pools — fetch all quotes in parallel
    final directPools = pools
        .where(
          (p) =>
              (p.tokenA == fromId && p.tokenB == toId) ||
              (p.tokenA == toId && p.tokenB == fromId),
        )
        .toList();

    final directQuotes = await Future.wait(
      directPools.map(
        (pool) => XerisApiService.getSwapQuote(
          poolId: pool.poolId,
          inputTokenId: fromId,
          amount: amountBase,
        ),
      ),
    );

    for (int i = 0; i < directPools.length; i++) {
      final pool = directPools[i];
      final quote = directQuotes[i];
      if (quote == null) continue;

      final direction = fromId == pool.tokenA ? 'swap_a_to_b' : 'swap_b_to_a';
      final route = SwapRoute(
        hops: [
          RouteHop(
            pool: pool,
            fromToken: fromId,
            toToken: toId,
            direction: direction,
            quote: quote,
          ),
        ],
        totalInputLamports: amountBase,
        totalOutputLamports: quote.outputAmount,
      );
      if (bestRoute == null ||
          route.totalOutputLamports > bestRoute.totalOutputLamports) {
        bestRoute = route;
      }
    }

    // — Pass 2: 2-hop routes — fetch all hop1 quotes in parallel first
    final intermediates = <String>{};
    for (final hub in _routingHubs) {
      if (hub != fromId && hub != toId) intermediates.add(hub);
    }
    for (final p in pools) {
      if (p.tokenA == fromId && p.tokenB != toId) intermediates.add(p.tokenB);
      if (p.tokenB == fromId && p.tokenA != toId) intermediates.add(p.tokenA);
    }

    // Collect all hop1 pool candidates across all intermediates
    final hop1Candidates = <({XerisPool pool, String mid})>[];
    for (final mid in intermediates) {
      final hop1Pools = pools
          .where(
            (p) =>
                (p.tokenA == fromId && p.tokenB == mid) ||
                (p.tokenA == mid && p.tokenB == fromId),
          )
          .toList();
      final hop2Pools = pools
          .where(
            (p) =>
                (p.tokenA == mid && p.tokenB == toId) ||
                (p.tokenA == toId && p.tokenB == mid),
          )
          .toList();
      if (hop1Pools.isEmpty || hop2Pools.isEmpty) continue;
      for (final pool in hop1Pools) {
        hop1Candidates.add((pool: pool, mid: mid));
      }
    }

    if (hop1Candidates.isNotEmpty) {
      // Fetch all hop1 quotes in parallel
      final hop1Quotes = await Future.wait(
        hop1Candidates.map(
          (c) => XerisApiService.getSwapQuote(
            poolId: c.pool.poolId,
            inputTokenId: fromId,
            amount: amountBase,
          ),
        ),
      );

      // Build hop2 candidates from successful hop1 quotes
      final hop2Candidates =
          <
            ({
              XerisPool hop1Pool,
              String mid,
              SwapQuote hop1Quote,
              XerisPool hop2Pool,
            })
          >[];
      for (int i = 0; i < hop1Candidates.length; i++) {
        final hop1Quote = hop1Quotes[i];
        if (hop1Quote == null) continue;
        final mid = hop1Candidates[i].mid;
        final hop1Pool = hop1Candidates[i].pool;
        final hop2Pools = pools
            .where(
              (p) =>
                  (p.tokenA == mid && p.tokenB == toId) ||
                  (p.tokenA == toId && p.tokenB == mid),
            )
            .toList();
        for (final hop2Pool in hop2Pools) {
          hop2Candidates.add((
            hop1Pool: hop1Pool,
            mid: mid,
            hop1Quote: hop1Quote,
            hop2Pool: hop2Pool,
          ));
        }
      }

      // Fetch all hop2 quotes in parallel
      final hop2Quotes = await Future.wait(
        hop2Candidates.map(
          (c) => XerisApiService.getSwapQuote(
            poolId: c.hop2Pool.poolId,
            inputTokenId: c.mid,
            amount: c.hop1Quote.outputAmount,
          ),
        ),
      );

      for (int i = 0; i < hop2Candidates.length; i++) {
        final c = hop2Candidates[i];
        final hop2Quote = hop2Quotes[i];
        if (hop2Quote == null) continue;

        final hop1Direction = fromId == c.hop1Pool.tokenA
            ? 'swap_a_to_b'
            : 'swap_b_to_a';
        final hop2Direction = c.mid == c.hop2Pool.tokenA
            ? 'swap_a_to_b'
            : 'swap_b_to_a';

        final route = SwapRoute(
          hops: [
            RouteHop(
              pool: c.hop1Pool,
              fromToken: fromId,
              toToken: c.mid,
              direction: hop1Direction,
              quote: c.hop1Quote,
            ),
            RouteHop(
              pool: c.hop2Pool,
              fromToken: c.mid,
              toToken: toId,
              direction: hop2Direction,
              quote: hop2Quote,
            ),
          ],
          totalInputLamports: amountBase,
          totalOutputLamports: hop2Quote.outputAmount,
        );
        if (bestRoute == null ||
            route.totalOutputLamports > bestRoute.totalOutputLamports) {
          bestRoute = route;
        }
      }
    }

    return bestRoute;
  }

  Future<String?> placeLimitOrder({
    required String walletAddress,
    required String mnemonic,
    required AssetModel fromAsset,
    required AssetModel toAsset,
    required double amount,
    required double limitPrice,
  }) async {
    throw UnsupportedError(ordersUnavailableMessage);
  }

  Future<String?> cancelLimitOrder({
    required String mnemonic,
    required String poolId,
    required String orderId,
  }) async {
    final keyPair = await WalletService.getKeyPair(mnemonic);

    return await XerisApiService.callContract(
      keyPair: keyPair,
      contractId: poolId,
      method: 'cancel_limit_order',
      args: Uint8List.fromList(jsonEncode({'order_id': orderId}).codeUnits),
    );
  }

  Future<String?> createDcaOrder({
    required String walletAddress,
    required String mnemonic,
    required AssetModel fromAsset,
    required AssetModel toAsset,
    required double totalAmount,
    required double amountPerTick,
    required int intervalSeconds,
    required int totalTicks,
  }) async {
    throw UnsupportedError(ordersUnavailableMessage);
  }

  Future<String?> cancelDcaOrder({
    required String mnemonic,
    required String poolId,
    required String orderId,
  }) async {
    final keyPair = await WalletService.getKeyPair(mnemonic);

    return await XerisApiService.callContract(
      keyPair: keyPair,
      contractId: poolId,
      method: 'cancel_dca_order',
      args: Uint8List.fromList(jsonEncode({'order_id': orderId}).codeUnits),
    );
  }

  /// Base-unit balance of [tokenId] in [balances], or 0 if not held.
  int _balanceOf(AccountBalances balances, String tokenId) {
    for (final tb in balances.tokenBalances) {
      if (tb.tokenId == tokenId) return tb.balance.toInt();
    }
    return 0;
  }

  String _mapTokenId(String id) {
    final lowerId = id.toLowerCase();
    if (lowerId == 'xrs' || lowerId == 'xrs_native') return 'xrs_native';
    if (lowerId == 'usdc' || lowerId == 'xusdc' || lowerId == 'xeris_usdc') {
      return 'xeris_usdc';
    }
    return id;
  }
}
