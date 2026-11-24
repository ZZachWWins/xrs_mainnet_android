import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:bs58/bs58.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:solana/solana.dart';
import 'package:xeris_wallet/core/config/network_config.dart';
import 'package:xeris_wallet/core/services/base_api_service.dart';
import 'package:xeris_wallet/core/services/xeris_api_service.dart';

void main() {
  late XerisNetwork original;
  late Ed25519HDKeyPair syntheticKey;

  setUp(() async {
    original = NetworkConfig.currentNetwork;
    NetworkConfig.currentNetwork = XerisNetwork.testnet;
    syntheticKey = await Ed25519HDKeyPair.fromPrivateKeyBytes(
      privateKey: List.filled(32, 23),
    );
  });
  tearDown(() {
    BaseApiService.clientOverride = null;
    NetworkConfig.currentNetwork = original;
  });

  for (final scenario in [
    'missing-id',
    'transport-error',
    'wrong-id',
    'rejected',
  ]) {
    test('signed submission preserves canonical ID: $scenario', () async {
      var writes = 0;
      String? actualId;
      BaseApiService.clientOverride = MockClient((request) async {
        final body = jsonDecode(request.body) as Map;
        if (body['method'] == 'getLatestBlockhash') {
          return http.Response(
            jsonEncode({
              'jsonrpc': '2.0',
              'id': 1,
              'result': {
                'value': {
                  'blockhash': List.filled(32, '11').join(),
                  'lastValidBlockHeight': 150,
                },
              },
            }),
            200,
          );
        }
        expect(request.url.path, '/submit');
        writes++;
        final bytes = base64Decode(body['tx_base64'] as String);
        expect(bytes.first, 1); // One compact-vector signature.
        actualId = base58.encode(Uint8List.fromList(bytes.sublist(1, 65)));
        if (scenario == 'transport-error') {
          throw const SocketException('response lost');
        }
        if (scenario == 'wrong-id') {
          return http.Response(
            jsonEncode({'status': 'queued', 'signature': 'different-id'}),
            200,
          );
        }
        if (scenario == 'rejected') {
          return http.Response(jsonEncode({'error': 'Rejected by node'}), 200);
        }
        return http.Response(jsonEncode({'status': 'queued'}), 200);
      });
      final submission = XerisApiService.wrapXrs(
        keyPair: syntheticKey,
        amountLamports: 1000,
        expectedNetworkScope: NetworkConfig.cacheKey,
      );
      if (scenario == 'missing-id') {
        expect(await submission, actualId);
      } else {
        await expectLater(
          submission,
          throwsA(
            isA<TransactionSubmissionUnknown>().having(
              (error) => error.signature,
              'canonical signature',
              predicate<String>(
                (value) => value == actualId && value.isNotEmpty,
              ),
            ),
          ),
        );
      }
      expect(
        writes,
        1,
        reason: 'An ambiguous submission must never retry the write.',
      );
      expect(actualId, isNotEmpty);
    });
  }
}
