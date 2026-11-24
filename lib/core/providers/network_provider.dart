import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xeris_wallet/core/config/network_config.dart';
import 'package:xeris_wallet/core/services/storage_service.dart';
import 'package:xeris_wallet/core/services/xeris_api_service.dart';
import 'package:xeris_wallet/core/services/dex_service.dart';

class NetworkNotifier extends Notifier<XerisNetwork> {
  @override
  XerisNetwork build() {
    return NetworkConfig.currentNetwork;
  }

  Future<void> setNetwork(XerisNetwork network) async {
    if (network == state) return;
    NetworkConfig.validate(network);
    await StorageService.setNetwork(
        network == XerisNetwork.mainnet ? 'mainnet' : 'testnet');
    NetworkConfig.currentNetwork = network;
    // Purge caches populated from the previous network before anything re-reads
    // balances or pools, so the two chains' data can never be mixed.
    XerisApiService.clearNetworkCaches();
    DexService.clearCache();
    state = network;
  }
}

final networkProvider = NotifierProvider<NetworkNotifier, XerisNetwork>(() {
  return NetworkNotifier();
});
