import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xeris_wallet/core/providers/wallet_provider.dart';
import 'package:xeris_wallet/core/theme/app_theme.dart';
import 'package:xeris_wallet/core/theme/app_theme_extension.dart';
import 'package:xeris_wallet/core/services/notification_service.dart';
import 'package:xeris_wallet/core/utils/string_extensions.dart';
import 'package:xeris_wallet/l10n/app_localizations.dart';

class WalletHeader extends ConsumerWidget {
  final String address;
  final double totalBalance;
  final double changePercentage;
  final bool isLoading;
  final bool valuationAvailable;

  const WalletHeader({
    super.key,
    required this.address,
    required this.totalBalance,
    required this.changePercentage,
    this.isLoading = false,
    this.valuationAvailable = true,
  });

  Future<void> _copyAddress(BuildContext context) async {
    if (address == 'Loading...' || address.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: address.trim()));
    if (context.mounted) {
      final l10n = AppLocalizations.of(context)!;
      NotificationService.show(context, l10n.addressCopied);
    }
  }

  String _truncateAddress(String address) {
    if (address.length < 10) return address;
    return '${address.safeSubstring(0, 6)}...${address.safeSubstring(address.length - 4)}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final themeExt = theme.extension<AppThemeExtension>();
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final stakedBalanceAsync = ref.watch(stakedBalanceProvider);
    final stakedBalance = isLoading || stakedBalanceAsync.isReloading
        ? 0.0
        : stakedBalanceAsync.value ?? 0.0;

    return Column(
      children: [
        // Address Pill
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: themeExt?.glassColor ?? theme.cardTheme.color,
            borderRadius: BorderRadius.circular(20),
            border: theme.cardTheme.shape is RoundedRectangleBorder
                ? Border.fromBorderSide(
                    (theme.cardTheme.shape as RoundedRectangleBorder).side)
                : Border.all(
                    color: colorScheme.onSurface.withValues(alpha: 0.1)),
          ),
          child: InkWell(
            onTap: () => context.push('/wallets'),
            onLongPress: () => _copyAddress(context),
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.account_balance_wallet_outlined,
                      size: 14, color: colorScheme.secondary),
                  const SizedBox(width: 8),
                  Text(
                    _truncateAddress(address),
                    style: textTheme.labelSmall?.copyWith(
                        letterSpacing: 0, color: colorScheme.onSurface),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.keyboard_arrow_down,
                      size: 16,
                      color: colorScheme.onSurface.withValues(alpha: 0.5)),
                ],
              ),
            ),
          ),
        ).animate().fade().scale(),

        const SizedBox(height: 24),

        // Total Balance
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => context.push('/balance-history'),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: currencySymbol(ref.watch(currencyProvider)),
                              style: (themeExt?.balanceStyle ??
                                      textTheme.displayLarge)
                                  ?.copyWith(
                                fontSize: 32,
                                color: colorScheme.onSurface
                                    .withValues(alpha: 0.5),
                              ),
                            ),
                            TextSpan(
                              text: isLoading || !valuationAvailable
                                  ? '---.--'
                                  : (ref.watch(privacyModeProvider)
                                      ? '••••••'
                                      : (totalBalance *
                                              fiatMultiplier(
                                                  ref.watch(currencyProvider)))
                                          .toStringAsFixed(2)),
                              style: (themeExt?.balanceStyle ??
                                      textTheme.displayLarge)
                                  ?.copyWith(
                                fontSize: (isLoading ||
                                        !ref.watch(privacyModeProvider))
                                    ? 48
                                    : 32,
                                height: 1.0,
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(
                      ref.watch(privacyModeProvider)
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: colorScheme.onSurface.withValues(alpha: 0.5),
                      size: 20,
                    ),
                    onPressed: () =>
                        ref.read(privacyModeProvider.notifier).toggle(),
                  ),
                ],
              ).animate().fade(),
            ),
          ),
        ),

        const SizedBox(height: 8),

        // PnL Pill
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: changePercentage >= 0
                ? AppColors.success.withValues(alpha: 0.1)
                : AppColors.error.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            '${changePercentage >= 0 ? '+' : ''}$changePercentage% ${AppLocalizations.of(context)!.sinceLastMonth}',
            style: textTheme.labelSmall?.copyWith(
              color:
                  changePercentage >= 0 ? AppColors.success : AppColors.error,
              fontWeight: FontWeight.w700,
            ),
          ),
        ).animate(delay: 200.ms).fade().moveY(begin: 10, end: 0),

        if (stakedBalance > 0) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border:
                  Border.all(color: colorScheme.primary.withValues(alpha: 0.2)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.security_outlined,
                    size: 14, color: colorScheme.secondary),
                const SizedBox(width: 6),
                Text(
                  '${stakedBalance.toStringAsFixed(2)} Staked XRS',
                  style: TextStyle(
                    color: colorScheme.onSurface.withValues(alpha: 0.7),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () => context.push('/unstake'),
                  style: TextButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'UNSTAKE',
                    style: TextStyle(
                      color: colorScheme.secondary,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ).animate(delay: 300.ms).fade().moveY(begin: 10, end: 0),
        ],
      ],
    );
  }
}
