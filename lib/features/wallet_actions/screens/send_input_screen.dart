import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:xeris_wallet/core/providers/wallet_provider.dart';
import 'package:xeris_wallet/core/theme/app_theme.dart';
import 'package:xeris_wallet/core/models/asset_model.dart';
import 'package:xeris_wallet/core/services/wallet_service.dart';
import 'package:xeris_wallet/core/services/zkp_service.dart';
import 'package:xeris_wallet/core/services/pqc_service.dart';
import 'package:xeris_wallet/core/models/stealth_models.dart';
import 'package:xeris_wallet/core/config/network_config.dart';
import 'package:xeris_wallet/core/services/stealth_service.dart';
import 'package:xeris_wallet/features/wallet_actions/widgets/asset_selection_modal.dart';
import 'package:xeris_wallet/l10n/app_localizations.dart';
import 'package:xeris_wallet/core/utils/context_extensions.dart';
import 'package:xeris_wallet/core/utils/amount_utils.dart';

class SendInputScreen extends ConsumerStatefulWidget {
  final String? initialAddress;
  final bool pqMode;
  final AssetModel? initialAsset;
  const SendInputScreen(
      {super.key, this.initialAddress, this.pqMode = false, this.initialAsset});

  @override
  ConsumerState<SendInputScreen> createState() => _SendInputScreenState();
}

class _SendInputScreenState extends ConsumerState<SendInputScreen> {
  final _addressController = TextEditingController();
  final _amountController = TextEditingController();

