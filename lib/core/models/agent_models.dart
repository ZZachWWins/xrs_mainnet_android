import 'package:xeris_wallet/core/config/feature_flags.dart';

class AgentModel {
  final String name;
  final String pubkey;
  final double maxPerTxXrs;
  final double dailyBudgetXrs;
  final List<String> allowedContracts;
  final String status;
  final String lastHeartbeat;

  AgentModel({
    required this.name,
    required this.pubkey,
    required this.maxPerTxXrs,
    required this.dailyBudgetXrs,
    required this.allowedContracts,
    required this.status,
    required this.lastHeartbeat,
  });

  static String _parseStatus(Map<String, dynamic> json) {
    if (json['revoked'] == true) return 'revoked';
    if (json['expired'] == true) return 'expired';
    final explicit = json['status'];
    final status =
        explicit is String && explicit.trim().isNotEmpty ? explicit : null;
    if (json['active'] == false ||
        json['is_active'] == false ||
        json['authorized'] == false) {
      return status != null && status.toLowerCase() != 'active'
          ? status
          : 'inactive';
    }
    // expires_at_slot is a chain slot, not a timestamp. Without the current
    // slot, preserve the node's status rather than inventing an expiry time.
    return status ?? 'active';
  }

  factory AgentModel.fromJson(Map<String, dynamic> json) {
    double parseLamports(dynamic value) {
      if (value == null) return 0.0;
      if (value is num) return value.toDouble() / 1000000000;
      final parsed = double.tryParse(value.toString());
      return parsed != null ? parsed / 1000000000 : 0.0;
    }

    return AgentModel(
      name: json['agent_name'] ?? json['name'] ?? 'Unnamed Agent',
      pubkey: json['agent_pubkey'] ?? json['pubkey'] ?? '',
      maxPerTxXrs:
          parseLamports(json['max_per_tx'] ?? json['max_per_tx_lamports']),
      dailyBudgetXrs: parseLamports(json['max_daily'] ??
          json['daily_budget'] ??
          json['max_daily_lamports']),
      allowedContracts: (json['allowed_contracts'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      status: _parseStatus(json),
      lastHeartbeat: json['last_heartbeat'] ?? '',
    );
  }
}

class AgentTask {
  final String id;
  final String title;
  final String category;
  final double rewardXrs;

  AgentTask({
    required this.id,
    required this.title,
    required this.category,
    required this.rewardXrs,
  });

  factory AgentTask.fromJson(Map<String, dynamic> json) {
    double parseLamports(dynamic value) {
      if (value == null) return 0.0;
      if (value is num) return value.toDouble() / 1000000000;
      final parsed = double.tryParse(value.toString());
      return parsed != null ? parsed / 1000000000 : 0.0;
    }

    return AgentTask(
      id: json['task_id'] ?? json['id'] ?? '',
      title: json['title'] ?? 'Unknown Task',
      category: json['required_category'] ?? json['category'] ?? 'generic',
      rewardXrs: parseLamports(json['reward']),
    );
  }
}

enum AgentRunnerStatus { idle, starting, running, error, stopped }

class AgentRunnerLog {
  final DateTime timestamp;
  final String agentPubkey;
  final String
      type; // 'heartbeat', 'task_claimed', 'task_executed', 'error', 'started', 'stopped'
  final String message;
  final String? txHash;

  AgentRunnerLog({
    required this.timestamp,
    required this.agentPubkey,
    required this.type,
    required this.message,
    this.txHash,
  });
}

class AgentTemplate {
  final String id;
  final String name;
  final String description;
  final String icon; // Icon name or character
  final double defaultMaxPerTx;
  final double defaultDailyBudget;
  final List<String> allowedContracts;
  final List<String> allowedOperations;

  AgentTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.defaultMaxPerTx,
    required this.defaultDailyBudget,
    this.allowedContracts = const [],
    this.allowedOperations = const [
      'NativeTransfer',
      'ContractCall',
      'WrapXrs',
      'UnwrapXrs'
    ],
  });

  static List<AgentTemplate> get defaults => [
        AgentTemplate(
          id: 'harvest',
          name: 'Yield Harvester',
          description:
              'Automatically claims and re-stakes your DeFi rewards to compound gains.',
          icon: '🚜',
          defaultMaxPerTx: 1.0,
          defaultDailyBudget: 5.0,
          allowedContracts: [
            'staking_program',
            'reward_distributor',
            'xeris_pool_liquidity'
          ],
          allowedOperations: ['ContractCall', 'WrapXrs', 'UnwrapXrs'],
        ),
        AgentTemplate(
          id: 'guard',
          name: 'Security Watchdog',
          description:
              'Monitors wallet health and moves assets to cold storage if threats detected.',
          icon: '🛡️',
          defaultMaxPerTx: 50.0,
          defaultDailyBudget: 100.0,
          allowedContracts: [],
          allowedOperations: ['NativeTransfer'],
        ),
        AgentTemplate(
          id: 'trade',
          name: 'Portfolio Manager',
          description:
              'Executes swaps and manages liquidity positions based on market signals.',
          icon: '📈',
          defaultMaxPerTx: 10.0,
          defaultDailyBudget: 50.0,
          allowedContracts: ['xeris_dex_v1', 'oracle_aggregator'],
          allowedOperations: ['ContractCall', 'NativeTransfer'],
        ),
        AgentTemplate(
          id: 'custom',
          name: 'Custom Agent',
          description: 'Full manual control over all delegation parameters.',
          icon: '⚙️',
          defaultMaxPerTx: 5.0,
          defaultDailyBudget: 20.0,
        ),
      ];

  /// Templates offered on the current platform. The swap/liquidity-based
  /// "Portfolio Manager" (id 'trade') is hidden on iOS for App Store
  /// compliance, since it executes on-chain swaps via the DEX.
  static List<AgentTemplate> get available => FeatureFlags.swapEnabled
      ? defaults
      : defaults.where((t) => t.id != 'trade').toList();
}
