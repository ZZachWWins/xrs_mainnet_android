import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:xeris_wallet/core/services/biometric_service.dart';
import 'package:xeris_wallet/core/services/storage_service.dart';
import 'package:xeris_wallet/core/theme/app_theme.dart';
import 'package:xeris_wallet/core/services/notification_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:xeris_wallet/l10n/app_localizations.dart';
import 'package:xeris_wallet/core/providers/language_provider.dart';
import 'package:xeris_wallet/core/providers/theme_provider.dart';
import 'package:xeris_wallet/core/providers/wallet_provider.dart';
import 'package:xeris_wallet/core/providers/network_provider.dart';
import 'package:xeris_wallet/core/providers/ui_scale_provider.dart';
import 'package:xeris_wallet/core/config/network_config.dart';
import 'package:xeris_wallet/core/services/auth_service.dart';
import 'package:xeris_wallet/features/security/screens/pin_code_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _biometricsEnabled = false;
  bool _usePin = false;
  bool _hasPinCode = false;
  bool _notificationsEnabled = true;
  bool _twoFactorEnabled = false;
  double _twoFactorThreshold = 0.0;
  String _twoFactorThresholdCurrency = 'USD';
  String _currency = 'USD';
  String _appVersion = '';
  bool _isLoading = true;

  bool get _twoFactorAvailable => _biometricsEnabled && _usePin && _hasPinCode;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final biometricsEnabled = await StorageService.getBiometricsEnabled();
    final usePin = await StorageService.getUsePin();
    final pinCode = await StorageService.getPinCode();
    final notificationsEnabled = await StorageService.getNotificationsEnabled();
    final currency = await StorageService.getCurrency();
    final twoFactorEnabled = await StorageService.getTwoFactorEnabled();
    final twoFactorThreshold = await StorageService.getTwoFactorSendThreshold();
    final twoFactorThresholdCurrency =
        await StorageService.getTwoFactorThresholdCurrency();

    PackageInfo packageInfo = await PackageInfo.fromPlatform();

    if (mounted) {
      setState(() {
        _biometricsEnabled = biometricsEnabled;
        _usePin = usePin;
        _hasPinCode = pinCode != null && pinCode.isNotEmpty;
        _notificationsEnabled = notificationsEnabled;
        _currency = currency;
        _twoFactorEnabled = twoFactorEnabled;
        _twoFactorThreshold = twoFactorThreshold;
        _twoFactorThresholdCurrency = twoFactorThresholdCurrency;
        _appVersion =
            'Version ${packageInfo.version} (${packageInfo.buildNumber})';
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleBiometrics(bool value) async {
    if (value) {
      final authenticated = await BiometricService.authenticate();
      if (!authenticated) {
        if (mounted) {
          NotificationService.show(
            context,
            AppLocalizations.of(context)!.biometricAuthFailed,
            isError: true,
          );
        }
        return;
      }
    }
    await StorageService.setBiometricsEnabled(value);
    if (!value && _twoFactorEnabled) {
      await StorageService.setTwoFactorEnabled(false);
    }
    if (mounted) {
      setState(() {
        _biometricsEnabled = value;
        if (!value) _twoFactorEnabled = false;
      });
    }
  }

  Future<void> _togglePin(bool value) async {
    if (value && !_hasPinCode) {
      final result = await Navigator.of(context).push<bool>(MaterialPageRoute(
          builder: (context) => const PinCodeScreen(mode: PinMode.setup)));
      if (result != true) return;
    }

    if (_hasPinCode) {
      if (!mounted) return;
      final authenticated = await Navigator.of(context).push<bool>(
          MaterialPageRoute(
              builder: (context) => const PinCodeScreen(mode: PinMode.verify)));
      if (authenticated != true) return;
    }

    await StorageService.setUsePin(value);
    final pinCode = await StorageService.getPinCode();
    if (!value && _twoFactorEnabled) {
      await StorageService.setTwoFactorEnabled(false);
    }

    if (mounted) {
      setState(() {
        _usePin = value;
        _hasPinCode = pinCode != null && pinCode.isNotEmpty;
        if (!value) _twoFactorEnabled = false;
      });
    }
  }

  Future<void> _toggleTwoFactor(bool value) async {
    if (value && !_twoFactorAvailable) {
      NotificationService.show(
        context,
        'Enable both PIN and biometrics first',
        isError: true,
      );
      return;
    }

    if (value) {
      // Verify both factors before turning on, so user can't enable 2FA
      // without proving they currently have access.
      final ok =
          await AuthService.authenticate(context, requireTwoFactor: true);
      if (!ok) {
        if (mounted) {
          NotificationService.show(context, 'Authentication failed',
              isError: true);
        }
        return;
      }
    }

    await StorageService.setTwoFactorEnabled(value);
    if (value) {
      // Stamp the threshold currency to whatever the user is currently using,
      // so the stored amount is interpreted consistently later.
      await StorageService.setTwoFactorThresholdCurrency(_currency);
    }
    if (mounted) {
      setState(() {
        _twoFactorEnabled = value;
        if (value) _twoFactorThresholdCurrency = _currency;
      });
    }
  }

  Future<void> _editTwoFactorThreshold() async {
    final controller = TextEditingController(
      text:
          _twoFactorThreshold > 0 ? _twoFactorThreshold.toStringAsFixed(2) : '',
    );
    final theme = Theme.of(context);
    final symbol = currencySymbol(_twoFactorThresholdCurrency);

    final result = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.cardTheme.color,
        title: const Text('2FA Send Threshold'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Require 2FA for sends at or above this amount '
              '(in $_twoFactorThresholdCurrency). Set to 0 to require 2FA on every send.',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: AppColors.textBody),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              autofocus: true,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                prefixText: '$symbol ',
                hintText: '0.00',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final parsed = double.tryParse(controller.text.trim());
              if (parsed == null || parsed < 0) {
                Navigator.of(ctx).pop();
                return;
              }
              Navigator.of(ctx).pop(parsed);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result == null) return;
    await StorageService.setTwoFactorSendThreshold(result);
    if (mounted) setState(() => _twoFactorThreshold = result);
  }

  Future<void> _changePin() async {
    if (!mounted) return;
    final authenticated = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
            builder: (context) => const PinCodeScreen(mode: PinMode.verify)));
    if (authenticated != true) return;

    if (!mounted) return;
    final setupResult = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
            builder: (context) => const PinCodeScreen(mode: PinMode.setup)));

    if (setupResult == true && mounted) {
      NotificationService.show(context, 'PIN Code updated successfully');
    }
  }

  Future<void> _setupPanicPin() async {
    if (!mounted) return;
    final authenticated = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
            builder: (context) => const PinCodeScreen(mode: PinMode.verify)));
    if (authenticated != true) return;

    if (!mounted) return;
    final result = await Navigator.of(context).push<bool>(MaterialPageRoute(
        builder: (context) => const PinCodeScreen(mode: PinMode.setupPanic)));

    if (result == true && mounted) {
      NotificationService.show(context, 'Panic PIN set successfully');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    if (_isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.brandVibrant));
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text(
                  l10n.settingsTitle,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: _buildSection(context, l10n.accountSection, [
                _buildTile(
                  context,
                  title: l10n.manageWalletsTitle,
                  subtitle: l10n.manageWalletsSubtitle,
                  icon: Icons.account_balance_wallet,
                  onTap: () => context.push('/wallets'),
                ),
                _buildDivider(),
                _buildTile(
                  context,
                  title: l10n.addressBookTitle,
                  subtitle: l10n.addressBookSubtitle,
                  icon: Icons.contacts_outlined,
                  onTap: () => context.push('/contacts'),
                ),
                _buildDivider(),
                _buildTile(
                  context,
                  title: l10n.connectedSitesTitle,
                  subtitle: l10n.connectedSitesSubtitle,
                  icon: Icons.language_rounded,
                  onTap: () => context.push('/settings/connected-sites'),
                ),
                _buildDivider(),
                _buildTile(
                  context,
                  title: l10n.recoveryPhraseTitle,
                  subtitle: l10n.recoveryPhraseSubtitle,
                  icon: Icons.security,
                  onTap: () => context.push('/settings/view-phrase'),
                ),
                _buildDivider(),
                _buildDestructiveTile(
                  context,
                  title: 'Delete Wallet',
                  subtitle:
                      'Permanently erase this wallet and all data from this device',
                  icon: Icons.delete_forever_outlined,
                  onTap: _confirmDeleteAccount,
                ),
              ]),
            ),
            SliverToBoxAdapter(
              child: _buildSection(context, l10n.generalSection, [
                _buildTile(
                  context,
                  title: l10n.currencyTitle,
                  subtitle: _currency,
                  icon: Icons.attach_money,
                  onTap: () => _showCurrencyPicker(),
                ),
                _buildDivider(),
                _buildTile(
                  context,
                  title: l10n.languageTitle,
                  subtitle:
                      ref.watch(languageProvider).languageCode.toUpperCase(),
                  icon: Icons.language,
                  onTap: () => _showLanguagePicker(l10n),
                ),
                _buildDivider(),
                _buildTile(
                  context,
                  title: l10n.themeTitle,
                  subtitle: _getThemeName(l10n, ref.watch(themeProvider)),
                  icon: Icons.palette_outlined,
                  onTap: () => _showThemePicker(l10n),
                ),
                _buildDivider(),
                _buildScaleTile(context, ref),
                _buildDivider(),
                _buildNetworkSwitch(l10n),
                _buildDivider(),
                _buildSwitchTile(
                  title: l10n.notificationsTitle,
                  subtitle: l10n.notificationsSubtitle,
                  value: _notificationsEnabled,
                  onChanged: (val) async {
                    await StorageService.setNotificationsEnabled(val);
                    setState(() => _notificationsEnabled = val);
                  },
                  icon: Icons.notifications_active,
                ),
                _buildDivider(),
                _buildTile(
                  context,
                  title: 'Price Alerts',
                  subtitle: 'Get notified when token prices hit your targets',
                  icon: Icons.notifications_none_outlined,
                  onTap: () => context.push('/price-alerts'),
                ),
              ]),
            ),
            SliverToBoxAdapter(
              child: _buildSection(context, l10n.securitySection, [
                _buildSwitchTile(
                  title: l10n.privacyModeTitle,
                  subtitle: l10n.privacyModeSubtitle,
                  value: ref.watch(privacyModeProvider),
                  onChanged: (val) =>
                      ref.read(privacyModeProvider.notifier).toggle(),
                  icon: Icons.visibility_off_outlined,
                ),
                _buildDivider(),
                _buildSwitchTile(
                  title: l10n.biometricTitle,
                  subtitle: l10n.biometricSubtitle,
                  value: _biometricsEnabled,
                  onChanged: _toggleBiometrics,
                  icon: Icons.fingerprint,
                ),
                _buildDivider(),
                _buildSwitchTile(
                  title: l10n.pinCodeTitle,
                  subtitle: l10n.pinCodeSubtitle,
                  value: _usePin,
                  onChanged: _togglePin,
                  icon: Icons.lock_outline,
                ),
                if (_hasPinCode) ...[
                  _buildDivider(),
                  _buildTile(
                    context,
                    title: l10n.changePinCodeTitle,
                    subtitle: l10n.changePinCodeSubtitle,
                    icon: Icons.password,
                    onTap: _changePin,
                  ),
                  _buildDivider(),
                  _buildTile(
                    context,
                    title: l10n.panicPinTitle,
                    subtitle: l10n.panicPinSubtitle,
                    icon: Icons.dangerous_outlined,
                    onTap: _setupPanicPin,
                  ),
                ],
                _buildDivider(),
                _buildSwitchTile(
                  title: 'Two-Factor Authentication',
                  subtitle: _twoFactorAvailable
                      ? 'Require biometrics + PIN for sensitive actions'
                      : 'Enable PIN and biometrics first',
                  value: _twoFactorEnabled,
                  onChanged: _twoFactorAvailable ? _toggleTwoFactor : (_) {},
                  icon: Icons.shield_outlined,
                ),
                if (_twoFactorEnabled) ...[
                  _buildDivider(),
                  _buildTile(
                    context,
                    title: '2FA Send Threshold',
                    subtitle: _twoFactorThreshold > 0
                        ? 'Require 2FA on sends ≥ ${currencySymbol(_twoFactorThresholdCurrency)}${_twoFactorThreshold.toStringAsFixed(2)} $_twoFactorThresholdCurrency'
                        : 'Require 2FA on every send',
                    icon: Icons.tune,
                    onTap: _editTwoFactorThreshold,
                  ),
                ],
                _buildDivider(),
                _buildTile(
                  context,
                  title: l10n.quantumShieldTitle,
                  subtitle: l10n.quantumShieldSubtitle,
                  icon: Icons.security_update_good,
                  onTap: () => context.push('/quantum-shield'),
                ),
              ]),
            ),
            SliverToBoxAdapter(
              child: _buildSection(context, l10n.supportSection, [
                _buildTile(
                  context,
                  title: l10n.privacyPolicyTitle,
                  subtitle: l10n.privacyPolicySubtitle,
                  icon: Icons.privacy_tip,
                  onTap: () => _launchUrl('https://xerisweb.com/privacy'),
                ),
                _buildDivider(),
                _buildTile(
                  context,
                  title: l10n.termsOfServiceTitle,
                  subtitle: l10n.termsOfServiceSubtitle,
                  icon: Icons.description,
                  onTap: () => _launchUrl('https://xerisweb.com/terms'),
                ),
                _buildDivider(),
                _buildTile(
                  context,
                  title: l10n.aboutWalletTitle,
                  subtitle: _appVersion,
                  icon: Icons.info_outline,
                  onTap: () {},
                ),
              ]),
            ),
            const SliverPadding(padding: EdgeInsets.only(bottom: 120)),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
      BuildContext context, String title, List<Widget> children) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Text(
            title.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              color: AppColors.brandVibrant,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: theme.cardTheme.color,
            borderRadius: BorderRadius.circular(12),
            border: theme.cardTheme.shape is RoundedRectangleBorder
                ? Border.fromBorderSide(
                    (theme.cardTheme.shape as RoundedRectangleBorder).side)
                : Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: Column(
            children: children,
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              _buildIcon(icon),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: TextStyle(
                            color: theme.colorScheme.onSurface,
                            fontWeight: FontWeight.w500)),
                    Text(subtitle,
                        style: TextStyle(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.5),
                            fontSize: 12)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.3)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDestructiveTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: AppColors.error, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            color: AppColors.error,
                            fontWeight: FontWeight.w600)),
                    Text(subtitle,
                        style: TextStyle(
                            color: AppColors.error.withValues(alpha: 0.7),
                            fontSize: 12)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right,
                  color: AppColors.error.withValues(alpha: 0.4)),
            ],
          ),
        ),
      ),
    );
  }

  /// Account deletion (App Store Guideline 5.1.1(v)): a confirmation dialog, then
  /// a full erase of the wallet, recovery phrase, keys, PIN, and all local data,
  /// returning the user to onboarding.
  Future<void> _confirmDeleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Wallet?'),
        content: const Text(
          'This permanently erases your wallet, recovery phrase, private keys, PIN, and all data stored on this device. It cannot be undone.\n\n'
          'Make sure you have backed up your recovery phrase first — it is the only way to restore access to your funds.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete Everything'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    await ref.read(walletControllerProvider.notifier).deleteAllData();
    if (!mounted) return;
    NotificationService.show(context, 'Wallet and all data deleted');
    context.go('/setup');
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
    required IconData icon,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          _buildIcon(icon),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w500)),
                Text(subtitle,
                    style: TextStyle(
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.5),
                        fontSize: 12)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.brandVibrant,
            activeTrackColor: AppColors.brandBlue.withValues(alpha: 0.3),
            inactiveThumbColor: AppColors.textBody,
            inactiveTrackColor: theme.brightness == Brightness.dark
                ? AppColors.brandMidnight
                : AppColors.lightBorder,
          ),
        ],
      ),
    );
  }

  Widget _buildNetworkSwitch(AppLocalizations l10n) {
    // A mainnet build ships HTTPS-only (ATS blocks the cleartext testnet node),
    // so the testnet toggle has nothing valid to switch to — hide it and lock
    // the app to mainnet. The switch remains available in dev/testnet builds.
    if (NetworkConfig.defaultNetwork == XerisNetwork.mainnet) {
      return const SizedBox.shrink();
    }

    final currentNetwork = ref.watch(networkProvider);
    final isMainnet = currentNetwork == XerisNetwork.mainnet;
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          _buildIcon(Icons.hub_outlined),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.networkLabel,
                    style: TextStyle(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w500)),
                Text(isMainnet ? l10n.mainnetLabel : l10n.testnetLabel,
                    style: TextStyle(
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.5),
                        fontSize: 12)),
                if (!isMainnet && !NetworkConfig.mainnetConfigured)
                  Text(
                    'Mainnet connection not configured',
                    style: const TextStyle(
                        color: AppColors.brandVibrant,
                        fontSize: 10,
                        fontWeight: FontWeight.bold),
                  ),
              ],
            ),
          ),
          Switch(
            value: isMainnet,
            onChanged: NetworkConfig.mainnetConfigured
                ? (value) async {
                    await ref.read(networkProvider.notifier).setNetwork(
                          value ? XerisNetwork.mainnet : XerisNetwork.testnet,
                        );
                  }
                : null,
            activeThumbColor: AppColors.brandVibrant,
            activeTrackColor: AppColors.brandBlue.withValues(alpha: 0.3),
            inactiveThumbColor: AppColors.textBody,
            inactiveTrackColor: theme.brightness == Brightness.dark
                ? AppColors.brandMidnight
                : AppColors.lightBorder,
          ),
        ],
      ),
    );
  }

  Widget _buildIcon(IconData icon) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.brandBlue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon,
          color: theme.brightness == Brightness.dark
              ? AppColors.brandLight
              : AppColors.brandBlue,
          size: 20),
    );
  }

  Widget _buildDivider() {
    final theme = Theme.of(context);
    return Divider(
        color: theme.colorScheme.onSurface.withValues(alpha: 0.05), height: 1);
  }

  void _showCurrencyPicker() {
    final theme = Theme.of(context);
    showModalBottomSheet(
        context: context,
        backgroundColor: theme.scaffoldBackgroundColor,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (context) {
          return Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Select Currency',
                    style: TextStyle(
                        color: theme.colorScheme.onSurface,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),
                _buildCurrencyOption('USD - United States Dollar', 'USD'),
                _buildCurrencyOption('EUR - Euro', 'EUR'),
              ],
            ),
          );
        });
  }

  Widget _buildCurrencyOption(String label, String code) {
    final theme = Theme.of(context);
    final isSelected = code == _currency;
    return ListTile(
      title: Text(label,
          style: TextStyle(
              color: isSelected
                  ? AppColors.brandVibrant
                  : theme.colorScheme.onSurface)),
      trailing: isSelected
          ? const Icon(Icons.check, color: AppColors.brandVibrant)
          : null,
      onTap: () async {
        ref.read(currencyProvider.notifier).setCurrency(code);
        setState(() => _currency = code);
        if (mounted) Navigator.pop(context);
      },
    );
  }

  void _showLanguagePicker(AppLocalizations l10n) {
    final theme = Theme.of(context);
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: theme.scaffoldBackgroundColor,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (context) {
          return SafeArea(
            child: Container(
              padding: const EdgeInsets.all(24),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(l10n.selectLanguage,
                        style: TextStyle(
                            color: theme.colorScheme.onSurface,
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    _buildLanguageOption('English', 'en'),
                    _buildLanguageOption('Afrikaans', 'af'),
                    _buildLanguageOption('Deutsch', 'de'),
                    _buildLanguageOption('Español', 'es'),
                    _buildLanguageOption('Français', 'fr'),
                    _buildLanguageOption('日本語', 'ja'),
                    _buildLanguageOption('中文', 'zh'),
                    _buildLanguageOption('Nederlands', 'nl'),
                    _buildLanguageOption('Tagalog', 'tl'),
                  ],
                ),
              ),
            ),
          );
        });
  }

  Widget _buildLanguageOption(String label, String code) {
    final theme = Theme.of(context);
    final currentLocale = ref.read(languageProvider).languageCode;
    final isSelected = code == currentLocale;
    return ListTile(
      title: Text(label,
          style: TextStyle(
              color: isSelected
                  ? AppColors.brandVibrant
                  : theme.colorScheme.onSurface)),
      trailing: isSelected
          ? const Icon(Icons.check, color: AppColors.brandVibrant)
          : null,
      onTap: () {
        ref.read(languageProvider.notifier).setLanguage(code);
        if (mounted) Navigator.pop(context);
      },
    );
  }

  Widget _buildScaleTile(BuildContext context, WidgetRef ref) {
    final scale = ref.watch(uiScaleProvider);
    final selectedIndex =
        uiScaleSteps.indexOf(scale).clamp(0, uiScaleSteps.length - 1);
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(Icons.text_fields_rounded,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              size: 22),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Interface Size', style: theme.textTheme.bodyLarge),
                const SizedBox(height: 8),
                Row(
                  children: List.generate(uiScaleSteps.length, (i) {
                    final selected = i == selectedIndex;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => ref
                            .read(uiScaleProvider.notifier)
                            .setScale(uiScaleSteps[i]),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: selected
                                ? AppColors.brandVibrant
                                : AppColors.brandVibrant
                                    .withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            uiScaleLabels[i],
                            style: TextStyle(
                              color: selected
                                  ? Colors.white
                                  : theme.colorScheme.onSurface
                                      .withValues(alpha: 0.6),
                              fontSize: 12,
                              fontWeight: selected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showThemePicker(AppLocalizations l10n) {
    final theme = Theme.of(context);
    showModalBottomSheet(
        context: context,
        backgroundColor: theme.scaffoldBackgroundColor,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (context) {
          return Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(l10n.selectTheme,
                    style: TextStyle(
                        color: theme.colorScheme.onSurface,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),
                _buildThemeOption(l10n.themeDark, AppThemeMode.dark),
                _buildThemeOption(l10n.themeLight, AppThemeMode.light),
                _buildThemeOption(l10n.themeSolar, AppThemeMode.solar),
                _buildThemeOption(l10n.themeCyberpunk, AppThemeMode.cyberpunk),
                _buildThemeOption(l10n.themeSystem, AppThemeMode.system),
              ],
            ),
          );
        });
  }

  Widget _buildThemeOption(String label, AppThemeMode mode) {
    final theme = Theme.of(context);
    final currentMode = ref.watch(themeProvider);
    final isSelected = mode == currentMode;
    return ListTile(
      title: Text(label,
          style: TextStyle(
              color: isSelected
                  ? AppColors.brandVibrant
                  : theme.colorScheme.onSurface)),
      trailing: isSelected
          ? const Icon(Icons.check, color: AppColors.brandVibrant)
          : null,
      onTap: () {
        ref.read(themeProvider.notifier).setThemeMode(mode);
        if (mounted) Navigator.pop(context);
      },
    );
  }

  String _getThemeName(AppLocalizations l10n, AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.dark:
        return l10n.themeNameDark;
      case AppThemeMode.light:
        return l10n.themeNameLight;
      case AppThemeMode.solar:
        return l10n.themeNameSolar;
      case AppThemeMode.cyberpunk:
        return l10n.themeNameCyberpunk;
      case AppThemeMode.system:
        return l10n.themeNameSystem;
    }
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        NotificationService.show(context, 'Could not open link', isError: true);
      }
    }
  }
}
