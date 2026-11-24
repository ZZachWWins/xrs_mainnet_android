import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:xeris_wallet/core/config/network_config.dart';
import 'package:xeris_wallet/core/services/base_api_service.dart';
import 'package:xeris_wallet/core/services/instruction_builder.dart';
import 'package:xeris_wallet/core/services/liquidity_quote_service.dart';
import 'package:xeris_wallet/features/wallet_actions/services/liquidity_service.dart';

LiquidityPoolState pool({
  int reserveA = 1000000,
  int reserveB = 2000000,
  int shares = 1000,
}) => LiquidityPoolState(
      poolId: 'pool',
      tokenA: 'token_a',
      tokenB: 'token_b',
      reserveA: BigInt.from(reserveA),
      reserveB: BigInt.from(reserveB),
      totalShares: BigInt.from(shares),
      ownerShares: {'owner': BigInt.from(250)},
    );

Map<String, dynamic> contractState({int reserveA = 10000, int reserveB = 20000}) => {
      'success': true,
      'contract': {
        'contract_id': 'pool',
        'is_active': true,
        'state': {
          'Swap': {
            'token_a': 'token_a',
            'token_b': 'token_b',
            'reserve_a': reserveA,
            'reserve_b': reserveB,
            'total_shares': 10000,
            'lp_shares': {'owner': 10000},
          },
        },
      },
    };

({String poolId, String method, String json}) decodeCall(Uint8List bytes) {
  final data = ByteData.sublistView(bytes);
  expect(data.getUint32(0, Endian.little), 4);
  var offset = 4;
  String nextString() {
    final length = data.getUint64(offset, Endian.little);
    offset += 8;
    final text = utf8.decode(bytes.sublist(offset, offset + length));
    offset += length;
    return text;
  }
  final poolId = nextString();
  final method = nextString();
  final json = nextString();
  expect(offset, bytes.length);
  return (poolId: poolId, method: method, json: json);
}

