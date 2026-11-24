import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:xeris_wallet/core/theme/app_theme.dart';
import 'package:xeris_wallet/core/providers/wallet_provider.dart';
import 'package:xeris_wallet/l10n/app_localizations.dart';

class WalletSetupScreen extends ConsumerWidget {
  const WalletSetupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final walletsAsync = ref.watch(walletListProvider);
    final hasWallets = walletsAsync.value?.isNotEmpty ?? false;

    return Scaffold(
      appBar: hasWallets 
        ? AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.pop(),
            ),
          )
        : null,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              
              // Logo/Animation placeholder
              Center(
                child: Image.asset(
                  'assets/images/LogoSplash.png',
                  width: 100,
                  height: 100,
                )
                .animate()
                .fade(duration: 1.seconds)
                .scale(begin: const Offset(0.8, 0.8)),
              ),
              
              const SizedBox(height: 48),
              
              Text(
                l10n.welcomeTo,
                style: Theme.of(context).textTheme.displayMedium,
                textAlign: TextAlign.center,
              ).animate().fade().moveY(begin: 20, end: 0),
              
              const SizedBox(height: 16),
              
              Text(
                l10n.secureWalletForChain,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ).animate().fade(delay: 200.ms),
              
              const Spacer(),
              
              // Create Button
              ElevatedButton(
                onPressed: () {
                  context.push('/create/secret-phrase');
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                ),
                child: Text(l10n.createANewWallet),
              ).animate().fade(delay: 400.ms).moveY(begin: 20, end: 0),
               
              const SizedBox(height: 16),
              
              // Import Button
              OutlinedButton(
                onPressed: () {
                  context.push('/import');
                },
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                  side: const BorderSide(color: AppColors.brandMuted),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                child: Text(
                  l10n.alreadyHaveWallet,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ).animate().fade(delay: 500.ms).moveY(begin: 20, end: 0),
              
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
