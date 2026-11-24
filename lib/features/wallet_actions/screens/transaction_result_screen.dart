import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:xeris_wallet/core/theme/app_theme.dart';
import 'package:xeris_wallet/core/utils/string_extensions.dart';
import 'package:xeris_wallet/l10n/app_localizations.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';

class TransactionResultScreen extends StatelessWidget {
  final bool success;
  final String? hash;

  const TransactionResultScreen({super.key, required this.success, this.hash});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.brandNavy,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: constraints.maxHeight),
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: 24),
                            
                            // Animated Icon
                            Center(
                              child: Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: success 
                                      ? AppColors.brandVibrant.withValues(alpha: 0.1) 
                                      : AppColors.error.withValues(alpha: 0.1),
                                ),
                                child: Icon(
                                  success ? Icons.schedule : Icons.error,
                                  size: 64,
                                  color: success ? AppColors.brandVibrant : AppColors.error,
                                ),
                              ).animate().scale(duration: 500.ms, curve: Curves.elasticOut),
                            ),
                
                            const SizedBox(height: 32),
                
                            Text(
                              success ? l10n.transactionSubmitted : l10n.transactionFailed,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.headlineMedium,
                            ).animate().fade().moveY(begin: 20, end: 0),
                
                            const SizedBox(height: 16),
                
                            if (success)
                              Text(
                                l10n.txSubmittedDesc,
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              
                            if (success && hash != null)
                              Column(
                                children: [
                                  const SizedBox(height: 16),
                                  _buildReceiptCard(context, hash!, l10n),
                                  const SizedBox(height: 24),
                                  OutlinedButton.icon(
                                    onPressed: () => _shareReceipt(context, hash!, l10n),
                                    icon: const Icon(Icons.share_outlined),
                                    label: Text(l10n.shareReceipt),
                                    style: OutlinedButton.styleFrom(
                                      minimumSize: const Size(double.infinity, 56),
                                      side: BorderSide(color: AppColors.brandVibrant.withValues(alpha: 0.5)),
                                      foregroundColor: AppColors.brandVibrant,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: ElevatedButton(
                onPressed: () {
                  context.go('/home');
                },
                style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 56)),
                child: Text(l10n.backToDashboard),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReceiptCard(BuildContext context, String hash, AppLocalizations l10n) {
    final dateStr = DateFormat('MMM dd, yyyy · HH:mm').format(DateTime.now());
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.brandSpace,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            l10n.transactionDetails.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.brandVibrant,
              fontWeight: FontWeight.bold,
              letterSpacing: 2.0,
            ),
          ),
          const SizedBox(height: 24),
          _buildReceiptRow(l10n.dateLabel, dateStr),
          _buildReceiptRow(l10n.statusLabel, l10n.transactionSubmitted, valueColor: AppColors.brandVibrant),
          const SizedBox(height: 16),
          const Divider(color: Colors.white10),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Transaction Hash',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 10),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${hash.safeSubstring(0, 8)}...${hash.safeSubstring(hash.length - 8)}',
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontFamily: 'monospace'),
                    ),
                  ],
                ),
              ),
              QrImageView(
                data: hash,
                version: QrVersions.auto,
                size: 60.0,
                eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Colors.white),
                dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: Colors.white),
              ),
            ],
          ),
        ],
      ),
    ).animate().fade().slideY(begin: 0.1, end: 0);
  }

  Widget _buildReceiptRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.5))),
          Text(value, style: TextStyle(color: valueColor ?? Colors.white, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  void _shareReceipt(BuildContext context, String hash, AppLocalizations l10n) {
    final text = '${l10n.receiptTitle}\n'
        '${l10n.statusLabel}: ${l10n.transactionSubmitted}\n'
        'Date: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}\n'
        'Hash: $hash';
    // ignore: deprecated_member_use
    Share.share(text, subject: l10n.receiptTitle);
  }
}