void main() {
  late XerisNetwork originalNetwork;
  setUp(() {
    originalNetwork = NetworkConfig.currentNetwork;
    NetworkConfig.currentNetwork = XerisNetwork.testnet;
  });
  tearDown(() {
    BaseApiService.clientOverride = null;
    NetworkConfig.currentNetwork = originalNetwork;
  });

  test('deposit matches proportional floor shares and ceiling token arithmetic', () {
    final quote = LiquidityQuoteService.quoteAdd(
      pool: pool(reserveA: 3, reserveB: 10, shares: 7),
      amountA: BigInt.from(2),
      amountB: BigInt.from(6),
    );
    expect(quote.shares, BigInt.from(4));
    expect(quote.acceptedA, BigInt.from(2));
    expect(quote.acceptedB, BigInt.from(6));
    expect(quote.minLpShares, BigInt.from(3));
    expect(quote.minAmountA, BigInt.one);
    expect(quote.minAmountB, BigInt.from(5));
  });

  test('unbalanced maxima sign minima for accepted proportional amounts', () {
    final quote = LiquidityQuoteService.quoteAdd(
      pool: pool(reserveA: 300, reserveB: 1000, shares: 1000),
      amountA: BigInt.from(30),
      amountB: BigInt.from(200),
    );
    expect(quote.shares, BigInt.from(100));
    expect(quote.acceptedA, BigInt.from(30));
    expect(quote.acceptedB, BigInt.from(100));
    final call = decodeCall(quote.toInstruction());
    expect(call.poolId, 'pool');
    expect(call.method, 'add_liquidity');
    expect(jsonDecode(call.json), {
      'amount_a': 30,
      'amount_b': 200,
      'min_lp_shares': 99,
      'min_amount_a': 29,
      'min_amount_b': 99,
    });
  });

  test('first deposit uses integer square root, never floating point sqrt', () {
    final quote = LiquidityQuoteService.quoteAdd(
      pool: pool(reserveA: 0, reserveB: 0, shares: 0),
      amountA: BigInt.from(1000),
      amountB: BigInt.from(9999),
    );
    expect(quote.shares, BigInt.from(3162));
    expect(quote.minLpShares, BigInt.from(3146));
    expect(quote.acceptedB, BigInt.from(9999));
  });

  test('reserves above 53 bits retain exact integer quote arithmetic', () {
    final reserve = BigInt.parse('9007199254740993');
    final quote = LiquidityQuoteService.quoteAdd(
      pool: LiquidityPoolState(
        poolId: 'pool', tokenA: 'a', tokenB: 'b',
        reserveA: reserve, reserveB: reserve * BigInt.from(3),
        totalShares: reserve,
      ),
      amountA: BigInt.from(1000),
      amountB: BigInt.from(3000),
    );
    expect(quote.shares, BigInt.from(1000));
    expect(quote.acceptedA, BigInt.from(1000));
    expect(quote.acceptedB, BigInt.from(3000));
    expect(quote.minAmountB, BigInt.from(2985));
  });

  test('LP instruction preserves full u64 decimal JSON numbers', () {
    final large = BigInt.parse('18446744073709551615');
    final call = decodeCall(InstructionBuilder.buildAddLiquidityInstruction(
      poolId: 'pool', amountA: large, amountB: BigInt.from(100),
      minLpShares: BigInt.from(10), minAmountA: large - BigInt.one,
      minAmountB: BigInt.from(99),
    ));
    expect(call.json, contains('"amount_a":18446744073709551615'));
    expect(call.json, contains('"min_amount_a":18446744073709551614'));
    expect(call.json, isNot(contains('"18446744073709551615"')));
  });

  test('displayed token amounts respect actual decimals without rounding', () {
    expect(LiquidityQuoteService.parseDisplayAmount('1,23456789', 8), BigInt.from(123456789));
    expect(LiquidityQuoteService.parseDisplayAmount('1.230000', 2), BigInt.from(123));
    expect(LiquidityQuoteService.parseDisplayAmount('90071992.54740993', 8), BigInt.parse('9007199254740993'));
    for (final amount in ['0', '-1', '1e4', 'NaN', '1.001']) {
      expect(() => LiquidityQuoteService.parseDisplayAmount(amount, 2), throwsFormatException);
    }
  });

  test('remove quote includes signed floors and verifies LP ownership', () {
    final quote = LiquidityQuoteService.quoteRemove(
      pool: pool(), walletAddress: 'owner', shares: BigInt.from(100),
    );
    expect(quote.amountA, BigInt.from(100000));
    expect(quote.amountB, BigInt.from(200000));
    final call = decodeCall(quote.toInstruction());
    expect(call.method, 'remove_liquidity');
    expect(jsonDecode(call.json), {
      'shares': 100, 'min_amount_a': 99500, 'min_amount_b': 199000,
    });
    expect(() => LiquidityQuoteService.quoteRemove(
      pool: pool(), walletAddress: 'other-owner', shares: BigInt.one,
    ), throwsFormatException);
    expect(() => LiquidityQuoteService.quoteRemove(
      pool: pool(), walletAddress: 'owner', shares: BigInt.from(251),
    ), throwsFormatException);
  });

  test('dust, missing reserves, zero minima and overflow fail closed', () {
    expect(() => LiquidityQuoteService.quoteAdd(
      pool: pool(reserveA: 0), amountA: BigInt.from(10), amountB: BigInt.from(10),
    ), throwsFormatException);
    expect(() => LiquidityQuoteService.quoteAdd(
      pool: pool(reserveA: 0, reserveB: 0, shares: 0),
      amountA: BigInt.one, amountB: BigInt.one,
    ), throwsFormatException);
    expect(() => LiquidityQuoteService.quoteAdd(
      pool: pool(), amountA: BigInt.from(1000), amountB: BigInt.from(2000),
      slippageBps: 10000,
    ), throwsFormatException);
    expect(() => LiquidityQuoteService.quoteRemove(
      pool: pool(reserveA: 1, reserveB: 1), walletAddress: 'owner', shares: BigInt.one,
    ), throwsFormatException);
    expect(() => InstructionBuilder.buildRemoveLiquidityInstruction(
      poolId: 'pool', shares: BigInt.one, minAmountA: BigInt.zero, minAmountB: BigInt.one,
    ), throwsArgumentError);
    final maximum = (BigInt.one << 64) - BigInt.one;
    expect(() => LiquidityQuoteService.quoteAdd(
      pool: LiquidityPoolState(poolId: 'pool', tokenA: 'a', tokenB: 'b',
        reserveA: maximum, reserveB: maximum, totalShares: maximum),
      amountA: BigInt.from(1000), amountB: BigInt.from(1000),
    ), throwsFormatException);
  });

  test('individual metadata resolves nonstandard token decimals', () async {
    BaseApiService.clientOverride = MockClient((request) async {
      expect(request.url.toString(), '${NetworkConfig.controlUrl}/token/balance/owner/token_a');
      return http.Response(jsonEncode({
        'token_info': {'token_id': 'token_a', 'decimals': 12}, 'balance': 0,
      }), 200);
    });
    expect(await LiquidityQuoteService.fetchTokenDecimals('owner', 'token_a'), 12);
  });

  test('missing token metadata cannot silently assume six or nine decimals', () async {
    BaseApiService.clientOverride = MockClient((_) async =>
        http.Response(jsonEncode({'token_info': null, 'balance': 0}), 200));
    await expectLater(
      LiquidityQuoteService.fetchTokenDecimals('owner', 'token_a'),
      throwsFormatException,
    );
  });

  test('each instruction requotes fresh pool state instead of cached prices', () async {
    var calls = 0;
    BaseApiService.clientOverride = MockClient((request) async {
      expect(request.url.toString(), '${NetworkConfig.controlUrl}/contract/pool');
      calls++;
      return http.Response(jsonEncode(contractState(
        reserveA: calls * 10000, reserveB: calls * 20000,
      )), 200);
    });
    final first = decodeCall(await LiquidityQuoteService.buildAddInstruction(
      poolId: 'pool', amountA: 1000, amountB: 2000,
    ));
    final second = decodeCall(await LiquidityQuoteService.buildAddInstruction(
      poolId: 'pool', amountA: 1000, amountB: 2000,
    ));
    expect(jsonDecode(first.json)['min_lp_shares'], 995);
    expect(jsonDecode(second.json)['min_lp_shares'], 497);
    expect(calls, 2);
  });

  test('network switch during quote lookup prevents instruction creation', () async {
    BaseApiService.clientOverride = MockClient((_) async {
      NetworkConfig.currentNetwork = XerisNetwork.mainnet;
      return http.Response(jsonEncode(contractState()), 200);
    });
    await expectLater(LiquidityQuoteService.buildAddInstruction(
      poolId: 'pool', amountA: 1000, amountB: 2000,
    ), throwsStateError);
  });

  test('deposit opened on another network fails before lookup or key access', () async {
    var requests = 0;
    BaseApiService.clientOverride = MockClient((_) async {
      requests++;
      throw StateError('No lookup is allowed after the form network changed');
    });
    await expectLater(LiquidityService().addLiquidity(
      mnemonic: 'pk:not-valid-base58-!', walletAddress: 'owner', poolId: 'pool',
      amountA: '1', amountB: '2',
      expectedNetworkScope: 'an-old-network-scope',
      expectedTokenA: 'token_a', expectedTokenB: 'token_b',
    ), throwsA(isA<StateError>().having(
      (error) => error.message, 'message', contains('network changed'),
    )));
    expect(requests, 0);
  });

  test('reused pool id with a different token pair fails before key access or signing', () async {
    var requests = 0;
    BaseApiService.clientOverride = MockClient((request) async {
      requests++;
      expect(request.method, 'GET');
      expect(request.url.toString(), '${NetworkConfig.controlUrl}/contract/pool');
      final changed = contractState();
      (changed['contract'] as Map)['state']['Swap']['token_a'] = 'different_token';
      return http.Response(jsonEncode(changed), 200);
    });
    await expectLater(LiquidityService().addLiquidity(
      mnemonic: 'pk:not-valid-base58-!', walletAddress: 'owner', poolId: 'pool',
      amountA: '1', amountB: '2', expectedNetworkScope: NetworkConfig.cacheKey,
      expectedTokenA: 'token_a', expectedTokenB: 'token_b',
    ), throwsA(isA<StateError>().having(
      (error) => error.message, 'message', contains('token pair changed'),
    )));
    expect(requests, 1);
  });

  test('incomplete or lossy pool state cannot produce an instruction', () async {
    final bad = contractState();
    (bad['contract'] as Map)['state']['Swap']['reserve_a'] = 9007199254740992.0;
    BaseApiService.clientOverride = MockClient((_) async =>
        http.Response(jsonEncode(bad), 200));
    await expectLater(LiquidityQuoteService.buildAddInstruction(
      poolId: 'pool', amountA: 1000, amountB: 2000,
    ), throwsFormatException);
  });
}
