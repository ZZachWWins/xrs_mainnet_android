// ignore_for_file: depend_on_referenced_packages
import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';
import 'package:local_auth_darwin/local_auth_darwin.dart';

class BiometricService {
  static final LocalAuthentication _auth = LocalAuthentication();

  /// Checks if biometric hardware is available and can be used.
  static Future<bool> get isBiometricsAvailable async {
    try {
      final bool canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
      final bool canAuthenticate =
          canAuthenticateWithBiometrics || await _auth.isDeviceSupported();
      return canAuthenticate;
    } catch (e) {
      debugPrint('Error checking biometrics availability: $e');
      return false;
    }
  }

  static Future<bool>? _authenticatingFuture;
  static bool get isAuthenticating => _authenticatingFuture != null;
  // NOTE: This property is actively read by main.dart's lock screen grace period logic
  static DateTime? lastSuccessfulAuthTime;

  /// Trigger the biometric prompt.
  /// Returns [true] if authenticated, [false] otherwise.
  static Future<bool> authenticate() async {
    if (_authenticatingFuture != null) {
      debugPrint('Authentication already in progress, awaiting result...');
      return await _authenticatingFuture!;
    }
    
    _authenticatingFuture = _doAuthenticate();
    try {
      return await _authenticatingFuture!;
    } finally {
      _authenticatingFuture = null;
    }
  }

  static Future<bool> _doAuthenticate() async {
    try {
      debugPrint('Triggering biometric prompt...');
      final bool didAuthenticate = await _auth.authenticate(
        localizedReason: 'Please authenticate to access your Xeris Wallet',
        authMessages: const <AuthMessages>[
          AndroidAuthMessages(
            signInTitle: 'Biometric authentication required',
          ),
          IOSAuthMessages(
            cancelButton: 'No thanks',
          ),
        ],
      );
      debugPrint('Authentication result: $didAuthenticate');
      
      if (didAuthenticate) {
        lastSuccessfulAuthTime = DateTime.now();
      }
      
      return didAuthenticate;
    } catch (e) {
      debugPrint('Error during authentication: $e');
      return false;
    }
  }
}
