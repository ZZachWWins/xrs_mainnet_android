import 'package:bip39/bip39.dart' as bip39;
import 'package:bs58/bs58.dart';
import 'package:cryptography/cryptography.dart' as cryptography;
import 'package:flutter/foundation.dart';
import 'package:solana/solana.dart';
import 'package:xeris_wallet/core/config/network_config.dart';
import 'package:xeris_wallet/core/models/stealth_models.dart';
import 'package:xeris_wallet/core/services/base_api_service.dart';
import 'package:xeris_wallet/core/services/storage_service.dart';
import 'package:xeris_wallet/core/services/wallet_service.dart';
import 'package:xeris_wallet/core/services/xeris_api_service.dart';
import 'package:xeris_wallet/core/utils/stealth_utils.dart';
import 'package:solana/encoder.dart';

class StealthService {
  static const unavailableMessage =
      'Stealth transfers are unavailable on mainnet. '
      'Ask the recipient for a standard Xeris address. No stealth payment was sent.';

  static void requireSendingAvailable() {
    if (!NetworkConfig.stealthEnabled) {
      throw UnsupportedError(unavailableMessage);
    }
  }

  /// Initialize stealth keys for a wallet if not already present.
  static Future<void> initializeStealthKeys(
      String walletId, String mnemonic) async {
    final existing = await StorageService.getStealthScanKey(walletId);
    if (existing != null) return;

    final walletSeed = _getWalletSeed(mnemonic);
    final scanSeed = StealthUtils.domainHash(
        'xeris_stealth_scan_v1', Uint8List.fromList(walletSeed));

    await StorageService.saveStealthScanKey(walletId, base58.encode(scanSeed));

    if (kDebugMode) {
      final scanKeyPair =
          await cryptography.X25519().newKeyPairFromSeed(scanSeed);
      final scanPubKey = await StealthUtils.getScanPublicKey(scanKeyPair);
      debugPrint('Stealth scan key initialized for wallet $walletId');
      debugPrint('Stealth meta-address: xstealth1${base58.encode(scanPubKey)}');
    }
  }

  /// Get the stealth meta-address for the active wallet (for receiving).
  static Future<StealthMetaAddress?> getStealthMetaAddress(
      String walletId) async {
    final scanKeyPair = await _loadScanKeyPair(walletId);
    if (scanKeyPair == null) return null;

    final scanPubKey = await StealthUtils.getScanPublicKey(scanKeyPair);
    return StealthMetaAddress(scanPublicKey: scanPubKey);
  }

  /// Send funds to a stealth meta-address.
  ///
  /// 1. Generates a one-time stealth address via ECDH
  /// 2. Sends funds to the one-time address
  /// 3. Posts an announcement so the receiver can discover the payment
  static Future<String?> sendToStealthAddress({
    required String senderWalletId,
    required String mnemonic,
    required String stealthMetaAddress,
    required double amount,
  }) async {
    requireSendingAvailable();
    final networkScope = NetworkConfig.cacheKey;
    final meta = StealthMetaAddress.decode(stealthMetaAddress);
    if (meta == null) throw Exception('Invalid stealth meta-address');

    // 1. Generate one-time stealth address via ECDH
    final payment =
        await StealthUtils.generateStealthPayment(meta.scanPublicKey);

    if (kDebugMode) {
      debugPrint('Stealth send: one-time address = ${payment.stealthAddress}');
      debugPrint(
          'Stealth send: ephemeral pubkey = ${base58.encode(payment.ephemeralPublicKey)}');
    }

    // 2. Send funds to the one-time stealth address
    requireSendingAvailable();
    if (NetworkConfig.cacheKey != networkScope) {
      throw StateError('Network changed. Review the transfer again.');
    }
    final txSignature = await WalletService.sendTransfer(
      mnemonic: mnemonic,
      destinationAddress: payment.stealthAddress,
      solAmount: amount,
      expectedNetworkScope: networkScope,
    );

    // 3. Create announcement
    final announcement = StealthAnnouncement(
      ephemeralPublicKey: base58.encode(payment.ephemeralPublicKey),
      stealthAddress: payment.stealthAddress,
      receiverScanPubKey: base58.encode(meta.scanPublicKey),
      txSignature: txSignature,
      timestamp: DateTime.now().millisecondsSinceEpoch ~/ 1000,
    );

    // 4. Post announcement (API + local backup)
    await _postAnnouncement(senderWalletId, announcement);

    return txSignature;
  }

