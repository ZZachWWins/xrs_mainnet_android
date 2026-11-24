import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:solana/solana.dart';
import 'package:xeris_wallet/core/config/network_config.dart';
import 'package:xeris_wallet/core/models/xeris_api_models.dart';
import 'package:xeris_wallet/core/services/base_api_service.dart';
import 'package:xeris_wallet/core/services/xeris_api_service.dart';

class _PoolCacheEntry {
  final List<XerisPool> pools;
  final DateTime fetchedAt;

  _PoolCacheEntry(this.pools) : fetchedAt = DateTime.now();
}

class DexService extends BaseApiService {
  static const _cacheLifetime = Duration(minutes: 5);
  static const _loadBudget = Duration(seconds: 8);
  static const _requestTimeout = Duration(seconds: 4);
  static const _detailConcurrency = 4;
  static const _maxPoolPages = 128;

  static final _cache = <bool, _PoolCacheEntry>{};
  static final _inflight = <bool, Future<List<XerisPool>?>>{};
  static String? _activeScope;
  static int _generation = 0;

  static String get _currentScope =>
      '${NetworkConfig.currentNetwork.name}|${NetworkConfig.rpcUrl}|${NetworkConfig.controlUrl}';

  /// Invalidate both cache entries and requests started before a network change.
  static void clearCache() {
    _generation++;
    _cache.clear();
    _inflight.clear();
    _activeScope = null;
  }

  static String _selectScope() {
    final scope = _currentScope;
    if (_activeScope != scope) {
      clearCache();
      _activeScope = scope;
    }
    return scope;
  }

  static bool _isCurrent(String scope, int generation) =>
      generation == _generation &&
      scope == _activeScope &&
      scope == _currentScope;

  /// Load bounded pool summaries for pricing. Order screens can explicitly
  /// request contract details without making dashboard balances wait for them.
  static Future<List<XerisPool>?> getPools({
    bool forceRefresh = false,
    bool includeOrders = false,
  }) {
    final scope = _selectScope();
    final cached = _cache[includeOrders];
    if (!forceRefresh &&
        cached != null &&
        DateTime.now().difference(cached.fetchedAt) < _cacheLifetime) {
      return Future.value(cached.pools);
    }
    final pending = _inflight[includeOrders];
    if (pending != null) return pending;

    final generation = _generation;
    final explorerUrl = NetworkConfig.rpcUrl;
    final controlUrl = NetworkConfig.controlUrl;
    late final Future<List<XerisPool>?> request;
    request = _fetchAndCache(
      scope: scope,
      generation: generation,
      explorerUrl: explorerUrl,
      controlUrl: controlUrl,
      forceRefresh: forceRefresh,
      includeOrders: includeOrders,
    ).whenComplete(() {
      if (identical(_inflight[includeOrders], request)) {
        _inflight.remove(includeOrders);
      }
    });
    _inflight[includeOrders] = request;
    return request;
  }

  static Future<List<XerisPool>?> _fetchAndCache({
    required String scope,
    required int generation,
    required String explorerUrl,
    required String controlUrl,
    required bool forceRefresh,
    required bool includeOrders,
  }) async {
    try {
      final List<XerisPool> pools;
      if (includeOrders) {
        final summaries = await getPools(forceRefresh: forceRefresh);
        if (summaries == null || !_isCurrent(scope, generation)) return null;
        if (summaries.every(
          (pool) => pool.limitOrders != null && pool.dcaOrders != null,
        )) {
          pools = summaries;
        } else {
          pools = await _loadDetails(
            summaries.map((pool) => pool.poolId).toList(),
            controlUrl,
            scope,
            generation,
            DateTime.now().add(_loadBudget),
            summaries: summaries,
          );
        }
      } else {
        pools = await _loadSummaries(
          explorerUrl,
          controlUrl,
          scope,
          generation,
          DateTime.now().add(_loadBudget),
        );
      }
      if (!_isCurrent(scope, generation)) return null;
      final result = List<XerisPool>.unmodifiable(pools);
      _cache[includeOrders] = _PoolCacheEntry(result);
      return result;
    } catch (error) {
      if (!_isCurrent(scope, generation)) return null;
      if (kDebugMode) debugPrint('Pool loading failed: $error');
      return _cache[includeOrders]?.pools ??
          (includeOrders ? _cache[false]?.pools : null);
    }
  }

