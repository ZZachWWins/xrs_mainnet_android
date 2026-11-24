import 'package:xeris_wallet/core/services/auth_service.dart';

/// In-memory app-lock state read synchronously by the router guard.
///
/// The splash screen authenticates on a normal cold launch, but a cold start via
/// a `xeris://` deep link skips the splash entirely — so without a router-level
/// guard those links route straight into authenticated screens. This state lets
/// the router redirect gate every protected route behind the lock screen,
/// closing that bypass, while [unlock] (called by splash/lock on success) keeps
/// a normal launch from prompting twice.
class AppLock {
  AppLock._();

  /// Whether any app lock (PIN or biometrics) is configured. Cached so the
  /// router redirect can read it without an async call.
  static bool securityEnabled = false;

  /// Whether the user has unlocked during this foreground session.
  static bool isUnlocked = false;

  /// Refresh [securityEnabled] from storage. Call at startup and on resume.
  static Future<void> refreshSecurityEnabled() async {
    securityEnabled = await AuthService.isSecurityEnabled();
  }

  static void unlock() => isUnlocked = true;
  static void lock() => isUnlocked = false;

  /// True when the current navigation must be diverted to the lock screen.
  static bool get shouldGate => securityEnabled && !isUnlocked;
}
