import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xeris_wallet/core/models/agent_models.dart';
import 'package:xeris_wallet/core/providers/wallet_provider.dart';
import 'package:xeris_wallet/core/services/agent_key_service.dart';
import 'package:xeris_wallet/core/services/agent_runner_service.dart';
import 'package:xeris_wallet/core/services/storage_service.dart';

class AgentRunnerState {
  final bool isRunning;
  final Map<String, AgentRunnerStatus> agentStatuses;
  final List<AgentRunnerLog> logs;

  const AgentRunnerState({
    this.isRunning = false,
    this.agentStatuses = const {},
    this.logs = const [],
  });

  AgentRunnerState copyWith({
    bool? isRunning,
    Map<String, AgentRunnerStatus>? agentStatuses,
    List<AgentRunnerLog>? logs,
  }) {
    return AgentRunnerState(
      isRunning: isRunning ?? this.isRunning,
      agentStatuses: agentStatuses ?? this.agentStatuses,
      logs: logs ?? this.logs,
    );
  }
}

class AgentRunnerNotifier extends Notifier<AgentRunnerState> {
  @override
  AgentRunnerState build() {
    final runner = AgentRunnerService.instance;
    runner.onStateChanged = _sync;
    ref.onDispose(() => runner.onStateChanged = null);
    return AgentRunnerState(
      isRunning: runner.isRunning,
      agentStatuses: runner.agentStatuses,
      logs: runner.logs,
    );
  }

  void _sync() {
    final runner = AgentRunnerService.instance;
    state = AgentRunnerState(
      isRunning: runner.isRunning,
      agentStatuses: runner.agentStatuses,
      logs: runner.logs,
    );
  }

  Future<void> startAgent(AgentModel agent) async {
    final walletId = await StorageService.getActiveWalletId();
    if (walletId == null) return;
    final address = await ref.read(walletAddressProvider.future);

    await AgentRunnerService.instance.startAgent(
      walletId: walletId,
      ownerAddress: address,
      agent: agent,
    );
  }

  void stopAgent(String pubkey) {
    AgentRunnerService.instance.stopAgent(pubkey);
  }

  void stopAll() {
    AgentRunnerService.instance.stopAll();
  }
}

final agentRunnerProvider = NotifierProvider<AgentRunnerNotifier, AgentRunnerState>(() {
  return AgentRunnerNotifier();
});

/// Provides the list of agent pubkeys that have locally stored seeds.
final localAgentKeysProvider = FutureProvider<List<String>>((ref) async {
  final walletId = await StorageService.getActiveWalletId();
  if (walletId == null) return [];
  return AgentKeyService.getStoredPubkeys(walletId);
});
