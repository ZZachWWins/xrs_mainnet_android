import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:xeris_wallet/core/theme/app_theme.dart';
import 'package:xeris_wallet/core/services/storage_service.dart';
import 'package:xeris_wallet/core/services/auth_service.dart';
import 'package:xeris_wallet/core/services/app_lock.dart';
import 'package:xeris_wallet/core/services/notification_service.dart';
import 'package:xeris_wallet/l10n/app_localizations.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _authFailed = false;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    // Artificial delay for splash animation
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;
    await _attemptUnlock();
  }

  Future<void> _attemptUnlock() async {
    final mnemonic = await StorageService.getMnemonic();
    
    if (mounted) {
      if (mnemonic != null && mnemonic.isNotEmpty) {
        // Use unified AuthService to handle Biometrics vs PIN fallbacks correctly
        final authenticated = await AuthService.authenticate(context);

        if (authenticated) {
          AppLock.unlock();
          if (mounted) context.go('/home');
        } else {
           // Auth failed
           if (mounted) {
             setState(() {
               _authFailed = true;
             });
             NotificationService.show(
               context, 
               AppLocalizations.of(context)!.authRequired, 
               isError: true,
             );
           }
        }
      } else {
        context.go('/setup');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.brandNavy,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            Image.asset(
              'assets/images/LogoSplash.png',
              width: 150,
              height: 150,
            )
            .animate()
            .fade(duration: 800.ms, curve: Curves.easeOut)
            .scale(duration: 800.ms, curve: Curves.easeOut),
            
            const SizedBox(height: 24),
            
            if (_authFailed) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _attemptUnlock,
                icon: const Icon(Icons.lock_open),
                label: Text(AppLocalizations.of(context)!.unlockWallet),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brandVibrant,
                  foregroundColor: AppColors.brandDeep,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
              ).animate().fade().scale(),
            ] else ...[
              // Text "XERIS WALLET"
              Text(
                'XERIS WALLET',
                style: Theme.of(context).textTheme.displayMedium,
              )
              .animate(delay: 400.ms)
              .fade(duration: 600.ms)
              .moveY(begin: 10, end: 0),
              
              const SizedBox(height: 48),
              
              // Loading Beam/Scan effect
              Container(
                width: 200,
                height: 2,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.brandBlue.withValues(alpha: 0),
                      AppColors.brandVibrant,
                      AppColors.brandBlue.withValues(alpha: 0),
                    ],
                  ),
                ),
              )
              .animate(onPlay: (controller) => controller.repeat())
              .shimmer(duration: 2.seconds, color: Colors.white),
            ],
          ],
        ),
      ),
    );
  }
}
