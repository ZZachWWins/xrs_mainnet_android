import 'dart:io';

/// Platform-specific feature availability.
class FeatureFlags {
  FeatureFlags._();

  /// Whether the in-app token swap / exchange trading feature is available.
  ///
  /// Disabled on iOS to comply with App Store review guidelines, which
  /// restrict in-app crypto exchange/swap functionality. When false, the
  /// swap button, the `/swap` route, and every path that leads into swap
  /// (e.g. limit-order creation) must be hidden or blocked.
  static bool get swapEnabled => !Platform.isIOS;
}
