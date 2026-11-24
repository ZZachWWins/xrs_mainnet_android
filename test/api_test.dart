// ignore_for_file: avoid_print
import 'package:flutter_test/flutter_test.dart';
import 'package:xeris_wallet/core/services/xeris_api_service.dart';
import 'package:xeris_wallet/core/services/dex_service.dart';

void main() {
  test('Test API Services', () async {
    final pools = await DexService.getPools();
    print('Pools count: ${pools?.length}');
    
    final tokens = await XerisApiService.getTokens();
    print('Tokens count: ${tokens?.length}');
    if (tokens != null && tokens.isNotEmpty) {
      print('First Token: ${tokens.first.id}');
    }
  });
}
