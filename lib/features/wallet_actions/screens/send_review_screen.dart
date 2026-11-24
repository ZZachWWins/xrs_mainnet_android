import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:xeris_wallet/core/models/asset_model.dart';
import 'package:xeris_wallet/core/theme/app_theme.dart';
import 'package:xeris_wallet/l10n/app_localizations.dart';
import 'package:xeris_wallet/core/services/wallet_service.dart';
import 'package:xeris_wallet/core/services/storage_service.dart';
import 'package:xeris_wallet/core/services/auth_service.dart';
import 'package:xeris_wallet/core/providers/wallet_provider.dart';
import 'package:xeris_wallet/core/services/pqc_service.dart';
import 'package:xeris_wallet/core/services/stealth_service.dart';
import 'package:xeris_wallet/core/services/xeris_api_service.dart';

class SendReviewScreen extends ConsumerStatefulWidget {
  final AssetModel asset;
  final String address;
  final double amount;
  final bool pqMode;
  final bool stealthMode;

  const SendReviewScreen({
    super.key,
    required this.asset,
    required this.address,
    required this.amount,
    this.pqMode = false,
    this.stealthMode = false,
  });

  @override
  ConsumerState<SendReviewScreen> createState() => _SendReviewScreenState();
}

class _SendReviewScreenState extends ConsumerState<SendReviewScreen> {
  bool _isSubmitting = false;

  /// Returns whether this send must clear the 2FA bar. True when 2FA is
  /// enabled in settings AND the transaction's fiat value (converted into the
  /// currency the threshold was set in) is at or above the configured
  /// threshold. A threshold of 0 means "always".
  Future<bool> _shouldRequireTwoFactor() async {
    final enabled = await StorageService.getTwoFactorEnabled();
    if (!enabled) return false;
    final threshold = await StorageService.getTwoFactorSendThreshold();
    if (threshold <= 0) return true;
    final thresholdCurrency = await StorageService.getTwoFactorThresholdCurrency();
    final txFiat = widget.amount * widget.asset.price * fiatMultiplier(thresholdCurrency);
    return txFiat >= threshold;
  }

  Future<void> _confirmTransaction() async {
    // Reentry guard: set the submitting flag synchronously BEFORE the async auth
    // gap, so a double-tap (the button stays enabled during auth) cannot submit
    // the transaction twice.
    if (_isSubmitting) return;
    setState(() {
      _isSubmitting = true;
    });

    final l10n = AppLocalizations.of(context)!;
    // Enforce 2FA when enabled and the send is at/above the configured threshold.
    final twoFactor = await _shouldRequireTwoFactor();
    if (!mounted) return;
    final authenticated = await AuthService.authenticate(
      context,
      requireTwoFactor: twoFactor,
    );
    if (!authenticated) {
      if (mounted) setState(() => _isSubmitting = false);
      return;
    }

    try {
      final mnemonic = await StorageService.getMnemonic();
      if (mnemonic == null) {
        throw Exception('No wallet found');
      }

      String? txHash;
      
      if (widget.asset.id == 'xrs' || widget.asset.id == 'xrs_native') {
        // Check spendable balance (native + wrapped) and auto-unwrap if needed
        final keyPair = await WalletService.getKeyPair(mnemonic);
        final address = keyPair.address;
        final nativeBalance = await WalletService.getBalance(address);

        if (nativeBalance < widget.amount) {
          // Check if wrapped XRS can cover the shortfall
          final spendable = await ref.read(spendableXrsProvider.future);
          if (spendable.spendable < widget.amount) {
            throw Exception('Insufficient spendable XRS. You have ${spendable.spendable.toStringAsFixed(4)} XRS available (${spendable.native.toStringAsFixed(4)} native + ${spendable.wrapped.toStringAsFixed(4)} wrapped). Staked XRS cannot be used for transfers.');
          }

          // Auto-unwrap the shortfall
          final shortfall = widget.amount - nativeBalance;
          final unwrapLamports = (shortfall * 1e9).ceil() + 1000; // ceil + buffer so we always unwrap enough to cover the shortfall
          await XerisApiService.unwrapXrs(
            keyPair: keyPair,
            amountLamports: unwrapLamports,
          );
          // Brief delay for the unwrap to settle on-chain
          await Future.delayed(const Duration(seconds: 2));
        }

        if (widget.stealthMode) {
          // Stealth send: generate one-time address via ECDH and transfer
          final activeWallet = await ref.read(activeWalletProvider.future);
          txHash = await StealthService.sendToStealthAddress(
            senderWalletId: activeWallet!.id,
            mnemonic: mnemonic,
            stealthMetaAddress: widget.address,
            amount: widget.amount,
          );
        } else if (widget.pqMode) {
          await ref.read(walletKeyPairProvider.future);
          txHash = await PqcService.sendPqTransfer(
            mnemonic: mnemonic,
            to: widget.address,
            amount: widget.amount,
          );
        } else {
          txHash = await WalletService.sendTransfer(
            mnemonic: mnemonic,
            destinationAddress: widget.address,
            solAmount: widget.amount,
          );
        }
      } else {
        // Assume Token (e.g. xeris_usdc)
        txHash = await WalletService.sendTokenTransfer(
          mnemonic: mnemonic,
          destinationAddress: widget.address,
          tokenId: widget.asset.id,
          amount: widget.amount,
          decimals: widget.asset.decimals,
        );
      }

      if (txHash == null) {
        throw Exception('Transaction failed: No signature returned from node.');
      }

      // Refresh balances now, before navigating away. Clearing the cache first
      // ensures the refetch isn't served the stale pre-send balance. (The old
      // delayed+mounted approach was dead code: the context.go below disposes
      // this screen, so the callback's mounted check was always false by the
      // time it fired.)
      XerisApiService.clearBalanceCache();
      ref.invalidate(accountBalancesProvider);
      ref.invalidate(assetsProvider);

      if (!mounted) return;

      // Navigate to Result
      context.go('/send/result', extra: {
        'success': true,
        'hash': txHash,
      });
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _isSubmitting = false;
      });

      // Show error dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.transactionFailed),
          content: Text(l10n.errorPrefix(e.toString())),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.ok),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.reviewTransaction)),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Amount Display
                Column(
                  children: [
                    Text(l10n.youAreSending, style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: 8),
                    Text(
                      '${AssetModel.formatValue(widget.amount)} ${widget.asset.symbol}',
                      style: Theme.of(context).textTheme.displayMedium?.copyWith(color: AppColors.brandLight),
                    ),
                    const SizedBox(height: 4),
                    Builder(
                      builder: (context) {
                        final currency = ref.watch(currencyProvider);
                        final symbol = currencySymbol(currency);
                        final fiatValue = widget.amount * widget.asset.price * fiatMultiplier(currency);
                        return Text(
                          '≈ $symbol${fiatValue.toStringAsFixed(2)}',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textBody),
                        );
                      },
                    ),
                  ],
                ),
                
                const SizedBox(height: 48),
    
                // Details Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.brandSpace,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Column(
                    children: [
                      _buildDetailRow(context, l10n.from, l10n.myWallet),
                      const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider(color: Colors.white10)),
                      _buildDetailRow(context, l10n.toLabel, widget.address),
                      const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider(color: Colors.white10)),
                      _buildDetailRow(context, l10n.networkFee, widget.pqMode ? '0.001 XRS' : '0.001 XRS'),
                    ],
                  ),
                ),
    
                const SizedBox(height: 48),
    
                ElevatedButton(
                  onPressed: _isSubmitting ? null : _confirmTransaction,
                  style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 56)),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(l10n.confirmAndSend),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textBody)),
        Flexible(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}
