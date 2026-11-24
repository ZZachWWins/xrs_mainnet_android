import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:xeris_wallet/core/config/network_config.dart';
import 'package:xeris_wallet/core/services/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  test(
    'mainnet build chooses mainnet despite a saved testnet preference',
    () async {
      FlutterSecureStorage.setMockInitialValues({'current_network': 'testnet'});
      final selected = await StorageService.getNetwork();
      expect(
        selected,
        NetworkConfig.defaultNetwork == XerisNetwork.mainnet
            ? 'mainnet'
            : 'testnet',
      );
    },
  );

  test('new installation follows mainnet build defaults', () async {
    expect(
      await StorageService.getNetwork(),
      NetworkConfig.defaultNetwork.name,
    );
    expect(NetworkConfig.mainnetRpcUrl, startsWith('https://'));
    expect(NetworkConfig.mainnetControlUrl, startsWith('https://'));
  });

  test('new browser defaults open the mainnet DEX', () async {
    final bookmarks = await StorageService.getBookmarks();
    expect(
      bookmarks.any((b) => b.isDefault && b.url == 'https://dex.xerisweb.com'),
      isTrue,
    );
    expect(
      bookmarks.any((b) => b.url == 'https://xeris-dex.vercel.app'),
      isFalse,
    );
  });

  test(
    'built-in old DEX bookmark migrates while custom bookmarks stay intact',
    () async {
      FlutterSecureStorage.setMockInitialValues({
        'browser_bookmarks': jsonEncode([
          {
            'title': 'Xeris DEX',
            'url': 'https://xeris-dex.vercel.app',
            'isDefault': true,
          },
          {
            'title': 'My saved site',
            'url': 'https://xeris-dex.vercel.app',
            'isDefault': false,
          },
        ]),
      });
      final bookmarks = await StorageService.getBookmarks();
      expect(bookmarks[0].url, 'https://dex.xerisweb.com');
      expect(bookmarks[1].url, 'https://xeris-dex.vercel.app');
    },
  );
}