  static Uri _endpoint(String base, String path) =>
      Uri.parse('${base.replaceFirst(RegExp(r'/+$'), '')}$path');

  static Future<dynamic> _get(
    Uri uri,
    String scope,
    int generation,
    DateTime deadline,
  ) {
    if (!_isCurrent(scope, generation)) {
      throw StateError('Network changed while loading pools');
    }
    final remaining = deadline.difference(DateTime.now());
    if (remaining <= Duration.zero) {
      throw TimeoutException('Pool loading exceeded its time budget');
    }
    return BaseApiService.get(
      uri.toString(),
      timeout: remaining < _requestTimeout ? remaining : _requestTimeout,
    );
  }

  static Future<List<XerisPool>> _loadSummaries(
    String explorerUrl,
    String controlUrl,
    String scope,
    int generation,
    DateTime deadline,
  ) async {
    final pools = <String, XerisPool>{};
    final seenCursors = <String>{};
    String? cursor;
    for (var page = 0; page < _maxPoolPages; page++) {
      final uri = _endpoint(explorerUrl, '/v2/pools').replace(
        queryParameters: {'limit': '32', if (cursor != null) 'after': cursor},
      );
      final dynamic data;
      try {
        data = await _get(uri, scope, generation, deadline);
      } on ApiException catch (error) {
        // An unavailable legacy route is the only reason to fan out to details.
        if (page == 0 && (error.statusCode == 404 || error.statusCode == 405)) {
          return _loadLegacyPools(controlUrl, scope, generation, deadline);
        }
        rethrow;
      }
      if (data is! Map || data['success'] == false || data['pools'] is! List) {
        throw const FormatException('Invalid pool page response');
      }
      for (final row in data['pools'] as List) {
        if (row is! Map) {
          throw const FormatException('Invalid pool entry');
        }
        final pool = XerisPool.fromJson(Map<String, dynamic>.from(row));
        if (pool.poolId.isEmpty || pool.tokenA.isEmpty || pool.tokenB.isEmpty) {
          throw const FormatException('Pool entry is missing its identity');
        }
        // These prices are raw reserve ratios. Decimal adjustment belongs to
        // the price provider, exactly as it did for contract detail responses.
        pools[pool.poolId] = pool;
      }
      final next = data['next_after'];
      if (next == null || next == '') return pools.values.toList();
      if (next is! String || !seenCursors.add(next)) {
        throw const FormatException('Pool pagination cursor did not advance');
      }
      cursor = next;
    }
    throw const FormatException('Pool pagination exceeded its page budget');
  }

  static Future<List<XerisPool>> _loadLegacyPools(
    String controlUrl,
    String scope,
    int generation,
    DateTime deadline,
  ) async {
    final data = await _get(
      _endpoint(controlUrl, '/contracts'),
      scope,
      generation,
      deadline,
    );
    if (data is! Map || data['success'] != true || data['contracts'] is! List) {
      throw const FormatException('Invalid legacy contract list');
    }
    final ids = <String>{};
    for (final contract in data['contracts'] as List) {
      if (contract is Map &&
          contract['type'] == 'Swap' &&
          contract['contract_id'] is String &&
          (contract['contract_id'] as String).isNotEmpty) {
        ids.add(contract['contract_id'] as String);
      }
    }
    return _loadDetails(ids.toList(), controlUrl, scope, generation, deadline);
  }

  static Future<List<XerisPool>> _loadDetails(
    List<String> ids,
    String controlUrl,
    String scope,
    int generation,
    DateTime deadline, {
    List<XerisPool>? summaries,
  }) async {
    final results = List<XerisPool?>.filled(ids.length, null);
    if (summaries != null) {
      for (var i = 0; i < summaries.length; i++) {
        results[i] = summaries[i];
      }
    }
    var nextIndex = 0;
    Future<void> worker() async {
      while (nextIndex < ids.length &&
          _isCurrent(scope, generation) &&
          DateTime.now().isBefore(deadline)) {
        final index = nextIndex++;
        try {
          final pool = await _getPoolInfoAt(
            ids[index],
            controlUrl,
            scope,
            generation,
            deadline,
          );
          if (pool != null) results[index] = pool;
        } catch (error) {
          if (kDebugMode) debugPrint('Pool detail unavailable: $error');
        }
      }
    }

    await Future.wait(List.generate(
      ids.length < _detailConcurrency ? ids.length : _detailConcurrency,
      (_) => worker(),
    ));
    return results.whereType<XerisPool>().toList();
  }

