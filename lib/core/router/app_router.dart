import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:xeris_wallet/core/config/feature_flags.dart';
import 'package:xeris_wallet/features/onboarding/screens/import_wallet_screen.dart';
import 'package:xeris_wallet/features/onboarding/screens/splash_screen.dart';
import 'package:xeris_wallet/features/dashboard/screens/home_screen.dart';
import 'package:xeris_wallet/features/wallet_actions/screens/send_input_screen.dart';
import 'package:xeris_wallet/features/wallet_actions/screens/send_review_screen.dart';
import 'package:xeris_wallet/features/wallet_actions/screens/transaction_result_screen.dart';
import 'package:xeris_wallet/features/wallet_actions/screens/receive_screen.dart';
import 'package:xeris_wallet/features/wallet_actions/screens/swap_screen.dart';
import 'package:xeris_wallet/features/onboarding/screens/secret_recovery_phrase_screen.dart';
import 'package:xeris_wallet/features/onboarding/screens/verify_phrase_screen.dart';
import 'package:xeris_wallet/features/onboarding/screens/wallet_setup_screen.dart';
import 'package:xeris_wallet/features/wallet_actions/screens/qr_scanner_screen.dart';
import 'package:xeris_wallet/features/auth/screens/lock_screen.dart';
import 'package:xeris_wallet/features/wallet_management/screens/wallet_manager_screen.dart';
import 'package:xeris_wallet/features/wallet_management/screens/add_wallet_options_screen.dart';
import 'package:xeris_wallet/features/dashboard/screens/balance_history_screen.dart';
import 'package:xeris_wallet/features/settings/screens/view_phrase_screen.dart';
import 'package:xeris_wallet/features/settings/screens/connected_sites_screen.dart';
import 'package:xeris_wallet/features/dapp_browser/screens/dapp_browser_screen.dart';
import 'package:xeris_wallet/features/dashboard/screens/asset_details_screen.dart';
import 'package:xeris_wallet/features/wallet_actions/screens/orders_dashboard_screen.dart';
import 'package:xeris_wallet/features/wallet_actions/screens/dca_order_screen.dart';
import 'package:xeris_wallet/core/models/asset_model.dart';

import 'package:xeris_wallet/features/security/screens/quantum_shield_screen.dart';
import 'package:xeris_wallet/features/security/screens/privacy_dashboard_screen.dart';
import 'package:xeris_wallet/features/agents/screens/register_agent_screen.dart';
import 'package:xeris_wallet/features/wallet_actions/screens/validators_screen.dart';
import 'package:xeris_wallet/features/wallet_actions/screens/stake_screen.dart';
import 'package:xeris_wallet/features/wallet_actions/screens/unstake_screen.dart';
import 'package:xeris_wallet/features/contacts/screens/contact_list_screen.dart';
import 'package:xeris_wallet/features/contacts/screens/add_edit_contact_screen.dart';
import 'package:xeris_wallet/features/contacts/screens/contact_detail_screen.dart';
import 'package:xeris_wallet/core/models/contact.dart';
import 'package:xeris_wallet/features/settings/screens/price_alerts_screen.dart';
import 'package:xeris_wallet/core/services/app_lock.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();

/// Routes reachable without unlocking: splash, the lock screen itself, and the
/// onboarding/import flows (no wallet or lock exists yet during those).
bool _isPublicRoute(String location) {
  if (location == '/') return true;
  const publicPrefixes = ['/lock', '/setup', '/create', '/import'];
  return publicPrefixes.any(location.startsWith);
}

final appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: '/',
  redirect: (context, state) {
    // Gate every protected route behind the lock screen when a lock is
    // configured and the session hasn't been unlocked — this also catches cold
    // starts via deep links, which bypass the splash/auth flow.
    if (!AppLock.shouldGate) return null;
    if (_isPublicRoute(state.matchedLocation)) return null;
    return '/lock?from=${Uri.encodeComponent(state.uri.toString())}';
  },
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/setup',
      builder: (context, state) => const WalletSetupScreen(),
    ),
    GoRoute(
      path: '/create/secret-phrase',
      builder: (context, state) => const SecretRecoveryPhraseScreen(),
    ),
    GoRoute(
      path: '/create/verify',
      builder: (context, state) {
        final mnemonic = state.extra as List<String>;
        return VerifyPhraseScreen(originalMnemonic: mnemonic);
      },
    ),
    GoRoute(
      path: '/import',
      builder: (context, state) => const ImportWalletScreen(),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/send/input',
      builder: (context, state) {
        final extras = state.extra as Map<String, dynamic>?;
        final initialAddress = extras?['initialAddress'] as String?;
        final pqMode = extras?['pq_mode'] as bool? ?? false;
        final initialAsset = extras?['initialAsset'] as AssetModel?;
        return SendInputScreen(
          initialAddress: initialAddress,
          pqMode: pqMode,
          initialAsset: initialAsset,
        );
      },
    ),
    GoRoute(
      path: '/send/review',
      builder: (context, state) {
        final extras = state.extra as Map<String, dynamic>;
        return SendReviewScreen(
          asset: extras['asset'],
          address: extras['address'],
          amount: extras['amount'],
          pqMode: extras['pq_mode'] ?? false,
          stealthMode: extras['stealth_mode'] ?? false,
        );
      },
    ),
    GoRoute(
      path: '/send/result',
      builder: (context, state) {
        final extras = state.extra as Map<String, dynamic>;
        return TransactionResultScreen(
          success: extras['success'],
          hash: extras['hash'],
        );
      },
    ),
    GoRoute(
      path: '/receive',
      builder: (context, state) => const ReceiveScreen(),
    ),
    GoRoute(
      path: '/swap',
      // Swap/exchange is disabled on iOS for App Store compliance. Block the
      // route so it stays unreachable even via deep link or programmatic push.
      redirect: (context, state) => FeatureFlags.swapEnabled ? null : '/home',
      builder: (context, state) => const SwapScreen(),
      routes: [
        GoRoute(
          path: 'orders',
          redirect: (context, state) => FeatureFlags.swapEnabled ? null : '/home',
          builder: (context, state) => const OrdersDashboardScreen(),
        ),
      ],
    ),
    GoRoute(
      // Orders (limit + DCA) are exchange/conversion features routed through the
      // DEX, so they are blocked on iOS along with swap.
      path: '/orders',
      redirect: (context, state) => FeatureFlags.swapEnabled ? null : '/home',
      builder: (context, state) => const OrdersDashboardScreen(),
    ),
    GoRoute(
      // DCA is recurring token→token conversion via the DEX — disabled on iOS.
      path: '/dca-order',
      redirect: (context, state) => FeatureFlags.swapEnabled ? null : '/home',
      builder: (context, state) => const DcaOrderScreen(),
    ),
    GoRoute(
      path: '/scan',
      builder: (context, state) => const QRScannerScreen(),
    ),
    GoRoute(
      path: '/lock',
      builder: (context, state) => const LockScreen(),
    ),
    GoRoute(
      path: '/wallets',
      builder: (context, state) => const WalletManagerScreen(),
    ),
    GoRoute(
      path: '/add-wallet',
      builder: (context, state) => const AddWalletOptionsScreen(),
    ),
    GoRoute(
      path: '/balance-history',
      builder: (context, state) => const BalanceHistoryScreen(),
    ),
    GoRoute(
       path: '/settings/view-phrase',
       builder: (context, state) => const ViewPhraseScreen(),
    ),
    GoRoute(
       path: '/settings/connected-sites',
       builder: (context, state) => const ConnectedSitesScreen(),
    ),
    GoRoute(
      path: '/browser',
      builder: (context, state) {
        final extras = state.extra as Map<String, dynamic>?;
        final initialUrl = extras?['url'] as String? ?? 'xeris://home';
        return DAppBrowserScreen(initialUrl: initialUrl);
      },
    ),
    GoRoute(
      path: '/asset-details',
      builder: (context, state) {
        final asset = state.extra as AssetModel;
        return AssetDetailsScreen(asset: asset);
      },
    ),
    GoRoute(
      path: '/quantum-shield',
      builder: (context, state) => const QuantumShieldScreen(),
    ),
    GoRoute(
      path: '/privacy-dashboard',
      builder: (context, state) => const PrivacyDashboardScreen(),
    ),
    GoRoute(
      path: '/agents/register',
      builder: (context, state) => const RegisterAgentScreen(),
    ),
    GoRoute(
      path: '/validators',
      builder: (context, state) => const ValidatorsScreen(),
    ),
    GoRoute(
      path: '/stake',
      builder: (context, state) {
        final address = state.extra as String? ?? '';
        return StakeScreen(validatorAddress: address);
      },
    ),
    GoRoute(
      path: '/unstake',
      builder: (context, state) => const UnstakeScreen(),
    ),
    GoRoute(
      path: '/contacts',
      builder: (context, state) {
        final extras = state.extra as Map<String, dynamic>?;
        final pickerMode = extras?['pickerMode'] as bool? ?? false;
        return ContactListScreen(pickerMode: pickerMode);
      },
    ),
    GoRoute(
      path: '/contacts/add',
      builder: (context, state) => const AddEditContactScreen(),
    ),
    GoRoute(
      path: '/contacts/detail',
      builder: (context, state) {
        final contact = state.extra as Contact;
        return ContactDetailScreen(contact: contact);
      },
    ),
    // Deep link: xeris://launchpad/:tokenId  →  open launchpad token page in browser
    GoRoute(
      path: '/launchpad/:tokenId',
      builder: (context, state) {
        final tokenId = state.pathParameters['tokenId'] ?? '';
        final url = 'https://launchpad.xerisweb.com/token/$tokenId';
        return DAppBrowserScreen(initialUrl: url);
      },
    ),
    GoRoute(
      path: '/price-alerts',
      builder: (context, state) => const PriceAlertsScreen(),
    ),
  ],
);
