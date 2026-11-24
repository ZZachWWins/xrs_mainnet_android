enum XerisNetwork { mainnet, testnet }

class NetworkConfig {
  static const _buildNetwork = String.fromEnvironment(
    'XERIS_NETWORK',
    defaultValue: 'mainnet',
  );
  static XerisNetwork get defaultNetwork =>
      _buildNetwork == 'mainnet' ? XerisNetwork.mainnet : XerisNetwork.testnet;
  static XerisNetwork currentNetwork = defaultNetwork;

  static const testnetRpcUrl = String.fromEnvironment(
    'XERIS_TESTNET_RPC_URL',
    defaultValue: 'http://138.197.116.81:50008',
  );
  static const testnetControlUrl = String.fromEnvironment(
    'XERIS_TESTNET_CONTROL_URL',
    defaultValue: 'http://138.197.116.81:56001',
  );
  static const testnetWsUrl = String.fromEnvironment(
    'XERIS_TESTNET_WS_URL',
    defaultValue: 'ws://138.197.116.81:50009',
  );

  // Never silently point a mainnet-labelled build at the testnet host.
  static const mainnetRpcUrl = String.fromEnvironment(
    'XERIS_MAINNET_RPC_URL',
    defaultValue: 'https://mainnetrpc.xerisweb.com',
  );
  static const mainnetControlUrl = String.fromEnvironment(
    'XERIS_MAINNET_CONTROL_URL',
    defaultValue: 'https://mainnetrpc.xerisweb.com',
  );
  static const mainnetWsUrl = String.fromEnvironment('XERIS_MAINNET_WS_URL');
  static const explorerUrl = String.fromEnvironment(
    'XERIS_EXPLORER_URL',
    defaultValue: 'https://mainnetrpc.xerisweb.com',
  );
  static bool get mainnetConfigured =>
      _validHttpUrl(mainnetRpcUrl) && _validHttpUrl(mainnetControlUrl);

  static bool _validHttpUrl(String value) {
    final uri = Uri.tryParse(value);
    return uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty &&
        uri.userInfo.isEmpty &&
        !uri.hasQuery &&
        !uri.hasFragment;
  }

  static void validate([XerisNetwork? network]) {
    if ((network ?? currentNetwork) == XerisNetwork.mainnet &&
        !mainnetConfigured) {
      throw StateError(
        'Mainnet is not configured. Supply XERIS_MAINNET_RPC_URL '
        'and XERIS_MAINNET_CONTROL_URL with --dart-define.',
      );
    }
  }

  static String _base(String url) => url.replaceFirst(RegExp(r'/+$'), '');
  static String get rpcUrl {
    validate();
    return _base(
      currentNetwork == XerisNetwork.mainnet ? mainnetRpcUrl : testnetRpcUrl,
    );
  }

  static String get controlUrl {
    validate();
    return _base(
      currentNetwork == XerisNetwork.mainnet
          ? mainnetControlUrl
          : testnetControlUrl,
    );
  }

  static String get jsonRpcUrl => rpcUrl;
  // Standard wallet requests use HTTP; the supplied node has no WebSocket API.
  static String get wsUrl =>
      currentNetwork == XerisNetwork.mainnet ? mainnetWsUrl : testnetWsUrl;
  static String get cacheKey => '${currentNetwork.name}|$rpcUrl|$controlUrl';

  // Consensus domains from the supplied node, not Solana genesis hashes.
  static String get chainId => currentNetwork == XerisNetwork.mainnet
      ? 'xeris-mainnet-v4'
      : 'xeris-testnet-v2';
  static const caipChainId = String.fromEnvironment('XERIS_CAIP_CHAIN_ID');
  static const int tokenDecimals = 9;
}
