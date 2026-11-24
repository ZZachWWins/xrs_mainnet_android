import 'dart:async';
import 'dart:convert';
import 'package:crypto/crypto.dart' as crypto;
import 'package:xeris_wallet/core/config/network_config.dart';
import 'package:xeris_wallet/core/services/base_api_service.dart';
import 'package:flutter/foundation.dart';
import 'package:solana/solana.dart';
import 'package:xeris_wallet/core/models/agent_models.dart';
import 'package:xeris_wallet/core/services/agent_key_service.dart';
import 'package:xeris_wallet/core/services/xeris_api_service.dart';

class _RunningAgentState {
  final AgentModel agent;
  final String walletId;
  final String ownerAddress;
  final Ed25519HDKeyPair keyPair;
  Timer? heartbeatTimer;
  Timer? taskPollTimer;
  int dailySpentLamports = 0;
  DateTime dailyResetDate = DateTime.now().toUtc();
  AgentRunnerStatus status = AgentRunnerStatus.idle;

  _RunningAgentState({
    required this.agent,
    required this.walletId,
    required this.ownerAddress,
    required this.keyPair,
  });

  void resetDailyIfNeeded() {
    final now = DateTime.now().toUtc();
    if (now.day != dailyResetDate.day || now.difference(dailyResetDate).inHours > 24) {
      dailySpentLamports = 0;
      dailyResetDate = now;
    }
  }
}

class AgentRunnerService {
  static AgentRunnerService? _instance;
  static AgentRunnerService get instance => _instance ??= AgentRunnerService._();
  AgentRunnerService._();

  final Map<String, _RunningAgentState> _agents = {};
  final List<AgentRunnerLog> _logs = [];
  static const int _maxLogs = 200;

  // Callbacks for notifying providers of state changes
  VoidCallback? onStateChanged;

  bool get isRunning => _agents.values.any((a) => a.status == AgentRunnerStatus.running);
  List<AgentRunnerLog> get logs => List.unmodifiable(_logs);

  Map<String, AgentRunnerStatus> get agentStatuses => {
    for (final entry in _agents.entries)
      entry.key: entry.value.status,
  };

  bool isAgentRunning(String pubkey) =>
      _agents[pubkey]?.status == AgentRunnerStatus.running;

  /// Matches ledger::identity_cid: SHA-256 of the full UTF-8 public-key
  /// STRING, not decoded key bytes; use its first 32 hex characters.
  static String identityContractId(String identityPubkey) =>
      'identity_${crypto.sha256.convert(utf8.encode(identityPubkey)).toString().substring(0, 32)}';

  static const identityRequiredMessage =
      'An active on-chain identity is required for this signing account. '
      'Register its identity before running an agent or claiming tasks. '
      'No transaction was sent.';

  /// Returns the checked network scope so callers cannot sign on another chain.
  static Future<String> ensureActiveIdentity(String identityPubkey) async {
    final scope = NetworkConfig.cacheKey;
    final cid = identityContractId(identityPubkey);
    dynamic data;
    try {
      data = await BaseApiService.get('${NetworkConfig.controlUrl}/contract/$cid');
    } on ApiException catch (error) {
      if (error.type == ApiErrorType.rpc &&
          error.message.toLowerCase().contains('contract not found')) {
        throw UnsupportedError(identityRequiredMessage);
      }
      rethrow;
    }
    if (scope != NetworkConfig.cacheKey) {
      throw StateError('The network changed. Review the agent action again.');
    }
    final contract = data is Map ? data['contract'] : null;
    final state = contract is Map ? contract['state'] : null;
    final identity = state is Map ? state['Identity'] : null;
    if (data is! Map || data['success'] != true || contract is! Map ||
        contract['contract_id'] != cid || contract['owner'] != identityPubkey ||
        contract['is_active'] != true || identity is! Map ||
        identity['identity_pubkey'] != identityPubkey || identity['active'] != true) {
      throw UnsupportedError(identityRequiredMessage);
    }
    return scope;
  }

