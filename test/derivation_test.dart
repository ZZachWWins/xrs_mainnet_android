// ignore_for_file: avoid_print
import 'package:flutter_test/flutter_test.dart';
import 'package:xeris_wallet/core/services/wallet_service.dart';

void main() {
  test('Wallet derivation should be deterministic', () async {
    const mnemonic = 'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about';
    
    final keyPair1 = await WalletService.getKeyPair(mnemonic);
    final keyPair2 = await WalletService.getKeyPair(mnemonic);
    
    print('Address 1: ${keyPair1.address}');
    print('Address 2: ${keyPair2.address}');
    
    expect(keyPair1.address, equals(keyPair2.address));
  });

  test('Wallet derivation should handle whitespace consistently', () async {
    const mnemonic1 = 'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about';
    const mnemonic2 = ' abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about ';
    const mnemonic3 = 'abandon  abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about'; // Double space
    
    final keyPair1 = await WalletService.getKeyPair(mnemonic1);
    final keyPair2 = await WalletService.getKeyPair(mnemonic2.trim());
    final keyPair3 = await WalletService.getKeyPair(mnemonic3);
    
    expect(keyPair1.address, equals(keyPair2.address));
    expect(keyPair1.address, equals(keyPair3.address), reason: 'Normalization should handle varied internal whitespace');
  });

  test('Addresses should be case-sensitive (Base58)', () {
    const address = 'EHqmfkN89RJ7Y33CXM6uCzhVeuywHoJXZZLszBHHZy7o';
    final lowerAddress = address.toLowerCase();
    
    expect(WalletService.isValidAddress(address), isTrue);
    expect(WalletService.isValidAddress(lowerAddress), isFalse, reason: 'Base58 is case-sensitive');
  });
}



