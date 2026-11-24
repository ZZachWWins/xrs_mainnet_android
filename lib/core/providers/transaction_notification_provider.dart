import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xeris_wallet/core/models/transaction_model.dart';
import 'package:xeris_wallet/core/providers/wallet_provider.dart';
import 'package:xeris_wallet/core/services/local_notification_service.dart';
import 'package:xeris_wallet/core/services/wallet_service.dart';

final transactionNotificationProvider = Provider<void>((ref) {
  final addressAsync = ref.watch(walletAddressProvider);

  addressAsync.whenData((address) {
    if (address == 'No Wallet' || address == 'Loading...') return;
    ref.watch(_pollingProvider(address));
  });
});

final _pollingProvider = Provider.family<void, String>((ref, address) {
  String? lastSeenId;
  Timer? timer;

  Future<void> poll() async {
    try {
      final txs = await WalletService.getTransactions(address);
      if (txs.isEmpty) return;

      final latest = txs.first;

      if (lastSeenId == null) {
        // First load — just record the latest, don't notify
        lastSeenId = latest.id;
        return;
      }

      if (latest.id != lastSeenId) {
        // Find all new received transactions since last check
        final newReceived = <TransactionModel>[];
        for (final tx in txs) {
          if (tx.id == lastSeenId) break;
          if (tx.type == TransactionType.receive &&
              tx.status == TransactionStatus.confirmed) {
            newReceived.add(tx);
          }
        }

        lastSeenId = latest.id;

        for (final tx in newReceived) {
          await LocalNotificationService.showTransactionReceived(
            amount: tx.amount,
            symbol: tx.symbol,
          );
        }
      }
    } catch (_) {
      // Silently ignore polling errors
    }
  }

  timer = Timer.periodic(const Duration(seconds: 30), (_) => poll());
  poll(); // Run immediately on first watch

  ref.onDispose(() => timer?.cancel());
});
