import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:xeris_wallet/core/config/network_config.dart';
import 'package:xeris_wallet/core/services/xeris_api_service.dart';
import 'package:xeris_wallet/core/services/wallet_service.dart';
import 'package:xeris_wallet/core/services/storage_service.dart';
import 'package:xeris_wallet/core/services/instruction_builder.dart';
import 'package:xeris_wallet/core/services/ffi_bridge.dart';
import 'package:flutter/foundation.dart';

class PqcService {
  /// Legacy random keygen. Kept for compatibility; new enables use the
  /// deterministic, seed-derived path so the PQ key follows the wallet.
  static Future<DilithiumKeypair> generatePqcKeypair() async {
    return await compute((_) => FfiBridge.dilithiumKeygen(), null);
  }

  /// Deterministically derive this wallet's ML-DSA-65 keypair from its seed.
  /// Same recovery phrase -> same PQ key on every device. The 32-byte keygen
  /// seed is derived inside the FFI via HKDF-SHA256 with domain separation.
  static Future<DilithiumKeypair> derivePqcKeypair(String mnemonic) async {
    final seed = await WalletService.pqSeedMaterial(mnemonic);
    final seedBytes = Uint8List.fromList(seed);
    return await compute(
      (Uint8List s) => FfiBridge.dilithiumKeygenFromSeed(s),
      seedBytes,
    );
  }

  /// Ensures the seed-derived PQ secret key is present in local storage,
  /// re-deriving it if this device doesn't have it yet (e.g. fresh install of
  /// an already-PQ-enabled wallet). Returns the keypair.
  static Future<DilithiumKeypair> ensureLocalKey(String mnemonic) async {
    final kp = await derivePqcKeypair(mnemonic);
    await StorageService.savePqKeys(
      base64Encode(kp.publicKey), base64Encode(kp.secretKey));
    return kp;
  }

  static Future<bool> registerPqcOnChain({
    required String mnemonic,
    required Uint8List pqPk,
    required Uint8List pqSk,
  }) async {
    try {
      final keyPair = await XerisApiService.getKeyPair(mnemonic);
      final ixData = InstructionBuilder.buildPqKeyRegisterInstruction(
        ed25519Pubkey: keyPair.address,
        pqPublicKey: pqPk,
      );

      final signature = await XerisApiService.submitXerisInstruction(
        keyPair: keyPair,
        instructionData: ixData,
      );

      if (signature != null) {
        await StorageService.savePqKeys(base64Encode(pqPk), base64Encode(pqSk));
        await StorageService.setPqProtectionActive(true);
        return true;
      }
    } catch (e) {
      if (kDebugMode) print('Error registering PQC: $e');
    }
    return false;
  }

  /// Derives the wallet's ML-DSA-65 keypair from the seed and registers it
  /// on-chain. Deterministic, so the same phrase enables the same key anywhere.
  static Future<bool> enableQuantumProtection({
    required String mnemonic,
  }) async {
    final keypair = await derivePqcKeypair(mnemonic);
    return await registerPqcOnChain(
      mnemonic: mnemonic,
      pqPk: keypair.publicKey,
      pqSk: keypair.secretKey,
    );
  }

  /// Source of truth for whether PQ protection is enabled for an *account*:
  /// the on-chain registry. This makes Quantum Shield follow the wallet across
  /// devices (registering on one device shows enabled on any other). Falls back
  /// to the local flag if the node is unreachable.
  static Future<bool> isPqcEnabledOnChain(String address) async {
    try {
      final resp = await http
          .get(Uri.parse('${NetworkConfig.controlUrl}/pq/keys/$address'))
          .timeout(const Duration(seconds: 6));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        return data['has_pq_key'] == true;
      }
    } catch (e) {
      if (kDebugMode) print('PQ on-chain status check failed: $e');
    }
    return await StorageService.isQuantumProtected();
  }

  static const transferUnavailableMessage =
      'Post-quantum transfers are unavailable on the current node. '
      'The legacy transfer format is disabled; no transaction was sent.';

  /// The current node disables legacy PqSignedTransfer (variant 52).
  /// Fail before loading keys or signing, and never downgrade to a plain send.
  static Future<String?> sendPqTransfer({
    required String mnemonic,
    required String to,
    required double amount,
  }) async {
    throw UnsupportedError(transferUnavailableMessage);
  }

  static Future<bool> isPqcEnabled() async {
    return await StorageService.isQuantumProtected();
  }
}
