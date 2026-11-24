import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xeris_wallet/core/models/xeris_api_models.dart';
import 'package:xeris_wallet/core/providers/wallet_provider.dart';
import 'package:xeris_wallet/core/services/dex_service.dart';

final limitOrdersProvider = FutureProvider<List<LimitOrder>>((ref) async {
  final address = await ref.watch(walletAddressProvider.future);
  if (address == 'No Wallet' || address.isEmpty) return [];

  final pools =
      await DexService.getPools(forceRefresh: true, includeOrders: true);
  if (pools == null) return [];

  final List<LimitOrder> userOrders = [];
  for (var pool in pools) {
    if (pool.limitOrders != null) {
      userOrders.addAll(pool.limitOrders!.where((o) => o.owner == address));
    }
  }

  // Sort by ID or timestamp if available (not currently in model, but ID might be sequential)
  return userOrders;
});
