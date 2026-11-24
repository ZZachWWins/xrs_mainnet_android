import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xeris_wallet/core/models/asset_model.dart';
import 'package:xeris_wallet/core/providers/wallet_provider.dart';
import 'package:xeris_wallet/core/services/storage_service.dart';
import 'package:xeris_wallet/core/theme/app_theme.dart';
import 'package:xeris_wallet/features/wallet_actions/providers/dca_orders_provider.dart';
import 'package:xeris_wallet/features/wallet_actions/providers/swap_provider.dart';
import 'package:xeris_wallet/features/wallet_actions/widgets/asset_selection_modal.dart';
import 'package:xeris_wallet/core/utils/amount_utils.dart';
import 'package:xeris_wallet/features/wallet_actions/services/swap_service.dart';

class DcaOrderScreen extends ConsumerStatefulWidget {
  const DcaOrderScreen({super.key});

  @override
  ConsumerState<DcaOrderScreen> createState() => _DcaOrderScreenState();
}

class _DcaOrderScreenState extends ConsumerState<DcaOrderScreen> {
  final _totalAmountController = TextEditingController();
  final _amountPerTickController = TextEditingController();
  final _intervalController = TextEditingController(text: '86400');

  AssetModel? _fromAsset;
  AssetModel? _toAsset;
  int _selectedInterval = 86400;
  int _totalTicks = 0;
  bool _isLoading = false;

  static const _intervals = [
    (label: 'Hourly', seconds: 3600),
    (label: 'Daily', seconds: 86400),
    (label: 'Weekly', seconds: 604800),
  ];

  @override
  void dispose() {
    _totalAmountController.dispose();
    _amountPerTickController.dispose();
    _intervalController.dispose();
    super.dispose();
  }

  void _calculateTicks() {
    final total = parseAmount(_totalAmountController.text);
    final perTick = parseAmount(_amountPerTickController.text);
    if (total != null && perTick != null && perTick > 0) {
      setState(() => _totalTicks = (total / perTick).floor());
    } else {
      setState(() => _totalTicks = 0);
    }
  }

  String _getFrequencyLabel() {
    if (_selectedInterval == 3600) return 'hour';
    if (_selectedInterval == 86400) return 'day';
    if (_selectedInterval == 604800) return 'week';
    return '$_selectedInterval seconds';
  }

  String _getDurationLabel() {
    if (_totalTicks == 0) return '—';
    final days = (_selectedInterval * _totalTicks) ~/ 86400;
    if (days == 0) {
      final hours = (_selectedInterval * _totalTicks) ~/ 3600;
      return '$hours hours';
    }
    return '$days days';
  }

