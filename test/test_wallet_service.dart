// ignore_for_file: avoid_print
import 'package:xeris_wallet/core/services/wallet_service.dart';
import 'package:flutter/widgets.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
     print("Fetching transactions...");
     final txs = await WalletService.getTransactions("8evPjjozSHNcoGRcv7zzxwan9sf3ubJ8q9CFzms6AK97");
     print("Txs count: \${txs.length}");
     for (var tx in txs) {
       print("${tx.date} - ${tx.symbol} ${tx.amount} (${tx.status.name})");
     }
  } catch (e) {
     print("Error: \$e");
  }
}
