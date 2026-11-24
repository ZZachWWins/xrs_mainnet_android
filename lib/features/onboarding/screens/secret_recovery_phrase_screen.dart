import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:xeris_wallet/core/services/wallet_service.dart';
import 'package:xeris_wallet/core/theme/app_theme.dart';
import 'package:xeris_wallet/core/services/notification_service.dart';
import 'package:xeris_wallet/l10n/app_localizations.dart';
import 'package:xeris_wallet/core/utils/secure_clipboard.dart';
import 'package:xeris_wallet/core/services/screen_security.dart';

class SecretRecoveryPhraseScreen extends StatefulWidget {
  const SecretRecoveryPhraseScreen({super.key});

  @override
  State<SecretRecoveryPhraseScreen> createState() => _SecretRecoveryPhraseScreenState();
}

class _SecretRecoveryPhraseScreenState extends State<SecretRecoveryPhraseScreen> {
  late List<String> mnemonic;

  @override
  void initState() {
    super.initState();
    ScreenSecurity.enable();
    mnemonic = WalletService.generateMnemonic();
  }

  @override
  void dispose() {
    ScreenSecurity.disable();
    super.dispose();
  }

  Future<void> _copyToClipboard() async {
    await copySensitiveToClipboard(mnemonic.join(' '));
    if (mounted) {
      NotificationService.show(context, AppLocalizations.of(context)!.secretPhraseCopied);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.secretRecoveryPhraseTitle),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    // Warning Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.brandMidnight,
                        image: const DecorationImage(
                          image: AssetImage('assets/images/LogoSplash.png'),
                          opacity: 0.05, 
                          fit: BoxFit.contain, // Subtle background logo
                        ),
                        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.warning_amber_rounded, color: Colors.amber),
                              const SizedBox(width: 12),
                              Text(
                                'IMPORTANT',
                                style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Colors.amber),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            l10n.secretPhraseMasterKeyDesc,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ).animate().fade().scale(),

                    const SizedBox(height: 32),

                    // Grid of Words
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2, // 2 columns
                        childAspectRatio: 3.5,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: mnemonic.length,
                      itemBuilder: (context, index) {
                        return Container(
                          decoration: BoxDecoration(
                            color: AppColors.brandSpace,
                            borderRadius: BorderRadius.circular(2),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          alignment: Alignment.centerLeft,
                          child: Row(
                            children: [
                              Text(
                                '${index + 1}.',
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.textBody),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                mnemonic[index],
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ).animate(delay: (50 * index).ms).fade().moveX(begin: -10, end: 0);
                      },
                    ),

                    const SizedBox(height: 24),

                    // Copy Button
                    TextButton.icon(
                      onPressed: _copyToClipboard,
                      icon: const Icon(Icons.copy, size: 18),
                      label: Text(l10n.copyToClipboard),
                      style: TextButton.styleFrom(foregroundColor: AppColors.brandVibrant),
                    ),
                  ],
                ),
              ),
            ),
            
            // Bottom Action
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: ElevatedButton(
                onPressed: () {
                  context.push('/create/verify', extra: mnemonic);
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                ),
                child: Text(l10n.savedSecretPhraseBtn),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
