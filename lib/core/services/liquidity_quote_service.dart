import 'dart:typed_data';

import 'package:xeris_wallet/core/config/network_config.dart';
import 'package:xeris_wallet/core/services/base_api_service.dart';
import 'package:xeris_wallet/core/services/instruction_builder.dart';

class LiquidityPoolState {
  final String poolId;
  final String tokenA;
  final String tokenB;
  final BigInt reserveA;
  final BigInt reserveB;
  final BigInt totalShares;
  final Map<String, BigInt> ownerShares;

  const LiquidityPoolState({
    required this.poolId,
    required this.tokenA,
    required this.tokenB,
    required this.reserveA,
    required this.reserveB,
    required this.totalShares,
    this.ownerShares = const {},
  });
}

class LiquidityAddQuote {
  final String poolId;
  final BigInt amountA;
  final BigInt amountB;
  final BigInt acceptedA;
  final BigInt acceptedB;
  final BigInt shares;
  final BigInt minLpShares;
  final BigInt minAmountA;
  final BigInt minAmountB;

  const LiquidityAddQuote({
    required this.poolId,
    required this.amountA,
    required this.amountB,
    required this.acceptedA,
    required this.acceptedB,
    required this.shares,
    required this.minLpShares,
    required this.minAmountA,
    required this.minAmountB,
  });

  Uint8List toInstruction() => InstructionBuilder.buildAddLiquidityInstruction(
        poolId: poolId,
        amountA: amountA,
        amountB: amountB,
        minLpShares: minLpShares,
        minAmountA: minAmountA,
        minAmountB: minAmountB,
      );
}

class LiquidityRemoveQuote {
  final String poolId;
  final BigInt shares;
  final BigInt amountA;
  final BigInt amountB;
  final BigInt minAmountA;
  final BigInt minAmountB;

  const LiquidityRemoveQuote({
    required this.poolId,
    required this.shares,
    required this.amountA,
    required this.amountB,
    required this.minAmountA,
    required this.minAmountB,
  });

  Uint8List toInstruction() => InstructionBuilder.buildRemoveLiquidityInstruction(
        poolId: poolId,
        shares: shares,
        minAmountA: minAmountA,
        minAmountB: minAmountB,
      );
}

/// Quotes against fresh raw pool state using the node's integer arithmetic.
/// A failed or incomplete lookup never produces guessed signing bounds.
class LiquidityQuoteService {
  static const defaultSlippageBps = 50;
  static final _u64Max = (BigInt.one << 64) - BigInt.one;

  static BigInt _u64(dynamic value, String field, {bool positive = false}) {
    final BigInt parsed;
    if (value is BigInt) {
      parsed = value;
    } else if (value is int) {
      parsed = BigInt.from(value);
    } else if (value is String && RegExp(r'^\d+$').hasMatch(value)) {
      parsed = BigInt.parse(value);
    } else {
      throw FormatException('Exact integer $field is unavailable from the node.');
    }
    if (parsed < BigInt.zero || parsed > _u64Max || (positive && parsed == BigInt.zero)) {
      throw FormatException('$field must be ${positive ? 'a positive' : 'an unsigned'} 64-bit integer.');
    }
    return parsed;
  }

  static void _validatePool(LiquidityPoolState pool) {
    if (pool.poolId.isEmpty || pool.tokenA.isEmpty || pool.tokenB.isEmpty || pool.tokenA == pool.tokenB) {
      throw const FormatException('A valid pool with two distinct tokens is required.');
    }
    _u64(pool.reserveA, 'reserve_a');
    _u64(pool.reserveB, 'reserve_b');
    _u64(pool.totalShares, 'total_shares');
  }

