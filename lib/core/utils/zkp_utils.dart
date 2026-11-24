import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';

/// SHA-256 domain hash matching the node's domain_hash() exactly.
/// Computes SHA-256(tag_bytes || data_bytes).
/// The tag is raw ASCII, NOT length-prefixed.
Uint8List domainHash(String tag, Uint8List data) {
  final input = Uint8List.fromList([...utf8.encode(tag), ...data]);
  return Uint8List.fromList(sha256.convert(input).bytes);
}

/// Generate all four ZK proof components for a private transfer.
/// 
/// amount: transfer amount in lamports
/// senderBalance: sender's EXACT balance in lamports AFTER subtracting the
///                2,000,000 lamport transaction fee
/// 
/// Returns a map with commitment, balanceProof, nullifier, rangeProof, and blinding.
Map<String, Uint8List> createZkProofs(int amount, int senderBalance) {
  if (amount <= 0) throw Exception('Amount must be > 0');
  if (senderBalance < amount) throw Exception('Insufficient balance after fee');

  // Generate 32 cryptographically random bytes
  final secureRng = Random.secure();
  final blinding = Uint8List(32);
  for (int i = 0; i < 32; i++) {
    blinding[i] = secureRng.nextInt(256);
  }

  final amountBytes = _toLeU64(amount);
  final balanceBytes = _toLeU64(senderBalance);

  // Commitment hash: SHA-256("zk_commit_v5" || amount_le || blinding)
  final commitmentHash = domainHash('zk_commit_v5',
    Uint8List.fromList([...amountBytes, ...blinding]));

  // Balance hash: SHA-256("zk_balance_v5" || commit_hash || balance_le || amount_le || blinding)
  final balanceHash = domainHash('zk_balance_v5',
    Uint8List.fromList([...commitmentHash, ...balanceBytes, ...amountBytes, ...blinding]));

  // Balance proof: [commitment_hash(32) | balance_hash(32)]
  final balanceProof = Uint8List.fromList([...commitmentHash, ...balanceHash]);

  // Nullifier: SHA-256("zk_null_v5" || blinding || amount_le || SHA-256(blinding))
  final blindingHash = Uint8List.fromList(sha256.convert(blinding).bytes);
  final nullifier = domainHash('zk_null_v5',
    Uint8List.fromList([...blinding, ...amountBytes, ...blindingHash]));

  // Range proof: 32 zero bytes (node ignores this for validator verification)
  final rangeProof = Uint8List(32);

  // Witness: [amount(8) | blinding(32) | claimed_balance(8)] = 48 bytes
  final commitment = Uint8List.fromList([...amountBytes, ...blinding, ...balanceBytes]);

  return {
    'commitment': commitment,       // 48 bytes
    'balanceProof': balanceProof,   // 64 bytes
    'nullifier': nullifier,         // 32 bytes
    'rangeProof': rangeProof,       // 32 bytes
    'blinding': blinding,           // 32 bytes (save locally if user wants to prove amount later)
  };
}

Uint8List _toLeU64(int value) {
  final buf = ByteData(8);
  buf.setUint64(0, value, Endian.little);
  return buf.buffer.asUint8List();
}
