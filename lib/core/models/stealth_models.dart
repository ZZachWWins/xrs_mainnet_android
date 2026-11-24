import 'dart:typed_data';
import 'package:bs58/bs58.dart';

/// Stealth meta-address: what the receiver shares publicly.
/// Contains the X25519 scan public key (32 bytes).
class StealthMetaAddress {
  final Uint8List scanPublicKey;

  StealthMetaAddress({required this.scanPublicKey});

  /// Encode as a shareable stealth address string.
  String encode() => 'xstealth1${base58.encode(scanPublicKey)}';

  /// Decode from encoded string. Returns null if invalid.
  static StealthMetaAddress? decode(String encoded) {
    if (!encoded.startsWith('xstealth1')) return null;
    try {
      final keyStr = encoded.substring('xstealth1'.length);
      final bytes = base58.decode(keyStr);
      if (bytes.length != 32) return null;
      return StealthMetaAddress(scanPublicKey: bytes);
    } catch (_) {
      return null;
    }
  }

  /// Check if a string is a valid stealth meta-address.
  static bool isStealthAddress(String address) => decode(address) != null;
}

/// Announcement created by the sender after sending to a stealth address.
/// Must be communicated to the receiver so they can derive the spending key.
class StealthAnnouncement {
  final String ephemeralPublicKey; // base58-encoded X25519 ephemeral pubkey
  final String stealthAddress; // one-time Ed25519 address that holds the funds
  final String receiverScanPubKey; // base58-encoded receiver scan pubkey
  final String? txSignature;
  final int timestamp; // unix seconds

  StealthAnnouncement({
    required this.ephemeralPublicKey,
    required this.stealthAddress,
    required this.receiverScanPubKey,
    this.txSignature,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'ephemeral_pubkey': ephemeralPublicKey,
        'stealth_address': stealthAddress,
        'receiver_scan_pubkey': receiverScanPubKey,
        'tx_signature': txSignature,
        'timestamp': timestamp,
      };

  factory StealthAnnouncement.fromJson(Map<String, dynamic> json) =>
      StealthAnnouncement(
        ephemeralPublicKey: json['ephemeral_pubkey'],
        stealthAddress: json['stealth_address'],
        receiverScanPubKey: json['receiver_scan_pubkey'],
        txSignature: json['tx_signature'],
        timestamp: json['timestamp'] ?? 0,
      );
}

/// A detected stealth payment ready for claiming/sweeping.
class DetectedStealthPayment {
  final StealthAnnouncement announcement;
  final double balance; // XRS balance at the stealth address
  final bool swept;

  DetectedStealthPayment({
    required this.announcement,
    required this.balance,
    this.swept = false,
  });
}