  static Future<LiquidityPoolState> fetchPoolState(String poolId) async {
    final data = await BaseApiService.get(
      '${NetworkConfig.controlUrl}/contract/${Uri.encodeComponent(poolId)}',
    );
    final contract = data is Map ? data['contract'] : null;
    final state = contract is Map ? contract['state'] : null;
    final swap = state is Map ? state['Swap'] : null;
    if (data is! Map || data['success'] != true || contract is! Map ||
        contract['contract_id'] != poolId || contract['is_active'] != true || swap is! Map) {
      throw const FormatException('Fresh active pool state is unavailable. No liquidity transaction was signed.');
    }
    final rawOwners = swap['lp_shares'];
    if (rawOwners is! Map) {
      throw const FormatException('Pool ownership data is unavailable.');
    }
    final owners = <String, BigInt>{};
    for (final entry in rawOwners.entries) {
      if (entry.key is! String) throw const FormatException('Invalid LP owner in pool state.');
      owners[entry.key as String] = _u64(entry.value, 'lp_shares');
    }
    final pool = LiquidityPoolState(
      poolId: poolId,
      tokenA: swap['token_a'] is String ? swap['token_a'] as String : '',
      tokenB: swap['token_b'] is String ? swap['token_b'] as String : '',
      reserveA: _u64(swap['reserve_a'], 'reserve_a'),
      reserveB: _u64(swap['reserve_b'], 'reserve_b'),
      totalShares: _u64(swap['total_shares'], 'total_shares'),
      ownerShares: Map.unmodifiable(owners),
    );
    _validatePool(pool);
    return pool;
  }

  /// This small endpoint includes registry metadata even for a zero balance.
  static Future<int> fetchTokenDecimals(String walletAddress, String tokenId) async {
    final data = await BaseApiService.get(
      '${NetworkConfig.controlUrl}/token/balance/'
      '${Uri.encodeComponent(walletAddress)}/${Uri.encodeComponent(tokenId)}',
    );
    final info = data is Map ? data['token_info'] : null;
    if (info is! Map || info['token_id'] != tokenId) {
      throw FormatException('Token metadata for $tokenId is unavailable.');
    }
    final value = _u64(info['decimals'], 'token decimals');
    if (value > BigInt.from(255)) throw const FormatException('Invalid token decimals.');
    return value.toInt();
  }

  /// Converts a displayed decimal amount without rounding or floating point.
  static BigInt parseDisplayAmount(String input, int decimals) {
    if (decimals < 0 || decimals > 255) throw const FormatException('Invalid token decimals.');
    final text = input.trim().replaceAll(',', '.');
    if (!RegExp(r'^\d+(?:\.\d+)?$').hasMatch(text)) {
      throw const FormatException('Enter a positive decimal amount.');
    }
    final parts = text.split('.');
    final fraction = parts.length == 2 ? parts[1].replaceFirst(RegExp(r'0+$'), '') : '';
    if (fraction.length > decimals) {
      throw FormatException('This token supports at most $decimals decimal places.');
    }
    final raw = BigInt.parse(parts[0]) * BigInt.from(10).pow(decimals) +
        (fraction.isEmpty ? BigInt.zero : BigInt.parse(fraction.padRight(decimals, '0')));
    return _u64(raw, 'Token amount', positive: true);
  }

  static BigInt _minimum(BigInt expected, int slippageBps) {
    if (slippageBps < 0 || slippageBps >= 10000) {
      throw const FormatException('Slippage must be between 0 and 9999 basis points.');
    }
    final minimum = expected * BigInt.from(10000 - slippageBps) ~/ BigInt.from(10000);
    if (minimum <= BigInt.zero) {
      throw const FormatException('The liquidity amount is too small to enforce the selected slippage.');
    }
    return _u64(minimum, 'Liquidity minimum', positive: true);
  }

  static BigInt _sqrt(BigInt value) {
    if (value < BigInt.two) return value;
    var current = BigInt.one << ((value.bitLength + 1) ~/ 2);
    while (true) {
      final next = (current + value ~/ current) >> 1;
      if (next >= current) return current;
      current = next;
    }
  }

