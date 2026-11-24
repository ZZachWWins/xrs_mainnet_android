import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xeris_wallet/core/models/price_alert.dart';
import 'package:xeris_wallet/core/providers/price_alert_provider.dart';
import 'package:xeris_wallet/core/providers/wallet_provider.dart';
import 'package:xeris_wallet/core/theme/app_theme.dart';
import 'package:xeris_wallet/core/utils/amount_utils.dart';

class PriceAlertsScreen extends ConsumerWidget {
  const PriceAlertsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alerts = ref.watch(priceAlertsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Price Alerts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: AppColors.brandVibrant),
            onPressed: () => _showAddAlertSheet(context, ref),
          ),
        ],
      ),
      body: alerts.isEmpty
          ? _buildEmptyState(context)
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: alerts.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) => _AlertCard(
                alert: alerts[index],
                onDelete: () => ref.read(priceAlertsProvider.notifier).removeAlert(index),
                onReactivate: alerts[index].isActive
                    ? null
                    : () => ref.read(priceAlertsProvider.notifier).reactivateAlert(index),
              ),
            ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: AppColors.brandSpace,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.notifications_outlined, size: 48, color: AppColors.brandVibrant),
          ),
          const SizedBox(height: 24),
          const Text(
            'No Price Alerts',
            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tap + to get notified when a token\nreaches your target price.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textBody),
          ),
        ],
      ),
    );
  }

  void _showAddAlertSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.brandNavy,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => _AddAlertSheet(
        onAdd: (alert) => ref.read(priceAlertsProvider.notifier).addAlert(alert),
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  final PriceAlert alert;
  final VoidCallback onDelete;
  final VoidCallback? onReactivate;

  const _AlertCard({required this.alert, required this.onDelete, this.onReactivate});

  @override
  Widget build(BuildContext context) {
    final isTriggered = !alert.isActive;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.brandSpace,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isTriggered
              ? Colors.green.withValues(alpha: 0.5)
              : AppColors.brandVibrant.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isTriggered ? Colors.green.withValues(alpha: 0.15) : AppColors.brandMidnight,
              shape: BoxShape.circle,
            ),
            child: Icon(
              alert.isAbove ? Icons.arrow_upward : Icons.arrow_downward,
              color: isTriggered ? Colors.green : AppColors.brandVibrant,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alert.symbol,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${alert.isAbove ? "Above" : "Below"} \$${alert.targetPrice.toStringAsFixed(4)}',
                  style: const TextStyle(color: AppColors.textBody, fontSize: 13),
                ),
              ],
            ),
          ),
          if (isTriggered)
            TextButton(
              onPressed: onReactivate,
              style: TextButton.styleFrom(
                foregroundColor: Colors.green,
                visualDensity: VisualDensity.compact,
              ),
              child: const Text('Reset'),
            )
          else
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Icon(Icons.notifications_active_outlined, color: AppColors.brandVibrant, size: 18),
            ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.white38, size: 20),
            onPressed: onDelete,
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}

class _AddAlertSheet extends ConsumerStatefulWidget {
  final void Function(PriceAlert) onAdd;

  const _AddAlertSheet({required this.onAdd});

  @override
  ConsumerState<_AddAlertSheet> createState() => _AddAlertSheetState();
}

class _AddAlertSheetState extends ConsumerState<_AddAlertSheet> {
  final _priceController = TextEditingController();
  String _selectedTokenId = 'xrs_native';
  String _selectedSymbol = 'XRS';
  bool _isAbove = true;
  String? _error;

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final assetsAsync = ref.watch(assetsProvider);
    final assets = assetsAsync.asData?.value ?? [];

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'New Price Alert',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          // Token selector
          DropdownButtonFormField<String>(
            value: _selectedTokenId,
            dropdownColor: AppColors.brandNavy,
            decoration: InputDecoration(
              labelText: 'Token',
              labelStyle: const TextStyle(color: AppColors.textBody),
              filled: true,
              fillColor: AppColors.brandSpace,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
            ),
            style: const TextStyle(color: Colors.white),
            items: assets.map((a) => DropdownMenuItem(
              value: a.id,
              child: Text(a.symbol, style: const TextStyle(color: Colors.white)),
            )).toList(), // ignore: deprecated_member_use
            onChanged: (id) {
              if (id == null) return;
              final asset = assets.firstWhere((a) => a.id == id);
              setState(() {
                _selectedTokenId = id;
                _selectedSymbol = asset.symbol;
              });
            },
          ),
          const SizedBox(height: 16),
          // Direction toggle
          Row(
            children: [
              const Text('Alert when price is:', style: TextStyle(color: AppColors.textBody)),
              const SizedBox(width: 12),
              ChoiceChip(
                label: const Text('Above'),
                selected: _isAbove,
                onSelected: (_) => setState(() => _isAbove = true),
                selectedColor: AppColors.brandVibrant,
                labelStyle: TextStyle(color: _isAbove ? Colors.white : AppColors.textBody),
                backgroundColor: AppColors.brandSpace,
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('Below'),
                selected: !_isAbove,
                onSelected: (_) => setState(() => _isAbove = false),
                selectedColor: AppColors.brandVibrant,
                labelStyle: TextStyle(color: !_isAbove ? Colors.white : AppColors.textBody),
                backgroundColor: AppColors.brandSpace,
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _priceController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Target Price (USD)',
              labelStyle: const TextStyle(color: AppColors.textBody),
              prefixText: '\$ ',
              prefixStyle: const TextStyle(color: AppColors.textBody),
              filled: true,
              fillColor: AppColors.brandSpace,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
              errorText: _error,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _submit,
            child: const Text('Set Alert'),
          ),
        ],
      ),
    );
  }

  void _submit() {
    final price = parseAmount(_priceController.text.trim());
    if (price == null || price <= 0) {
      setState(() => _error = 'Enter a valid price');
      return;
    }
    widget.onAdd(PriceAlert(
      tokenId: _selectedTokenId,
      symbol: _selectedSymbol,
      targetPrice: price,
      isAbove: _isAbove,
    ));
    Navigator.pop(context);
  }
}
