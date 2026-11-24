import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xeris_wallet/core/models/transaction_model.dart';
import 'package:xeris_wallet/core/providers/wallet_provider.dart';
import 'package:xeris_wallet/core/services/wallet_service.dart';

final activityProvider = FutureProvider.autoDispose<List<TransactionModel>>((ref) async {
  final address = await ref.watch(walletAddressProvider.future);

  if (address == 'No Wallet' || address == 'Loading...') {
    return [];
  }

  return WalletService.getTransactions(address);
});
