import 'dart:typed_data';
import 'package:xeris_wallet/core/utils/bincode_utils.dart';

class AgentInstructionEncoder {
  static Uint8List buildRegisterAgent({
    required String agentName,
    required String agentPubkey,
    required int maxPerTxLamports,
    required int maxDailyLamports,
    List<String> allowedContracts = const [],
    List<String> allowedOperations = const ['NativeTransfer', 'ContractCall', 'WrapXrs', 'UnwrapXrs'],
    int expiresAtSlot = 0,
  }) {
    return Uint8List.fromList([
      ...encodeU32(15),
      ...encodeBincodeString(agentName),
      ...encodeBincodeString(agentPubkey),
      ...encodeU64(maxPerTxLamports),
      ...encodeU64(maxDailyLamports),
      ...encodeBincodeStringVec(allowedContracts),
      ...encodeBincodeStringVec(allowedOperations),
      ...encodeU64(expiresAtSlot),
    ]);
  }

  static Uint8List buildRevokeAgent(String agentPubkey) {
    return Uint8List.fromList([
      ...encodeU32(16),                          // UpdateAgent variant
      ...encodeBincodeString(agentPubkey),
      ...encodeNone(),                           // new_max_per_tx: None
      ...encodeNone(),                           // new_max_daily: None
      ...encodeNone(),                           // new_allowed_contracts: None
      ...encodeNone(),                           // new_allowed_operations: None
      ...encodeNone(),                           // new_expires_at_slot: None
      ...encodeBool(true),                       // revoked: true
    ]);
  }

  static Uint8List buildAgentExecute({
    required String ownerPubkey,
    required Uint8List innerInstruction,
  }) {
    return Uint8List.fromList([
      ...encodeU32(17),
      ...encodeBincodeString(ownerPubkey),
      ...encodeBincodeVec(innerInstruction),
    ]);
  }

  static Uint8List buildCreateIdentity({
    required String identityPubkey,
    required String displayName,
    String identityType = 'agent',
    String parentIdentity = '',
    String metadataJson = '{}',
  }) {
    return Uint8List.fromList([
      ...encodeU32(18),
      ...encodeBincodeString(identityPubkey),
      ...encodeBincodeString(displayName),
      ...encodeBincodeString(identityType),
      ...encodeBincodeString(parentIdentity),
      ...encodeBincodeString(metadataJson),
    ]);
  }

  static Uint8List buildAgentHeartbeat({
    required String identityPubkey,
    String currentModelHash = '',
    int activeTasks = 0,
    int availableCapacity = 10,
    String statusMessage = 'online',
  }) {
    return Uint8List.fromList([
      ...encodeU32(45),
      ...encodeBincodeString(identityPubkey),
      ...encodeBincodeString(currentModelHash),
      ...encodeU32(activeTasks),
      ...encodeU32(availableCapacity),
      ...encodeBincodeString(statusMessage),
    ]);
  }

  static Uint8List buildAttestReputation({
    required String subjectPubkey,
    required int score,             // 1 to 100
    required String category,
    String evidence = '',
  }) {
    final clampedScore = score.clamp(1, 100);
    return Uint8List.fromList([
      ...encodeU32(20),
      ...encodeBincodeString(subjectPubkey),
      ...encodeU8(clampedScore),
      ...encodeBincodeString(category),
      ...encodeBincodeString(evidence),
    ]);
  }
}
