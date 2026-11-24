import 'dart:math';

class XerisStatsResponse {
  final bool success;
  final StatsData data;

  XerisStatsResponse({required this.success, required this.data});

  factory XerisStatsResponse.fromJson(Map<String, dynamic> json) {
    return XerisStatsResponse(
      success: json['success'] ?? false,
      data: StatsData.fromJson(json['data'] ?? {}),
    );
  }
}

class StatsData {
  final int blockHeight;
  final int currentSlot;
  final int totalTransactions;
  final int totalAccounts;
  final num totalStaked;
  final int validatorCount;
  final double tpsEstimate;

  StatsData({
    required this.blockHeight,
    required this.currentSlot,
    required this.totalTransactions,
    required this.totalAccounts,
    required this.totalStaked,
    required this.validatorCount,
    required this.tpsEstimate,
  });

  factory StatsData.fromJson(Map<String, dynamic> json) {
    return StatsData(
      blockHeight: json['block_height'] ?? 0,
      currentSlot: json['current_slot'] ?? 0,
      totalTransactions: json['total_transactions'] ?? 0,
      totalAccounts: json['total_accounts'] ?? 0,
      totalStaked: json['total_staked'] ?? 0,
      validatorCount: json['validator_count'] ?? 0,
      tpsEstimate: (json['tps_estimate'] ?? 0).toDouble(),
    );
  }
}

class XerisBlocksResponse {
  final bool success;
  final List<XerisBlock> data;
  final Pagination? pagination;

  XerisBlocksResponse(
      {required this.success, required this.data, this.pagination});

  factory XerisBlocksResponse.fromJson(Map<String, dynamic> json) {
    return XerisBlocksResponse(
      success: json['success'] ?? false,
      data: (json['data'] as List? ?? [])
          .map((item) => XerisBlock.fromJson(item))
          .toList(),
      pagination: json['pagination'] != null
          ? Pagination.fromJson(json['pagination'])
          : null,
    );
  }
}

class XerisBlock {
  final int slot;
  final String hash;
  final String proposer;
  final int txCount;
  final int pohTimestamp;

  XerisBlock({
    required this.slot,
    required this.hash,
    required this.proposer,
    required this.txCount,
    required this.pohTimestamp,
  });

  factory XerisBlock.fromJson(Map<String, dynamic> json) {
    return XerisBlock(
      slot: json['slot'] ?? 0,
      hash: json['hash'] ?? '',
      proposer: json['proposer'] ?? '',
      txCount: json['tx_count'] ?? 0,
      pohTimestamp: json['poh_timestamp'] ?? 0,
    );
  }
}

class XerisTransactionsResponse {
  final bool success;
  final List<XerisTransaction> data;
  final Pagination? pagination;

  XerisTransactionsResponse(
      {required this.success, required this.data, this.pagination});

  factory XerisTransactionsResponse.fromJson(Map<String, dynamic> json) {
    return XerisTransactionsResponse(
      success: json['success'] ?? false,
      data: (json['data'] as List? ?? [])
          .map((item) => XerisTransaction.fromJson(item))
          .toList(),
      pagination: json['pagination'] != null
          ? Pagination.fromJson(json['pagination'])
          : null,
    );
  }
}

class XerisTransaction {
  final String signature;
  final int blockSlot;
  final String from;
  final String to;
  final num amount;
  final double amountXrs;
  final String status;
  final String? txType;
  final String? tokenId;
  final double? tokenAmount;
  final String? method;
  final int? timestamp;
  final num? fee;

  XerisTransaction({
    required this.signature,
    required this.blockSlot,
    required this.from,
    required this.to,
    required this.amount,
    required this.amountXrs,
    required this.status,
    this.txType,
    this.tokenId,
    this.tokenAmount,
    this.method,
    this.timestamp,
    this.fee,
  });

  factory XerisTransaction.fromJson(Map<String, dynamic> json) {
    return XerisTransaction(
      signature: json['signature'] ?? '',
      blockSlot: json['block_slot'] ?? 0,
      from: json['from'] ?? '',
      to: json['to'] ?? '',
      amount: json['amount'] ?? 0,
      amountXrs: (json['amount_xrs'] ?? 0).toDouble(),
      status: json['status'] ?? '',
      txType: json['tx_type'],
      tokenId: json['token_id'],
      tokenAmount: json['token_amount'] != null
          ? (json['token_amount'] is int
              ? (json['token_amount'] as int).toDouble()
              : (json['token_amount'] as num).toDouble())
          : null,
      method: json['method'],
      timestamp: json['timestamp'] ?? json['poh_timestamp'],
      fee: json['fee'],
    );
  }
}

