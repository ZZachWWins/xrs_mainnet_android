import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:xeris_wallet/core/config/network_config.dart';
import 'package:xeris_wallet/core/models/asset_model.dart';
import 'package:xeris_wallet/core/services/agent_runner_service.dart';
import 'package:xeris_wallet/core/services/base_api_service.dart';
import 'package:xeris_wallet/core/services/instruction_builder.dart';
import 'package:xeris_wallet/features/wallet_actions/services/swap_service.dart';

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

  test('ClaimTask golden bytes contain variant 32 and both Rust string fields', () {
    // Latest node token.rs: ClaimTask { task_id: String, claimant_identity: String }.
    // Bincode enum u32 LE followed by each UTF-8 string's u64 LE length.
    final bytes = InstructionBuilder.buildClaimTaskInstruction(
      taskId: 'a', claimantIdentity: 'b',
    );
    final hex = bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
    expect(hex, '20000000010000000000000061010000000000000062');
    expect(() => InstructionBuilder.buildClaimTaskInstruction(
      taskId: 'a', claimantIdentity: '',
    ), throwsArgumentError);
  });

  test('canonical identity CID hashes the full UTF-8 address string', () {
    // ledger::identity_cid hashes pubkey.as_bytes(), where pubkey is &str.
    // SHA256(UTF8('1' * 32)) starts with 8a83665f3798727f14f92ad0e6c99fda.
    expect(
      AgentRunnerService.identityContractId('11111111111111111111111111111111'),
      'identity_8a83665f3798727f14f92ad0e6c99fda',
    );
  });

  test('active identity preflight uses the exact canonical contract and owner', () async {
    const identity = '11111111111111111111111111111111';
    const cid = 'identity_8a83665f3798727f14f92ad0e6c99fda';
    var requests = 0;
    BaseApiService.clientOverride = MockClient((request) async {
      requests++;
      expect(request.method, 'GET');
      expect(request.url.toString(), '${NetworkConfig.controlUrl}/contract/$cid');
      return http.Response(jsonEncode({
        'success': true,
        'contract': {
          'contract_id': cid, 'owner': identity, 'is_active': true,
          'state': {'Identity': {'identity_pubkey': identity, 'active': true}},
        },
      }), 200);
    });
    expect(await AgentRunnerService.ensureActiveIdentity(identity), NetworkConfig.cacheKey);
    expect(requests, 1);
  });

  test('absent or inactive identity prevents claims before a transaction is prepared', () async {
    const identity = '11111111111111111111111111111111';
    var writes = 0;
    BaseApiService.clientOverride = MockClient((request) async {
      if (request.method != 'GET') writes++;
      return http.Response(jsonEncode({'success': false, 'error': 'Contract not found'}), 200);
    });
    await expectLater(
      AgentRunnerService.ensureActiveIdentity(identity),
      throwsA(isA<UnsupportedError>()),
    );
    BaseApiService.clientOverride = MockClient((request) async {
      if (request.method != 'GET') writes++;
      return http.Response(jsonEncode({
        'success': true,
        'contract': {
          'contract_id': AgentRunnerService.identityContractId(identity),
          'owner': identity, 'is_active': true,
          'state': {'Identity': {'identity_pubkey': identity, 'active': false}},
        },
      }), 200);
    });
    await expectLater(
      AgentRunnerService.ensureActiveIdentity(identity),
      throwsA(isA<UnsupportedError>()),
    );
    expect(writes, 0);
  });

  test('disabled legacy limit and DCA creation fail before key access or requests', () async {
    var requests = 0;
    BaseApiService.clientOverride = MockClient((_) async {
      requests++;
      throw StateError('Disabled order creation must not issue requests');
    });
    const asset = AssetModel(
      id: 'token', symbol: 'T', name: 'Token', balance: 10,
      price: 1, changePercentage24h: 0,
    );
    final service = SwapService();
    await expectLater(service.placeLimitOrder(
      walletAddress: 'unused', mnemonic: 'pk:not-valid-base58-!',
      fromAsset: asset, toAsset: asset, amount: 1, limitPrice: 2,
    ), throwsA(isA<UnsupportedError>()));
    await expectLater(service.createDcaOrder(
      walletAddress: 'unused', mnemonic: 'pk:not-valid-base58-!',
      fromAsset: asset, toAsset: asset, totalAmount: 10,
      amountPerTick: 1, intervalSeconds: 3600, totalTicks: 10,
    ), throwsA(isA<UnsupportedError>()));
    expect(requests, 0);
  });
}
