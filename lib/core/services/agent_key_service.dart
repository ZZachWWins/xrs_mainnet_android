import 'dart:math';
import 'dart:typed_data';
import 'package:bs58/bs58.dart';
import 'package:solana/solana.dart';
import 'package:xeris_wallet/core/services/storage_service.dart';

class AgentKeyService {

  /// Generates a new Ed25519 agent keypair and saves it to secure storage.
  /// Returns the keypair. The public key (base58) is the agent's identity.
  static Future<Ed25519HDKeyPair> generateAndSave(String walletId) async {
    final rng = Random.secure();
    final seed = Uint8List(32);
    for (int i = 0; i < 32; i++) {
      seed[i] = rng.nextInt(256);
    }

    final keyPair = await Ed25519HDKeyPair.fromPrivateKeyBytes(privateKey: seed);
    final pubkeyBase58 = keyPair.address;
    final seedBase58 = base58.encode(seed);

    await StorageService.saveAgentSeed(walletId, pubkeyBase58, seedBase58);
    return keyPair;
  }

  /// Retrieves an agent keypair from storage by its public key.
  static Future<Ed25519HDKeyPair?> getKeyPair(String walletId, String agentPubkey) async {
    final seedBase58 = await StorageService.getAgentSeed(walletId, agentPubkey);
    if (seedBase58 == null) return null;

    final seed = base58.decode(seedBase58);
    return Ed25519HDKeyPair.fromPrivateKeyBytes(privateKey: seed);
  }

  /// Returns all agent public keys that have locally stored seeds for this wallet.
  static Future<List<String>> getStoredPubkeys(String walletId) async {
    return StorageService.getAgentPubkeysForWallet(walletId);
  }

  /// Checks if an agent key exists locally.
  static Future<bool> hasLocalKey(String walletId, String agentPubkey) async {
    final seed = await StorageService.getAgentSeed(walletId, agentPubkey);
    return seed != null;
  }

  /// Deletes an agent key from storage.
  static Future<void> deleteKey(String walletId, String agentPubkey) async {
    await StorageService.deleteAgentSeed(walletId, agentPubkey);
  }
}
