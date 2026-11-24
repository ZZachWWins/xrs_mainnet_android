import 'package:flutter_test/flutter_test.dart';
import 'package:xeris_wallet/core/services/wallet_service.dart';

void main() {
  group('WalletService Tests', () {
    test('isValidAddress returns true for valid addresses', () {
      // Valid Solana address (example)
      // Note: The validator uses the solana package's verify logic. 
      // We need a real valid address locally to test.
      // Let's use a known valid one from the manual script or generated.
      const realValid = 'HTmnBihZNiLuziVU2bFpMXRJkj78pnSHW5jkdzMrrjHy';
      
      expect(WalletService.isValidAddress(realValid), isTrue);
    });

    test('isValidAddress returns false for invalid addresses', () {
      expect(WalletService.isValidAddress(''), isFalse);
      expect(WalletService.isValidAddress('short'), isFalse);
      expect(WalletService.isValidAddress('ThisIsDefinitelyTooLongToBeASolanaAddressAndItHasInvalidChars!'), isFalse);
    });

    test('validateMnemonic returns true for valid phrase', () {
      const validMnemonic = 'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about';
      expect(WalletService.validateMnemonic(validMnemonic), isTrue);
    });

    test('validateMnemonic returns false for invalid phrase', () {
      expect(WalletService.validateMnemonic(''), isFalse);
      expect(WalletService.validateMnemonic('one two'), isFalse);
      expect(WalletService.validateMnemonic('crypto is fun but this is not a valid mnemonic phrase'), isFalse);
    });
  });
}
