import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xeris_wallet/core/services/storage_service.dart';
import 'package:xeris_wallet/core/services/biometric_service.dart';
import 'package:xeris_wallet/core/providers/wallet_provider.dart';

class PrivacyMetrics {
  final int zkProofsCount;
  final int pqKeysCount;
  final bool isBiometricAvailable;
  final bool isPinSet;
  final bool isQuantumProtected;
  final bool isPrivacyModeEnabled;

  PrivacyMetrics({
    required this.zkProofsCount,
    required this.pqKeysCount,
    required this.isBiometricAvailable,
    required this.isPinSet,
    required this.isQuantumProtected,
    required this.isPrivacyModeEnabled,
  });
}

final privacyMetricsProvider = FutureProvider<PrivacyMetrics>((ref) async {
  final zkCount = await StorageService.getZkProofCount();
  final isBioAvailable = await BiometricService.isBiometricsAvailable;
  final pin = await StorageService.getPinCode();
  final isPQ = await StorageService.isQuantumProtected();
  final privacyMode = ref.watch(privacyModeProvider);

  return PrivacyMetrics(
    zkProofsCount: zkCount,
    pqKeysCount: isPQ ? 1 : 0, // In this version, we usually have 1 active PQ registration
    isBiometricAvailable: isBioAvailable,
    isPinSet: pin != null && pin.isNotEmpty,
    isQuantumProtected: isPQ,
    isPrivacyModeEnabled: privacyMode,
  );
});
