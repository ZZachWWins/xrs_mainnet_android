import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:xeris_wallet/core/config/feature_flags.dart';
import 'package:xeris_wallet/core/models/asset_model.dart';
import 'package:xeris_wallet/core/models/xeris_api_models.dart';
import 'package:xeris_wallet/core/providers/wallet_provider.dart';
import 'package:xeris_wallet/core/services/storage_service.dart';
import 'package:xeris_wallet/core/theme/app_theme.dart';
import 'package:xeris_wallet/features/wallet_actions/providers/dca_orders_provider.dart';
import 'package:xeris_wallet/features/wallet_actions/providers/limit_orders_provider.dart';
import 'package:xeris_wallet/features/wallet_actions/providers/swap_provider.dart';
import 'package:xeris_wallet/l10n/app_localizations.dart';

class OrdersDashboardScreen extends ConsumerWidget {
  const OrdersDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    // Limit orders are created through swap, which is disabled on iOS for App
    // Store compliance. On iOS collapse to a DCA-only view.
    final showLimitOrders = FeatureFlags.swapEnabled;

    return DefaultTabController(
      length: showLimitOrders ? 2 : 1,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Orders'),
          bottom: TabBar(
            tabs: [
              if (showLimitOrders) const Tab(text: 'Limit Orders'),
              const Tab(text: 'DCA Orders'),
            ],
            indicatorColor: AppColors.brandVibrant,
            labelColor: AppColors.brandVibrant,
            unselectedLabelColor: AppColors.textBody,
          ),
        ),
        body: TabBarView(
          children: [
            if (showLimitOrders) _LimitOrdersTab(l10n: l10n),
            _DcaOrdersTab(l10n: l10n),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showNewOrderDialog(context),
          label: const Text('New Order'),
          icon: const Icon(Icons.add),
          backgroundColor: AppColors.brandVibrant,
        ),
      ),
    );
  }

  void _showNewOrderDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.brandSpace,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'Create New Order',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            if (FeatureFlags.swapEnabled)
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.brandVibrant.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.price_change_outlined, color: AppColors.brandVibrant, size: 22),
                ),
                title: const Text('Limit Order', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Execute at a target price', style: TextStyle(color: AppColors.textBody, fontSize: 12)),
                onTap: () {
                  Navigator.pop(context);
                  context.push('/swap');
                },
              ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.repeat_rounded, color: Colors.green, size: 22),
              ),
              title: const Text('DCA Order', style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text('Regular purchases over time', style: TextStyle(color: AppColors.textBody, fontSize: 12)),
              onTap: () {
                Navigator.pop(context);
                context.push('/dca-order');
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _LimitOrdersTab extends ConsumerWidget {
  final AppLocalizations l10n;
  const _LimitOrdersTab({required this.l10n});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(limitOrdersProvider);
    final assets = ref.watch(assetsProvider).value ?? [];

    AssetModel findAsset(String id) {
      final lowerId = id.toLowerCase();
      return assets.firstWhere(
        (a) =>
            a.id.toLowerCase() == lowerId ||
            (lowerId == 'xrs_native' && a.id.toLowerCase() == 'xrs') ||
            (lowerId == 'xeris_usdc' && a.id.toLowerCase().contains('usdc')),
        orElse: () => AssetModel(
          id: id,
          name: id,
          symbol: id.toUpperCase().replaceAll('XERIS_', '').replaceAll('_NATIVE', ''),
          balance: 0,
          price: 0,
          changePercentage24h: 0,
          decimals: 9,
        ),
      );
    }

    return ordersAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text(l10n.errorPrefix(err.toString()))),
      data: (orders) {
        if (orders.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.price_change_outlined, size: 56, color: Colors.white24),
                const SizedBox(height: 16),
                Text(
                  l10n.noActiveLimitOrders,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.textBody),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Use Swap → Limit to place an order',
                  style: TextStyle(color: AppColors.textBody, fontSize: 13),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: orders.length,
          itemBuilder: (context, index) {
            final order = orders[index];
            final fromAsset = findAsset(order.fromToken);
            final toAsset = findAsset(order.targetToken);
            final amountStr = (order.amount / pow(10, fromAsset.decimals)).toStringAsFixed(4);
            final minOutputStr = (order.minOutput / pow(10, toAsset.decimals)).toStringAsFixed(4);
            final targetPrice = (order.minOutput / order.amount) *
                pow(10, fromAsset.decimals - toAsset.decimals);

            return _OrderCard(
              header: '${fromAsset.symbol} → ${toAsset.symbol}',
              badge: 'OPEN',
              badgeColor: AppColors.brandVibrant,
              rows: [
                (l10n.sellingLabel, '$amountStr ${fromAsset.symbol}'),
                (l10n.buyingMinLabel, '$minOutputStr ${toAsset.symbol}'),
                (l10n.targetPriceLabel, '${targetPrice.toStringAsFixed(4)} ${toAsset.symbol}/${fromAsset.symbol}'),
                (l10n.orderIdLabel, '${order.id.substring(0, order.id.length.clamp(0, 8))}...'),
              ],
              onCancel: () => _confirmCancelLimit(context, ref, order),
            );
          },
        );
      },
    );
  }

  Future<void> _confirmCancelLimit(BuildContext context, WidgetRef ref, LimitOrder order) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.cancelOrderTitle),
        content: Text(l10n.cancelOrderConfirm),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.no)),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.yesCancel, style: const TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final mnemonic = await StorageService.getMnemonic();
      if (mnemonic == null) return;

      final success = await ref.read(swapServiceProvider).cancelLimitOrder(
        mnemonic: mnemonic,
        poolId: order.poolId,
        orderId: order.id,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success != null ? l10n.cancelTxSubmitted : l10n.cancelTxFailed),
          ),
        );
        if (success != null) ref.invalidate(limitOrdersProvider);
      }
    }
  }
}

