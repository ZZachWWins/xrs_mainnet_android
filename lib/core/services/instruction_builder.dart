import 'dart:convert';
import 'dart:typed_data';
import 'package:xeris_wallet/core/utils/bincode_utils.dart';

/// Centralized class for building Bincode-encoded instructions for the Xeris blockchain.
class InstructionBuilder {
  
  static Uint8List buildWrapInstruction({required int amountLamports}) {
    return Uint8List.fromList([
      ...encodeU32(13), // variant index 13 for Wrap
      ...encodeU64(amountLamports),
    ]);
  }

  static Uint8List buildUnwrapInstruction({required int amountLamports}) {
    return Uint8List.fromList([
      ...encodeU32(14), // variant index 14 for Unwrap
      ...encodeU64(amountLamports),
    ]);
  }  static Uint8List buildSwapInstruction({
    required String poolId,
    required String direction,
    required int inputAmount,
    required int minOutput,
  }) {
    final argsBuffer = ByteData(16);
    argsBuffer.setUint64(0, inputAmount, Endian.little);
    argsBuffer.setUint64(8, minOutput, Endian.little);

    return Uint8List.fromList([
      ...encodeU32(4), // variant index 4 (ContractCall positional for Swap)
      ...encodeBincodeString(poolId),
      ...encodeBincodeString(direction),
      ...encodeBincodeVec(argsBuffer.buffer.asUint8List()),
    ]);
  }

  static void _requireLiquidityU64(BigInt value, String name) {
    if (value <= BigInt.zero || value >= (BigInt.one << 64)) {
      throw ArgumentError.value(value, name, 'Must be a positive u64');
    }
  }

  static Uint8List buildAddLiquidityInstruction({
    required String poolId,
    required BigInt amountA,
    required BigInt amountB,
    required BigInt minLpShares,
    required BigInt minAmountA,
    required BigInt minAmountB,
  }) {
    for (final entry in {
      'amount_a': amountA,
      'amount_b': amountB,
      'min_lp_shares': minLpShares,
      'min_amount_a': minAmountA,
      'min_amount_b': minAmountB,
    }.entries) {
      _requireLiquidityU64(entry.value, entry.key);
    }
    if (minAmountA > amountA || minAmountB > amountB) {
      throw ArgumentError('Liquidity minima cannot exceed deposit maxima');
    }
    // BigInt decimal interpolation emits exact JSON numbers without rounding.
    final jsonStr = '{"amount_a":$amountA,"amount_b":$amountB,'
        '"min_lp_shares":$minLpShares,"min_amount_a":$minAmountA,'
        '"min_amount_b":$minAmountB}';
    return buildContractCallInstruction(
      contractId: poolId,
      method: 'add_liquidity',
      args: Uint8List.fromList(utf8.encode(jsonStr)),
    );
  }

  static Uint8List buildRemoveLiquidityInstruction({
    required String poolId,
    required BigInt shares,
    required BigInt minAmountA,
    required BigInt minAmountB,
  }) {
    for (final entry in {
      'shares': shares,
      'min_amount_a': minAmountA,
      'min_amount_b': minAmountB,
    }.entries) {
      _requireLiquidityU64(entry.value, entry.key);
    }
    final jsonStr = '{"shares":$shares,"min_amount_a":$minAmountA,'
        '"min_amount_b":$minAmountB}';
    return buildContractCallInstruction(
      contractId: poolId,
      method: 'remove_liquidity',
      args: Uint8List.fromList(utf8.encode(jsonStr)),
    );
  }

  static Uint8List buildStakingInstruction({required String validatorAddress, required int amountLamports}) {
    return Uint8List.fromList([
      ...encodeU32(9), // variant index 9 for Stake
      ...encodeBincodeString(validatorAddress),
      ...encodeU64(amountLamports),
    ]);
  }

  static Uint8List buildUnstakingInstruction({required String validatorAddress, required int amountLamports}) {
    return Uint8List.fromList([
      ...encodeU32(10), // variant index 10 for Unstake
      ...encodeBincodeString(validatorAddress),
      ...encodeU64(amountLamports),
    ]);
  }

  static Uint8List buildPqKeyRegisterInstruction({
    required String ed25519Pubkey,
    required Uint8List pqPublicKey,
    String pqAlgorithm = 'dilithium3',
    int securityLevel = 3,
  }) {
    return Uint8List.fromList([
      ...encodeU32(50), // variant index 50 for PQ Register
      ...encodeBincodeString(ed25519Pubkey),
      ...encodeBincodeVec(pqPublicKey),
      ...encodeBincodeString(pqAlgorithm),
      ...encodeU8(securityLevel),
    ]);
  }

  static Uint8List buildPqSignedTransferInstruction({
    required String from,
    required String to,
    required int amountLamports,
    required Uint8List pqSignature,
    String pqAlgorithm = 'dilithium3',
  }) {
    return Uint8List.fromList([
      ...encodeU32(52), // variant index 52 for PQ Signed Transfer
      ...encodeBincodeString(from),
      ...encodeBincodeString(to),
      ...encodeU64(amountLamports),
      ...encodeBincodeVec(pqSignature),
      ...encodeBincodeString(pqAlgorithm),
    ]);
  }

  static Uint8List buildNativeTransferInstruction({
    required String from,
    required String to,
    required int amountLamports,
  }) {
    return Uint8List.fromList([
      ...encodeU32(11), // variant index 11 for NativeTransfer
      ...encodeBincodeString(from),
      ...encodeBincodeString(to),
      ...encodeU64(amountLamports),
    ]);
  }

