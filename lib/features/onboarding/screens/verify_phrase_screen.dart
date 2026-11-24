import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:xeris_wallet/core/providers/wallet_provider.dart';
import 'package:xeris_wallet/core/services/storage_service.dart';
import 'package:xeris_wallet/core/theme/app_theme.dart';
import 'package:xeris_wallet/core/services/notification_service.dart';
import 'package:xeris_wallet/l10n/app_localizations.dart';

class VerifyPhraseScreen extends ConsumerStatefulWidget {
  final List<String> originalMnemonic;

  const VerifyPhraseScreen({super.key, required this.originalMnemonic});

  @override
  ConsumerState<VerifyPhraseScreen> createState() => _VerifyPhraseScreenState();
}

class _VerifyPhraseScreenState extends ConsumerState<VerifyPhraseScreen> {
  // We will ask the user to verify 3 random indices
  late List<int> indicesToVerify;
  final Map<int, TextEditingController> _controllers = {};
  bool _isVerifying = false;
  
  @override
  void initState() {
    super.initState();
    // Pick 3 random distinct indices (0-11)
    final random = Random();
    final Set<int> indices = {};
    while (indices.length < 3) {
      indices.add(random.nextInt(12));
    }
    indicesToVerify = indices.toList()..sort();
    
    for (var index in indicesToVerify) {
      _controllers[index] = TextEditingController();
    }
  }
  
  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _verify() async {
    if (_isVerifying) return;
    
    bool allCorrect = true;
    for (var index in indicesToVerify) {
      final input = _controllers[index]!.text.trim().toLowerCase();
      if (input != widget.originalMnemonic[index]) {
        allCorrect = false;
        break;
      }
    }

    if (allCorrect) {
      setState(() => _isVerifying = true);
      
      try {
        // Save to secure storage with auto-name
        final wallets = await StorageService.getWallets();
        final name = 'Wallet ${wallets.length + 1}';
        
        // Use provider
        final id = await ref.read(walletControllerProvider.notifier).addWallet(name, widget.originalMnemonic.join(' '));
        
        if (id != null) {
           await ref.read(walletControllerProvider.notifier).switchWallet(id);
           
           if (!mounted) return;
    
           // Success!
           NotificationService.show(
             context,
             AppLocalizations.of(context)!.walletVerified,
           );
           context.go('/home');
        }
      } catch (e) {
        if (mounted) {
           NotificationService.show(context, AppLocalizations.of(context)!.failedCreateWallet(e.toString()), isError: true);
           setState(() => _isVerifying = false);
        }
      }
    } else {
      NotificationService.show(
        context,
        AppLocalizations.of(context)!.incorrectWords,
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.verifySecretPhraseTitle),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.verifyBackup,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                l10n.verifyBackupDesc,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              
              const SizedBox(height: 32),
              
              // Input Fields for specific indices
              ...indicesToVerify.map((index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.wordNumber((index + 1).toString()),
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: AppColors.brandVibrant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _controllers[index],
                        enabled: !_isVerifying,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: AppColors.brandSpace,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(2),
                            borderSide: BorderSide.none,
                          ),
                          hintText: l10n.enterWordNumber((index + 1).toString()),
                          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                        ),
                      ),
                    ],
                  ),
                ).animate().fade().moveX(begin: 10, end: 0);
              }),
              
              const SizedBox(height: 32),
              
              ElevatedButton(
                onPressed: _isVerifying ? null : _verify,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                ),
                child: _isVerifying 
                  ? const SizedBox(
                      width: 24, 
                      height: 24, 
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.brandDeep)
                    )
                  : Text(l10n.verifyComplete),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
