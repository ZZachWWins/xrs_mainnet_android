import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:cryptography/cryptography.dart' as cryptography;
import 'package:solana/solana.dart';

/// Core cryptographic operations for the stealth address protocol.
///
/// Protocol:
/// 1. Receiver derives X25519 scan keypair from wallet seed
/// 2. Receiver shares stealth meta-address (X25519 scan pubkey)
/// 3. Sender generates ephemeral X25519 keypair
/// 4. Sender computes shared_secret = X25519_DH(ephemeral_priv, receiver_scan_pub)
/// 5. Sender derives one-time seed = SHA256("xeris_stealth_v1" || shared_secret)
/// 6. Sender creates Ed25519 keypair from seed → stealth address
/// 7. Sender transfers funds to stealth address + announces ephemeral pubkey
/// 8. Receiver computes shared_secret = X25519_DH(scan_priv, ephemeral_pub)
/// 9. Receiver derives same one-time seed → same keypair → can spend
class StealthUtils {
  static final _x25519 = cryptography.X25519();

  /// Derives the X25519 scan keypair from the wallet's seed bytes.
  /// Uses domain separation to ensure the scan key is independent from the spend key.
  static Future<cryptography.SimpleKeyPair> deriveScanKeyPair(
      List<int> walletSeed) async {
    final scanSeed = domainHash(
        'xeris_stealth_scan_v1', Uint8List.fromList(walletSeed));
    return await _x25519.newKeyPairFromSeed(scanSeed);
  }

  /// Extracts the scan public key bytes from a scan keypair.
  static Future<Uint8List> getScanPublicKey(
      cryptography.SimpleKeyPair scanKeyPair) async {
    final pubKey = await scanKeyPair.extractPublicKey();
    return Uint8List.fromList(pubKey.bytes);
  }

  /// Generates a stealth payment for a receiver. Called by the SENDER.
  ///
  /// [receiverScanPubKey] is the receiver's X25519 scan public key (32 bytes).
  /// Returns the one-time stealth address and ephemeral public key.
  static Future<StealthPaymentResult> generateStealthPayment(
      Uint8List receiverScanPubKey) async {
    // 1. Generate ephemeral X25519 keypair
    final ephemeralKeyPair = await _x25519.newKeyPair();
    final ephemeralPubKey = await ephemeralKeyPair.extractPublicKey();

    // 2. Compute shared secret via ECDH
    final sharedSecret = await _x25519.sharedSecretKey(
      keyPair: ephemeralKeyPair,
      remotePublicKey: cryptography.SimplePublicKey(
        receiverScanPubKey,
        type: cryptography.KeyPairType.x25519,
      ),
    );
    final sharedSecretBytes = await sharedSecret.extractBytes();

    // 3. Derive one-time Ed25519 seed from shared secret
    final stealthSeed = domainHash(
        'xeris_stealth_v1', Uint8List.fromList(sharedSecretBytes));

    // 4. Create Ed25519 keypair from seed → stealth address
    final stealthKeyPair = await Ed25519HDKeyPair.fromPrivateKeyBytes(
      privateKey: stealthSeed,
    );

    return StealthPaymentResult(
      stealthAddress: stealthKeyPair.address,
      ephemeralPublicKey: Uint8List.fromList(ephemeralPubKey.bytes),
      stealthSeed: stealthSeed,
    );
  }

  /// Recovers the stealth spending keypair from an announcement.
  /// Called by the RECEIVER using their scan private key.
  static Future<Ed25519HDKeyPair?> recoverStealthKeyPair(
    cryptography.SimpleKeyPair scanKeyPair,
    Uint8List ephemeralPubKey,
  ) async {
    try {
      // 1. Compute shared secret via ECDH (mirror of sender's computation)
      final sharedSecret = await _x25519.sharedSecretKey(
        keyPair: scanKeyPair,
        remotePublicKey: cryptography.SimplePublicKey(
          ephemeralPubKey,
          type: cryptography.KeyPairType.x25519,
        ),
      );
      final sharedSecretBytes = await sharedSecret.extractBytes();

      // 2. Derive the same one-time Ed25519 seed
      final stealthSeed = domainHash(
          'xeris_stealth_v1', Uint8List.fromList(sharedSecretBytes));

      // 3. Reconstruct the keypair
      return await Ed25519HDKeyPair.fromPrivateKeyBytes(
        privateKey: stealthSeed,
      );
    } catch (_) {
      return null;
    }
  }

  /// Verifies that an announcement corresponds to an expected stealth address.
  static Future<bool> verifyAnnouncement(
    cryptography.SimpleKeyPair scanKeyPair,
    Uint8List ephemeralPubKey,
    String expectedStealthAddress,
  ) async {
    final keyPair =
        await recoverStealthKeyPair(scanKeyPair, ephemeralPubKey);
    if (keyPair == null) return false;
    return keyPair.address == expectedStealthAddress;
  }

  /// SHA-256 domain hash: SHA256(tag_ascii || data).
  static Uint8List domainHash(String tag, Uint8List data) {
    final input = Uint8List.fromList([...tag.codeUnits, ...data]);
    return Uint8List.fromList(sha256.convert(input).bytes);
  }
}

/// Result of generating a stealth payment (sender-side).
class StealthPaymentResult {
  final String stealthAddress;
  final Uint8List ephemeralPublicKey;
  final Uint8List stealthSeed;

  StealthPaymentResult({
    required this.stealthAddress,
    required this.ephemeralPublicKey,
    required this.stealthSeed,
  });
}
