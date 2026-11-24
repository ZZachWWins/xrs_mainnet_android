import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:xeris_wallet/core/services/auth_service.dart';
import 'package:xeris_wallet/core/services/app_lock.dart';
import 'package:xeris_wallet/core/theme/app_theme.dart';
import 'package:xeris_wallet/l10n/app_localizations.dart';

class LockScreen extends StatefulWidget {
  const LockScreen({super.key});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  bool _isAuthenticating = false;

  @override
  void initState() {
    super.initState();
    _authenticate();
  }

  Future<void> _authenticate() async {
    if (_isAuthenticating) return;
    setState(() => _isAuthenticating = true);

    // Small delay to ensure UI builds first
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;

    final authenticated = await AuthService.authenticate(context);
    if (authenticated && mounted) {
      AppLock.unlock();
      // When pushed over an existing screen (resume lock), just pop back.
      // When reached via the router guard (deep-link cold start), there's
      // nothing to pop, so continue to the originally requested route.
      if (context.canPop()) {
        context.pop();
      } else {
        final from = GoRouterState.of(context).uri.queryParameters['from'];
        context.go((from != null && from.isNotEmpty) ? from : '/home');
      }
    } else {
      setState(() => _isAuthenticating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // PopScope prevents back button
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.brandMidnight,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/images/LogoDark.png', width: 120),
              const SizedBox(height: 48),
              Text(
                l10n.appLockedTitle,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.authenticateToContinue,
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 48),
              ElevatedButton.icon(
                onPressed: _isAuthenticating ? null : _authenticate,
                icon: _isAuthenticating 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.fingerprint),
                label: Text(l10n.unlockWallet),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
