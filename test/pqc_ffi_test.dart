import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:xeris_wallet/core/services/ffi_bridge.dart';

void main() {
  group('PQC FFI Integration Tests', () {
    test('Dilithium Keygen should produce valid length keys', () {
      final keypair = FfiBridge.dilithiumKeygen();
      
      expect(keypair.publicKey.length, 1952);
      expect(keypair.secretKey.length, 4032);
      
      // Check that they aren't all zeros
      expect(keypair.publicKey.any((b) => b != 0), isTrue);
      expect(keypair.secretKey.any((b) => b != 0), isTrue);
    });

    test('Dilithium Sign and Verify should work', () {
      final keypair = FfiBridge.dilithiumKeygen();
      final message = utf8.encode('test message');
      
      final signature = FfiBridge.dilithiumSign(
        keypair.secretKey, 
        Uint8List.fromList(message),
      );
      
      expect(signature.length, 3309);
      
      final isValid = FfiBridge.dilithiumVerify(
        keypair.publicKey,
        Uint8List.fromList(message),
        signature,
      );
      
      expect(isValid, isTrue);
    });

    test('Dilithium Verify should fail for invalid message', () {
      final keypair = FfiBridge.dilithiumKeygen();
      final message = utf8.encode('test message');
      final wrongMessage = utf8.encode('wrong message');
      
      final signature = FfiBridge.dilithiumSign(
        keypair.secretKey, 
        Uint8List.fromList(message),
      );
      
      final isValid = FfiBridge.dilithiumVerify(
        keypair.publicKey,
        Uint8List.fromList(wrongMessage),
        signature,
      );
      
      expect(isValid, isFalse);
    });

    test('PQC Integration Guide Example: Sign format "{from}:{to}:{amount}"', () {
      final keypair = FfiBridge.dilithiumKeygen();
      const from = 'EHqmfkN89RJ7Y33CXM6uCzhVeuywHoJXZZLszBHHZy7o';
      const to = 'EHqmfkN89RJ7Y33CXM6uCzhVeuywHoJXZZLszBHHZy7o';
      const amount = 1000000;
      
      final messageStr = '$from:$to:$amount';
      final message = utf8.encode(messageStr);
      
      final signature = FfiBridge.dilithiumSign(
        keypair.secretKey, 
        Uint8List.fromList(message),
      );
      
      final isValid = FfiBridge.dilithiumVerify(
        keypair.publicKey,
        Uint8List.fromList(message),
        signature,
      );
      
      expect(isValid, isTrue);
    });
  });
}
