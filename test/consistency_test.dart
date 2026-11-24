// ignore_for_file: avoid_print
import 'package:bip39/bip39.dart' as bip39;
import 'package:solana/solana.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Derivation consistency check', () async {
    const mnemonic = 'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about';
    
    // 1. Raw BIP39 Seed
    final seed = bip39.mnemonicToSeed(mnemonic);
    
    // 2. Ed25519 Keypair from first 32 bytes
    final first32Bytes = seed.sublist(0, 32);
    final keyPair = await Ed25519HDKeyPair.fromPrivateKeyBytes(
      privateKey: first32Bytes,
    );
    
    print('Derived Address: ${keyPair.address}');
    expect(keyPair.address, equals('EHqmfkN89RJ7Y33CXM6uCzhVeuywHoJXZZLszBHHZy7o'));
  });

  test('Mnemonic case sensitivity', () {
    const mnemonicMixed = 'Abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about';
    // The bip39 package is case-sensitive and should return false for "Abandon"
    expect(bip39.validateMnemonic(mnemonicMixed), isFalse);
  });
}