  /// Scan for incoming stealth payments addressed to this wallet.
  static Future<List<DetectedStealthPayment>> scanForPayments(
      String walletId) async {
    final scanKeyPair = await _loadScanKeyPair(walletId);
    if (scanKeyPair == null) return [];

    final scanPubKey = await StealthUtils.getScanPublicKey(scanKeyPair);
    final scanPubKeyB58 = base58.encode(scanPubKey);

    // Fetch announcements from API
    final apiAnnouncements = await _fetchAnnouncements(scanPubKeyB58);

    // Also load locally stored announcements
    final localRaw = await StorageService.getStealthAnnouncementsRaw(walletId);
    final localAnnouncements =
        localRaw.map((e) => StealthAnnouncement.fromJson(e)).toList();

    // Merge and deduplicate by stealth_address
    final allAnnouncements = <String, StealthAnnouncement>{};
    for (final a in [...apiAnnouncements, ...localAnnouncements]) {
      allAnnouncements[a.stealthAddress] = a;
    }

    // For each announcement, verify it belongs to us and check balance
    final detected = <DetectedStealthPayment>[];
    for (final announcement in allAnnouncements.values) {
      try {
        final ephPubKey = base58.decode(announcement.ephemeralPublicKey);
        final isValid = await StealthUtils.verifyAnnouncement(
          scanKeyPair,
          ephPubKey,
          announcement.stealthAddress,
        );
        if (!isValid) continue;

        // Check balance at the stealth address
        final balance =
            await WalletService.getBalance(announcement.stealthAddress);
        if (balance > 0) {
          detected.add(DetectedStealthPayment(
            announcement: announcement,
            balance: balance,
          ));
        }
      } catch (e) {
        if (kDebugMode) debugPrint('Error checking stealth payment: $e');
      }
    }

    return detected;
  }

  /// Sweep (claim) funds from a stealth address back to the main wallet.
  static Future<String?> sweepStealthPayment({
    required String walletId,
    required StealthAnnouncement announcement,
    required String mainWalletAddress,
  }) async {
    final scanKeyPair = await _loadScanKeyPair(walletId);
    if (scanKeyPair == null) throw Exception('No stealth scan key found');

    // 1. Recover the one-time spending keypair
    final ephPubKey = base58.decode(announcement.ephemeralPublicKey);
    final stealthKeyPair =
        await StealthUtils.recoverStealthKeyPair(scanKeyPair, ephPubKey);
    if (stealthKeyPair == null) {
      throw Exception('Failed to recover stealth keypair');
    }

    // 2. Verify recovered address matches the announcement
    if (stealthKeyPair.address != announcement.stealthAddress) {
      throw Exception('Recovered address does not match announcement');
    }

    // 3. Get balance and calculate sweep amount (minus fee)
    final balance = await WalletService.getBalance(announcement.stealthAddress);
    const fee = 0.002; // 2,000,000 lamports
    if (balance <= fee) throw Exception('Balance too low to cover fee');

    final sweepAmountLamports = ((balance - fee) * 1e9).round();

    // 4. Build and submit sweep transaction using the stealth keypair
    final ixData = XerisApiService.buildNativeTransfer(
      from: announcement.stealthAddress,
      to: mainWalletAddress,
      amountLamports: sweepAmountLamports,
    );

    final txSignature = await XerisApiService.submitXerisInstruction(
      keyPair: stealthKeyPair,
      instructionData: ixData,
      extraAccounts: [
        AccountMeta.writeable(
          pubKey: Ed25519HDPublicKey.fromBase58(mainWalletAddress),
          isSigner: false,
        ),
      ],
    );

    // 5. Mark as swept in local storage
    if (txSignature != null) {
      await StorageService.markStealthSwept(
          walletId, announcement.stealthAddress);
    }

    return txSignature;
  }

  // --- Private helpers ---

  /// Post an announcement. Try the API first, always store locally as backup.
  static Future<void> _postAnnouncement(
      String walletId, StealthAnnouncement announcement) async {
    // Try posting to the control node's stealth endpoint
    try {
      await BaseApiService.post(
        '${NetworkConfig.controlUrl}/stealth/announce',
        announcement.toJson(),
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
            'Stealth API announcement failed (expected if endpoint not deployed): $e');
      }
    }

    // Always store locally so the sender has a record
    await StorageService.saveStealthAnnouncement(
        walletId, announcement.toJson());
  }

  /// Fetch announcements for a receiver scan pubkey from the API.
  static Future<List<StealthAnnouncement>> _fetchAnnouncements(
      String scanPubKeyB58) async {
    try {
      final data = await BaseApiService.get(
        '${NetworkConfig.controlUrl}/stealth/scan/$scanPubKeyB58',
      );
      if (data != null && data['announcements'] is List) {
        return (data['announcements'] as List)
            .map((e) => StealthAnnouncement.fromJson(e))
            .toList();
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
            'Stealth API scan failed (expected if endpoint not deployed): $e');
      }
    }
    return [];
  }

  /// Load the X25519 scan keypair from secure storage.
  static Future<cryptography.SimpleKeyPair?> _loadScanKeyPair(
      String walletId) async {
    final seedB58 = await StorageService.getStealthScanKey(walletId);
    if (seedB58 == null) return null;
    final seed = base58.decode(seedB58);
    return await cryptography.X25519().newKeyPairFromSeed(seed);
  }

  /// Extract the 32-byte wallet seed from a mnemonic or private key string.
  static List<int> _getWalletSeed(String mnemonic) {
    if (WalletService.isPrivateKeyWallet(mnemonic)) {
      // pk:<base58_seed> — decode the seed directly
      final encoded = mnemonic.substring(3); // skip "pk:"
      return base58.decode(encoded);
    }
    // BIP39 mnemonic → first 32 bytes of the 64-byte seed
    return bip39.mnemonicToSeed(mnemonic).sublist(0, 32);
  }
}
