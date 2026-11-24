// ignore_for_file: avoid_print
import 'package:flutter_test/flutter_test.dart';
import 'package:xeris_wallet/core/services/xeris_api_service.dart';

void main() {
  test('Fetch consolidated balance and tokens', () async {
    const address = 'Au9sPpdrgBnsRVgpF5GxDc4H6fACvKgH6rtTMUfrFS8w';
    
    print('Testing balance for: $address');
    
    final balance = await XerisApiService.getBalance(address);
    print('Native Balance: $balance XRS');
    expect(balance, isNonZero);
    
    final tokenBalances = await XerisApiService.getAllTokenBalances(address);
    print('Token Balances count: ${tokenBalances.length}');
    
    for (var tb in tokenBalances) {
      print('Token: ${tb.tokenId}, Symbol: ${tb.balanceXrs}');
    }
    
    expect(tokenBalances, isNotEmpty);
    final hasUsdc = tokenBalances.any((t) => t.tokenId == 'xeris_usdc');
    print('Has xeris_usdc: $hasUsdc');
    expect(hasUsdc, isTrue);
  });
}
