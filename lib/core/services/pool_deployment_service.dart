import 'dart:convert';

import 'package:xeris_wallet/core/config/network_config.dart';
import 'package:xeris_wallet/core/services/base_api_service.dart';
import 'package:xeris_wallet/core/services/liquidity_quote_service.dart';
import 'package:xeris_wallet/core/services/transaction_confirmation_service.dart';
import 'package:xeris_wallet/core/services/xeris_api_service.dart';

enum PoolDeploymentStatus { created, pending, failed, verificationFailed }

class PoolDeploymentRequest {
  final String poolId;
  final String walletAddress;
  final String expectedNetworkScope;
  final String tokenA;
  final String tokenB;
  final String amountA;
  final String amountB;
  final int feeBps;

  const PoolDeploymentRequest({
    required this.poolId,
    required this.walletAddress,
    required this.expectedNetworkScope,
    required this.tokenA,
    required this.tokenB,
    required this.amountA,
    required this.amountB,
    this.feeBps = 30,
  });
}

class PoolDeploymentPlan {
  final PoolDeploymentRequest request;
  final BigInt rawAmountA;
  final BigInt rawAmountB;
  final BigInt initialShares;

  const PoolDeploymentPlan({
    required this.request,
    required this.rawAmountA,
    required this.rawAmountB,
    required this.initialShares,
  });

  BigInt get ownerShares => initialShares - BigInt.from(1000);

  // JSON numbers must remain exact throughout the full u64 range. Do not
  // convert BigInt to double or signed int before encoding these quantities.
  String get paramsJson =>
      '{"token_a":${jsonEncode(request.tokenA)},'
      '"token_b":${jsonEncode(request.tokenB)},'
      '"amount_a":$rawAmountA,"amount_b":$rawAmountB,'
      '"fee_bps":${request.feeBps}}';
}

class PoolDeploymentResult {
  final String poolId;
  final String txSignature;
  final PoolDeploymentStatus status;
  final String message;

  const PoolDeploymentResult({
    required this.poolId,
    required this.txSignature,
    required this.status,
    required this.message,
  });
}

typedef PoolContractReader =
    Future<Map<String, dynamic>?> Function(String poolId);
typedef PoolDecimalsReader = Future<int> Function(String wallet, String token);
typedef PoolReceiptReader =
    Future<TransactionConfirmationResult> Function(
      String signature,
      String networkScope,
    );

/// Prepares exact initial liquidity and follows one submitted transaction.
/// Rechecking an attempt never creates or resubmits a transaction.
class PoolDeploymentService {
  final PoolContractReader readContract;
  final PoolDecimalsReader readDecimals;
  final PoolReceiptReader readReceipt;
  final String Function() currentNetworkScope;
  final _attempts = <String, ({PoolDeploymentPlan plan, String signature})>{};
  final _inflight = <String>{};

  PoolDeploymentService({
    PoolContractReader? readContract,
    PoolDecimalsReader? readDecimals,
    PoolReceiptReader? readReceipt,
    String Function()? currentNetworkScope,
  }) : readContract = readContract ?? _readContract,
       readDecimals = readDecimals ?? LiquidityQuoteService.fetchTokenDecimals,
       readReceipt = readReceipt ?? _readReceipt,
       currentNetworkScope =
           currentNetworkScope ?? (() => NetworkConfig.cacheKey);

  static Future<Map<String, dynamic>?> _readContract(String id) async {
    try {
      final data = await BaseApiService.get(
        '${NetworkConfig.controlUrl}/contract/${Uri.encodeComponent(id)}',
      );
      if (data is! Map || data['success'] != true || data['contract'] is! Map) {
        throw const FormatException('A valid contract lookup is required.');
      }
      return Map<String, dynamic>.from(data['contract'] as Map);
    } on ApiException catch (error) {
      // The native handler returns this specific JSON error with HTTP 200.
      // A proxy 404 or another transport error does not establish absence.
      if (error.statusCode == 200 &&
          error.type == ApiErrorType.rpc &&
          error.originalError == 'Contract not found') {
        return null;
      }
      rethrow;
    }
  }

