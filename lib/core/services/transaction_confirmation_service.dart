import 'dart:async';

import 'package:xeris_wallet/core/config/network_config.dart';
import 'package:xeris_wallet/core/services/base_api_service.dart';

enum TransactionConfirmationStatus {
  confirmedSuccess,
  confirmedFailure,
  pending,
}

class TransactionConfirmationResult {
  final String signature;
  final TransactionConfirmationStatus status;
  final String? detail;
  final int? slot;

  const TransactionConfirmationResult({
    required this.signature,
    required this.status,
    this.detail,
    this.slot,
  });

  bool get isConfirmed =>
      status == TransactionConfirmationStatus.confirmedSuccess;
  bool get isFailed => status == TransactionConfirmationStatus.confirmedFailure;
  bool get isPending => status == TransactionConfirmationStatus.pending;
}

typedef TransactionReceiptWaiter =
    Future<TransactionConfirmationResult> Function({
      required String signature,
      required String expectedNetworkScope,
    });

typedef TransactionReceiptLookup =
    Future<dynamic> Function(
      String signature,
      String rpcEndpoint,
      Duration timeout,
    );

/// Stops a dependent operation while retaining its already submitted ID.
class TransactionConfirmationException implements Exception {
  final TransactionConfirmationResult result;

  const TransactionConfirmationException(this.result);

  String get signature => result.signature;

  @override
  String toString() =>
      '${result.detail ?? 'Transaction is not confirmed.'} '
      'Transaction ID: ${result.signature}. No dependent transaction was sent.';
}

/// Receipt polling only. This service never signs or submits a transaction.
class TransactionConfirmationService {
  static Future<dynamic> _lookup(
    String signature,
    String endpoint,
    Duration timeout,
  ) {
    return BaseApiService.post(endpoint, {
      'jsonrpc': '2.0',
      'id': 1,
      'method': 'getTransaction',
      'params': [signature],
    }, timeout: timeout);
  }

  static Future<TransactionConfirmationResult> waitForReceipt({
    required String signature,
    required String expectedNetworkScope,
    Duration timeout = const Duration(seconds: 90),
    Duration pollInterval = const Duration(seconds: 2),
    TransactionReceiptLookup? lookup,
    Duration Function()? elapsed,
    Future<void> Function(Duration)? delay,
    String Function()? networkScope,
    String Function()? rpcEndpoint,
  }) async {
    if (signature.isEmpty) throw ArgumentError.value(signature, 'signature');
    if (timeout <= Duration.zero || pollInterval <= Duration.zero) {
      throw ArgumentError(
        'Confirmation timeout and poll interval must be positive.',
      );
    }
    final currentScope = networkScope ?? () => NetworkConfig.cacheKey;
    final currentEndpoint = rpcEndpoint ?? () => NetworkConfig.rpcUrl;
    final watch = Stopwatch()..start();
    final clock = elapsed ?? () => watch.elapsed;
    final started = clock();
    final pause = delay ?? Future<void>.delayed;
    final receiptLookup = lookup ?? _lookup;
    String endpoint;
    try {
      if (currentScope() != expectedNetworkScope) {
        return _pending(
          signature,
          'Network changed. Check the original network before continuing.',
        );
      }
      endpoint = currentEndpoint();
    } catch (_) {
      return _pending(
        signature,
        'The original network endpoint is unavailable.',
      );
    }
    String? bindingError() {
      try {
        if (currentScope() != expectedNetworkScope ||
            currentEndpoint() != endpoint) {
          return 'Network changed. Check this transaction on its original endpoint: $endpoint';
        }
      } catch (_) {
        return 'The original network endpoint is unavailable.';
      }
      return null;
    }

    String? lastIssue;
    while (true) {
      final changed = bindingError();
      if (changed != null) return _pending(signature, changed);
      final remaining = timeout - (clock() - started);
      if (remaining <= Duration.zero) {
        return _pending(
          signature,
          'Confirmation timed out. '
          '${lastIssue ?? 'The transaction may still execute.'} Check its ID before retrying.',
        );
      }
      final requestTimeout = remaining < const Duration(seconds: 8)
          ? remaining
          : const Duration(seconds: 8);
      try {
        final raw = await receiptLookup(
          signature,
          endpoint,
          requestTimeout,
        ).timeout(requestTimeout);
        final changedAfterRead = bindingError();
        if (changedAfterRead != null) {
          return _pending(signature, changedAfterRead);
        }
        final result = _classify(signature, raw);
        if (!result.isPending) return result;
        lastIssue = result.detail;
      } catch (_) {
        // Repeating a receipt lookup is safe. Never repeat the submission.
        lastIssue =
            'Receipt lookup is unavailable. The transaction may still execute; check its ID before retrying.';
      }
      final left = timeout - (clock() - started);
      if (left <= Duration.zero) {
        return _pending(
          signature,
          'Confirmation timed out. ${lastIssue ?? 'The transaction may still execute.'} Check its ID before retrying.',
        );
      }
      await pause(left < pollInterval ? left : pollInterval);
    }
  }

  static TransactionConfirmationResult _pending(
    String signature,
    String detail,
  ) => TransactionConfirmationResult(
    signature: signature,
    status: TransactionConfirmationStatus.pending,
    detail: detail,
  );

  static TransactionConfirmationResult _classify(
    String signature,
    dynamic raw,
  ) {
    final dynamic receipt = raw is Map && raw.containsKey('result')
        ? raw['result']
        : raw;
    if (receipt is! Map) {
      return _pending(
        signature,
        'The transaction has no execution receipt yet.',
      );
    }
    final transaction = receipt['transaction'];
    final signatures = transaction is Map ? transaction['signatures'] : null;
    final slot = receipt['slot'];
    final meta = receipt['meta'];
    if (signatures is! List ||
        !signatures.contains(signature) ||
        slot is! int ||
        slot < 0 ||
        meta is! Map ||
        !meta.containsKey('err')) {
      return _pending(
        signature,
        'A matching execution receipt is not available yet.',
      );
    }
    final error = meta['err'];
    if (error == 'OutcomeUnknown') {
      return _pending(
        signature,
        'The block includes this transaction, but its execution outcome is unavailable.',
      );
    }
    if (error != null) {
      if (error is! String && error is! Map) {
        return _pending(signature, 'The execution error field is malformed.');
      }
      return TransactionConfirmationResult(
        signature: signature,
        status: TransactionConfirmationStatus.confirmedFailure,
        slot: slot,
        detail:
            'The node reports execution failure. Some instructions may have committed; inspect balances before any retry.',
      );
    }
    // The supplied node emits explicit per-instruction outcomes. Missing or
    // contradictory outcome data must never be promoted to successful execution.
    final outcomes = meta['instructionOutcomes'];
    if (outcomes is! List || outcomes.isEmpty) {
      return _pending(
        signature,
        'The receipt does not yet prove successful instruction execution.',
      );
    }
    for (var index = 0; index < outcomes.length; index++) {
      final outcome = outcomes[index];
      if (outcome is! Map ||
          outcome['index'] != index ||
          outcome['ok'] != true) {
        return _pending(
          signature,
          'The receipt instruction outcomes are incomplete or inconsistent.',
        );
      }
    }
    return TransactionConfirmationResult(
      signature: signature,
      status: TransactionConfirmationStatus.confirmedSuccess,
      slot: slot,
    );
  }
}
