import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xeris_wallet/core/services/storage_service.dart';
import 'package:xeris_wallet/core/theme/app_theme.dart';

class ThemeNotifier extends Notifier<AppThemeMode> {
  @override
  AppThemeMode build() {
    _init();
    return AppThemeMode.dark; // Default
  }

  Future<void> _init() async {
    final mode = await StorageService.getThemeMode();
    state = mode;
  }

  Future<void> setThemeMode(AppThemeMode mode) async {
    await StorageService.setThemeMode(mode);
    state = mode;
  }
}

final themeProvider = NotifierProvider<ThemeNotifier, AppThemeMode>(() {
  return ThemeNotifier();
});