  static Future<TransactionConfirmationResult> _readReceipt(
    String signature,
    String scope,
  ) => TransactionConfirmationService.waitForReceipt(
    signature: signature,
    expectedNetworkScope: scope,
  );

  void _checkScope(PoolDeploymentRequest request) {
    if (request.expectedNetworkScope != currentNetworkScope()) {
      throw StateError(
        'The network changed. Review the pool on the selected network.',
      );
    }
  }

  static void _validate(PoolDeploymentRequest request) {
    if (!RegExp(r'^[A-Za-z0-9_-]{1,128}$').hasMatch(request.poolId)) {
      throw const FormatException(
        'Pool ID must use 1–128 ASCII letters, digits, underscores or hyphens.',
      );
    }
    if ([
          'xeris_',
          'identity_',
          'agent_registry_',
          '__',
        ].any(request.poolId.startsWith) ||
        request.poolId.endsWith('_xrs_pool')) {
      throw const FormatException('This pool ID is reserved by the protocol.');
    }
    if (!RegExp(
      r'^[1-9A-HJ-NP-Za-km-z]{32,44}$',
    ).hasMatch(request.walletAddress)) {
      throw const FormatException(
        'A public liquidity-owner wallet address is required.',
      );
    }
    if (request.tokenA.isEmpty ||
        request.tokenB.isEmpty ||
        request.tokenA == request.tokenB ||
        request.tokenA == 'xrs' ||
        request.tokenB == 'xrs') {
      throw const FormatException(
        'Choose two distinct registered token IDs; native XRS must be wrapped first.',
      );
    }
    if (request.feeBps < 0 || request.feeBps >= 10000) {
      throw const FormatException(
        'Pool fee must be between 0 and 9999 basis points.',
      );
    }
  }

  static BigInt _sqrt(BigInt value) {
    var root = BigInt.one << ((value.bitLength + 1) ~/ 2);
    while (true) {
      final next = (root + value ~/ root) >> 1;
      if (next >= root) return root;
      root = next;
    }
  }

  static BigInt? _unsigned(dynamic value) {
    if (value is! int && value is! String) return null;
    if (!RegExp(r'^\d+$').hasMatch('$value')) return null;
    final parsed = BigInt.tryParse('$value');
    return parsed != null && parsed <= (BigInt.one << 64) - BigInt.one
        ? parsed
        : null;
  }

  Future<PoolDeploymentPlan> prepare(PoolDeploymentRequest request) async {
    _validate(request);
    _checkScope(request);
    final existing = await readContract(request.poolId);
    _checkScope(request);
    if (existing != null) {
      throw StateError(
        'This pool ID is already in use. Inspect the existing pool.',
      );
    }
    final decimalsA = await readDecimals(request.walletAddress, request.tokenA);
    _checkScope(request);
    final decimalsB = await readDecimals(request.walletAddress, request.tokenB);
    _checkScope(request);
    final rawA = LiquidityQuoteService.parseDisplayAmount(
      request.amountA,
      decimalsA,
    );
    final rawB = LiquidityQuoteService.parseDisplayAmount(
      request.amountB,
      decimalsB,
    );
    final shares = _sqrt(rawA * rawB);
    if (shares <= BigInt.from(1000)) {
      throw const FormatException(
        'Initial liquidity must create more than 1000 raw LP shares; 1000 shares remain permanently locked.',
      );
    }
    return PoolDeploymentPlan(
      request: request,
      rawAmountA: rawA,
      rawAmountB: rawB,
      initialShares: shares,
    );
  }

