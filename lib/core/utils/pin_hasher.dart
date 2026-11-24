import 'dart:convert';
import 'dart:math';
import 'package:cryptography/cryptography.dart';

/// Salted PBKDF2 hashing for the unlock PIN and panic PIN, so secure storage
/// never holds the raw code. Stored format: `v1:<saltB64>:<hashB64>`. Legacy
/// plaintext values (from before hashing) are detected so callers can verify and
/// migrate them transparently on the next successful entry.
class PinHasher {
  PinHasher._();

  static const _iterations = 100000;
  static final _pbkdf2 = Pbkdf2(
    macAlgorithm: Hmac.sha256(),
    iterations: _iterations,
    bits: 256,
  );

  static bool isHashed(String stored) => stored.startsWith('v1:');

  /// Produces a versioned, salted hash string for [pin].
  static Future<String> hash(String pin) async {
    final salt = _randomBytes(16);
    final bytes = await _derive(pin, salt);
    return 'v1:${base64Encode(salt)}:${base64Encode(bytes)}';
  }

  /// True if [pin] matches [stored], handling both hashed and legacy-plaintext
  /// stored values with constant-time comparison.
  static Future<bool> verify(String pin, String stored) async {
    if (isHashed(stored)) {
      final parts = stored.split(':');
      if (parts.length != 3) return false;
      final salt = base64Decode(parts[1]);
      final expected = base64Decode(parts[2]);
      final actual = await _derive(pin, salt);
      return _constantTimeEquals(actual, expected);
    }
    // Legacy plaintext.
    return _constantTimeEquals(utf8.encode(pin), utf8.encode(stored));
  }

  static Future<List<int>> _derive(String pin, List<int> salt) async {
    final key = await _pbkdf2.deriveKey(
      secretKey: SecretKey(utf8.encode(pin)),
      nonce: salt,
    );
    return key.extractBytes();
  }

  static List<int> _randomBytes(int n) {
    final r = Random.secure();
    return List<int>.generate(n, (_) => r.nextInt(256));
  }

  static bool _constantTimeEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    var result = 0;
    for (var i = 0; i < a.length; i++) {
      result |= a[i] ^ b[i];
    }
    return result == 0;
  }
}