class XerisAccountResponse {
  final bool success;
  final XerisAccount data;

  XerisAccountResponse({required this.success, required this.data});

  factory XerisAccountResponse.fromJson(Map<String, dynamic> json) {
    return XerisAccountResponse(
      success: json['success'] ?? false,
      data: XerisAccount.fromJson(json['data'] ?? {}),
    );
  }
}

class XerisAccount {
  final String address;
  final num balance;
  final double balanceXrs;
  final num stake;
  final num unbonding;
  final int? unlockAt;
  final bool isValidator;
  final int blocksProposed;
  final int nonce;
  final Map<String, XerisTokenBalance> tokens;

  XerisAccount({
    required this.address,
    required this.balance,
    required this.balanceXrs,
    required this.stake,
    this.unbonding = 0,
    this.unlockAt,
    required this.isValidator,
    required this.blocksProposed,
    required this.nonce,
    this.tokens = const {},
  });

  factory XerisAccount.fromJson(Map<String, dynamic> json) {
    // Handle both flat and nested JSON structures
    final address = json['address'] ?? '';
    final balance = toNum(json['balance']);

    Map<String, XerisTokenBalance> tokenMap = {};
    if (json['tokens'] is Map) {
      final tokensJson = json['tokens'] as Map<String, dynamic>;
      tokensJson.forEach((id, tokenData) {
        tokenMap[id] = XerisTokenBalance.fromJson({
          'address': address,
          'token_id': id,
          'balance': tokenData, // Passes full map to sub-parser
        });
      });
    }

    return XerisAccount(
      address: address,
      balance: balance,
      balanceXrs: toDouble(json['balance_xrs'] ?? (balance / 1e9)),
      stake: toNum(json['stake']),
      unbonding: toNum(json['unbonding']),
      unlockAt:
          json['unlock_at'] != null ? toNum(json['unlock_at']).toInt() : null,
      isValidator: json['is_validator'] ?? false,
      blocksProposed: toNum(json['blocks_proposed']).toInt(),
      nonce: toNum(json['nonce']).toInt(),
      tokens: tokenMap,
    );
  }

  XerisAccount copyWith({
    String? address,
    num? balance,
    double? balanceXrs,
    num? stake,
    num? unbonding,
    int? unlockAt,
    bool? isValidator,
    int? blocksProposed,
    int? nonce,
    Map<String, XerisTokenBalance>? tokens,
  }) {
    return XerisAccount(
      address: address ?? this.address,
      balance: balance ?? this.balance,
      balanceXrs: balanceXrs ?? this.balanceXrs,
      stake: stake ?? this.stake,
      unbonding: unbonding ?? this.unbonding,
      unlockAt: unlockAt ?? this.unlockAt,
      isValidator: isValidator ?? this.isValidator,
      blocksProposed: blocksProposed ?? this.blocksProposed,
      nonce: nonce ?? this.nonce,
      tokens: tokens ?? this.tokens,
    );
  }

  static num toNum(dynamic val) {
    if (val == null) return 0;
    if (val is num) return val;
    if (val is String) return num.tryParse(val) ?? 0;
    if (val is Map) {
      // Handle nested balance objects common on Xeris port 50008
      return toNum(val['lamports'] ??
          val['amount'] ??
          val['total'] ??
          val['balance'] ??
          0);
    }
    return 0;
  }

  static double toDouble(dynamic val) {
    if (val == null) return 0.0;
    if (val is double) return val;
    if (val is int) return val.toDouble();
    if (val is String) return double.tryParse(val) ?? 0.0;
    if (val is Map) {
      return toDouble(
          val['display'] ?? val['value'] ?? val['amount_xrs'] ?? 0.0);
    }
    return 0.0;
  }
}

class XerisValidatorsResponse {
  final bool success;
  final List<XerisValidator> data;
  final num totalStaked;
  final double totalStakedXrs;
  final int validatorCount;

