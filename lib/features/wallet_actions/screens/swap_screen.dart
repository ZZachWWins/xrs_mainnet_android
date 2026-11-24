import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
// import 'package:xeris_wallet/core/data/mock_data.dart'; // Accessed via provider
import 'package:xeris_wallet/core/models/asset_model.dart';
import 'package:xeris_wallet/core/theme/app_theme.dart';
import 'package:xeris_wallet/features/wallet_actions/providers/swap_provider.dart';
import 'package:xeris_wallet/features/wallet_actions/widgets/asset_selection_modal.dart';
import 'package:xeris_wallet/l10n/app_localizations.dart';

class SwapScreen extends ConsumerStatefulWidget {
  const SwapScreen({super.key});

  @override
  ConsumerState<SwapScreen> createState() => _SwapScreenState();
}

class _SwapScreenState extends ConsumerState<SwapScreen> {
  final _fromController = TextEditingController();
  final _toController = TextEditingController();

  void _setMaxFromAmount(AssetModel asset) {
    double amount = asset.balance;
    // Deduct fee for native XRS
    if (asset.id == 'xrs' || asset.id == 'xrs_native') {
      const double fee = 0.001;
      amount = (amount - fee).clamp(0, double.infinity);
    }
    
    String formattedAmount = amount.toStringAsFixed(asset.decimals > 0 ? asset.decimals : 4);
    if (formattedAmount.contains('.')) {
      formattedAmount = formattedAmount.replaceAll(RegExp(r'0*$'), '').replaceAll(RegExp(r'\.$'), '');
    }
    
    _fromController.text = formattedAmount;
    ref.read(swapProvider.notifier).updateFromAmount(formattedAmount);
  }

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    super.dispose();
  }

  // Sync controllers with state when state changes externally (e.g. quote update)
  // or initial load.
  // We use a listener in build or simple reconstruction. 
  // For text inputs being edited by user, we must be careful not to reset cursor or overwrite user input 
  // unless necessary.

  @override
  Widget build(BuildContext context) {
    final swapState = ref.watch(swapProvider);
    final notifier = ref.read(swapProvider.notifier);

    // Sync TO controller (readonly usually)
    if (_toController.text != swapState.toAmount) {
        // Only update if changed to avoid loop
        _toController.text = swapState.toAmount;
    }
    
    // Sync FROM controller only if empty (reset) or if we want bi-directional sync later.
    // For now, let's just let user type. If swap happens (switch assets), we might need to update.
    // NOTE: This simple approach might have cursor issues if we updated fromState -> controller constantly.
    // But since fromState comes FROM controller, we usually don't write back unless logic changes it (like Max button).
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.swapTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded),
            tooltip: 'Limit Orders',
            onPressed: () => context.push('/swap/orders'),
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isSmallScreen = constraints.maxWidth <= 375;
            final padding = isSmallScreen ? 12.0 : 24.0;
            
            return SingleChildScrollView(
              padding: EdgeInsets.all(padding),
              child: Column(
                children: [
              // Order Type Toggle
              Container(
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: AppColors.brandSpace,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => notifier.toggleLimitOrder(false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: !swapState.isLimitOrder ? AppColors.brandVibrant.withValues(alpha: 0.2) : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            border: !swapState.isLimitOrder ? Border.all(color: AppColors.brandVibrant) : null,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            l10n.marketOrder,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: !swapState.isLimitOrder ? AppColors.brandVibrant : Colors.white70,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => notifier.toggleLimitOrder(true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: swapState.isLimitOrder ? AppColors.brandVibrant.withValues(alpha: 0.2) : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            border: swapState.isLimitOrder ? Border.all(color: AppColors.brandVibrant) : null,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            l10n.limitOrder,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: swapState.isLimitOrder ? AppColors.brandVibrant : Colors.white70,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // FROM Card
              _buildSwapCard(
                context, 
                title: l10n.from, 
                asset: swapState.fromAsset, 
                controller: _fromController, 
                onChanged: (val) => notifier.updateFromAmount(val),
                onAssetTap: () => _showAssetSelector(context, (asset) => notifier.setFromAsset(asset), isFrom: true),
              ),

              const SizedBox(height: 16),

              // Switcher Icon
              GestureDetector(
                onTap: () {
                    notifier.switchAssets();
                    // Update controller text if we swapped values or logic dictates
                    _fromController.text = ref.read(swapProvider).fromAmount;
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.brandMidnight,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.brandVibrant.withValues(alpha: 0.5)),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.brandBlue.withValues(alpha: 0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: swapState.isLoading 
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.swap_vert, color: AppColors.brandVibrant),
                ),
              ),

              const SizedBox(height: 16),

              if (swapState.isLimitOrder) ...[
                // Limit Price Field
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.brandSpace,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(l10n.limitPriceLabel, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppColors.textBody)),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          onChanged: (val) => notifier.updateLimitPrice(val),
                          textAlign: TextAlign.right,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: Theme.of(context).textTheme.titleMedium,
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: '0.0',
                            suffixText: ' ${swapState.toAsset.symbol}',
                            suffixStyle: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white54),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // TO Card
              _buildSwapCard(
                context, 
                title: l10n.toEstimated, 
                asset: swapState.toAsset, 
                controller: _toController,
                readOnly: true,
                onAssetTap: () => _showAssetSelector(context, (asset) => notifier.setToAsset(asset), isFrom: false),
              ),

              const SizedBox(height: 40),

              // Info Card
              if (swapState.exchangeRate != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.brandSpace,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Column(
                  children: [
                    _buildRow(context, l10n.price, l10n.priceEstimate(swapState.fromAsset.symbol, swapState.exchangeRate!.toStringAsFixed(4), swapState.toAsset.symbol)),
                    const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider(color: Colors.white10)),
                    _buildRow(context, l10n.slippageTolerance, '0.5%'),
                    if (swapState.routePath != null) ...[
                      const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider(color: Colors.white10)),
                      _buildRow(context, 'Route', swapState.routePath!),
                    ],
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              
              if (swapState.error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Text(swapState.error!, style: const TextStyle(color: AppColors.error)),
                ),

              ElevatedButton(
                onPressed: swapState.isLoading ? null : () async {
                    final tx = await notifier.executeSwap(context);
                    if (tx != null && context.mounted) {
                        context.push('/send/result', extra: {
                            'success': true,
                            'hash': tx,
                        });
                    }
                },
                style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 56)),
                child: Text(
                  swapState.isLoading 
                    ? (swapState.status ?? l10n.swapping) 
                    : (swapState.isLimitOrder ? l10n.placeLimitOrder : l10n.swapTitle)
                ),
              ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSwapCard(BuildContext context, {
    required String title,
    required AssetModel asset,
    required TextEditingController controller,
    bool readOnly = false,
    Function(String)? onChanged,
    VoidCallback? onAssetTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.brandSpace,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppColors.textBody)),
              Row(
                children: [
                  Text(AppLocalizations.of(context)!.balance(asset.balance.toString(), ''), style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.textBody)),
                  if (!readOnly) ...[
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () => _setMaxFromAmount(asset),
                      child: Text(
                        AppLocalizations.of(context)!.max,
                        style: const TextStyle(
                          color: AppColors.brandVibrant,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // Asset Selector
              GestureDetector(
                onTap: onAssetTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.brandNavy,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      if (asset.iconPath != null)
                        Image.asset(
                          asset.iconPath!,
                          width: 20,
                          height: 20,
                          errorBuilder: (context, error, stackTrace) => const Icon(Icons.circle, size: 20, color: Colors.grey),
                        )
                      else 
                        const Icon(Icons.circle, size: 20, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text(asset.symbol, style: const TextStyle(fontWeight: FontWeight.bold)),
                      const Icon(Icons.keyboard_arrow_down, size: 16),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  controller: controller,
                  onChanged: onChanged,
                  readOnly: readOnly,
                  textAlign: TextAlign.right,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: Theme.of(context).textTheme.headlineSmall,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: '0.0',
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRow(BuildContext context, String key, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(key, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textBody)),
        Text(value, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
      ],
    );
  }

  void _showAssetSelector(BuildContext context, Function(AssetModel) onSelect, {bool isFrom = false}) {
    AssetSelectionModal.show(
      context,
      onSelect: onSelect,
      allowedSymbols: null,
      requireBalance: isFrom,
      showSearchField: !isFrom,
    );
  }
}
