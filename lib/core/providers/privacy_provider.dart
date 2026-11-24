import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xeris_wallet/core/services/storage_service.dart';
import 'package:xeris_wallet/core/services/pqc_service.dart';
import 'package:xeris_wallet/core/services/biometric_service.dart';
import 'package:xeris_wallet/core/providers/wallet_provider.dart';

class PrivacyMetrics {
  final int zkProofsCount;
  final int pqKeysCount;
  final bool isBiometricAvailable;
  final bool isPinSet;
  final PqRegistrationStatus pqRegistration;
  final bool isPrivacyModeEnabled;

  PrivacyMetrics({
    required this.zkProofsCount,
    required this.pqKeysCount,
    required this.isBiometricAvailable,
    required this.isPinSet,
    required this.pqRegistration,
    required this.isPrivacyModeEnabled,
  });
}

final privacyMetricsProvider = FutureProvider<PrivacyMetrics>((ref) async {
  final zkCount = await StorageService.getZkProofCount();
  final isBioAvailable = await BiometricService.isBiometricsAvailable;
  final pin = await StorageService.getPinCode();
  final address = await ref.watch(walletAddressProvider.future);
  final registration = await PqcService.getRegistrationStatus(address);
  final privacyMode = ref.watch(privacyModeProvider);

  return PrivacyMetrics(
    zkProofsCount: zkCount,
    pqKeysCount: registration == PqRegistrationStatus.registered ? 1 : 0,
    isBiometricAvailable: isBioAvailable,
    isPinSet: pin != null && pin.isNotEmpty,
    pqRegistration: registration,
    isPrivacyModeEnabled: privacyMode,
  );
});
