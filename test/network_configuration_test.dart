import 'package:flutter_test/flutter_test.dart';
import 'package:xeris_wallet/core/config/network_config.dart';

void main() {
  late XerisNetwork original;
  setUp(() => original = NetworkConfig.currentNetwork);
  tearDown(() => NetworkConfig.currentNetwork = original);

  test('testnet selects its own endpoints and consensus domain', () {
    NetworkConfig.currentNetwork = XerisNetwork.testnet;
    expect(
      NetworkConfig.rpcUrl,
      NetworkConfig.testnetRpcUrl.replaceFirst(RegExp(r'/+$'), ''),
    );
    expect(
      NetworkConfig.controlUrl,
      NetworkConfig.testnetControlUrl.replaceFirst(RegExp(r'/+$'), ''),
    );
    expect(NetworkConfig.chainId, 'xeris-testnet-v2');
  });

  test(
    'mainnet either uses explicit endpoints or fails before any request',
    () {
      NetworkConfig.currentNetwork = XerisNetwork.mainnet;
      expect(NetworkConfig.chainId, 'xeris-mainnet-v4');
      if (NetworkConfig.mainnetConfigured) {
        expect(
          NetworkConfig.rpcUrl,
          NetworkConfig.mainnetRpcUrl.replaceFirst(RegExp(r'/+$'), ''),
        );
        expect(
          NetworkConfig.controlUrl,
          NetworkConfig.mainnetControlUrl.replaceFirst(RegExp(r'/+$'), ''),
        );
        expect(NetworkConfig.cacheKey, startsWith('mainnet|'));
      } else {
        expect(() => NetworkConfig.rpcUrl, throwsStateError);
        expect(() => NetworkConfig.controlUrl, throwsStateError);
      }
    },
  );

  test('default network follows the build configuration', () {
    const selected = String.fromEnvironment(
      'XERIS_NETWORK',
      defaultValue: 'mainnet',
    );
    expect(
      NetworkConfig.defaultNetwork,
      selected == 'mainnet' ? XerisNetwork.mainnet : XerisNetwork.testnet,
    );
    expect(NetworkConfig.caipChainId, isNot(contains('CustomGenesisHash')));
  });
}
