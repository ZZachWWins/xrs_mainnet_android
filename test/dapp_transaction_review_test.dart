import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:xeris_wallet/core/services/dapp_transaction_review.dart';
import 'package:xeris_wallet/core/services/wallet_service.dart';

void main() {
  final fixtures = jsonDecode(
          File('test/fixtures/dapp-signing-vectors.json').readAsStringSync())
      as Map;
  for (final vector in fixtures['positives'] as List) {
    test('independent Dart review: ${vector['name']}', () {
      final result =
          DAppTransactionReview.parse(vector['transaction'], vector['signer']);
      expect(result.intent, vector['expected']);
      expect(result.blockhash, fixtures['blockhash']);
      expect(result.display['From wallet'], vector['signer']);
      expect(result.display['Recipient'], vector['expected']['recipient']);
      expect(result.display['Network fee'], '0.001 native XRS');
      expect(result.wire.sublist(65), result.message);
      final copy = result.wire..[65] = 0;
      expect(copy[65], 0);
      expect(result.wire[65], 1,
          reason: 'reviewed bytes cannot be modified by caller');
      expect(() => result.intent['amount'] = '0', throwsUnsupportedError);
    });
  }
  for (final vector in fixtures['negatives'] as List) {
    test('reject shared malformed wire: ${vector['name']}', () {
      expect(
          () => DAppTransactionReview.parse(
              vector['transaction'], vector['signer']),
          throwsA(isA<FormatException>()));
    });
  }
  final wrap =
      (fixtures['positives'] as List).firstWhere((v) => v['name'] == 'wrap');
  test('unbound burn, zero amounts and pre-signed payloads never reach signer',
      () async {
    final burn = base64Decode(wrap['transaction'])
      ..[base64Decode(wrap['transaction']).length - 12] = 2;
    var contextChecks = 0;
    await expectLater(
        WalletService.signDAppTransaction(
          mnemonic: 'not a mnemonic',
          txBase64: base64Encode(burn),
          expectedPublicKey: wrap['signer'],
          ensureCurrent: () async {
            contextChecks++;
          },
        ),
        throwsA(isA<FormatException>()));
    expect(contextChecks, 0);
    final zero = base64Decode(wrap['transaction']);
    zero.fillRange(zero.length - 8, zero.length, 0);
    expect(
        () => DAppTransactionReview.parse(base64Encode(zero), wrap['signer']),
        throwsFormatException);
    final signed = base64Decode(wrap['transaction'])..[1] = 1;
    expect(
        () => DAppTransactionReview.parse(base64Encode(signed), wrap['signer']),
        throwsFormatException);
  });
  test(
      'canonical base64, compact counts, instruction EOF and key length are enforced',
      () {
    final bytes = base64Decode(wrap['transaction']);
    for (final malformed in [
      wrap['transaction'] + '\n',
      base64Encode([129, 0, ...bytes.sublist(1)]),
      base64Encode([...bytes, 0])
    ]) {
      expect(() => DAppTransactionReview.parse(malformed, wrap['signer']),
          throwsFormatException);
    }
    expect(
        () => DAppTransactionReview.parse(
            wrap['transaction'], '11111111111111111111111111111111'),
        throwsFormatException);
  });
  test(
      'ownership text is exact printable ASCII with LF and no binary escape route',
      () {
    const message =
        'Xeris settlement ownership proof\nxeris-mainnet-settlement-intent-v2\n{"amount_raw":"500000"}';
    expect(
        reviewDAppMessage(Uint8List.fromList(utf8.encode(message))), message);
    for (final value in [
      '',
      '  ',
      'a\rb',
      'a\tb',
      'a\x00b',
      'a\u200bb',
      'a\ufeffb',
      'a\u202eb',
      'é',
      'a' * 8193,
      wrap['transaction']
    ]) {
      expect(() => reviewDAppMessage(Uint8List.fromList(utf8.encode(value))),
          throwsFormatException,
          reason: value.length > 100 ? 'bounded/binary payload' : value);
    }
    expect(() => reviewDAppMessage(Uint8List.fromList([0xff])),
        throwsFormatException);
  });
  test('binary ownership signing is rejected before key derivation', () async {
    var checked = false;
    await expectLater(
        WalletService.signDAppMessage(
            mnemonic: 'not a mnemonic',
            message: Uint8List.fromList([1, 0, 0]),
            expectedPublicKey: wrap['signer'],
            ensureCurrent: () async {
              checked = true;
            }),
        throwsFormatException);
    expect(checked, false);
  });
  test(
      'ambiguous or unapproved swap effects are rejected despite a valid envelope',
      () {
    List<int> u64(int value) =>
        List.generate(8, (i) => (value >> (8 * i)) & 255);
    List<int> text(String value) {
      final bytes = utf8.encode(value);
      return [...u64(bytes.length), ...bytes];
    }

    String transaction(List<int> instruction) {
      final prefix = base64Decode(wrap['transaction']).sublist(0, 165);
      final size = instruction.length;
      final compact = size < 128 ? [size] : [(size & 127) | 128, size >> 7];
      return base64Encode([...prefix, 1, 1, 0, ...compact, ...instruction]);
    }

    for (final args in [
      '{"amount":1,"amount":2,"min_output":1}',
      '{"amount":1e3,"min_output":1}',
      '{"amount":1.0,"min_output":1}',
      '{"min_output":1,"amount":1}',
      '{"amount":18446744073709551616,"min_output":1}',
      '{"amount":1,"min_output":0}',
      '{"amount":1,"min_output":1,"recipient":"other"}'
    ]) {
      final wire = transaction([
        4,
        0,
        0,
        0,
        ...text('xrs-xusdc-mainnet-v1'),
        ...text('swap_b_to_a'),
        ...text(args)
      ]);
      expect(() => DAppTransactionReview.parse(wire, wrap['signer']),
          throwsFormatException);
    }
    for (final contract in ['other-pool', 'xrs-xusdc-mainnet-v1']) {
      final wire = transaction([
        4,
        0,
        0,
        0,
        ...text(contract),
        ...text('withdraw'),
        ...text('{"amount":1,"min_output":1}')
      ]);
      expect(() => DAppTransactionReview.parse(wire, wrap['signer']),
          throwsFormatException);
    }
  });
}
