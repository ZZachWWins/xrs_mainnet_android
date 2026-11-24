import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xeris_wallet/core/models/stealth_models.dart';
import 'package:xeris_wallet/core/providers/wallet_provider.dart';
import 'package:xeris_wallet/core/services/stealth_service.dart';
import 'package:xeris_wallet/core/services/storage_service.dart';

/// Provides the stealth meta-address for the active wallet.
/// Initializes stealth keys on first access.
final stealthMetaAddressProvider =
    FutureProvider<StealthMetaAddress?>((ref) async {
  final activeWallet = await ref.watch(activeWalletProvider.future);
  if (activeWallet == null) return null;

  final mnemonic = await StorageService.getMnemonicById(activeWallet.id);
  if (mnemonic == null) return null;

  // Ensure stealth keys are initialized
  await StealthService.initializeStealthKeys(activeWallet.id, mnemonic);
  return StealthService.getStealthMetaAddress(activeWallet.id);
});

/// Provides detected (unclaimed) stealth payments for the active wallet.
/// Auto-refreshes every 30 seconds.
final stealthPaymentsProvider =
    FutureProvider<List<DetectedStealthPayment>>((ref) async {
  final activeWallet = await ref.watch(activeWalletProvider.future);
  if (activeWallet == null) return [];

  // Auto-refresh every 30 seconds
  final timer = Timer.periodic(const Duration(seconds: 30), (_) {
    ref.invalidateSelf();
  });
  ref.onDispose(timer.cancel);

  return StealthService.scanForPayments(activeWallet.id);
});

/// Controller for stealth actions (sweep, etc.)
class StealthController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() => null;

  /// Sweep funds from a stealth address to the main wallet.
  Future<String?> sweepPayment(StealthAnnouncement announcement) async {
    state = const AsyncValue.loading();
    String? txSignature;
    state = await AsyncValue.guard(() async {
      final activeWallet = await ref.read(activeWalletProvider.future);
      if (activeWallet == null) throw Exception('No active wallet');

      txSignature = await StealthService.sweepStealthPayment(
        walletId: activeWallet.id,
        announcement: announcement,
        mainWalletAddress: activeWallet.address,
      );

      // Refresh balances and stealth payments
      ref.invalidate(accountBalancesProvider);
      ref.invalidate(stealthPaymentsProvider);
    });
    return txSignature;
  }
}

final stealthControllerProvider =
    AsyncNotifierProvider<StealthController, void>(() => StealthController());
