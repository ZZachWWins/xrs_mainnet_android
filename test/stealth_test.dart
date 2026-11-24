import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:xeris_wallet/core/models/stealth_models.dart';
import 'package:xeris_wallet/core/utils/stealth_utils.dart';
import 'package:cryptography/cryptography.dart' as cryptography;
import 'package:bs58/bs58.dart';
import 'package:solana/solana.dart';

void main() {
  group('StealthMetaAddress Tests', () {
    test('encode/decode meta-address matches', () async {
      final scanPubKey = Uint8List.fromList(List.generate(32, (i) => i));
      final meta = StealthMetaAddress(scanPublicKey: scanPubKey);
      
      final encoded = meta.encode();
      expect(encoded.startsWith('xstealth1'), true);
      
      final decoded = StealthMetaAddress.decode(encoded);
      expect(decoded, isNotNull);
      expect(decoded!.scanPublicKey, equals(scanPubKey));
    });

    test('invalid meta-address fails decoding', () {
      expect(StealthMetaAddress.decode('not_a_stealth_address'), isNull);
      expect(StealthMetaAddress.decode('xstealth1short'), isNull);
    });
  });

  group('StealthUtils Cryptography Tests', () {
    test('end-to-end stealth payment generation and recovery', () async {
      // 1. Receiver generates scan keypair
      final receiverSeed = List<int>.generate(32, (i) => i);
      final scanKeyPair = await StealthUtils.deriveScanKeyPair(receiverSeed);
      final scanPubKey = await StealthUtils.getScanPublicKey(scanKeyPair);

      // 2. Sender generates payment result for the receiver's scan pubkey
      final payment = await StealthUtils.generateStealthPayment(scanPubKey);
      
      expect(payment.stealthAddress, isNotEmpty);
      expect(payment.ephemeralPublicKey.length, 32);

      // 3. Receiver recovers spending keypair from the announcement (ephemeral pubkey)
      final recoveredKeyPair = await StealthUtils.recoverStealthKeyPair(
        scanKeyPair,
        payment.ephemeralPublicKey,
      );

      expect(recoveredKeyPair, isNotNull);
      expect(recoveredKeyPair!.address, equals(payment.stealthAddress));
    });

    test('different receivers get different stealth addresses from same ephemeral key (hypothetically)', () async {
      // This test ensures domain separation and unique address generation per receiver
      final receiverASeed = List<int>.generate(32, (i) => i);
      final receiverBSeed = List<int>.generate(32, (i) => i + 1);

      final scanKeyPairA = await StealthUtils.deriveScanKeyPair(receiverASeed);
      final scanPubKeyA = await StealthUtils.getScanPublicKey(scanKeyPairA);
      final scanKeyPairB = await StealthUtils.deriveScanKeyPair(receiverBSeed);
      final scanPubKeyB = await StealthUtils.getScanPublicKey(scanKeyPairB);

      final paymentA = await StealthUtils.generateStealthPayment(scanPubKeyA);
      
      // Try to recover A's payment with B's key (should NOT work)
      final recoveredWithB = await StealthUtils.recoverStealthKeyPair(
        scanKeyPairB,
        paymentA.ephemeralPublicKey,
      );

      expect(recoveredWithB!.address, isNot(equals(paymentA.stealthAddress)));
    });

    test('verifyAnnouncement correctly validates matching pairs', () async {
      final receiverSeed = List<int>.generate(32, (i) => 100 + i);
      final scanKeyPair = await StealthUtils.deriveScanKeyPair(receiverSeed);
      final scanPubKey = await StealthUtils.getScanPublicKey(scanKeyPair);

      final payment = await StealthUtils.generateStealthPayment(scanPubKey);

      final isValid = await StealthUtils.verifyAnnouncement(
        scanKeyPair,
        payment.ephemeralPublicKey,
        payment.stealthAddress,
      );

      expect(isValid, true);

      final isInvalid = await StealthUtils.verifyAnnouncement(
        scanKeyPair,
        payment.ephemeralPublicKey,
        'some_other_address',
      );

      expect(isInvalid, false);
    });
  });
}
