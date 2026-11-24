// ignore_for_file: avoid_print
import 'package:flutter_test/flutter_test.dart';
import 'package:xeris_wallet/core/services/dex_service.dart';

void main() {
  test('Fetch DEX pools and quotes', () async {
    final pools = await DexService.getPools(forceRefresh: true);
    print('Pools count: ${pools?.length}');
    expect(pools, isNotEmpty);
    
    final poolId = pools![0].poolId;
    print('Testing Pool: $poolId');
    
    final poolInfo = await DexService.getPoolInfo(poolId);
    print('Pool Info: ${poolInfo?.tokenA} / ${poolInfo?.tokenB}');
    expect(poolInfo, isNotNull);
    expect(poolInfo!.tokenA, isNotEmpty);
    
    final quote = await DexService.getSwapQuote(
      poolId: poolId,
      inputTokenId: poolInfo.tokenA,
      amount: 1000000000, // 1 XRS
    );
    print('Quote: $quote');
    expect(quote, isNotNull);
    expect(quote['success'], isTrue);
  });
}
