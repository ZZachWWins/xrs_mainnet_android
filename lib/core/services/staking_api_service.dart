import 'package:solana/solana.dart';
import 'package:xeris_wallet/core/services/base_api_service.dart';
import 'package:xeris_wallet/core/config/network_config.dart';
import 'package:xeris_wallet/core/services/xeris_api_service.dart';

class StakingApiService extends BaseApiService {
  
  static void _requireSelfStake(
    Ed25519HDKeyPair keyPair,
    String validatorAddress,
  ) {
    if (validatorAddress != keyPair.address) {
      throw UnsupportedError(
        'This node supports staking only for the signing account, not '
        'delegation to another validator. Public self-staking is restricted '
        'to approved producers during the federated beta.',
      );
    }
  }

  /// Stakes the signing account. The node enforces the producer roster.
  static Future<String?> stakeXrs({
    required Ed25519HDKeyPair keyPair,
    required String validatorAddress,
    required int amountLamports,
  }) async {
    _requireSelfStake(keyPair, validatorAddress);
    final ixData = XerisApiService.buildStakingInstruction(
      validatorAddress: validatorAddress, 
      amountLamports: amountLamports,
    );
    return await XerisApiService.submitXerisInstruction(
      keyPair: keyPair, 
      instructionData: ixData,
      endpoint: '/stake',
    );
  }

  /// Unstakes XRS
  static Future<String?> unstakeXrs({
    required Ed25519HDKeyPair keyPair,
    required String validatorAddress,
    required int amountLamports,
  }) async {
    _requireSelfStake(keyPair, validatorAddress);
    final ixData = XerisApiService.buildUnstakingInstruction(
      validatorAddress: validatorAddress, 
      amountLamports: amountLamports,
    );
    return await XerisApiService.submitXerisInstruction(
      keyPair: keyPair, 
      instructionData: ixData,
      endpoint: '/unstake',
    );
  }

  /// Fetches registered agents for a specific owner via REST.
  static Future<dynamic> getAgentsRegistry(String ownerAddress) async {
    return await BaseApiService.get('${NetworkConfig.controlUrl}/agent/registry/$ownerAddress');
  }

  /// Fetches open tasks on the network via REST.
  static Future<dynamic> getOpenTasks() async {
    return await BaseApiService.get('${NetworkConfig.controlUrl}/tasks');
  }
}