  Future<void> _createDcaOrder() async {
    if (!SwapService.advancedOrdersSupported) {
      _showError(SwapService.ordersUnavailableMessage);
      return;
    }
    final fromAsset = _fromAsset;
    final toAsset = _toAsset;

    if (fromAsset == null || toAsset == null) {
      _showError('Please select both tokens');
      return;
    }

    final totalAmount = parseAmount(_totalAmountController.text);
    final amountPerTick = parseAmount(_amountPerTickController.text);

    if (totalAmount == null || totalAmount <= 0) {
      _showError('Please enter a valid total amount');
      return;
    }
    if (amountPerTick == null || amountPerTick <= 0) {
      _showError('Please enter a valid amount per tick');
      return;
    }
    if (_totalTicks <= 0) {
      _showError('Total ticks must be greater than 0');
      return;
    }
    if (totalAmount > fromAsset.balance) {
      _showError('Insufficient balance');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final address = await ref.read(walletAddressProvider.future);
      if (address == 'No Wallet' || address.isEmpty) {
        _showError('No wallet connected');
        return;
      }

      final mnemonic = await StorageService.getMnemonic();
      if (mnemonic == null) {
        _showError('Wallet not configured');
        return;
      }

      final txHash = await ref.read(swapServiceProvider).createDcaOrder(
        walletAddress: address,
        mnemonic: mnemonic,
        fromAsset: fromAsset,
        toAsset: toAsset,
        totalAmount: totalAmount,
        amountPerTick: amountPerTick,
        intervalSeconds: _selectedInterval,
        totalTicks: _totalTicks,
      );

      if (txHash != null && mounted) {
        ref.invalidate(dcaOrdersProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('DCA order created successfully')),
        );
        Navigator.of(context).pop();
      } else if (mounted) {
        _showError('Failed to create DCA order');
      }
    } catch (e) {
      _showError('Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
  }

  void _showAssetSelector({required bool isFrom}) {
    AssetSelectionModal.show(
      context,
      onSelect: (asset) {
        setState(() {
          if (isFrom) {
            _fromAsset = asset;
            if (_toAsset?.id == asset.id) _toAsset = null;
          } else {
            _toAsset = asset;
            if (_fromAsset?.id == asset.id) _fromAsset = null;
          }
        });
      },
      showSearchField: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Create DCA Order')),
      bottomNavigationBar: const SafeArea(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text(SwapService.ordersUnavailableMessage),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Token selectors
              _buildTokenRow(theme),
              const SizedBox(height: 20),

              // Total amount
              _buildInputField(
                controller: _totalAmountController,
                label: 'Total Amount',
                hint: 'Total to invest (${_fromAsset?.symbol ?? '—'})',
                suffix: _fromAsset != null
                    ? TextButton(
                        onPressed: () {
                          _totalAmountController.text =
                              _fromAsset!.balance.toStringAsFixed(4);
                          _calculateTicks();
                        },
                        child: const Text('MAX'),
                      )
                    : null,
                onChanged: (_) => _calculateTicks(),
              ),
              const SizedBox(height: 12),

              // Amount per tick
              _buildInputField(
                controller: _amountPerTickController,
                label: 'Amount Per Execution',
                hint: 'Amount per purchase',
                onChanged: (_) => _calculateTicks(),
              ),
              const SizedBox(height: 12),

              // Interval selector
              _buildIntervalSelector(theme),
              const SizedBox(height: 12),

              // Total ticks (read-only)
              _buildReadOnlyField(
                label: 'Total Executions',
                value: _totalTicks > 0 ? '$_totalTicks purchases' : '—',
                hint: 'Auto-calculated',
              ),
              const SizedBox(height: 20),

              // Summary card
              _buildSummaryCard(theme),
              const SizedBox(height: 24),

              // Create button
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _createDcaOrder,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text(
                          'Create DCA Order',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTokenRow(ThemeData theme) {
    return Row(
      children: [
        Expanded(child: _buildTokenSelector(label: 'From', asset: _fromAsset, isFrom: true)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Icon(Icons.arrow_forward, color: AppColors.textBody, size: 20),
        ),
        Expanded(child: _buildTokenSelector(label: 'To', asset: _toAsset, isFrom: false)),
      ],
    );
  }

  Widget _buildTokenSelector({
    required String label,
    required AssetModel? asset,
    required bool isFrom,
  }) {
    return GestureDetector(
      onTap: () => _showAssetSelector(isFrom: isFrom),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.brandSpace,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(color: AppColors.textBody, fontSize: 11)),
                  const SizedBox(height: 2),
                  Text(
                    asset?.symbol ?? 'Select',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: asset != null ? Colors.white : AppColors.textBody,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.keyboard_arrow_down, size: 18, color: AppColors.textBody),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    Widget? suffix,
    void Function(String)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textBody, fontSize: 12)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: AppColors.textBody),
            filled: true,
            fillColor: AppColors.brandSpace,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.white10),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.white10),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.brandVibrant),
            ),
            suffixIcon: suffix,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildIntervalSelector(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Purchase Interval', style: TextStyle(color: AppColors.textBody, fontSize: 12)),
        const SizedBox(height: 6),
        Row(
          children: _intervals.map((interval) {
            final isSelected = _selectedInterval == interval.seconds;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedInterval = interval.seconds),
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.brandVibrant.withValues(alpha: 0.2)
                        : AppColors.brandSpace,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected ? AppColors.brandVibrant : Colors.white10,
                    ),
                  ),
                  child: Text(
                    interval.label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isSelected ? AppColors.brandVibrant : AppColors.textBody,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildReadOnlyField({
    required String label,
    required String value,
    required String hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textBody, fontSize: 12)),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.brandSpace.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white10),
          ),
          child: Text(
            value,
            style: TextStyle(
              color: _totalTicks > 0 ? Colors.white : AppColors.textBody,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(ThemeData theme) {
    final totalAmount = parseAmount(_totalAmountController.text);
    final amountPerTick = parseAmount(_amountPerTickController.text);
    final hasData = totalAmount != null && amountPerTick != null && _totalTicks > 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.brandVibrant.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.brandVibrant.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'DCA Summary',
            style: theme.textTheme.titleSmall?.copyWith(
              color: AppColors.brandVibrant,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          _buildSummaryRow(
            'From',
            _fromAsset?.symbol ?? '—',
          ),
          _buildSummaryRow(
            'To',
            _toAsset?.symbol ?? '—',
          ),
          _buildSummaryRow(
            'Frequency',
            'Every ${_getFrequencyLabel()}',
          ),
          _buildSummaryRow(
            'Duration',
            hasData ? _getDurationLabel() : '—',
          ),
          _buildSummaryRow(
            'Total Cost',
            hasData
                ? '${totalAmount.toStringAsFixed(4)} ${_fromAsset?.symbol ?? ''}'
                : '—',
          ),
          if (hasData && _fromAsset != null)
            _buildSummaryRow(
              'Per Purchase',
              '${amountPerTick.toStringAsFixed(4)} ${_fromAsset!.symbol}',
            ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textBody, fontSize: 13)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
        ],
      ),
    );
  }
}
