import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:xeris_wallet/core/config/network_config.dart';
import 'package:xeris_wallet/core/services/base_api_service.dart';
import 'package:xeris_wallet/core/services/pool_deployment_service.dart';
import 'package:xeris_wallet/core/services/transaction_confirmation_service.dart';
import 'package:xeris_wallet/core/services/xeris_api_service.dart';

const owner = '11111111111111111111111111111111';
const otherOwner = '22222222222222222222222222222222';
const signature = 'existing-transaction-signature';

PoolDeploymentRequest request({
  String id = 'xrs-xusdc-mainnet-v1',
  String tokenA = 'xrs_native',
  String tokenB = 'xeris_usdc',
  String amountA = '1',
  String amountB = '2',
  int fee = 30,
  String scope = 'reviewed-network',
}) => PoolDeploymentRequest(
  poolId: id,
  walletAddress: owner,
  expectedNetworkScope: scope,
  tokenA: tokenA,
  tokenB: tokenB,
  amountA: amountA,
  amountB: amountB,
  feeBps: fee,
);

Map<String, dynamic> contract({String wallet = owner, int fee = 30}) => {
  'contract_id': 'xrs-xusdc-mainnet-v1',
  'owner': wallet,
  'is_active': true,
  'state': {
    'Swap': {
      'token_a': 'xrs_native',
      'token_b': 'xeris_usdc',
      'fee_bps': fee,
      'reserve_a': 1000000000,
      'reserve_b': 2000000,
      'total_shares': 44721359,
      'lp_shares': {
        owner: 44720359,
        'BURNED_LIQUIDITY_000000000000000000000': 1000,
      },
    },
  },
};

Future<int> decimals(String _, String token) async =>
    token == 'xrs_native' ? 9 : 6;