class _DcaOrdersTab extends ConsumerWidget {
  final AppLocalizations l10n;
  const _DcaOrdersTab({required this.l10n});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(dcaOrdersProvider);
    final assets = ref.watch(assetsProvider).value ?? [];

    AssetModel findAsset(String id) {
      final lowerId = id.toLowerCase();
      return assets.firstWhere(
        (a) =>
            a.id.toLowerCase() == lowerId ||
            (lowerId == 'xrs_native' && a.id.toLowerCase() == 'xrs') ||
            (lowerId == 'xeris_usdc' && a.id.toLowerCase().contains('usdc')),
        orElse: () => AssetModel(
          id: id,
          name: id,
          symbol: id.toUpperCase().replaceAll('XERIS_', '').replaceAll('_NATIVE', ''),
          balance: 0,
          price: 0,
          changePercentage24h: 0,
          decimals: 9,
        ),
      );
    }

    return ordersAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text(l10n.errorPrefix(err.toString()))),
      data: (orders) {
        if (orders.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.repeat_rounded, size: 56, color: Colors.white24),
                const SizedBox(height: 16),
                Text(
                  'No active DCA orders',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.textBody),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Tap + to create a DCA order',
                  style: TextStyle(color: AppColors.textBody, fontSize: 13),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: orders.length,
          itemBuilder: (context, index) {
            final order = orders[index];
            final fromAsset = findAsset(order.inputToken);
            final toAsset = findAsset(order.outputToken);

            final totalStr = (order.totalAmountIn / pow(10, fromAsset.decimals)).toStringAsFixed(4);
            final perTickStr = (order.amountPerTick / pow(10, fromAsset.decimals)).toStringAsFixed(4);
            final progress = order.totalTicks > 0
                ? '${order.ticksCompleted}/${order.totalTicks}'
                : '—';
            final intervalLabel = _intervalLabel(order.intervalSeconds);

            return _OrderCard(
              header: '${fromAsset.symbol} → ${toAsset.symbol}',
              badge: order.isActive ? 'ACTIVE' : 'INACTIVE',
              badgeColor: order.isActive ? Colors.green : Colors.grey,
              rows: [
                ('Total', '$totalStr ${fromAsset.symbol}'),
                ('Per Purchase', '$perTickStr ${fromAsset.symbol}'),
                ('Interval', intervalLabel),
                ('Progress', progress),
              ],
              onCancel: order.isActive
                  ? () => _confirmCancelDca(context, ref, order)
                  : null,
            );
          },
        );
      },
    );
  }

  String _intervalLabel(int seconds) {
    if (seconds == 3600) return 'Hourly';
    if (seconds == 86400) return 'Daily';
    if (seconds == 604800) return 'Weekly';
    return '$seconds seconds';
  }

  Future<void> _confirmCancelDca(BuildContext context, WidgetRef ref, DcaOrder order) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel DCA Order?'),
        content: Text(
          'Remaining funds will be returned to your wallet.\n\nCompleted: ${order.ticksCompleted}/${order.totalTicks}',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Keep')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Cancel Order', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final mnemonic = await StorageService.getMnemonic();
      if (mnemonic == null) return;

      final success = await ref.read(swapServiceProvider).cancelDcaOrder(
        mnemonic: mnemonic,
        poolId: order.poolId,
        orderId: order.id,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success != null ? 'DCA order cancelled' : 'Failed to cancel DCA order'),
          ),
        );
        if (success != null) ref.invalidate(dcaOrdersProvider);
      }
    }
  }
}

class _OrderCard extends StatelessWidget {
  final String header;
  final String badge;
  final Color badgeColor;
  final List<(String, String)> rows;
  final VoidCallback? onCancel;

  const _OrderCard({
    required this.header,
    required this.badge,
    required this.badgeColor,
    required this.rows,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.brandSpace,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  header,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: badgeColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        badge,
                        style: TextStyle(
                          color: badgeColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (onCancel != null) ...[
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: onCancel,
                        child: const Icon(Icons.cancel_outlined, color: AppColors.error, size: 20),
                      ),
                    ],
                  ],
                ),
              ],
            ),
            const Divider(color: Colors.white10, height: 20),
            ...rows.map(
              (row) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(row.$1, style: const TextStyle(color: AppColors.textBody, fontSize: 13)),
                    Text(row.$2, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
