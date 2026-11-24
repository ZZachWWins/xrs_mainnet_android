import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xeris_wallet/core/theme/app_theme.dart';
import 'package:xeris_wallet/l10n/app_localizations.dart';
import 'package:xeris_wallet/core/providers/privacy_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';

class PrivacyDashboardScreen extends ConsumerWidget {
  const PrivacyDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final metricsAsync = ref.watch(privacyMetricsProvider);
    
    return Scaffold(
      backgroundColor: AppColors.brandNavy,
      appBar: AppBar(
        title: Text(l10n.quantumShieldTitle),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: metricsAsync.when(
        data: (metrics) => SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatusHeader(context, l10n, metrics.isQuantumProtected),
              const SizedBox(height: 32),
              _buildMetricGrid(context, l10n, metrics),
              const SizedBox(height: 32),
              _buildSecurityList(context, l10n, metrics),
              const SizedBox(height: 40),
              _buildInfoCard(context, l10n),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.brandVibrant)),
        error: (err, stack) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.white))),
      ),
    );
  }

  Widget _buildStatusHeader(BuildContext context, AppLocalizations l10n, bool isPQActive) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            isPQActive ? AppColors.brandBlue.withValues(alpha: 0.2) : Colors.red.withValues(alpha: 0.1), 
            isPQActive ? AppColors.brandVibrant.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.05)
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isPQActive ? AppColors.brandVibrant.withValues(alpha: 0.3) : Colors.red.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(isPQActive ? Icons.shield_outlined : Icons.shield_outlined, size: 64, color: isPQActive ? AppColors.brandVibrant : Colors.redAccent)
              .animate(onPlay: (c) => c.repeat())
              .shimmer(duration: 2.seconds, color: Colors.white24),
          const SizedBox(height: 16),
          Text(
            isPQActive ? l10n.quantumProtectionActive : l10n.notProtected,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isPQActive ? l10n.pqSecurityLevel : l10n.vulnerableToQuantum,
            style: const TextStyle(color: AppColors.textBody),
          ),
          if (!isPQActive) ...[
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.push('/quantum-shield'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandVibrant,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                l10n.enableQuantumProtectionBtn,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetricGrid(BuildContext context, AppLocalizations l10n, PrivacyMetrics metrics) {
    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            context,
            l10n.zkProofsUsed,
            metrics.zkProofsCount.toString(),
            Icons.vpn_key_outlined,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildMetricCard(
            context,
            l10n.pqKeysRegistered,
            metrics.pqKeysCount.toString(),
            Icons.fingerprint,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard(BuildContext context, String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.brandSpace,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.brandVibrant, size: 24),
          const SizedBox(height: 16),
          Text(
            value,
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityList(BuildContext context, AppLocalizations l10n, PrivacyMetrics metrics) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.securityAudit,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: AppColors.brandVibrant,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 16),
        _buildSecurityItem(
          metrics.isBiometricAvailable ? Icons.check_circle : Icons.warning_amber_rounded,
          l10n.biometricLockActive,
          metrics.isBiometricAvailable,
        ),
        _buildSecurityItem(
          metrics.isPinSet ? Icons.check_circle : Icons.warning_amber_rounded,
          l10n.pinProtected6Digit,
          metrics.isPinSet,
        ),
        _buildSecurityItem(
          metrics.isPrivacyModeEnabled ? Icons.check_circle : Icons.warning_amber_rounded,
          metrics.isPrivacyModeEnabled ? l10n.privacyModeEnabled : l10n.privacyModeDisabled,
          metrics.isPrivacyModeEnabled,
        ),
        _buildSecurityItem(Icons.check_circle, l10n.fullDiskEncryption, true),
      ],
    );
  }

  Widget _buildSecurityItem(IconData icon, String label, bool active) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        children: [
          Icon(icon, color: active ? AppColors.success : AppColors.error, size: 18),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              color: active ? Colors.white : Colors.white.withValues(alpha: 0.5),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.brandBlue.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.brandBlue.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: AppColors.brandLight, size: 20),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              l10n.zkProofAsyncInfo,
              style: const TextStyle(color: AppColors.textBody, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
