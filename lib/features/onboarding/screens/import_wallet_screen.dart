import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:xeris_wallet/core/providers/wallet_provider.dart';
import 'package:xeris_wallet/core/services/storage_service.dart';
import 'package:xeris_wallet/core/services/wallet_service.dart';
import 'package:xeris_wallet/core/theme/app_theme.dart';
import 'package:xeris_wallet/core/services/notification_service.dart';
import 'package:xeris_wallet/l10n/app_localizations.dart';
import 'package:xeris_wallet/core/services/screen_security.dart';

class ImportWalletScreen extends ConsumerStatefulWidget {
  const ImportWalletScreen({super.key});

  @override
  ConsumerState<ImportWalletScreen> createState() => _ImportWalletScreenState();
}

class _ImportWalletScreenState extends ConsumerState<ImportWalletScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  // Seed phrase state
  final _phraseController = TextEditingController();
  String? _phraseError;
  bool _phraseValid = false;

  // Private key state
  final _pkController = TextEditingController();
  String? _pkError;
  bool _pkValid = false;
  String? _pkAddress; // preview address

  bool _isImporting = false;
  bool _obscurePk = true;

  @override
  void initState() {
    super.initState();
    ScreenSecurity.enable();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    ScreenSecurity.disable();
    _tabController.dispose();
    _phraseController.dispose();
    _pkController.dispose();
    super.dispose();
  }

  // ── Seed phrase ──────────────────────────────────────────────────────────

  void _validatePhrase(String value) {
    if (value.trim().isEmpty) {
      setState(() { _phraseError = null; _phraseValid = false; });
      return;
    }
    final isValid = WalletService.validateMnemonic(value.trim());
    setState(() {
      _phraseValid = isValid;
      _phraseError = isValid ? null : AppLocalizations.of(context)!.invalidRecoveryPhrase;
    });
  }

  // ── Private key ──────────────────────────────────────────────────────────

  void _validatePrivateKey(String value) async {
    if (value.trim().isEmpty) {
      setState(() { _pkError = null; _pkValid = false; _pkAddress = null; });
      return;
    }
    final isValid = WalletService.validatePrivateKey(value.trim());
    if (isValid) {
      final address = await WalletService.getAddressFromPrivateKey(value.trim());
      if (mounted) {
        setState(() {
          _pkValid = true;
          _pkError = null;
          _pkAddress = address;
        });
      }
    } else {
      setState(() {
        _pkValid = false;
        _pkError = 'Invalid private key. Enter a base58 or hex encoded key.';
        _pkAddress = null;
      });
    }
  }

  // ── Import ────────────────────────────────────────────────────────────────

  Future<void> _import() async {
    final isPhrase = _tabController.index == 0;
    if (isPhrase && !_phraseValid) return;
    if (!isPhrase && !_pkValid) return;
    if (_isImporting) return;

    setState(() => _isImporting = true);

    try {
      final wallets = await StorageService.getWallets();
      final name = 'Wallet ${wallets.length + 1}';

      // The "key material" stored — either mnemonic or encoded private key
      final keyMaterial = isPhrase
          ? _phraseController.text.trim()
          : WalletService.encodePrivateKeyForStorage(_pkController.text.trim());

      final id = await ref
          .read(walletControllerProvider.notifier)
          .addWallet(name, keyMaterial);

      if (id != null) {
        await ref.read(walletControllerProvider.notifier).switchWallet(id);
        if (!mounted) return;
        NotificationService.show(
          context,
          AppLocalizations.of(context)!.walletImportedSuccess,
        );
        context.go('/home');
      }
    } catch (e) {
      if (mounted) {
        NotificationService.show(
          context,
          AppLocalizations.of(context)!.failedImportWallet(e.toString()),
          isError: true,
        );
        setState(() => _isImporting = false);
      }
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isPhrase = _tabController.index == 0;
    final canImport = isPhrase ? _phraseValid : _pkValid;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.importWalletTitle),
        bottom: TabBar(
          controller: _tabController,
          onTap: (_) => setState(() {}),
          indicatorColor: AppColors.brandVibrant,
          labelColor: AppColors.brandVibrant,
          unselectedLabelColor: AppColors.textBody,
          tabs: const [
            Tab(text: 'Seed Phrase'),
            Tab(text: 'Private Key'),
          ],
        ),
      ),
      body: SafeArea(
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildSeedPhraseTab(l10n),
            _buildPrivateKeyTab(),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.fromLTRB(24, 0, 24, MediaQuery.of(context).viewInsets.bottom + 24),
        child: ElevatedButton(
          onPressed: (canImport && !_isImporting) ? _import : null,
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 56),
            backgroundColor: (canImport && !_isImporting)
                ? AppColors.brandLight
                : AppColors.brandMuted.withValues(alpha: 0.5),
            foregroundColor: (canImport && !_isImporting)
                ? AppColors.brandDeep
                : AppColors.textBody,
          ),
          child: _isImporting
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.brandDeep),
                )
              : Text(l10n.importWalletTitle),
        ),
      ),
    );
  }

  Widget _buildSeedPhraseTab(AppLocalizations l10n) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.enterSecretPhrase, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(l10n.enterRecoveryPhraseDesc, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 32),
          TextField(
            controller: _phraseController,
            maxLines: 4,
            onChanged: _validatePhrase,
            enabled: !_isImporting,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.brandSpace,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              hintText: 'word1 word2 word3 ...',
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
              errorText: _phraseError,
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivateKeyTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Enter Private Key',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          const Text(
            'Enter your base58-encoded private key (64-byte Phantom format) or hex seed.',
            style: TextStyle(color: AppColors.textBody),
          ),
          const SizedBox(height: 32),
          TextField(
            controller: _pkController,
            maxLines: _obscurePk ? 1 : 3,
            obscureText: _obscurePk,
            onChanged: _validatePrivateKey,
            enabled: !_isImporting,
            style: const TextStyle(color: Colors.white, fontFamily: 'monospace'),
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.brandSpace,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.brandVibrant),
              ),
              hintText: 'Base58 or hex private key...',
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
              errorText: _pkError,
              contentPadding: const EdgeInsets.all(16),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(
                      _obscurePk ? Icons.visibility_off : Icons.visibility,
                      color: AppColors.textBody,
                      size: 20,
                    ),
                    onPressed: () => setState(() => _obscurePk = !_obscurePk),
                  ),
                  IconButton(
                    icon: const Icon(Icons.paste, color: AppColors.textBody, size: 20),
                    onPressed: () async {
                      final data = await Clipboard.getData('text/plain');
                      if (data?.text != null) {
                        _pkController.text = data!.text!;
                        _validatePrivateKey(data.text!);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Address preview
          if (_pkAddress != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green, size: 16),
                      SizedBox(width: 6),
                      Text('Wallet Address', style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _pkAddress!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 24),

          // Security warning
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Never share your private key. Anyone with it has full control of your wallet.',
                    style: TextStyle(color: AppColors.error, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
