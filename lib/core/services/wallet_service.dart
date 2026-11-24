import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:bip39/bip39.dart' as bip39;
import 'package:solana/solana.dart';
import 'package:solana/encoder.dart';
import 'package:bs58/bs58.dart';
import 'package:xeris_wallet/core/models/transaction_model.dart';
import 'package:xeris_wallet/core/services/xeris_api_service.dart';
import 'package:xeris_wallet/core/services/base_api_service.dart';
import 'package:xeris_wallet/core/config/network_config.dart';
import 'dart:math';

class WalletService {
  // Cache derived key pairs to avoid re-running expensive BIP39 derivation
  static final Map<String, Ed25519HDKeyPair> _keyPairCache = {};

  /// Clears the key pair cache (call on wallet switch/delete).
  static void clearKeyPairCache() => _keyPairCache.clear();

  /// Generates a random 12-word mnemonic phrase.
  static List<String> generateMnemonic() {
    final String mnemonic = bip39.generateMnemonic();
    return mnemonic.split(' ');
  }

  /// Normalizes a mnemonic phrase by trimming and collapsing multiple whitespaces.
  static String _normalizeMnemonic(String mnemonic) {
    return mnemonic.trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  static bool validateMnemonic(String mnemonic) {
    return bip39.validateMnemonic(_normalizeMnemonic(mnemonic));
  }

  /// Validates a Solana/Xeris address (Ed25519 public key).

  static bool isValidAddress(String address) {
    try {
      Ed25519HDPublicKey.fromBase58(address);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Prefix used to identify private-key-imported wallets in storage.
  static const _pkPrefix = 'pk:';

  /// Returns true if [stored] represents a private-key wallet (not a mnemonic).
  static bool isPrivateKeyWallet(String stored) => stored.startsWith(_pkPrefix);

  /// Validates a raw private key input from the user.
  /// Accepts:
  ///   - Base58-encoded 64-byte keypair (Phantom / Solana CLI export)
  ///   - Base58-encoded 32-byte seed
  ///   - Hex string of 64 chars (32 bytes)
  static bool validatePrivateKey(String input) {
    final trimmed = input.trim();
    try {
      final seed = _extractSeedBytes(trimmed);
      return seed.length == 32;
    } catch (_) {
      return false;
    }
  }

  /// Returns the wallet address for a given raw private key input.
  static Future<String> getAddressFromPrivateKey(String input) async {
    final keyPair = await getKeyPairFromPrivateKeyInput(input.trim());
    return keyPair.address;
  }

  /// Derives a keypair from a raw private key input (base58 64-byte, base58 32-byte, or hex).
  static Future<Ed25519HDKeyPair> getKeyPairFromPrivateKeyInput(
      String input) async {
    final seed = _extractSeedBytes(input.trim());
    return Ed25519HDKeyPair.fromPrivateKeyBytes(privateKey: seed);
  }

  /// Encodes a raw private key input into the storage format (pk:base58_seed).
  static String encodePrivateKeyForStorage(String input) {
    final seed = _extractSeedBytes(input.trim());
    return '$_pkPrefix${base58.encode(Uint8List.fromList(seed))}';
  }

  /// Extracts the 32-byte seed from the user-provided input string.
  static List<int> _extractSeedBytes(String input) {
    // Try hex: exactly 64 hex chars → 32 bytes
    if (RegExp(r'^[0-9a-fA-F]{64}$').hasMatch(input)) {
      return _hexToBytes(input);
    }
    // Try base58: decode and take first 32 bytes
    final bytes = base58.decode(input);
    if (bytes.length == 64 || bytes.length == 32) {
      return bytes.sublist(0, 32);
    }
    throw const FormatException('Invalid private key format');
  }

  /// Derives an Ed25519HDKeyPair from a mnemonic phrase using the
  /// specific "raw entropy" method (first 32 bytes of the BIP39 seed).
  /// Also handles private-key wallets stored with the "pk:" prefix.
  static Future<Ed25519HDKeyPair> getKeyPair(String mnemonic) async {
    final cacheKey = mnemonic;
    if (_keyPairCache.containsKey(cacheKey)) {
      return _keyPairCache[cacheKey]!;
    }

    // Handle private-key wallets
    if (isPrivateKeyWallet(mnemonic)) {
      final encoded = mnemonic.substring(_pkPrefix.length);
      final seed = base58.decode(encoded);
      final keyPair =
          await Ed25519HDKeyPair.fromPrivateKeyBytes(privateKey: seed);
      _keyPairCache[cacheKey] = keyPair;
      return keyPair;
    }

    final normalized = _normalizeMnemonic(mnemonic);
    // Run CPU-intensive derivation in an isolate
    final List<int> seed = await compute(_deriveSeed, normalized);
    final first32Bytes = seed.sublist(0, 32);

    final keyPair = await Ed25519HDKeyPair.fromPrivateKeyBytes(
      privateKey: first32Bytes,
    );

    _keyPairCache[cacheKey] = keyPair;

    if (kDebugMode) {
      debugPrint('Derived address (Raw Entropy Method): ${keyPair.address}');
    }
    return keyPair;
  }

  /// Top-level function for compute
  static List<int> _deriveSeed(String mnemonic) {
    return bip39.mnemonicToSeed(mnemonic);
  }

  /// Canonical seed bytes used as input keying material for deriving this
  /// wallet's deterministic post-quantum (ML-DSA-65) key. Mirrors getKeyPair's
  /// seed derivation so the PQ key is bound to the same wallet and reproduces on
  /// any device that imports the same recovery phrase / private key.
  /// Private-key wallets -> the 32-byte key; mnemonic wallets -> the BIP39 seed.
  static Future<List<int>> pqSeedMaterial(String mnemonic) async {
    if (isPrivateKeyWallet(mnemonic)) {
      final encoded = mnemonic.substring(_pkPrefix.length);
      return base58.decode(encoded);
    }
    final normalized = _normalizeMnemonic(mnemonic);
    return await compute(_deriveSeed, normalized);
  }

  /// Fetches XRS using the API service's bounded request budget.
  /// A failed lookup is unavailable data, never a confirmed zero balance.
  /// [retries] remains accepted for callers; the API service owns that budget.
  static Future<double> getBalance(String address, {int retries = 2}) =>
      XerisApiService.getBalance(address);

  /// Sends a native XRS transfer using XerisInstruction::NativeTransfer (variant 11).
  /// This replaces the legacy SystemInstruction::Transfer path which is sunset
  /// after LEGACY_TRANSFER_SUNSET_SLOT on the Xeris chain.
  static Future<String?> sendTransfer({
    required String mnemonic,
    required String destinationAddress,
    required double solAmount,
    String? expectedNetworkScope,
  }) async {
    try {
      if (expectedNetworkScope != null &&
          expectedNetworkScope != NetworkConfig.cacheKey) {
        throw StateError('Network changed. Review the transfer again.');
      }
      if (!solAmount.isFinite || solAmount <= 0) {
        throw Exception('Invalid transfer amount');
      }
      if (solAmount > 9000000000) {
        throw Exception('Amount exceeds total supply and would cause overflow');
      }
      final keyPair = await getKeyPair(mnemonic);
      final lamports = (solAmount * 1000000000).round();
      if (lamports < 0 || lamports > 9007199254740992) {
        throw Exception(
            'Amount has too many significant digits to send precisely.');
      }

      final ixData = XerisApiService.buildNativeTransfer(
        from: keyPair.address,
        to: destinationAddress,
        amountLamports: lamports,
      );

      return await XerisApiService.submitXerisInstruction(
        keyPair: keyPair,
        instructionData: ixData,
        expectedNetworkScope: expectedNetworkScope,
        extraAccounts: [
          AccountMeta.writeable(
              pubKey: Ed25519HDPublicKey.fromBase58(destinationAddress),
              isSigner: false),
        ],
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error sending native transfer: $e');
      }
      rethrow;
    }
  }

  /// Submits an already-signed transaction once to the control API.
  /// A timeout is not proof of rejection; callers must check its signature
  /// before deciding whether to submit again.
  static Future<String?> submitTransaction(String txBase64) async {
    final data = await BaseApiService.post(
      '${NetworkConfig.controlUrl}/submit',
      {'tx_base64': txBase64},
      timeout: const Duration(seconds: 25),
    );
    if (data is Map && (data['status'] == 'ok' || data['status'] == 'queued')) {
      final signature = data['signature'];
      if (signature is String && signature.isNotEmpty) return signature;
    }
    throw ApiException(
      message: 'The node did not return an accepted transaction signature. '
          'Check the transaction status before submitting again.',
      type: ApiErrorType.rpc,
    );
  }

  /// Fetches transaction history for the given address via Node RPC.
  static Future<List<TransactionModel>> getTransactions(String address) async {
    try {
      // 1. Get recent signatures for the address from RPC.
      // The Xeris node returns enriched transaction info in this call.
      final List<dynamic> signaturesResult =
          await XerisApiService.getSignaturesForAddress(address, limit: 20);

      if (signaturesResult.isEmpty) return [];

      return signaturesResult.map((tx) {
        final String signature = tx['signature'] ?? '';
        final dynamic rawBlockTime =
            tx['blockTime'] ?? tx['block_time'] ?? tx['timestamp'];
        final int timestamp = (rawBlockTime is num)
            ? rawBlockTime.toInt()
            : (DateTime.now().millisecondsSinceEpoch ~/ 1000);

        // Use UTC for consistency across app and server
        final String date =
            DateTime.fromMillisecondsSinceEpoch(timestamp * 1000, isUtc: true)
                .toIso8601String();

        final String rawType = tx['type']?.toString().toLowerCase() ?? 'sent';
        final TransactionType type = rawType == 'received'
            ? TransactionType.receive
            : TransactionType.send;

        // Find other party based on transaction direction
        final String otherParty = type == TransactionType.receive
            ? (tx['from']?.toString() ?? '')
            : (tx['to']?.toString() ?? '');

        // Determine symbol and amount
        String symbol = 'XRS';
        if (tx['details'] != null && tx['details']['token'] != null) {
          symbol = tx['details']['token'].toString().toUpperCase();
        }

        final double amount = (tx['amount_xrs'] != null)
            ? (tx['amount_xrs'] as num).toDouble()
            : 0.0;
        final TransactionStatus status = (tx['err'] == null)
            ? TransactionStatus.confirmed
            : TransactionStatus.failed;

        return TransactionModel(
          id: signature,
          date: date,
          amount: amount,
          symbol: symbol,
          type: type,
          status: status,
          otherPartyAddress: otherParty,
        );
      }).toList();
    } catch (e) {
      debugPrint('Error fetching transactions from RPC: $e');
      return [];
    }
  }

  /// Fetches the balance of a specific token (e.g. 'xeris_usdc').
  static Future<double> getTokenBalance(String address, String tokenId,
      {int decimals = 9}) async {
    // debugPrint('Fetching token balance for $tokenId at $address');
    try {
      final rawBalance =
          await XerisApiService.getTokenBalance(address, tokenId);
      final balance = rawBalance?.balance ?? 0;
      return balance / pow(10, decimals);
    } catch (e) {
      debugPrint('Error fetching token balance: $e');
      return 0.0;
    }
  }

  /// Sends a token transfer.
  static Future<String?> sendTokenTransfer({
    required String mnemonic,
    required String destinationAddress,
    required String tokenId,
    required double amount,
    int? decimals,
  }) async {
    try {
      final keyPair = await getKeyPair(mnemonic);
      final effectiveDecimals = decimals ?? NetworkConfig.tokenDecimals;
      final rawAmount = (amount * pow(10, effectiveDecimals)).round();

      final ixData = XerisApiService.buildTokenTransfer(
        tokenId: tokenId,
        from: keyPair.address,
        to: destinationAddress,
        amount: rawAmount,
      );

      return await XerisApiService.submitXerisInstruction(
        keyPair: keyPair,
        instructionData: ixData,
        extraAccounts: [
          AccountMeta.writeable(
              pubKey: Ed25519HDPublicKey.fromBase58(destinationAddress),
              isSigner: false),
        ],
      );
    } catch (e) {
      debugPrint('Error sending token transfer: $e');
      rethrow;
    }
  }

  /// Fetches a real recent blockhash; never signs with a fabricated fallback.
  /// The node returns hex, while the Solana message encoder expects base58.
  static Future<String> getRecentBlockhash() async {
    final result = await BaseApiService.callRpc('getLatestBlockhash');
    final value = result is Map ? result['value'] : null;
    final raw = value is Map ? value['blockhash'] : null;
    if (raw is! String || raw.isEmpty) {
      throw ApiException(
        message: 'A recent blockhash is unavailable. Wait for a mined block '
            'and try again.',
        type: ApiErrorType.rpc,
      );
    }

    var blockhash = raw;
    if (RegExp(r'^(?:0x)?[0-9a-fA-F]{64}$').hasMatch(raw)) {
      blockhash = base58.encode(Uint8List.fromList(_hexToBytes(raw)));
    }
    try {
      final bytes = base58.decode(blockhash);
      if (bytes.length != 32 || bytes.every((byte) => byte == 0)) {
        throw const FormatException('Invalid recent blockhash');
      }
    } catch (error) {
      throw ApiException(
        message: 'The node returned an invalid recent blockhash.',
        type: ApiErrorType.rpc,
        originalError: error,
      );
    }
    return blockhash;
  }

  /// Helper to convert a hex string to byte array
  static List<int> _hexToBytes(String hexString) {
    var cleanHex =
        hexString.startsWith('0x') ? hexString.substring(2) : hexString;
    List<int> bytes = [];
    for (int i = 0; i < cleanHex.length; i += 2) {
      String byteString = cleanHex.substring(i, i + 2);
      bytes.add(int.parse(byteString, radix: 16));
    }
    return bytes;
  }

  /// Signs a base64 encoded transaction from a dApp
  static Future<Map<String, String>> signDAppTransaction({
    required String mnemonic,
    required String txBase64,
  }) async {
    try {
      final keyPair = await getKeyPair(mnemonic);
      final txBytes = base64Decode(txBase64);

      if (txBytes.isEmpty) throw Exception('Empty transaction bytes');

      final numSigs = txBytes[0];
      final messageOffset = 1 + (numSigs * 64);

      if (txBytes.length <= messageOffset) {
        throw Exception('Invalid transaction format');
      }

      final messageBytes = txBytes.sublist(messageOffset);
      final signature = await keyPair.sign(messageBytes);

      final signedTx = Uint8List.fromList(txBytes);
      signedTx.setRange(1, 1 + 64, signature.bytes);

      return {
        'signature': signature.toBase58(),
        'signedTxBase64': base64Encode(signedTx),
      };
    } catch (e) {
      debugPrint('Error signing dApp transaction: $e');
      rethrow;
    }
  }

  /// Signs an arbitrary message from a dApp
  static Future<String> signDAppMessage({
    required String mnemonic,
    required Uint8List message,
  }) async {
    try {
      final keyPair = await getKeyPair(mnemonic);
      final signature = await keyPair.sign(message);
      return base64Encode(signature.bytes);
    } catch (e) {
      debugPrint('Error signing dApp message: $e');
      rethrow;
    }
  }
}