  static Uint8List buildZkPrivateTransferInstruction({
    required String tokenId,
    required String from,
    required String to,
    required Uint8List commitment,
    required Uint8List rangeProof,
    required Uint8List balanceProof,
    required Uint8List nullifier,
  }) {
    return Uint8List.fromList([
      ...encodeU32(48), // variant index 48 for ZK Private Transfer
      ...encodeBincodeString(tokenId),
      ...encodeBincodeString(from),
      ...encodeBincodeString(to),
      ...encodeBincodeVec(commitment),
      ...encodeBincodeVec(rangeProof),
      ...encodeBincodeVec(balanceProof),
      ...encodeBincodeVec(nullifier),
    ]);
  }

  static Uint8List buildContractCallInstruction({
    required String contractId,
    required String method,
    required Uint8List args,
  }) {
    return Uint8List.fromList([
      ...encodeU32(4), // variant index 4 for ContractCall
      ...encodeBincodeString(contractId),
      ...encodeBincodeString(method),
      ...encodeBincodeVec(args),
    ]);
  }

  static Uint8List buildContractDeployInstruction({
    required String contractId,
    required String contractType,
    required String paramsJson,
  }) {
    return Uint8List.fromList([
      ...encodeU32(5), // variant index 5 for ContractDeploy
      ...encodeBincodeString(contractId),
      ...encodeBincodeString(contractType),
      ...encodeBincodeString(paramsJson),
    ]);
  }

  // ══════════════════════════════════════════════════════════════
  // TOKEN VARIANTS (Consolidated)
  // ══════════════════════════════════════════════════════════════

  static Uint8List buildTokenTransferInstruction({
    required String tokenId,
    required String from,
    required String to,
    required int amount,
  }) {
    return Uint8List.fromList([
      ...encodeU32(1), // TokenTransfer
      ...encodeBincodeString(tokenId),
      ...encodeBincodeString(from),
      ...encodeBincodeString(to),
      ...encodeU64(amount),
    ]);
  }

  static Uint8List buildTokenMintInstruction({
    required String tokenId,
    required String to,
    required int amount,
  }) {
    return Uint8List.fromList([
      ...encodeU32(0), // TokenMint
      ...encodeBincodeString(tokenId),
      ...encodeBincodeString(to),
      ...encodeU64(amount),
    ]);
  }

  static Uint8List buildTokenBurnInstruction({
    required String tokenId,
    required String from,
    required int amount,
  }) {
    return Uint8List.fromList([
      ...encodeU32(2), // TokenBurn
      ...encodeBincodeString(tokenId),
      ...encodeBincodeString(from),
      ...encodeU64(amount),
    ]);
  }

  static Uint8List buildTokenCreateInstruction({
    required String tokenId,
    required String name,
    required String symbol,
    required int decimals,
    required int maxSupply,
    required String mintAuthority,
  }) {
    return Uint8List.fromList([
      ...encodeU32(3), // TokenCreate
      ...encodeBincodeString(tokenId),
      ...encodeBincodeString(name),
      ...encodeBincodeString(symbol),
      ...encodeU8(decimals),
      ...encodeU64(maxSupply),
      ...encodeBincodeString(mintAuthority),
    ]);
  }

  // ══════════════════════════════════════════════════════════════
  // AGENT VARIANTS
  // ══════════════════════════════════════════════════════════════

  static Uint8List buildRegisterAgentInstruction({
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

  static Uint8List buildUpdateAgentInstruction({
    required String agentPubkey,
    int? newMaxPerTx,
    int? newMaxDaily,
    List<String>? newAllowedContracts,
    List<String>? newAllowedOperations,
    int? newExpiresAtSlot,
    bool revoked = false,
  }) {
    return Uint8List.fromList([
      ...encodeU32(16),
      ...encodeBincodeString(agentPubkey),
      ...(newMaxPerTx != null ? encodeSomeU64(newMaxPerTx) : encodeNone()),
      ...(newMaxDaily != null ? encodeSomeU64(newMaxDaily) : encodeNone()),
      ...(newAllowedContracts != null ? encodeSomeStringVec(newAllowedContracts) : encodeNone()),
      ...(newAllowedOperations != null ? encodeSomeStringVec(newAllowedOperations) : encodeNone()),
      ...(newExpiresAtSlot != null ? encodeSomeU64(newExpiresAtSlot) : encodeNone()),
      ...encodeBool(revoked),
    ]);
  }

  static Uint8List buildAgentExecuteInstruction({
    required String ownerPubkey,
    required Uint8List innerInstruction,
  }) {
    return Uint8List.fromList([
      ...encodeU32(17),
      ...encodeBincodeString(ownerPubkey),
      ...encodeBincodeVec(innerInstruction),
    ]);
  }

  static Uint8List buildCreateIdentityInstruction({
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

  static Uint8List buildAttestReputationInstruction({
    required String subjectPubkey,
    required int score,
    required String category,
    String evidence = '',
  }) {
    return Uint8List.fromList([
      ...encodeU32(20),
      ...encodeBincodeString(subjectPubkey),
      ...encodeU8(score.clamp(1, 100)),
      ...encodeBincodeString(category),
      ...encodeBincodeString(evidence),
    ]);
  }

  static Uint8List buildAgentHeartbeatInstruction({
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

  static Uint8List buildClaimTaskInstruction({
    required String taskId,
    required String claimantIdentity,
  }) {
    if (taskId.isEmpty || claimantIdentity.isEmpty) {
      throw ArgumentError('Task ID and signing claimant identity are required');
    }
    return Uint8List.fromList([
      ...encodeU32(32), // ClaimTask { task_id, claimant_identity }
      ...encodeBincodeString(taskId),
      ...encodeBincodeString(claimantIdentity),
    ]);
  }
}
