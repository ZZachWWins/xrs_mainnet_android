import 'dart:io';
import 'package:flutter/services.dart';

/// Toggles OS-level screen-capture protection while a sensitive screen (recovery
/// phrase, private-key import) is visible.
///
/// Android: sets/clears `FLAG_SECURE`, which blocks screenshots and screen
/// recording and removes the window from the app-switcher thumbnail.
/// iOS: apps cannot block screenshots; the app-switcher snapshot is obscured
/// globally by a privacy blur in AppDelegate, so these calls are a safe no-op.
class ScreenSecurity {
  static const _channel = MethodChannel('io.xeris.wallet/screen_security');

  static Future<void> enable() async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('enable');
    } catch (_) {
      // Best-effort; never block the UI on a platform-channel failure.
    }
  }

  static Future<void> disable() async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('disable');
    } catch (_) {}
  }
}
