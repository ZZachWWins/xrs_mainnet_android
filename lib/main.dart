import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xeris_wallet/core/router/app_router.dart';
import 'package:xeris_wallet/core/theme/app_theme.dart';
import 'package:xeris_wallet/core/services/storage_service.dart';
import 'package:xeris_wallet/core/providers/language_provider.dart';
import 'package:xeris_wallet/core/providers/theme_provider.dart';
import 'package:xeris_wallet/l10n/app_localizations.dart';
import 'package:xeris_wallet/core/services/local_notification_service.dart';
import 'package:xeris_wallet/core/services/widget_service.dart';
import 'package:xeris_wallet/core/providers/transaction_notification_provider.dart';
import 'package:xeris_wallet/core/providers/price_alert_provider.dart';
import 'package:xeris_wallet/core/providers/wallet_provider.dart';
import 'package:xeris_wallet/core/providers/ui_scale_provider.dart';

import 'package:xeris_wallet/core/services/biometric_service.dart';
import 'package:xeris_wallet/core/services/auth_service.dart';
import 'package:xeris_wallet/core/services/app_lock.dart';
import 'package:xeris_wallet/core/config/network_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Resolve the saved/default network before providers can start requests.
  NetworkConfig.currentNetwork = await StorageService.getNetwork() == 'mainnet'
      ? XerisNetwork.mainnet
      : XerisNetwork.testnet;
  NetworkConfig.validate();
  await LocalNotificationService.init();
  await WidgetService.init();
  // Load whether an app lock is configured before the first route resolves, so
  // the router guard can gate deep-link cold starts.
  await AppLock.refreshSecurityEnabled();
  runApp(const ProviderScope(child: XerisApp()));
}

class XerisApp extends ConsumerStatefulWidget {
  const XerisApp({super.key});

  @override
  ConsumerState<XerisApp> createState() => _XerisAppState();
}

class _XerisAppState extends ConsumerState<XerisApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Activate transaction polling for local notifications
    ref.read(transactionNotificationProvider);
    // Activate price alert monitor
    ref.read(priceAlertMonitorProvider);
    // Activate home screen widget sync
    ref.read(widgetSyncProvider);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkLockScreen();
    }
  }

  Future<void> _checkLockScreen() async {
    if (BiometricService.isAuthenticating) return;

    if (BiometricService.lastSuccessfulAuthTime != null) {
      final diff =
          DateTime.now().difference(BiometricService.lastSuccessfulAuthTime!);
      if (diff < const Duration(seconds: 5)) return;
    }

    final mnemonic = await StorageService.getMnemonic();
    final securityEnabled = await AuthService.isSecurityEnabled();
    AppLock.securityEnabled = securityEnabled;

    if (mnemonic != null && securityEnabled) {
      // Mark the session locked so the router guard also blocks navigation, then
      // surface the lock screen over the current route.
      AppLock.lock();
      final currentPath =
          appRouter.routerDelegate.currentConfiguration.uri.toString();
      if (currentPath.startsWith('/lock')) return;
      appRouter.push('/lock');
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentLocale = ref.watch(languageProvider);
    final appThemeMode = ref.watch(themeProvider);
    final uiScale = ref.watch(uiScaleProvider);

    ThemeData theme;
    ThemeMode mode;

    switch (appThemeMode) {
      case AppThemeMode.light:
        theme = AppTheme.lightTheme;
        mode = ThemeMode.light;
        break;
      case AppThemeMode.dark:
        theme = AppTheme.darkTheme;
        mode = ThemeMode.dark;
        break;
      case AppThemeMode.solar:
        theme = AppTheme.solarTheme;
        mode = ThemeMode.dark;
        break;
      case AppThemeMode.cyberpunk:
        theme = AppTheme.cyberpunkTheme;
        mode = ThemeMode.dark;
        break;
      case AppThemeMode.system:
        theme = AppTheme.lightTheme;
        mode = ThemeMode.system;
        break;
    }

    return MaterialApp.router(
      title: 'Xeris Wallet',
      debugShowCheckedModeBanner: false,
      theme: theme,
      darkTheme:
          appThemeMode == AppThemeMode.system ? AppTheme.darkTheme : theme,
      themeMode: mode,
      routerConfig: appRouter,
      locale: currentLocale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) {
        final narrowScreen = MediaQuery.of(context).size.width <= 375;
        final effectiveScale = narrowScreen ? uiScale * 0.85 : uiScale;
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(effectiveScale),
          ),
          child: child!,
        );
      },
    );
  }
}
