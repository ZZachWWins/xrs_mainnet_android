import 'package:flutter/widgets.dart';
import 'package:xeris_wallet/l10n/app_localizations.dart';

extension ContextExt on BuildContext {
  /// Safely accesses localized strings.
  /// Audit Note: Centralizes force-unwrapping to make it easier to audit and 
  /// eventually replace with a fallback mechanism if necessary.
  AppLocalizations get l10n {
    final loc = AppLocalizations.of(this);
    if (loc == null) {
      // In a real production app, we might return a fallback or throw a more 
      // descriptive error than just a null pointer exception.
      throw StateError('AppLocalizations not found in the current context.');
    }
    return loc;
  }
}
