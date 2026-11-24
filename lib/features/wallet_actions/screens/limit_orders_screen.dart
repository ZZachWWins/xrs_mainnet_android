import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xeris_wallet/core/models/asset_model.dart';
import 'package:xeris_wallet/core/models/xeris_api_models.dart';
import 'package:xeris_wallet/core/providers/wallet_provider.dart';
import 'package:xeris_wallet/core/theme/app_theme.dart';
import 'package:xeris_wallet/core/services/storage_service.dart';
import 'package:xeris_wallet/features/wallet_actions/providers/limit_orders_provider.dart';
import 'package:xeris_wallet/features/wallet_actions/providers/swap_provider.dart';
import 'package:xeris_wallet/l10n/app_localizations.dart';
import 'dart:math';

class LimitOrdersScreen extends ConsumerWidget {
  const LimitOrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(limitOrdersProvider);
    final assets = ref.watch(assetsProvider).value ?? [];
    final l10n = AppLocalizations.of(context)!;

    AssetModel findAsset(String id) {
      final lowerId = id.toLowerCase();
      return assets.firstWhere(
        (a) => a.id.toLowerCase() == lowerId || 
               (lowerId == 'xrs_native' && a.id.toLowerCase() == 'xrs') ||
               (lowerId == 'xeris_usdc' && a.id.toLowerCase().contains('usdc')), 
        orElse: () => AssetModel(
          id: id, 
          name: id, 
          symbol: id.toUpperCase().replaceAll('XERIS_', '').replaceAll('_NATIVE', ''), 
          balance: 0, 
          price: 0,
          changePercentage24h: 0,
          decimals: 9
        )
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.limitOrder),
      ),
      body: ordersAsync.when(
        data: (orders) {
          if (orders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.history, size: 64, color: Colors.white24),
                  const SizedBox(height: 16),
                  Text(
                    l10n.noActiveLimitOrders,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.textBody),
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
              final targetPrice = (order.minOutput / order.amount) * pow(10, fromAsset.decimals - toAsset.decimals);

              return Card(
                color: AppColors.brandSpace,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Text(
                                '${fromAsset.symbol} → ${toAsset.symbol}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.brandVibrant.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  l10n.openStatus,
                                  style: const TextStyle(color: AppColors.brandVibrant, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(Icons.cancel_outlined, color: AppColors.error, size: 20),
                            onPressed: () => _confirmCancel(context, ref, order),
                          ),
                        ],
                      ),
                      const Divider(color: Colors.white10),
                      const SizedBox(height: 8),
                      _buildInfoRow(l10n.sellingLabel, '$amountStr ${fromAsset.symbol}'),
                      _buildInfoRow(l10n.buyingMinLabel, '$minOutputStr ${toAsset.symbol}'),
                      _buildInfoRow(l10n.targetPriceLabel, '1 ${fromAsset.symbol} = ${targetPrice.toStringAsFixed(4)} ${toAsset.symbol}'),
                      _buildInfoRow(l10n.orderIdLabel, '${order.id.substring(0, min(8, order.id.length))}...'),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text(l10n.errorPrefix(err.toString()))),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textBody, fontSize: 13)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
        ],
      ),
    );
  }

  void _confirmCancel(BuildContext context, WidgetRef ref, LimitOrder order) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.cancelOrderTitle),
        content: Text(l10n.cancelOrderConfirm),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.no)),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: Text(l10n.yesCancel, style: const TextStyle(color: AppColors.error))
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

      if (success != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.cancelTxSubmitted)),
        );
        ref.invalidate(limitOrdersProvider);
      } else if (context.mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.cancelTxFailed)),
        );
      }
    }
  }
}
