import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:xeris_wallet/core/providers/wallet_provider.dart';
import 'package:xeris_wallet/core/services/xeris_api_service.dart';
import 'package:xeris_wallet/core/providers/activity_provider.dart';
import 'package:xeris_wallet/core/theme/app_theme_extension.dart';
import 'package:xeris_wallet/features/dashboard/widgets/action_buttons.dart';
import 'package:xeris_wallet/features/dashboard/widgets/asset_list.dart';
import 'package:xeris_wallet/features/dashboard/widgets/wallet_header.dart';
import 'package:xeris_wallet/features/activity/screens/activity_screen.dart';
import 'package:xeris_wallet/features/settings/screens/settings_screen.dart';
import 'package:xeris_wallet/features/dapp_browser/screens/dapp_browser_screen.dart';
import 'package:xeris_wallet/features/agents/screens/agents_screen.dart';
import 'package:xeris_wallet/features/dashboard/widgets/feature_carousel.dart';
import 'package:xeris_wallet/l10n/app_localizations.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(activityProvider.future);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeExt = theme.extension<AppThemeExtension>();
    final l10n = AppLocalizations.of(context)!;
    final isLight = theme.brightness == Brightness.light;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Theme-aware Hero Background
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).size.height * 0.5,
            child: Container(
              decoration: themeExt?.heroDecoration ??
                  BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(0, -0.6),
                      radius: 0.8,
                      colors: [
                        theme.colorScheme.primary
                            .withValues(alpha: isLight ? 0.05 : 0.15),
                        theme.scaffoldBackgroundColor,
                      ],
                    ),
                  ),
            ),
          ),

          IndexedStack(
            index: _selectedIndex,
            children: [
              _buildWalletDashboard(context, ref),
              const DAppBrowserScreen(initialUrl: 'xeris://home'),
              const ActivityScreen(),
              const AgentsScreen(),
              const SettingsScreen(),
            ],
          ),

          // Bottom Navigation Bar
          Positioned(
            left: 16,
            right: 16,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(32),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(
                        sigmaX: themeExt?.surfaceBlur ?? (isLight ? 10 : 0),
                        sigmaY: themeExt?.surfaceBlur ?? (isLight ? 10 : 0)),
                    child: Container(
                      height: 68,
                      decoration: themeExt?.navbarDecoration ??
                          BoxDecoration(
                            color: theme.cardTheme.color
                                ?.withValues(alpha: isLight ? 0.9 : 0.85),
                            borderRadius: BorderRadius.circular(32),
                            border: Border.all(
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.1)),
                            boxShadow: [
                              if (isLight)
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 20,
                                  offset: const Offset(0, 4),
                                ),
                            ],
                          ),
                      child: Row(
                        children: [
                          _buildNavItemExpanded(
                              context,
                              Icons.account_balance_wallet_outlined,
                              l10n.navWallet,
                              0),
                          _buildNavItemExpanded(
                              context, Icons.language, l10n.navBrowser, 1),
                          _buildNavItemExpanded(
                              context, Icons.show_chart, l10n.navActivity, 2),
                          _buildNavItemExpanded(
                              context, Icons.psychology, l10n.navAgents, 3),
                          _buildNavItemExpanded(context,
                              Icons.settings_outlined, l10n.settingsTitle, 4),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWalletDashboard(BuildContext context, WidgetRef ref) {
    final snapshotAsync = ref.watch(dashboardAssetsSnapshotProvider);
    final snapshot = snapshotAsync.value;
    final addressAsync = ref.watch(walletAddressProvider);
    final isSwitching = ref.watch(walletControllerProvider).isLoading;
    final theme = Theme.of(context);

    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(activityProvider);
          XerisApiService.clearBalanceCache();
          ref.invalidate(stakingInfoProvider);
          ref.invalidate(tokenPricesProvider);
          ref.invalidate(accountBalancesProvider);
          try {
            await ref.read(accountBalancesProvider.future);
          } catch (_) {
            // The dashboard renders a retryable error or its last scoped value.
          }
        },
        color: theme.colorScheme.secondary,
        backgroundColor: theme.cardTheme.color,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(top: 24, bottom: 140),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: Icon(Icons.account_balance_wallet_outlined,
                          color: theme.colorScheme.onSurface),
                      onPressed: () => context.push('/wallets'),
                    ),
                    Icon(Icons.notifications_outlined,
                        color: theme.colorScheme.onSurface),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              WalletHeader(
                address: isSwitching
                    ? AppLocalizations.of(context)!.loadingAddress
                    : (addressAsync.value ??
                        (addressAsync.isLoading
                            ? AppLocalizations.of(context)!.loadingAddress
                            : AppLocalizations.of(context)!
                                .errorLoadingAddress)),
                totalBalance: snapshot?.totalBalanceUsd ?? 0.0,
                changePercentage: 0.0,
                isLoading: isSwitching ||
                    (snapshot == null && snapshotAsync.isLoading),
                valuationAvailable: snapshot?.hasValuation ?? false,
              ),
              if (snapshotAsync.hasError ||
                  (snapshot != null && !snapshot.hasValuation))
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: Text('Portfolio valuation is unavailable.',
                      textAlign: TextAlign.center),
                ),
              const SizedBox(height: 32),
              const ActionButtons(),
              const SizedBox(height: 32),
              const FeatureCarousel(),
              const SizedBox(height: 32),
              const AssetList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItemExpanded(
      BuildContext context, IconData icon, String label, int index) {
    return Expanded(
      child: _buildNavItem(context, icon, label, index),
    );
  }

  Widget _buildNavItem(
      BuildContext context, IconData icon, String label, int index) {
    final isActive = _selectedIndex == index;
    final theme = Theme.of(context);
    final themeExt = theme.extension<AppThemeExtension>();
    final colorScheme = theme.colorScheme;
    final isLight = theme.brightness == Brightness.light;

    return GestureDetector(
      onTap: () {
        if (index == 2) ref.invalidate(activityProvider);
        setState(() => _selectedIndex = index);
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutBack,
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        padding: const EdgeInsets.symmetric(vertical: 4),
        decoration: isActive
            ? BoxDecoration(
                color: isLight
                    ? colorScheme.primary.withValues(alpha: 0.1)
                    : colorScheme.primary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  if (themeExt?.accentGlowColor != null && !isLight)
                    BoxShadow(
                      color: themeExt!.accentGlowColor!,
                      blurRadius: 10,
                      spreadRadius: -2,
                    ),
                ],
              )
            : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isActive
                  ? (isLight ? colorScheme.primary : colorScheme.secondary)
                  : colorScheme.onSurface
                      .withValues(alpha: isLight ? 0.7 : 0.4),
              size: isActive ? 22 : 20,
            ),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: isActive
                      ? colorScheme.onSurface
                      : colorScheme.onSurface
                          .withValues(alpha: isLight ? 0.7 : 0.4),
                  fontSize: 8,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  letterSpacing: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
