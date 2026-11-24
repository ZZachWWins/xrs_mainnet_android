import 'package:xeris_wallet/core/services/xeris_api_service.dart';
import 'package:xeris_wallet/core/models/xeris_api_models.dart';
import 'package:xeris_wallet/core/services/wallet_service.dart';
import 'dart:math';

class StakingService {
  
  /// Fetches list of active validators.
  Future<List<XerisValidator>> getValidators() async {
    final response = await XerisApiService.getValidators();
    return response;
  }

  /// Takes XRS to a validator
  Future<String?> stake({
    required String mnemonic,
    required String validatorAddress,
    required double amount,
  }) async {
    final int amountBase = (amount * pow(10, 9)).round();
    final keyPair = await WalletService.getKeyPair(mnemonic);

    return await XerisApiService.stakeXrs(
      keyPair: keyPair,
      validatorAddress: validatorAddress,
      amountLamports: amountBase,
    );
  }

  /// Unstakes XRS
  Future<String?> unstake({
    required String mnemonic,
    required String validatorAddress,
    required double amount,
  }) async {
    final int amountBase = (amount * pow(10, 9)).round();
    final keyPair = await WalletService.getKeyPair(mnemonic);

    return await XerisApiService.unstakeXrs(
      keyPair: keyPair,
      validatorAddress: validatorAddress,
      amountLamports: amountBase,
    );
  }
}