  XerisValidatorsResponse({
    required this.success,
    required this.data,
    required this.totalStaked,
    required this.totalStakedXrs,
    required this.validatorCount,
  });

  factory XerisValidatorsResponse.fromJson(Map<String, dynamic> json) {
    return XerisValidatorsResponse(
      success: json['success'] ?? false,
      data: (json['data'] as List? ?? [])
          .map((item) => XerisValidator.fromJson(item))
          .toList(),
      totalStaked: json['total_staked'] ?? 0,
      totalStakedXrs: (json['total_staked_xrs'] ?? 0).toDouble(),
      validatorCount: json['validator_count'] ?? 0,
    );
  }
}

class XerisValidator {
  final String address;
  final int blocksProposed;
  final num stake;
  final double stakePercentage;
  final double commission;
  final int lastVote;
  final String nodePubkey;

  XerisValidator({
    required this.address,
    required this.blocksProposed,
    required this.stake,
    required this.stakePercentage,
    required this.commission,
    required this.lastVote,
    required this.nodePubkey,
  });

  factory XerisValidator.fromJson(Map<String, dynamic> json) {
    return XerisValidator(
      address: json['address'] ?? json['votePubkey'] ?? '',
      blocksProposed: json['blocks_proposed'] ?? 0,
      stake: json['activatedStake'] ?? json['stake'] ?? 0,
      stakePercentage: (json['stake_percentage'] ?? 0).toDouble(),
      commission: (json['commission'] ?? 0).toDouble(),
      lastVote: json['lastVote'] ?? 0,
      nodePubkey: json['nodePubkey'] ?? '',
    );
  }
}

class XerisSearchResponse {
  final bool success;
  final String resultType;
  final dynamic data;

  XerisSearchResponse({
    required this.success,
    required this.resultType,
    required this.data,
  });

  factory XerisSearchResponse.fromJson(Map<String, dynamic> json) {
    return XerisSearchResponse(
      success: json['success'] ?? false,
      resultType: json['result_type'] ?? '',
      data: json['data'],
    );
  }
}

class Pagination {
  final int total;
  final int page;
  final int pageSize;
  final int totalPages;

  Pagination({
    required this.total,
    required this.page,
    required this.pageSize,
    required this.totalPages,
  });

  factory Pagination.fromJson(Map<String, dynamic> json) {
    return Pagination(
      total: json['total'] ?? 0,
      page: json['page'] ?? 0,
      pageSize: json['page_size'] ?? 0,
      totalPages: json['total_pages'] ?? 0,
    );
  }
}

class XerisToken {
  final String id;
  final String symbol;
  final String name;
  final int decimals;
  final num totalSupply;
  final String? icon;

  XerisToken({
    required this.id,
    required this.symbol,
    required this.name,
    required this.decimals,
    required this.totalSupply,
    this.icon,
  });

  factory XerisToken.fromJson(Map<String, dynamic> json) {
    return XerisToken(
      id: json['token_id'] ?? json['id'] ?? '',
      symbol: json['symbol'] ?? '',
      name: json['name'] ?? '',
      decimals: int.tryParse(json['decimals']?.toString() ?? '0') ?? 0,
      totalSupply: num.tryParse(json['total_supply']?.toString() ?? '0') ?? 0,
      icon: json['icon'],
    );
  }
}

class XerisPoolsResponse {
  final List<XerisPool> pools;

  XerisPoolsResponse({required this.pools});

  factory XerisPoolsResponse.fromJson(Map<String, dynamic> json) {
    return XerisPoolsResponse(
      pools: (json['pools'] as List? ?? [])
          .map((item) => XerisPool.fromJson(item))
          .toList(),
    );
  }
}

class XerisPool {
  final String poolId;
  final String tokenA;
  final String tokenB;
  final double priceAInB;
  final double priceBInA;
  final List<LimitOrder>? limitOrders;
  final List<DcaOrder>? dcaOrders;

  XerisPool({
    required this.poolId,
    required this.tokenA,
    required this.tokenB,
    required this.priceAInB,
    required this.priceBInA,
    this.limitOrders,
    this.dcaOrders,
  });