TransactionConfirmationResult receipt(TransactionConfirmationStatus status) =>
    TransactionConfirmationResult(signature: signature, status: status);

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

  test(
    'native contract absence and fresh registry decimals produce exact 9/6 amounts',
    () async {
      BaseApiService.clientOverride = MockClient((http.Request call) async {
        if (call.url.path.startsWith('/contract/')) {
          return http.Response(
            '{"success":false,"error":"Contract not found"}',
            200,
          );
        }
        final token = call.url.pathSegments.last;
        return http.Response(
          jsonEncode({
            'token_info': {
              'token_id': token,
              'decimals': token == 'xrs_native' ? 9 : 6,
            },
          }),
          200,
        );
      });
      final plan = await PoolDeploymentService().prepare(
        request(
          scope: NetworkConfig.cacheKey,
          amountA: '1.000000001',
          amountB: '2.000001',
        ),
      );
      expect(plan.rawAmountA, BigInt.from(1000000001));
      expect(plan.rawAmountB, BigInt.from(2000001));
      expect(jsonDecode(plan.paramsJson), {
        'token_a': 'xrs_native',
        'token_b': 'xeris_usdc',
        'amount_a': 1000000001,
        'amount_b': 2000001,
        'fee_bps': 30,
      });
      expect(plan.request.poolId, 'xrs-xusdc-mainnet-v1');
      expect(plan.ownerShares, plan.initialShares - BigInt.from(1000));
    },
  );

  test(
    'u64 initial amounts remain exact numeric JSON without double conversion',
    () async {
      final service = PoolDeploymentService(
        readContract: (_) async => null,
        readDecimals: (_, __) async => 0,
        currentNetworkScope: () => 'reviewed-network',
      );
      final plan = await service.prepare(
        request(amountA: '18446744073709551615', amountB: '1000000'),
      );
      expect(plan.paramsJson, contains('"amount_a":18446744073709551615'));
      expect(plan.paramsJson, isNot(contains('"18446744073709551615"')));
    },
  );

  test('proxy 404 does not establish that a contract ID is unused', () async {
    BaseApiService.clientOverride = MockClient(
      (_) async => http.Response('not allowed', 404),
    );
    await expectLater(
      PoolDeploymentService().prepare(request(scope: NetworkConfig.cacheKey)),
      throwsA(isA<ApiException>()),
    );
  });

  test(
    'unsafe IDs, pair, fee, precision, zero amounts and locked-share boundary stop before signing',
    () async {
      var signed = 0;
      final service = PoolDeploymentService(
        readContract: (_) async => null,
        readDecimals: decimals,
        currentNetworkScope: () => 'reviewed-network',
      );
      for (final invalid in [
        request(id: '../pool'),
        request(id: ''),
        request(id: 'a' * 129),
        request(tokenB: 'xrs_native'),
        request(tokenA: 'xrs'),
        request(fee: -1),
        request(id: 'xeris_reserved'),
        request(id: 'identity_reserved'),
        request(id: 'agent_registry_reserved'),
        request(id: '__reserved'),
        request(id: 'token_xrs_pool'),
        request(fee: 10000),
        request(amountB: '1.0000001'),
        request(amountA: '0'),
        request(amountA: '0.000001', amountB: '0.001'),
        request(amountA: '18446744073709551616'),
      ]) {
        await expectLater(
          service.deploy(
            request: invalid,
            signerAddress: () async {
              signed++;
              return owner;
            },
            submit: (_) async => signature,
          ),
          throwsFormatException,
        );
      }
      expect(signed, 0);
    },
  );

  test('existing ID and changed network cannot reach signing', () async {
    var signed = 0;
    final used = PoolDeploymentService(
      readContract: (_) async => contract(),
      readDecimals: decimals,
      currentNetworkScope: () => 'reviewed-network',
    );
    await expectLater(
      used.deploy(
        request: request(),
        signerAddress: () async {
          signed++;
          return owner;
        },
        submit: (_) async => signature,
      ),
      throwsStateError,
    );
    var scope = 'reviewed-network';
    final switched = PoolDeploymentService(
      readContract: (_) async => null,
      readDecimals: (_, __) async {
        scope = 'other-network';
        return 9;
      },
      currentNetworkScope: () => scope,
    );
    await expectLater(
      switched.deploy(
        request: request(),
        signerAddress: () async {
          signed++;
          return owner;
        },
        submit: (_) async => signature,
      ),
      throwsStateError,
    );
    expect(signed, 0);
  });

  test('a signer different from reviewed LP owner cannot submit', () async {
    var submitted = 0;
    final service = PoolDeploymentService(
      readContract: (_) async => null,
      readDecimals: decimals,
      currentNetworkScope: () => 'reviewed-network',
    );
    await expectLater(
      service.deploy(
        request: request(),
        signerAddress: () async => otherOwner,
        submit: (_) async {
          submitted++;
          return signature;
        },
      ),
      throwsStateError,
    );
    expect(submitted, 0);
  });

  test(
    'ambiguous submission preserves signature and rechecks without signing or sending again',
    () async {
      var submitted = 0;
      var signed = 0;
      var checks = 0;
      final service = PoolDeploymentService(
        readContract: (_) async => null,
        readDecimals: decimals,
        currentNetworkScope: () => 'reviewed-network',
        readReceipt: (id, scope) async {
          checks++;
          expect(id, signature);
          expect(scope, 'reviewed-network');
          return receipt(TransactionConfirmationStatus.pending);
        },
      );
      Future<PoolDeploymentResult> attempt() => service.deploy(
        request: request(),
        signerAddress: () async {
          signed++;
          return owner;
        },
        submit: (_) async {
          submitted++;
          throw const TransactionSubmissionUnknown(signature: signature);
        },
      );
      final first = await attempt();
      final next = await attempt();
      expect(first.status, PoolDeploymentStatus.pending);
      expect(next.txSignature, signature);
      expect(next.message, contains('do not submit'));
      expect(submitted, 1);
      expect(signed, 1);
      expect(checks, 2);
      final changed = await service.deploy(
        request: request(fee: 99),
        signerAddress: () async => fail('A changed retry must not sign'),
        submit: (_) async => fail('A changed retry must not submit'),
      );
      expect(changed.txSignature, signature);
      expect(changed.message, contains('different reviewed parameters'));
      expect(checks, 2);
    },
  );

  test('execution failure is not reported as pool creation', () async {
    final service = PoolDeploymentService(
      readContract: (_) async => null,
      readDecimals: decimals,
      currentNetworkScope: () => 'reviewed-network',
      readReceipt: (_, __) async =>
          receipt(TransactionConfirmationStatus.confirmedFailure),
    );
    final result = await service.deploy(
      request: request(),
      signerAddress: () async => owner,
      submit: (_) async => signature,
    );
    expect(result.status, PoolDeploymentStatus.failed);
    expect(result.txSignature, signature);
  });

  test(
    'receipt success additionally requires matching active pool, owner, fee and LP state',
    () async {
      for (final state in [
        contract(),
        contract(wallet: otherOwner),
        contract(fee: 99),
        null,
      ]) {
        var submitted = false;
        final service = PoolDeploymentService(
          readContract: (_) async => submitted ? state : null,
          readDecimals: decimals,
          currentNetworkScope: () => 'reviewed-network',
          readReceipt: (_, __) async =>
              receipt(TransactionConfirmationStatus.confirmedSuccess),
        );
        final result = await service.deploy(
          request: request(),
          signerAddress: () async => owner,
          submit: (_) async {
            submitted = true;
            return signature;
          },
        );
        expect(
          result.status,
          state == null
              ? PoolDeploymentStatus.pending
              : state['owner'] == owner &&
                    (state['state'] as Map)['Swap']['fee_bps'] == 30
              ? PoolDeploymentStatus.created
              : PoolDeploymentStatus.verificationFailed,
        );
        expect(result.poolId, 'xrs-xusdc-mainnet-v1');
        expect(result.txSignature, signature);
      }
    },
  );

  test(
    'confirmation transport failure preserves the submitted transaction',
    () async {
      var submitted = 0;
      final service = PoolDeploymentService(
        readContract: (_) async => null,
        readDecimals: decimals,
        currentNetworkScope: () => 'reviewed-network',
        readReceipt: (_, __) async =>
            throw StateError('temporary lookup failure'),
      );
      final result = await service.deploy(
        request: request(),
        signerAddress: () async => owner,
        submit: (_) async {
          submitted++;
          return signature;
        },
      );
      expect(result.status, PoolDeploymentStatus.pending);
      expect(result.txSignature, signature);
      expect(submitted, 1);
    },
  );
}