  Future<void> startAgent({
    required String walletId,
    required String ownerAddress,
    required AgentModel agent,
  }) async {
    if (_agents.containsKey(agent.pubkey) &&
        _agents[agent.pubkey]!.status == AgentRunnerStatus.running) {
      return; // Already running
    }

    final keyPair = await AgentKeyService.getKeyPair(walletId, agent.pubkey);
    if (keyPair == null) {
      _addLog(agent.pubkey, 'error', 'No local key found for agent');
      return;
    }

    if (keyPair.address != agent.pubkey) {
      _addLog(agent.pubkey, 'error', 'The local signing key does not match this agent.');
      return;
    }
    try {
      await ensureActiveIdentity(keyPair.address);
    } catch (error) {
      _addLog(agent.pubkey, 'error', error.toString());
      return;
    }

    final state = _RunningAgentState(
      agent: agent,
      walletId: walletId,
      ownerAddress: ownerAddress,
      keyPair: keyPair,
    );
    state.status = AgentRunnerStatus.running;
    _agents[agent.pubkey] = state;

    _addLog(agent.pubkey, 'started', 'Agent runner started');

    // Start heartbeat timer (every 60s)
    state.heartbeatTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      _sendHeartbeat(state);
    });
    // Send first heartbeat immediately
    _sendHeartbeat(state);

    // Start task polling timer (every 45s)
    state.taskPollTimer = Timer.periodic(const Duration(seconds: 45), (_) {
      _pollAndExecuteTasks(state);
    });

    onStateChanged?.call();
  }

  void stopAgent(String pubkey) {
    final state = _agents[pubkey];
    if (state == null) return;

    state.heartbeatTimer?.cancel();
    state.taskPollTimer?.cancel();
    state.status = AgentRunnerStatus.stopped;

    _addLog(pubkey, 'stopped', 'Agent runner stopped');
    onStateChanged?.call();
  }

  void stopAll() {
    for (final pubkey in _agents.keys.toList()) {
      stopAgent(pubkey);
    }
  }

  Future<void> _sendHeartbeat(_RunningAgentState state) async {
    try {
      final scope = await ensureActiveIdentity(state.keyPair.address);
      final ixData = XerisApiService.buildAgentHeartbeat(
        identityPubkey: state.agent.pubkey,
        statusMessage: 'online',
        activeTasks: 0,
        availableCapacity: 10,
      );

      final txHash = await XerisApiService.submitXerisInstruction(
        keyPair: state.keyPair,
        instructionData: ixData,
        expectedNetworkScope: scope,
      );

      _addLog(state.agent.pubkey, 'heartbeat', 'Heartbeat submitted', txHash: txHash);
    } catch (e) {
      _addLog(state.agent.pubkey, 'error', 'Heartbeat failed: $e');
      if (kDebugMode) debugPrint('Agent heartbeat error: $e');
    }
  }

  Future<void> _pollAndExecuteTasks(_RunningAgentState state) async {
    try {
      state.resetDailyIfNeeded();

      final tasksData = await XerisApiService.getOpenTasks();
      if (tasksData == null) return;

      final List? tasksList = tasksData['tasks'] ?? tasksData['data'];
      if (tasksList == null || tasksList.isEmpty) return;

      final tasks = tasksList.map((e) => AgentTask.fromJson(e)).toList();

      for (final task in tasks) {
        // Check if task fits within agent's allowed contracts
        if (state.agent.allowedContracts.isNotEmpty &&
            !state.agent.allowedContracts.contains(task.category)) {
          continue;
        }

        // Check spending limits
        final rewardLamports = (task.rewardXrs * 1e9).round();
        final maxPerTx = (state.agent.maxPerTxXrs * 1e9).round();
        final maxDaily = (state.agent.dailyBudgetXrs * 1e9).round();

        if (rewardLamports > maxPerTx) continue;
        if (state.dailySpentLamports + rewardLamports > maxDaily) continue;

        // A task identity is self-owned; ClaimTask is not an allowed
        // delegated AgentExecute instruction in the current node.
        try {
          final scope = await ensureActiveIdentity(state.keyPair.address);
          final claimIx = XerisApiService.buildClaimTask(
            taskId: task.id,
            claimantIdentity: state.keyPair.address,
          );
          final txHash = await XerisApiService.submitXerisInstruction(
            keyPair: state.keyPair,
            instructionData: claimIx,
            expectedNetworkScope: scope,
          );

          state.dailySpentLamports += rewardLamports;
          _addLog(state.agent.pubkey, 'task_claimed',
              'Task claim submitted: ${task.title}', txHash: txHash);
        } catch (e) {
          _addLog(state.agent.pubkey, 'error', 'Failed to claim task ${task.id}: $e');
        }
      }
    } catch (e) {
      _addLog(state.agent.pubkey, 'error', 'Task polling error: $e');
      if (kDebugMode) debugPrint('Agent task poll error: $e');
    }
  }

  void _addLog(String pubkey, String type, String message, {String? txHash}) {
    _logs.insert(0, AgentRunnerLog(
      timestamp: DateTime.now(),
      agentPubkey: pubkey,
      type: type,
      message: message,
      txHash: txHash,
    ));
    if (_logs.length > _maxLogs) {
      _logs.removeRange(_maxLogs, _logs.length);
    }
    onStateChanged?.call();
  }
}