  /// Gets a swap quote via REST from the control API.
  static Future<dynamic> getSwapQuote({
    required String poolId,
    required String inputTokenId,
    required int amount,
  }) async {
    final uri = _endpoint(
      NetworkConfig.controlUrl,
      '/contract/${Uri.encodeComponent(poolId)}/quote',
    ).replace(
        queryParameters: {'input_token': inputTokenId, 'amount': '$amount'});
    return BaseApiService.get(uri.toString());
  }

  /// Get full contract state when a swap or order screen needs it.
  static Future<XerisPool?> getPoolInfo(String poolId) async {
    final scope = _selectScope();
    final generation = _generation;
    final pool = await _getPoolInfoAt(
      poolId,
      NetworkConfig.controlUrl,
      scope,
      generation,
      DateTime.now().add(_requestTimeout),
    );
    return _isCurrent(scope, generation) ? pool : null;
  }

  static Future<XerisPool?> _getPoolInfoAt(
    String poolId,
    String controlUrl,
    String scope,
    int generation,
    DateTime deadline,
  ) async {
    final data = await _get(
      _endpoint(controlUrl, '/contract/${Uri.encodeComponent(poolId)}'),
      scope,
      generation,
      deadline,
    );
    if (data is! Map || data['success'] != true || data['contract'] is! Map) {
      return null;
    }
    final stateMap = data['contract']['state'];
    if (stateMap is! Map) return null;
    final state = stateMap['Swap'] ?? stateMap;
    if (state is! Map) return null;
    final reserveA = XerisAccount.toNum(state['reserve_a']).toDouble();
    final reserveB = XerisAccount.toNum(state['reserve_b']).toDouble();
    final tokenA = state['token_a'];
    final tokenB = state['token_b'];
    if (tokenA is! String ||
        tokenA.isEmpty ||
        tokenB is! String ||
        tokenB.isEmpty) {
      return null;
    }
    return XerisPool(
      poolId: poolId,
      tokenA: tokenA,
      tokenB: tokenB,
      priceAInB: reserveA > 0 ? reserveB / reserveA : 0.0,
      priceBInA: reserveB > 0 ? reserveA / reserveB : 0.0,
      limitOrders: (state['limit_orders'] as List? ?? [])
          .map((order) => LimitOrder.fromJson(order, poolId))
          .toList(),
      dcaOrders: (state['dca_orders'] as List? ?? [])
          .map((order) => DcaOrder.fromJson(order, poolId))
          .toList(),
    );
  }

  /// Wrap native XRS -> xrs_native token for DEX trading
  static Future<String?> wrapXrs({
    required Ed25519HDKeyPair keyPair,
    required int amountLamports,
  }) async {
    return await XerisApiService.wrapXrs(
      keyPair: keyPair,
      amountLamports: amountLamports,
    );
  }

  /// Unwrap xrs_native token -> native XRS
  static Future<String?> unwrapXrs({
    required Ed25519HDKeyPair keyPair,
    required int amountLamports,
  }) async {
    return await XerisApiService.unwrapXrs(
      keyPair: keyPair,
      amountLamports: amountLamports,
    );
  }

  /// Execute swap tokens on a pool.
  static Future<String?> swap({
    required Ed25519HDKeyPair keyPair,
    required String poolId,
    required String direction,
    required int inputAmount,
    required int minOutput,
  }) async {
    return await XerisApiService.swap(
      keyPair: keyPair,
      poolId: poolId,
      direction: direction,
      inputAmount: inputAmount,
      minOutput: minOutput,
    );
  }

  /// Add liquidity to a pool.
  static Future<String?> addLiquidity({
    required Ed25519HDKeyPair keyPair,
    required String poolId,
    required int amountA,
    required int amountB,
  }) async {
    return await XerisApiService.addLiquidity(
      keyPair: keyPair,
      poolId: poolId,
      amountA: amountA,
      amountB: amountB,
    );
  }

  /// Remove liquidity from a pool.
  static Future<String?> removeLiquidity({
    required Ed25519HDKeyPair keyPair,
    required String poolId,
    required int shares,
  }) async {
    return await XerisApiService.removeLiquidity(
      keyPair: keyPair,
      poolId: poolId,
      shares: shares,
    );
  }
}