  static LiquidityAddQuote quoteAdd({
    required LiquidityPoolState pool,
    required BigInt amountA,
    required BigInt amountB,
    int slippageBps = defaultSlippageBps,
  }) {
    _validatePool(pool);
    _u64(amountA, 'amount_a', positive: true);
    _u64(amountB, 'amount_b', positive: true);
    final BigInt shares;
    final BigInt acceptedA;
    final BigInt acceptedB;
    if (pool.totalShares == BigInt.zero) {
      shares = _sqrt(amountA * amountB);
      acceptedA = amountA;
      acceptedB = amountB;
    } else {
      if (pool.reserveA == BigInt.zero || pool.reserveB == BigInt.zero) {
        throw const FormatException('Pool reserves are invalid.');
      }
      final sharesA = amountA * pool.totalShares ~/ pool.reserveA;
      final sharesB = amountB * pool.totalShares ~/ pool.reserveB;
      shares = sharesA < sharesB ? sharesA : sharesB;
      acceptedA = (shares * pool.reserveA + pool.totalShares - BigInt.one) ~/ pool.totalShares;
      acceptedB = (shares * pool.reserveB + pool.totalShares - BigInt.one) ~/ pool.totalShares;
    }
    _u64(shares, 'LP shares', positive: true);
    _u64(acceptedA, 'Accepted amount A', positive: true);
    _u64(acceptedB, 'Accepted amount B', positive: true);
    if (acceptedA > amountA || acceptedB > amountB) {
      throw const FormatException('The proportional deposit exceeds its maxima.');
    }
    _u64(pool.reserveA + acceptedA, 'Resulting reserve A');
    _u64(pool.reserveB + acceptedB, 'Resulting reserve B');
    _u64(pool.totalShares + shares, 'Resulting LP supply');
    return LiquidityAddQuote(
      poolId: pool.poolId,
      amountA: amountA,
      amountB: amountB,
      acceptedA: acceptedA,
      acceptedB: acceptedB,
      shares: shares,
      minLpShares: _minimum(shares, slippageBps),
      minAmountA: _minimum(acceptedA, slippageBps),
      minAmountB: _minimum(acceptedB, slippageBps),
    );
  }

  static LiquidityRemoveQuote quoteRemove({
    required LiquidityPoolState pool,
    required String walletAddress,
    required BigInt shares,
    int slippageBps = defaultSlippageBps,
  }) {
    _validatePool(pool);
    _u64(shares, 'LP shares', positive: true);
    final owned = pool.ownerShares[walletAddress] ?? BigInt.zero;
    if (pool.totalShares == BigInt.zero || shares > pool.totalShares || shares > owned) {
      throw const FormatException('Insufficient LP shares or empty pool.');
    }
    final amountA = shares * pool.reserveA ~/ pool.totalShares;
    final amountB = shares * pool.reserveB ~/ pool.totalShares;
    return LiquidityRemoveQuote(
      poolId: pool.poolId,
      shares: shares,
      amountA: amountA,
      amountB: amountB,
      minAmountA: _minimum(amountA, slippageBps),
      minAmountB: _minimum(amountB, slippageBps),
    );
  }

  static void _requireSameNetwork(XerisNetwork network, String endpoint) {
    if (NetworkConfig.currentNetwork != network || NetworkConfig.controlUrl != endpoint) {
      throw StateError('The network changed. Request a new liquidity quote.');
    }
  }

  static Future<Uint8List> buildAddInstruction({
    required String poolId,
    required int amountA,
    required int amountB,
    int slippageBps = defaultSlippageBps,
  }) async {
    final network = NetworkConfig.currentNetwork;
    final endpoint = NetworkConfig.controlUrl;
    final rawA = _u64(amountA, 'amount_a', positive: true);
    final rawB = _u64(amountB, 'amount_b', positive: true);
    final pool = await fetchPoolState(poolId);
    _requireSameNetwork(network, endpoint);
    return quoteAdd(
      pool: pool,
      amountA: rawA,
      amountB: rawB,
      slippageBps: slippageBps,
    ).toInstruction();
  }

  static Future<Uint8List> buildRemoveInstruction({
    required String poolId,
    required String walletAddress,
    required int shares,
    int slippageBps = defaultSlippageBps,
  }) async {
    final network = NetworkConfig.currentNetwork;
    final endpoint = NetworkConfig.controlUrl;
    final rawShares = _u64(shares, 'LP shares', positive: true);
    final pool = await fetchPoolState(poolId);
    _requireSameNetwork(network, endpoint);
    return quoteRemove(
      pool: pool,
      walletAddress: walletAddress,
      shares: rawShares,
      slippageBps: slippageBps,
    ).toInstruction();
  }
}
