import 'package:flutter/material.dart';
import 'package:xeris_wallet/core/services/biometric_service.dart';
import 'package:xeris_wallet/core/services/storage_service.dart';
import 'package:xeris_wallet/features/security/screens/pin_code_screen.dart';

class AuthService {
  /// Checks if ANY security (Biometrics or PIN) is enabled.
  static Future<bool> isSecurityEnabled() async {
    final biometricsEnabled = await StorageService.getBiometricsEnabled();
    final usePin = await StorageService.getUsePin();
    return biometricsEnabled || usePin;
  }

  /// Whether the user has both factors configured to support 2FA.
  static Future<bool> canUseTwoFactor() async {
    final biometricsEnabled = await StorageService.getBiometricsEnabled();
    final biometricsAvailable = await BiometricService.isBiometricsAvailable;
    final usePin = await StorageService.getUsePin();
    final pinCode = await StorageService.getPinCode();
    return biometricsEnabled &&
        biometricsAvailable &&
        usePin &&
        pinCode != null &&
        pinCode.isNotEmpty;
  }

  /// Unified authentication method.
  ///
  /// Default behavior: Tries Biometrics if enabled and available, falls back
  /// to PIN if enabled.
  ///
  /// When [requireTwoFactor] is true, BOTH biometrics AND PIN must succeed
  /// in sequence. If either factor is unconfigured/unavailable at call time,
  /// authentication fails closed — callers should gate this on
  /// [canUseTwoFactor] before requesting it.
  ///
  /// Returns [true] if authenticated, [false] otherwise.
  static Future<bool> authenticate(
    BuildContext context, {
    String? reason,
    bool requireTwoFactor = false,
  }) async {
    final biometricsEnabled = await StorageService.getBiometricsEnabled();
    final usePin = await StorageService.getUsePin();

    // If no security is configured, we allow access (unless 2FA was requested).
    if (!biometricsEnabled && !usePin) {
      return !requireTwoFactor;
    }

    if (requireTwoFactor) {
      if (!context.mounted) return false;
      return _authenticateTwoFactor(context);
    }

    // 1. Try Biometrics if enabled
    if (biometricsEnabled) {
      final available = await BiometricService.isBiometricsAvailable;
      if (available) {
        final authenticated = await BiometricService.authenticate();
        if (authenticated) return true;

        // If biometrics failed/canceled but PIN is NOT available, we STOP here.
        // User must succeed with biometrics.
        if (!usePin) return false;

        // If PIN is available, we fall through to PIN challenge
      } else if (!usePin) {
        // Biometrics enabled but hardware unavailable, and NO PIN fallback?
        // This is a security risk if we return true. We must deny access.
        debugPrint('Auth Error: Biometrics enabled but unavailable, and no PIN set.');
        return false;
      }
    }

    // 2. Try PIN if enabled
    if (usePin) {
      if (!context.mounted) return false;
      return _runPinChallenge(context);
    }

    // Fallback security: if we got here and some security was intended but not met, deny.
    return false;
  }

  /// Two-factor: requires biometric success, then PIN success. No fallback
  /// between the two.
  static Future<bool> _authenticateTwoFactor(BuildContext context) async {
    if (!await canUseTwoFactor()) {
      debugPrint('Auth Error: 2FA requested but both factors are not configured.');
      return false;
    }

    final bioOk = await BiometricService.authenticate();
    if (!bioOk) return false;

    if (!context.mounted) return false;
    return _runPinChallenge(context);
  }

  static Future<bool> _runPinChallenge(BuildContext context) async {
    final pinCode = await StorageService.getPinCode();
    if (pinCode == null || pinCode.isEmpty) {
      debugPrint('Auth Error: PIN enabled but no code stored.');
      return false;
    }

    if (!context.mounted) return false;

    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => const PinCodeScreen(mode: PinMode.verify),
      ),
    );

    return result ?? false;
  }
}