  Future<PoolDeploymentResult> deploy({
    required PoolDeploymentRequest request,
    required Future<String> Function() signerAddress,
    required Future<String?> Function(PoolDeploymentPlan plan) submit,
  }) async {
    _validate(request);
    _checkScope(request);
    final key = '${request.expectedNetworkScope}|${request.poolId}';
    if (!_inflight.add(key)) {
      throw StateError('This pool deployment is already being checked.');
    }
    try {
      final previous = _attempts[key];
      if (previous != null) {
        final original = previous.plan.request;
        if (request.walletAddress != original.walletAddress ||
            request.tokenA != original.tokenA ||
            request.tokenB != original.tokenB ||
            request.amountA != original.amountA ||
            request.amountB != original.amountB ||
            request.feeBps != original.feeBps) {
          return PoolDeploymentResult(
            poolId: request.poolId,
            txSignature: previous.signature,
            status: PoolDeploymentStatus.pending,
            message:
                'This pool ID already has a transaction with different '
                'reviewed parameters. Inspect ${previous.signature}; '
                'no replacement transaction was submitted.',
          );
        }
        return await checkDeployment(previous.plan, previous.signature);
      }
      final plan = await prepare(request);
      final address = await signerAddress();
      _checkScope(request);
      if (address != request.walletAddress) {
        throw StateError(
          'The signing wallet does not match the reviewed liquidity owner.',
        );
      }
      String signature;
      try {
        final submitted = await submit(plan);
        if (submitted == null || submitted.isEmpty) {
          throw StateError(
            'Submission returned no signature. Check the wallet transaction history before trying again.',
          );
        }
        signature = submitted;
      } on TransactionSubmissionUnknown catch (error) {
        signature = error.signature;
      }
      _attempts[key] = (plan: plan, signature: signature);
      return await checkDeployment(plan, signature);
    } finally {
      _inflight.remove(key);
    }
  }

  Future<PoolDeploymentResult> checkDeployment(
    PoolDeploymentPlan plan,
    String signature,
  ) async {
    final request = plan.request;
    PoolDeploymentResult result(PoolDeploymentStatus status, String message) =>
        PoolDeploymentResult(
          poolId: request.poolId,
          txSignature: signature,
          status: status,
          message: message,
        );
    try {
      _checkScope(request);
      final receipt = await readReceipt(
        signature,
        request.expectedNetworkScope,
      );
      _checkScope(request);
      if (receipt.status == TransactionConfirmationStatus.confirmedFailure) {
        return result(
          PoolDeploymentStatus.failed,
          'The pool transaction failed. Inspect transaction $signature before preparing another attempt.',
        );
      }
      if (receipt.status != TransactionConfirmationStatus.confirmedSuccess) {
        return result(
          PoolDeploymentStatus.pending,
          'Pool deployment is pending. Check transaction $signature; do not submit it again.',
        );
      }
      final contract = await readContract(request.poolId);
      _checkScope(request);
      if (contract == null) {
        return result(
          PoolDeploymentStatus.pending,
          'The transaction is confirmed but pool state is not available yet. Check $signature; do not resubmit.',
        );
      }
      final state = contract['state'];
      final swap = state is Map ? state['Swap'] : null;
      final owners = swap is Map ? swap['lp_shares'] : null;
      final owned = owners is Map
          ? _unsigned(owners[request.walletAddress])
          : null;
      final locked = owners is Map
          ? _unsigned(owners['BURNED_LIQUIDITY_000000000000000000000'])
          : null;
      final total = swap is Map ? _unsigned(swap['total_shares']) : null;
      final reserveA = swap is Map ? _unsigned(swap['reserve_a']) : null;
      final reserveB = swap is Map ? _unsigned(swap['reserve_b']) : null;
      if (contract['contract_id'] != request.poolId ||
          contract['owner'] != request.walletAddress ||
          contract['is_active'] != true ||
          swap is! Map ||
          swap['token_a'] != request.tokenA ||
          swap['token_b'] != request.tokenB ||
          swap['fee_bps'] != request.feeBps ||
          owned == null ||
          owned < plan.ownerShares ||
          locked != BigInt.from(1000) ||
          total == null ||
          total < plan.initialShares ||
          reserveA == null ||
          reserveA <= BigInt.zero ||
          reserveB == null ||
          reserveB <= BigInt.zero) {
        return result(
          PoolDeploymentStatus.verificationFailed,
          'The transaction is confirmed but the pool does not match the reviewed deployment. Inspect $signature and the pool before any further transaction.',
        );
      }
      return result(
        PoolDeploymentStatus.created,
        'Pool ${request.poolId} is confirmed and verified.',
      );
    } catch (_) {
      return result(
        PoolDeploymentStatus.pending,
        'Pool confirmation is unavailable. Check existing transaction $signature on the reviewed network; do not submit it again.',
      );
    }
  }
}
