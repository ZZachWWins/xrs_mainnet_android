import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xeris_wallet/core/models/xeris_api_models.dart';
import 'package:xeris_wallet/core/providers/wallet_provider.dart';
import 'package:xeris_wallet/core/services/storage_service.dart';
import 'package:xeris_wallet/features/wallet_actions/services/staking_service.dart';
import 'package:xeris_wallet/core/utils/string_extensions.dart';

final stakingServiceProvider = Provider<StakingService>((ref) => StakingService());

// State for fetching validators and staking
class StakingState {
  final bool isLoading;
  final String? error;
  final String? resultMessage;
  final List<XerisValidator> validators;
  final XerisValidator? selectedValidator;

  const StakingState({
    this.isLoading = false,
    this.error,
    this.resultMessage,
    this.validators = const [],
    this.selectedValidator,
  });

  StakingState copyWith({
    bool? isLoading,
    String? error,
    String? resultMessage,
    List<XerisValidator>? validators,
    XerisValidator? selectedValidator,
  }) {
    return StakingState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      resultMessage: resultMessage,
      validators: validators ?? this.validators,
      selectedValidator: selectedValidator ?? this.selectedValidator,
    );
  }
}

class StakingNotifier extends Notifier<StakingState> {
  @override
  StakingState build() {
    // Initial fetch
    Future.microtask(() => fetchValidators());
    return const StakingState();
  }

  StakingService get _service => ref.read(stakingServiceProvider);

  Future<void> fetchValidators() async {
    state = state.copyWith(isLoading: true);
    try {
      final validators = await _service.getValidators();
      state = state.copyWith(isLoading: false, validators: validators);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Failed to fetch validators');
    }
  }

  void selectValidator(XerisValidator validator) {
    state = state.copyWith(selectedValidator: validator);
  }

  Future<bool> stakeXrs(String validatorAddress, double amount) async {
    final mnemonic = await StorageService.getMnemonic();
    if (mnemonic == null) {
        state = state.copyWith(error: 'Wallet not connected');
        return false;
    }

    state = state.copyWith(isLoading: true, error: null, resultMessage: null);

    try {
      final tx = await _service.stake(
        mnemonic: mnemonic,
        validatorAddress: validatorAddress,
        amount: amount,
      );

      if (tx != null) {
          state = state.copyWith(isLoading: false, resultMessage: 'Staked Successfully! Tx: ${tx.safeSubstring(0, 8)}...');
          // Refresh wallet balance
          ref.invalidate(accountBalancesProvider);
          return true;
      } else {
           state = state.copyWith(isLoading: false, error: 'Staking failed');
           return false;
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> unstakeXrs(String validatorAddress, double amount) async {
    final mnemonic = await StorageService.getMnemonic();
    if (mnemonic == null) {
        state = state.copyWith(error: 'Wallet not connected');
        return false;
    }

    state = state.copyWith(isLoading: true, error: null, resultMessage: null);

    try {
      final tx = await _service.unstake(
        mnemonic: mnemonic,
        validatorAddress: validatorAddress,
        amount: amount,
      );

      if (tx != null) {
          state = state.copyWith(isLoading: false, resultMessage: 'Unstake Request Submitted! Tx: ${tx.safeSubstring(0, 8)}...');
          // Refresh wallet balance and staked balance
          ref.invalidate(accountBalancesProvider);
          ref.invalidate(stakedBalanceProvider);
          return true;
      } else {
           state = state.copyWith(isLoading: false, error: 'Unstaking failed');
           return false;
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }
}

final stakingProvider = NotifierProvider<StakingNotifier, StakingState>(() {
  return StakingNotifier();
});
