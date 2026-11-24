import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:xeris_wallet/core/config/feature_flags.dart';
import 'package:xeris_wallet/core/theme/app_theme.dart';
import 'package:xeris_wallet/l10n/app_localizations.dart';

class ActionButtons extends StatelessWidget {
  const ActionButtons({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildActionButton(context, Icons.arrow_upward_rounded, l10n.actionSend, 'Send'),
        _buildActionButton(context, Icons.arrow_downward_rounded, l10n.actionReceive, 'Receive'),
        if (FeatureFlags.swapEnabled)
          _buildActionButton(context, Icons.swap_horiz_rounded, l10n.actionSwap, 'Swap'),
        _buildActionButton(context, Icons.security, l10n.actionEarn, 'Earn'),
        _buildActionButton(context, Icons.qr_code_scanner_rounded, l10n.actionScan, 'Scan'),
      ].animate(interval: 100.ms).fade().moveY(begin: 20, end: 0),
    );
  }

  Widget _buildActionButton(BuildContext context, IconData icon, String label, String actionId) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: theme.brightness == Brightness.dark 
                ? AppColors.brandSpace 
                : colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colorScheme.secondary.withValues(alpha: 0.2), 
              width: 1,
            ),
            boxShadow: [
              if (theme.brightness == Brightness.dark)
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () async {
                 if (actionId == 'Send') {
                   context.push('/send/input');
                 } else if (actionId == 'Receive') {
                   context.push('/receive');
                 } else if (actionId == 'Swap') {
                   context.push('/swap');
                 } else if (actionId == 'Earn') {
                   context.push('/validators');
                 } else if (actionId == 'Scan') {
                   final result = await context.push<String>('/scan');
                     if (result != null && context.mounted) {
                       context.push('/send/input', extra: {'initialAddress': result});
                     }
                 }
              },
              borderRadius: BorderRadius.circular(16),
              child: Icon(
                icon,
                color: theme.brightness == Brightness.dark ? colorScheme.secondary : colorScheme.primary,
                size: 24,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurface.withValues(alpha: 0.7),
            fontWeight: FontWeight.w600,
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }
}
