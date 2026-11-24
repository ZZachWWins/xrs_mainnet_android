import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:bs58/bs58.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:xeris_wallet/core/config/network_config.dart';
import 'package:xeris_wallet/core/models/asset_model.dart';
import 'package:xeris_wallet/core/services/base_api_service.dart';
import 'package:xeris_wallet/core/services/dex_service.dart';
import 'package:xeris_wallet/core/services/transaction_confirmation_service.dart';
import 'package:xeris_wallet/core/services/wallet_service.dart';
import 'package:xeris_wallet/core/services/xeris_api_service.dart';
import 'package:xeris_wallet/features/wallet_actions/services/swap_service.dart';

class FakeClock {
  Duration value = Duration.zero;
  Duration elapsed() => value;
  Future<void> delay(Duration duration) async {
    value += duration;
  }
}

Map<String, dynamic> receipt({
  String signature = 'submitted-id',
  dynamic error,
  dynamic outcomes = const [
    {'index': 0, 'ok': true},
  ],
}) => {
  'slot': 42,
  'transaction': {
    'signatures': [signature],
  },
  'meta': {'err': error, 'instructionOutcomes': outcomes},
};

void main() {
  group('bounded receipt polling', () {
    late FakeClock clock;
    late String scope;
    late String endpoint;
    setUp(() {
      clock = FakeClock();
      scope = 'original-scope';
      endpoint = 'https://original.invalid';
    });
    Future<TransactionConfirmationResult> poll(
      TransactionReceiptLookup lookup,
    ) => TransactionConfirmationService.waitForReceipt(
      signature: 'submitted-id',
      expectedNetworkScope: 'original-scope',
      timeout: const Duration(seconds: 6),
      pollInterval: const Duration(seconds: 2),
      lookup: lookup,
      elapsed: clock.elapsed,
      delay: clock.delay,
      networkScope: () => scope,
      rpcEndpoint: () => endpoint,
    );

    test('null and queued acknowledgments cannot confirm execution', () async {
      var calls = 0;
      final result = await poll((signature, captured, _) async {
        expect(signature, 'submitted-id');
        expect(captured, 'https://original.invalid');
        calls++;
        return calls == 1 ? null : {'status': 'queued', 'signature': signature};
      });
      expect(calls, 3);
      expect(result.isPending, isTrue);
      expect(result.signature, 'submitted-id');
      expect(result.detail, contains('timed out'));
    });

    test(
      'unknown execution outcome waits until every instruction committed',
      () async {
        var calls = 0;
        final result = await poll((_, __, ___) async {
          calls++;
          return calls == 1
              ? receipt(error: 'OutcomeUnknown', outcomes: null)
              : {'jsonrpc': '2.0', 'id': 1, 'result': receipt()};
        });
        expect(calls, 2);
        expect(result.isConfirmed, isTrue);
        expect(result.slot, 42);
      },
    );

    test(
      'explicit mixed execution failure stops without waiting or retrying',
      () async {
        var calls = 0;
        final result = await poll((_, __, ___) async {
          calls++;
          return receipt(
            error: {
              'InstructionError': [1, 'ExecutionFailed'],
            },
            outcomes: [
              {'index': 0, 'ok': true},
              {'index': 1, 'ok': false},
            ],
          );
        });
        expect(calls, 1);
        expect(result.isFailed, isTrue);
        expect(result.signature, 'submitted-id');
        expect(result.detail, contains('may have committed'));
      },
    );

    test(
      'missing or contradictory successful outcomes remain pending',
      () async {
        for (final outcomes in [
          null,
          [],
          [
            {'index': 0, 'ok': false},
          ],
        ]) {
          clock = FakeClock();
          final result = await poll(
            (_, __, ___) async => receipt(outcomes: outcomes),
          );
          expect(result.isPending, isTrue);
        }
      },
    );

    test(
      'receipt for another signature cannot confirm this submission',
      () async {
        final result = await poll(
          (_, __, ___) async => receipt(signature: 'another-id'),
        );
        expect(result.isPending, isTrue);
        expect(result.signature, 'submitted-id');
      },
    );

    test('network mismatch prevents any receipt request', () async {
      scope = 'different-scope';
      var calls = 0;
      final result = await poll((_, __, ___) async {
        calls++;
        return receipt();
      });
      expect(calls, 0);
      expect(result.isPending, isTrue);
      expect(result.signature, 'submitted-id');
    });

    test(
      'endpoint switch during a request rejects even a successful receipt',
      () async {
        var calls = 0;
        final result = await poll((_, captured, ___) async {
          calls++;
          expect(captured, 'https://original.invalid');
          endpoint = 'https://different.invalid';
          return receipt();
        });
        expect(calls, 1);
        expect(result.isPending, isTrue);
        expect(result.detail, contains('original endpoint'));
      },
    );

    test('network lookup errors preserve the ID and remain pending', () async {
      var calls = 0;
      final result = await poll((_, __, ___) async {
        calls++;
        throw TimeoutException('synthetic receipt read timeout');
      });
      expect(calls, 3);
      expect(result.isPending, isTrue);
      expect(result.signature, 'submitted-id');
    });
  });

  group('swap dependent actions', () {
    late XerisNetwork previousNetwork;
    setUp(() {
      previousNetwork = NetworkConfig.currentNetwork;
      NetworkConfig.currentNetwork = XerisNetwork.testnet;
      DexService.clearCache();
      XerisApiService.clearBalanceCache();
    });
    tearDown(() {
      BaseApiService.clientOverride = null;
      NetworkConfig.currentNetwork = previousNetwork;
      DexService.clearCache();
      XerisApiService.clearBalanceCache();
      WalletService.clearKeyPairCache();
    });

    const xrs = AssetModel(
      id: 'xrs',
      symbol: 'XRS',
      name: 'XRS',
      balance: 0,
      price: 0,
      changePercentage24h: 0,
      decimals: 9,
    );
    const xusdc = AssetModel(
      id: 'xeris_usdc',
      symbol: 'xUSDC',
      name: 'xUSDC',
      balance: 0,
      price: 0,
      changePercentage24h: 0,
      decimals: 6,
    );

    Future<void> checkStopped({
      required bool wrapsFirst,
      required TransactionConfirmationStatus status,
    }) async {
      // Public synthetic fixture only. Every HTTP request is intercepted below;
      // no real key file, network endpoint or funded transaction is used.
      final storedFixture =
          'pk:${base58.encode(Uint8List.fromList(List.filled(32, 7)))}';
      final fixtureKey = await WalletService.getKeyPair(storedFixture);
      var submissions = 0;
      var receiptReads = 0;
      String? observedSignature;
      http.Response json(Object value) => http.Response(
        jsonEncode(value),
        200,
        headers: {'content-type': 'application/json'},
      );
      BaseApiService.clientOverride = MockClient((request) async {
        if (request.method == 'GET' && request.url.path == '/v2/pools') {
          return json({
            'success': true,
            'count': 1,
            'next_after': null,
            'pools': [
              {
                'pool_id': 'pool',
                'token_a': 'xrs_native',
                'token_b': 'xeris_usdc',
                'price_a_in_b': '0.001',
                'price_b_in_a': '1000',
                'reserve_a': 100000000000,
                'reserve_b': 100000000,
                'fee_bps': 30,
                'total_shares': 1000000,
              },
            ],
          });
        }
        if (request.method == 'GET' &&
            request.url.path == '/contract/pool/quote') {
          final input = request.url.queryParameters['input_token'];
          return json({
            'success': true,
            'quote': {
              'input_token': input,
              'input_amount': int.parse(request.url.queryParameters['amount']!),
              'output_token': input == 'xrs_native'
                  ? 'xeris_usdc'
                  : 'xrs_native',
              'output_amount': input == 'xrs_native' ? 1000000 : 1000000000,
              'fee': 0,
              'fee_bps': 30,
              'price_impact_pct': '0',
              'effective_price': 1,
            },
          });
        }
        if (request.method == 'GET' &&
            request.url.path.startsWith('/token/accounts/')) {
          return json({
            'success': true,
            'native_xrs': 10000000000,
            'token_accounts': [],
          });
        }
        if (request.method == 'POST' && request.url.path == '/submit') {
          submissions++;
          // Deliberately ambiguous ACK: root API must preserve its locally
          // computed signature; the service must poll it, never send again.
          return json({'status': 'queued'});
        }
        if (request.method == 'POST') {
          final payload = jsonDecode(request.body);
          if (payload['method'] == 'getLatestBlockhash') {
            return json({
              'jsonrpc': '2.0',
              'id': payload['id'],
              'result': {
                'context': {'slot': 1},
                'value': {
                  'blockhash': base58.encode(
                    Uint8List.fromList(List.filled(32, 1)),
                  ),
                  'lastValidBlockHeight': 151,
                },
              },
            });
          }
        }
        throw StateError(
          'Unexpected mocked request: ${request.method} ${request.url.path}',
        );
      });
      final service = SwapService(
        waitForReceipt:
            ({required signature, required expectedNetworkScope}) async {
              receiptReads++;
              observedSignature = signature;
              expect(expectedNetworkScope, NetworkConfig.cacheKey);
              return TransactionConfirmationResult(
                signature: signature,
                status: status,
                detail: 'Synthetic receipt result',
              );
            },
      );
      await expectLater(
        service.executeSwap(
          walletAddress: fixtureKey.address,
          mnemonic: storedFixture,
          fromAsset: wrapsFirst ? xrs : xusdc,
          toAsset: wrapsFirst ? xusdc : xrs,
          amount: 1,
        ),
        throwsA(
          isA<TransactionConfirmationException>().having(
            (error) => error.signature,
            'submitted signature',
            isNotEmpty,
          ),
        ),
      );
      expect(
        submissions,
        1,
        reason: 'No resubmission, second hop or unwrap is allowed.',
      );
      expect(receiptReads, 1);
      expect(observedSignature, isNotEmpty);
    }

    test('pending wrap never submits the dependent swap', () async {
      await checkStopped(
        wrapsFirst: true,
        status: TransactionConfirmationStatus.pending,
      );
    });
    test('failed swap never submits an unwrap', () async {
      await checkStopped(
        wrapsFirst: false,
        status: TransactionConfirmationStatus.confirmedFailure,
      );
    });
    test('pending swap never submits an unwrap', () async {
      await checkStopped(
        wrapsFirst: false,
        status: TransactionConfirmationStatus.pending,
      );
    });
  });
}
