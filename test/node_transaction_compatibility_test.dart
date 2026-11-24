import 'dart:convert';
import 'dart:typed_data';

import 'package:bs58/bs58.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:solana/solana.dart';
import 'package:xeris_wallet/core/config/network_config.dart';
import 'package:xeris_wallet/core/services/base_api_service.dart';
import 'package:xeris_wallet/core/services/pqc_service.dart';
import 'package:xeris_wallet/core/services/staking_api_service.dart';
import 'package:xeris_wallet/core/services/wallet_service.dart';
import 'package:xeris_wallet/core/services/zkp_service.dart';
import 'package:xeris_wallet/features/wallet_actions/screens/transaction_result_screen.dart';
import 'package:xeris_wallet/l10n/app_localizations.dart';

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

  test('signed transactions use the control API exactly once', () async {
    var requests = 0;
    BaseApiService.clientOverride = MockClient((request) async {
      requests++;
      expect(request.method, 'POST');
      expect(request.url.toString(), '${NetworkConfig.controlUrl}/submit');
      expect(jsonDecode(request.body), {'tx_base64': 'synthetic-signed-bytes'});
      return http.Response(
        jsonEncode({'status': 'queued', 'signature': 'synthetic-signature'}),
        200,
      );
    });

    expect(
      await WalletService.submitTransaction('synthetic-signed-bytes'),
      'synthetic-signature',
    );
    expect(requests, 1);
  });

  test('HTTP 200 node rejection is not a successful transaction', () async {
    var requests = 0;
    BaseApiService.clientOverride = MockClient((_) async {
      requests++;
      return http.Response(jsonEncode({'error': 'Insufficient balance'}), 200);
    });

    await expectLater(
      WalletService.submitTransaction('synthetic-signed-bytes'),
      throwsA(isA<ApiException>()),
    );
    expect(requests, 1);
  });

  test('unacknowledged submission does not invent a transaction id', () async {
    BaseApiService.clientOverride = MockClient((_) async =>
        http.Response(jsonEncode({'status': 'queued'}), 200));

    await expectLater(
      WalletService.submitTransaction('synthetic-signed-bytes'),
      throwsA(isA<ApiException>()),
    );
  });

  test('recent blockhash converts the node hex value to 32-byte base58', () async {
    final bytes = Uint8List.fromList(List.generate(32, (index) => index + 1));
    final hex = bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
    BaseApiService.clientOverride = MockClient((request) async {
      expect(jsonDecode(request.body)['method'], 'getLatestBlockhash');
      return http.Response(
        jsonEncode({
          'jsonrpc': '2.0',
          'id': 1,
          'result': {
            'value': {'blockhash': hex, 'lastValidBlockHeight': 150},
          },
        }),
        200,
      );
    });

    expect(await WalletService.getRecentBlockhash(), base58.encode(bytes));
  });

  test('missing or dummy recent blockhash fails rather than signing a fallback', () async {
    for (final value in [
      <String, dynamic>{},
      {'blockhash': '11111111111111111111111111111111'},
      {'blockhash': 'not-a-blockhash'},
    ]) {
      BaseApiService.clientOverride = MockClient((_) async => http.Response(
            jsonEncode({'jsonrpc': '2.0', 'id': 1, 'result': {'value': value}}),
            200,
          ));
      await expectLater(
        WalletService.getRecentBlockhash(),
        throwsA(isA<ApiException>()),
      );
    }
  });

  test('balance lookup propagates failure without an extra retry loop', () async {
    var requests = 0;
    BaseApiService.clientOverride = MockClient((_) async {
      requests++;
      return http.Response(jsonEncode({'error': 'Invalid request'}), 400);
    });

    await expectLater(
      WalletService.getBalance('synthetic-unavailable-wallet', retries: 5),
      throwsA(isA<ApiException>()),
    );
    expect(requests, 1);
  });

  test('legacy PQ and private transfers fail before any request', () async {
    var requests = 0;
    BaseApiService.clientOverride = MockClient((_) async {
      requests++;
      throw StateError('No request should be made for disabled transfers');
    });
    final keyPair = await Ed25519HDKeyPair.fromPrivateKeyBytes(
      privateKey: List.filled(32, 7),
    );

    await expectLater(
      PqcService.sendPqTransfer(mnemonic: 'unused', to: 'unused', amount: 1),
      throwsA(isA<UnsupportedError>()),
    );
    await expectLater(
      ZkpService.sendZkPrivateTransfer(
        senderKeypair: keyPair,
        recipientAddress: 'unused',
        amountXrs: 1,
      ),
      throwsA(isA<UnsupportedError>()),
    );
    expect(requests, 0);
  });

  test('staking cannot silently stake for a different validator', () async {
    var requests = 0;
    BaseApiService.clientOverride = MockClient((_) async {
      requests++;
      throw StateError('Delegated staking must be rejected locally');
    });
    final keyPair = await Ed25519HDKeyPair.fromPrivateKeyBytes(
      privateKey: List.filled(32, 7),
    );
    const anotherValidator = '11111111111111111111111111111111';

    await expectLater(
      StakingApiService.stakeXrs(
        keyPair: keyPair,
        validatorAddress: anotherValidator,
        amountLamports: 1000000000,
      ),
      throwsA(isA<UnsupportedError>()),
    );
    await expectLater(
      StakingApiService.unstakeXrs(
        keyPair: keyPair,
        validatorAddress: anotherValidator,
        amountLamports: 1000000000,
      ),
      throwsA(isA<UnsupportedError>()),
    );
    expect(requests, 0);
  });

  testWidgets('submission receipt does not claim on-chain confirmation', (tester) async {
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: const TransactionResultScreen(
        success: true,
        hash: 'synthetic-transaction-signature-for-receipt',
      ),
    ));
    await tester.pump(const Duration(seconds: 1));

    expect(find.text(l10n.transactionSubmitted), findsWidgets);
    expect(find.text(l10n.successStatus), findsNothing);
    expect(find.byIcon(Icons.schedule), findsOneWidget);
    expect(find.byIcon(Icons.check_circle), findsNothing);
  });
}
