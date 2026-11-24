import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xeris_wallet/core/models/xeris_api_models.dart';
import 'package:xeris_wallet/core/providers/wallet_provider.dart';
import 'package:xeris_wallet/core/services/dex_service.dart';

final dcaOrdersProvider = FutureProvider<List<DcaOrder>>((ref) async {
  final address = await ref.watch(walletAddressProvider.future);
  if (address == 'No Wallet' || address.isEmpty) return [];

  final pools =
      await DexService.getPools(forceRefresh: true, includeOrders: true);
  if (pools == null) return [];

  final List<DcaOrder> userOrders = [];
  for (var pool in pools) {
    if (pool.dcaOrders != null) {
      userOrders.addAll(pool.dcaOrders!.where((o) => o.owner == address));
    }
  }

  return userOrders;
});
