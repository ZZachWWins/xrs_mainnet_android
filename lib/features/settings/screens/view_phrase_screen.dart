import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:xeris_wallet/core/services/storage_service.dart';
import 'package:xeris_wallet/core/services/auth_service.dart';
import 'package:xeris_wallet/core/services/notification_service.dart';
import 'package:xeris_wallet/core/theme/app_theme.dart';
import 'package:xeris_wallet/core/utils/secure_clipboard.dart';
import 'package:xeris_wallet/core/services/screen_security.dart';

class ViewPhraseScreen extends ConsumerStatefulWidget {
  const ViewPhraseScreen({super.key});

  @override
  ConsumerState<ViewPhraseScreen> createState() => _ViewPhraseScreenState();
}

class _ViewPhraseScreenState extends ConsumerState<ViewPhraseScreen> {

  List<String> _mnemonic = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    ScreenSecurity.enable();
    _authenticateAndLoad();
  }

  @override
  void dispose() {
    ScreenSecurity.disable();
    super.dispose();
  }

  Future<void> _authenticateAndLoad() async {
    // Check if security (Biometrics or PIN) is enabled and authenticate
    final securityEnabled = await AuthService.isSecurityEnabled();
    
    if (securityEnabled) {
      final twoFactor = await StorageService.getTwoFactorEnabled();
      if (!mounted) return;
      final authenticated = await AuthService.authenticate(
        context,
        requireTwoFactor: twoFactor,
      );
      if (!mounted) return;
      if (!authenticated) {
        NotificationService.show(context, 'Authentication failed', isError: true);
        context.pop(); // Go back if failed
        return;
      }
    }
    
    // 2. Load phrase
    final mnemonicString = await StorageService.getMnemonic();
    
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (mnemonicString != null) {
          _mnemonic = mnemonicString.split(' ');
        }
      });
    }
  }

  Future<void> _copyPhrase() async {
    if (_mnemonic.isEmpty) return;
    await copySensitiveToClipboard(_mnemonic.join(' '));
    if (mounted) {
      NotificationService.show(context, 'Recovery phrase copied to clipboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recovery Phrase'),
      ),
      backgroundColor: AppColors.brandNavy,
      body: SafeArea(
        child: _isLoading 
            ? const Center(child: CircularProgressIndicator(color: AppColors.brandVibrant))
            : Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded, color: AppColors.error),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Never share this phrase. Anyone with these words can steal your assets.',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.error),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    if (_mnemonic.isEmpty)
                      const Text(
                        'No wallet found.',
                        style: TextStyle(color: AppColors.textBody),
                      )
                    else
                      Expanded(
                        child: GridView.builder(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2, // 2 columns
                            childAspectRatio: 3.5,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
                          itemCount: _mnemonic.length,
                          itemBuilder: (context, index) {
                            return Container(
                              decoration: BoxDecoration(
                                color: AppColors.brandSpace,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              alignment: Alignment.centerLeft,
                              child: Row(
                                children: [
                                  Text(
                                    '${index + 1}.',
                                    style: const TextStyle(
                                      color: AppColors.textBody,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      _mnemonic[index],
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      
                    const SizedBox(height: 24),
                    
                    if (_mnemonic.isNotEmpty)
                      OutlinedButton.icon(
                        onPressed: _copyPhrase,
                        icon: const Icon(Icons.copy),
                        label: const Text('Copy to Clipboard'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.brandVibrant,
                          side: const BorderSide(color: AppColors.brandVibrant),
                          minimumSize: const Size(double.infinity, 56),
                        ),
                      ),
                  ],
                ),
              ),
      ),
    );
  }
}