  factory XerisPool.fromJson(Map<String, dynamic> json) {
    return XerisPool(
      poolId: json['pool_id'] ?? '',
      tokenA: json['token_a'] ?? '',
      tokenB: json['token_b'] ?? '',
      priceAInB: double.tryParse(json['price_a_in_b']?.toString() ?? '') ?? 0.0,
      priceBInA: double.tryParse(json['price_b_in_a']?.toString() ?? '') ?? 0.0,
      limitOrders: (json['limit_orders'] as List?)
          ?.map((o) => LimitOrder.fromJson(o, json['pool_id'] ?? ''))
          .toList(),
      dcaOrders: (json['dca_orders'] as List?)
          ?.map((o) => DcaOrder.fromJson(o, json['pool_id'] ?? ''))
          .toList(),
    );
  }
}

class LimitOrder {
  final String id;
  final String poolId;
  final String owner;
  final num amount;
  final num minOutput;
  final String targetToken;
  final String fromToken;

  LimitOrder({
    required this.id,
    required this.poolId,
    required this.owner,
    required this.amount,
    required this.minOutput,
    required this.targetToken,
    required this.fromToken,
  });

  factory LimitOrder.fromJson(Map<String, dynamic> json, String poolId) {
    return LimitOrder(
      id: json['order_id'] ?? json['id'] ?? '',
      poolId: poolId,
      owner: json['owner'] ?? '',
      amount: XerisAccount.toNum(json['amount']),
      minOutput:
          XerisAccount.toNum(json['expected_output'] ?? json['min_output']),
      targetToken: json['target_token'] ?? '',
      fromToken: json['from_token'] ?? '',
    );
  }
}

class DcaOrder {
  final String id;
  final String poolId;
  final String owner;
  final String inputToken;
  final String outputToken;
  final num totalAmountIn;
  final num amountPerTick;
  final int intervalSeconds;
  final int totalTicks;
  final int ticksCompleted;
  final bool isActive;

  DcaOrder({
    required this.id,
    required this.poolId,
    required this.owner,
    required this.inputToken,
    required this.outputToken,
    required this.totalAmountIn,
    required this.amountPerTick,
    required this.intervalSeconds,
    required this.totalTicks,
    required this.ticksCompleted,
    required this.isActive,
  });

  factory DcaOrder.fromJson(Map<String, dynamic> json, String poolId) {
    return DcaOrder(
      id: json['order_id'] ?? json['id'] ?? '',
      poolId: poolId,
      owner: json['owner'] ?? '',
      inputToken: json['input_token'] ?? json['from_token'] ?? '',
      outputToken: json['output_token'] ?? json['target_token'] ?? '',
      totalAmountIn: XerisAccount.toNum(json['total_amount'] ?? json['amount']),
      amountPerTick: XerisAccount.toNum(json['amount_per_tick']),
      intervalSeconds: XerisAccount.toNum(json['interval_seconds']).toInt(),
      totalTicks: XerisAccount.toNum(json['total_ticks']).toInt(),
      ticksCompleted: XerisAccount.toNum(json['ticks_completed']).toInt(),
      isActive: json['is_active'] ?? true,
    );
  }
}

class SwapQuote {
  final String inputToken;
  final int inputAmount;
  final String outputToken;
  final int outputAmount;
  final int fee;
  final int feeBps;
  final double priceImpactPct;
  final double effectivePrice;

  SwapQuote({
    required this.inputToken,
    required this.inputAmount,
    required this.outputToken,
    required this.outputAmount,
    required this.fee,
    required this.feeBps,
    required this.priceImpactPct,
    required this.effectivePrice,
  });

  factory SwapQuote.fromJson(Map<String, dynamic> json) {
    return SwapQuote(
      inputToken: json['input_token']?.toString() ?? '',
      inputAmount: toInt(json['input_amount']),
      outputToken: json['output_token']?.toString() ?? '',
      outputAmount: toInt(json['output_amount']),
      fee: toInt(json['fee']),
      feeBps: toInt(json['fee_bps']),
      priceImpactPct:
          double.tryParse(json['price_impact_pct']?.toString() ?? '0') ?? 0.0,
      effectivePrice:
          double.tryParse(json['effective_price']?.toString() ?? '0') ?? 0.0,
    );
  }