  AssetModel? _selectedAsset;
  String? _errorText;
  bool _isZkPrivate = false;
  bool _isSubmittingZk = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialAddress != null) {
      _addressController.text = widget.initialAddress!;
    }
    if (widget.initialAsset != null) {
      _selectedAsset = widget.initialAsset;
    }
  }

  void _validateAndContinue(AssetModel asset, BuildContext context) {
    final address = _addressController.text.trim();
    final amountText = _amountController.text.trim();
    final amount = parseAmount(amountText);
    final l10n = AppLocalizations.of(context)!;

    setState(() {
      _errorText = null;
    });

    if (widget.pqMode || _isZkPrivate) {
      setState(() => _errorText = widget.pqMode
          ? PqcService.transferUnavailableMessage
          : ZkpService.transferUnavailableMessage);
      return;
    }

    if (address.isEmpty) {
      setState(() => _errorText = l10n.errorEnterRecipient);
      return;
    }

    // Accept both standard addresses and stealth meta-addresses
    final bool isStealth = StealthMetaAddress.isStealthAddress(address);
    if (isStealth && !NetworkConfig.stealthEnabled) {
      setState(() => _errorText = StealthService.unavailableMessage);
      return;
    }
    if (!isStealth && !WalletService.isValidAddress(address)) {
      setState(() => _errorText = l10n.errorInvalidAddress);
      return;
    }

    if (amount == null || amount <= 0) {
      setState(() => _errorText = l10n.errorEnterValidAmount);
      return;
    }

    // For XRS, validate against spendable balance (native + wrapped, not staked)
    if (asset.id == 'xrs' || asset.id == 'xrs_native') {
      final spendable = ref.read(spendableXrsProvider).value;
      if (spendable != null && amount > spendable.spendable) {
        setState(() => _errorText = l10n.errorInsufficientBalance);
        return;
      }
    } else if (amount > asset.balance) {
      setState(() => _errorText = l10n.errorInsufficientBalance);
      return;
    }

    if (_isZkPrivate) {
      if (asset.id != 'xrs' && asset.id != 'xrs_native') {
        setState(() => _errorText = l10n.zkpOnlyXrsError);
        return;
      }
      _submitZkTransfer(address, amount, context);
      return;
    }

    if (widget.pqMode && (asset.id != 'xrs' && asset.id != 'xrs_native')) {
      setState(() => _errorText = l10n.pqcOnlyXrsError);
      return;
    }

    // Pass data to Review Screen
    context.push('/send/review', extra: {
      'asset': asset,
      'address': address,
      'amount': amount,
      'pq_mode': widget.pqMode,
      'stealth_mode': isStealth,
    });
  }

  Future<void> _submitZkTransfer(
      String address, double amount, BuildContext context) async {
    setState(() {
      _isSubmittingZk = true;
      _errorText = null;
    });

    try {
      final keyPair = await ref.read(walletKeyPairProvider.future);

      final signature = await ZkpService.sendZkPrivateTransfer(
        senderKeypair: keyPair,
        recipientAddress: address,
        amountXrs: amount,
      );

      if (!context.mounted) return;

      final l10n = context.l10n;
      // Pop input screen since it is part of a full-screen bottom sheet usually
      Navigator.of(context).pop();
      // Since we bypassed review, let's assume there is a way to show success or we use standard snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                '${l10n.zkpTransferSubmitted}\n${l10n.hashLabel(signature ?? "")}')),
      );
    } catch (e) {
      if (mounted) {
        final l10n = context.l10n;
        setState(() => _errorText =
            l10n.errorPrefix(e.toString().replaceAll('Exception: ', '')));
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmittingZk = false);
      }
    }
  }

  Widget _buildBalanceLabel(AssetModel asset, AppLocalizations l10n) {
    if (asset.id == 'xrs' || asset.id == 'xrs_native') {
      final spendableAsync = ref.watch(spendableXrsProvider);
      final spendable = spendableAsync.value;
      if (spendable != null) {
        final spendableFormatted = AssetModel.formatValue(spendable.spendable);
        return Text(
          'Spendable: $spendableFormatted ${asset.symbol}',
          style: Theme.of(context).textTheme.labelSmall,
        );
      }
    }
    return Text(
      l10n.balance(asset.formattedBalance, asset.symbol),
      style: Theme.of(context).textTheme.labelSmall,
    );
  }

  void _setMaxAmount(AssetModel asset) {
    double amount;
    // For XRS, use spendable balance (native + wrapped, not staked)
    if (asset.id == 'xrs' || asset.id == 'xrs_native') {
      final spendable = ref.read(spendableXrsProvider).value;
      amount = spendable?.spendable ?? asset.balance;
      const double fee = 0.001;
      amount = (amount - fee).clamp(0, double.infinity);
    } else {
      amount = asset.balance;
    }

    // Use toStringAsFixed to avoid scientific notation for tiny amounts
    // and trim trailing zeros for better UX
    String formattedAmount =
        amount.toStringAsFixed(asset.decimals > 0 ? asset.decimals : 4);
    if (formattedAmount.contains('.')) {
      formattedAmount = formattedAmount
          .replaceAll(RegExp(r'0*$'), '')
          .replaceAll(RegExp(r'\.$'), '');
    }

    _amountController.text = formattedAmount;
    setState(() {
      _errorText = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (widget.pqMode) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.sendAssetsTitle)),
        body: const SafeArea(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(PqcService.transferUnavailableMessage),
          ),
        ),
      );
    }
    final assetsAsync = ref.watch(assetsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.sendAssetsTitle),
      ),
      body: assetsAsync.when(
        data: (assets) => _buildBody(context, assets, l10n),
        loading: () {
          // If we have previous data, keep showing it instead of a spinner
          // to prevent losing focus/flickering during background refreshes.
          if (assetsAsync.hasValue) {
            return _buildBody(context, assetsAsync.value!, l10n);
          }
          return const Center(child: CircularProgressIndicator());
        },
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildBody(
      BuildContext context, List<AssetModel> assets, AppLocalizations l10n) {
    // Filter for owned assets to set default
    final ownedAssets = assets.where((a) => a.balance > 0).toList();

    // Use first owned asset as default if none selected, or original logic if no owned assets (edge case)
    final currentAsset = _selectedAsset ??
        (ownedAssets.isNotEmpty
            ? ownedAssets[0]
            : (assets.isNotEmpty ? assets[0] : AssetModel.empty()));

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Asset Selector
                        GestureDetector(
                          onTap: () {
                            AssetSelectionModal.show(
                              context,
                              requireBalance: true,
                              onSelect: (asset) {
                                setState(() {
                                  _selectedAsset = asset;
                                  _errorText = null;
                                  if (asset.id != 'xrs' &&
                                      asset.id != 'xrs_native') {
                                    _isZkPrivate = false;
                                  }
                                });
                              },
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.brandSpace,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.05)),
                            ),
                            child: Row(
                              children: [
                                Image.asset(
                                  currentAsset.iconPath ??
                                      'assets/images/LogoDark.png',
                                  width: 32,
                                  height: 32,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(Icons.circle,
                                          size: 32, color: Colors.grey),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(currentAsset.name,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyLarge),
                                    _buildBalanceLabel(currentAsset, l10n),
                                  ],
                                ),
                                const Spacer(),
                                const Icon(Icons.keyboard_arrow_down,
                                    color: AppColors.textBody),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Address Input
                        Text(l10n.recipientAddress,
                            style: Theme.of(context).textTheme.labelLarge),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _addressController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: AppColors.brandSpace,
                            hintText: l10n.pasteAddressOrScan,
                            hintStyle: TextStyle(
                                color: Colors.white.withValues(alpha: 0.3)),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(4),
                                borderSide: BorderSide.none),
                            suffixIcon: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.paste,
                                      color: AppColors.brandVibrant),
                                  onPressed: () async {
                                    final data = await Clipboard.getData(
                                        Clipboard.kTextPlain);
                                    final text = data?.text;
                                    if (text != null) {
                                      _addressController.text = text.trim();
                                    }
                                  },
                                  tooltip: l10n.paste,
                                ),
                                IconButton(
                                  icon: const Icon(Icons.contacts_outlined,
                                      color: AppColors.brandVibrant),
                                  tooltip: 'Address book',
                                  onPressed: () async {
                                    final address = await context.push<String>(
                                      '/contacts',
                                      extra: {'pickerMode': true},
                                    );
                                    if (address != null) {
                                      _addressController.text = address;
                                    }
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.qr_code_scanner,
                                      color: AppColors.brandVibrant),
                                  onPressed: () async {
                                    final result =
                                        await context.push<String>('/scan');
                                    if (result != null) {
                                      _addressController.text = result;
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Amount Input
                        Text(l10n.amount,
                            style: Theme.of(context).textTheme.labelLarge),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _amountController,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: AppColors.brandSpace,
                            hintText: '0.0',
                            hintStyle: TextStyle(
                                color: Colors.white.withValues(alpha: 0.3)),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(4),
                                borderSide: BorderSide.none),
                            suffixIcon: TextButton(
                              onPressed: () => _setMaxAmount(currentAsset),
                              style: TextButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 12),
                              ),
                              child: Text(
                                l10n.max,
                                style: const TextStyle(
                                  color: AppColors.brandVibrant,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ),
                        ),

                        if (_errorText != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 16.0),
                            child: Text(
                              _errorText!,
                              style: const TextStyle(
                                  color: AppColors.error, fontSize: 14),
                            ),
                          ),

                        const SizedBox(height: 24),

                        // ZKP Toggle
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.brandSpace,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: Colors.white.withValues(alpha: 0.05)),
                          ),
                          child: SwitchListTile(
                            value: _isZkPrivate,
                            onChanged: null, // Disabled by the current node.
                            title: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(l10n.sendPrivately,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyLarge
                                        ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14)),
                                const SizedBox(width: 8),
                                const Icon(Icons.lock,
                                    color: Colors.amber, size: 16),
                              ],
                            ),
                            subtitle: Text(
                                ZkpService.transferUnavailableMessage,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                        color: AppColors.textBody
                                            .withValues(alpha: 0.7),
                                        fontSize: 12)),
                            activeThumbColor: Colors.white,
                            activeTrackColor: AppColors.brandBlue,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 4),
                          ),
                        ),

                        if (_isZkPrivate) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.brandBlue.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: AppColors.brandBlue
                                      .withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.info_outline,
                                    color: AppColors.brandBlue, size: 16),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    l10n.zkpInfoBox,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: AppColors.brandLight
                                              .withValues(alpha: 0.8),
                                          fontSize: 13,
                                          height: 1.4,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const Spacer(),
                        const SizedBox(height: 24),

                        ElevatedButton(
                          onPressed: _isSubmittingZk
                              ? null
                              : () =>
                                  _validateAndContinue(currentAsset, context),
                          style: ElevatedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 56)),
                          child: _isSubmittingZk
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.brandDeep))
                              : Text(_isZkPrivate
                                  ? l10n.generateProofAndSend
                                  : l10n.review),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