  static int toInt(dynamic val) {
    if (val == null) return 0;
    if (val is int) return val;
    if (val is String) return int.tryParse(val) ?? 0;
    if (val is double) return val.toInt();
    if (val is num) return val.toInt();
    return 0;
  }
}

class RouteHop {
  final XerisPool pool;
  final String fromToken;
  final String toToken;
  final String direction; // 'swap_a_to_b' or 'swap_b_to_a'
  final SwapQuote quote;

  RouteHop({
    required this.pool,
    required this.fromToken,
    required this.toToken,
    required this.direction,
    required this.quote,
  });
}

class SwapRoute {
  final List<RouteHop> hops;
  final int totalInputLamports;
  final int totalOutputLamports;

  SwapRoute({
    required this.hops,
    required this.totalInputLamports,
    required this.totalOutputLamports,
  });

  bool get isMultiHop => hops.length > 1;

  /// Token ID path, e.g. "xrs_native → xeris_usdc → some_token"
  String get routeDescription {
    final parts = hops.map((h) => h.fromToken).toList()..add(hops.last.toToken);
    return parts.join(' → ');
  }
}

class PoolInfo {
  final String tokenA;
  final String tokenB;
  final int reserveA;
  final int reserveB;
  final int feeBps;
  final int totalShares;

  PoolInfo({
    required this.tokenA,
    required this.tokenB,
    required this.reserveA,
    required this.reserveB,
    required this.feeBps,
    required this.totalShares,
  });

  factory PoolInfo.fromJson(Map<String, dynamic> json) {
    return PoolInfo(
      tokenA: json['token_a'] ?? '',
      tokenB: json['token_b'] ?? '',
      reserveA: json['reserve_a'] ?? 0,
      reserveB: json['reserve_b'] ?? 0,
      feeBps: json['fee_bps'] ?? 0,
      totalShares: json['total_shares'] ?? 0,
    );
  }
}

class AccountBalances {
  final double nativeXrs;
  final List<XerisTokenBalance> tokenBalances;
  final bool isStale;

  AccountBalances({
    required this.nativeXrs,
    required this.tokenBalances,
    this.isStale = false,
  });

  AccountBalances asStale() => AccountBalances(
        nativeXrs: nativeXrs,
        tokenBalances: tokenBalances,
        isStale: true,
      );

  static AccountBalances get empty =>
      AccountBalances(nativeXrs: 0.0, tokenBalances: []);
}

class XerisTokenBalance {
  final String address;
  final String tokenId;
  final num balance;
  final double balanceXrs;
  final String? symbol;
  final int decimals;

  XerisTokenBalance({
    required this.address,
    required this.tokenId,
    required this.balance,
    required this.balanceXrs,
    this.symbol,
    this.decimals = 9,
  });

  factory XerisTokenBalance.fromJson(Map<String, dynamic> json) {
    final balanceRaw = json['balance'];
    final balance = XerisAccount.toNum(balanceRaw);

    final tokenInfo = json['token_info'];
    final decimalValue = json['decimals'] ??
        (tokenInfo is Map ? tokenInfo['decimals'] : null) ??
        (balanceRaw is Map ? balanceRaw['decimals'] : null);
    final decimals = int.tryParse(decimalValue?.toString() ?? '9') ?? 9;
    if (decimals < 0 || decimals > 255) {
      throw const FormatException('Invalid token decimals');
    }

    // An explicit zero is valid. Missing display metadata must be scaled from
    // raw units rather than interpreted as a zero balance.
    final displayValue = json['balance_display'] ??
        json['balance_xrs'] ??
        (balanceRaw is Map
            ? balanceRaw['display'] ??
                balanceRaw['value'] ??
                balanceRaw['balance_xrs']
            : null);
    final display =
        displayValue == null ? null : double.tryParse(displayValue.toString());
    final balanceXrs = display ?? balance / pow(10, decimals);
    if (!balanceXrs.isFinite) {
      throw const FormatException('Invalid token display balance');
    }

    final rawSymbol = json['symbol']?.toString().trim();

    return XerisTokenBalance(
      address: json['address'] ?? '',
      tokenId: json['token_id'] ?? json['id'] ?? '',
      balance: balance,
      balanceXrs: balanceXrs,
      symbol: (rawSymbol != null && rawSymbol.isNotEmpty) ? rawSymbol : null,
      decimals: decimals,
    );
  }
}
