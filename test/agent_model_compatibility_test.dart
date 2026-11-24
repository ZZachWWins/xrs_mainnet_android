import 'package:flutter_test/flutter_test.dart';
import 'package:xeris_wallet/core/models/agent_models.dart';

void main() {
  group('AgentModel node compatibility', () {
    test('reads the supplied node AgentEntry fields', () {
      final agent = AgentModel.fromJson({
        'agent_pubkey': 'current-agent',
        'agent_name': 'Mainnet Agent',
        'owner': 'owner',
        'max_per_tx': 1500000000,
        'max_daily': 7000000000,
        'allowed_contracts': ['pool-a', 'registry'],
        'allowed_operations': ['ContractCall'],
        'expires_at_slot': 0,
        'revoked': false,
        'created_slot': 5,
      });

      expect(agent.pubkey, 'current-agent');
      expect(agent.name, 'Mainnet Agent');
      expect(agent.maxPerTxXrs, 1.5);
      expect(agent.dailyBudgetXrs, 7);
      expect(agent.allowedContracts, ['pool-a', 'registry']);
      expect(agent.status, 'active');
      expect(agent.lastHeartbeat, isEmpty);
    });

    test('preserves legacy names, lamport strings, and explicit state', () {
      final agent = AgentModel.fromJson({
        'pubkey': 'legacy-agent',
        'name': 'Legacy Agent',
        'max_per_tx_lamports': '2500000000',
        'max_daily_lamports': '9000000000',
        'allowed_contracts': ['old-pool'],
        'status': 'paused',
        'last_heartbeat': '2026-11-22T12:00:00Z',
      });

      expect(agent.pubkey, 'legacy-agent');
      expect(agent.name, 'Legacy Agent');
      expect(agent.maxPerTxXrs, 2.5);
      expect(agent.dailyBudgetXrs, 9);
      expect(agent.status, 'paused');
      expect(agent.lastHeartbeat, '2026-11-22T12:00:00Z');
    });

    test('retains the legacy daily_budget alias', () {
      final agent = AgentModel.fromJson({'daily_budget': 4000000000});
      expect(agent.dailyBudgetXrs, 4);
    });

    test('canonical node identity and budgets take precedence over aliases',
        () {
      final agent = AgentModel.fromJson({
        'agent_pubkey': 'canonical-key',
        'pubkey': 'old-key',
        'agent_name': 'Canonical',
        'name': 'Old',
        'max_per_tx': 1000000000,
        'max_per_tx_lamports': 2000000000,
        'max_daily': 3000000000,
        'daily_budget': 4000000000,
        'max_daily_lamports': 5000000000,
      });
      expect(agent.pubkey, 'canonical-key');
      expect(agent.name, 'Canonical');
      expect(agent.maxPerTxXrs, 1);
      expect(agent.dailyBudgetXrs, 3);
    });

    test('revocation overrides an active or expired display state', () {
      final agent = AgentModel.fromJson({
        'revoked': true,
        'status': 'active',
        'active': true,
        'expired': true,
      });
      expect(agent.status, 'revoked');
    });

    test('an explicit expiry overrides active flags', () {
      final agent = AgentModel.fromJson({
        'revoked': false,
        'expired': true,
        'status': 'active',
        'is_active': true,
      });
      expect(agent.status, 'expired');
    });

    for (final flag in ['active', 'is_active', 'authorized']) {
      test('$flag=false is not displayed as active', () {
        final agent = AgentModel.fromJson({flag: false, 'status': 'active'});
        expect(agent.status, 'inactive');
      });
    }

    test('an inactive flag preserves a more specific legacy status', () {
      final agent = AgentModel.fromJson({'active': false, 'status': 'paused'});
      expect(agent.status, 'paused');
    });

    test('slot expiry is not compared to wall-clock time', () {
      final agent = AgentModel.fromJson({'expires_at_slot': 123});
      expect(agent.status, 'active');
    });

    test('missing optional fields retain existing defaults', () {
      final agent = AgentModel.fromJson({});
      expect(agent.name, 'Unnamed Agent');
      expect(agent.pubkey, isEmpty);
      expect(agent.maxPerTxXrs, 0);
      expect(agent.dailyBudgetXrs, 0);
      expect(agent.allowedContracts, isEmpty);
      expect(agent.status, 'active');
    });
  });

  group('AgentTask node compatibility', () {
    test('reads current TaskEntry identifiers and required category', () {
      final task = AgentTask.fromJson({
        'task_id': 'task-current',
        'title': 'Verify a document',
        'required_category': 'verification',
        'reward': 1250000000,
        'status': 'open',
      });
      expect(task.id, 'task-current');
      expect(task.title, 'Verify a document');
      expect(task.category, 'verification');
      expect(task.rewardXrs, 1.25);
    });

    test('preserves legacy task fields and string rewards', () {
      final task = AgentTask.fromJson({
        'id': 'task-legacy',
        'title': 'Legacy task',
        'category': 'compute',
        'reward': '2000000000',
      });
      expect(task.id, 'task-legacy');
      expect(task.title, 'Legacy task');
      expect(task.category, 'compute');
      expect(task.rewardXrs, 2);
    });

    test('canonical task fields take precedence over legacy aliases', () {
      final task = AgentTask.fromJson({
        'task_id': 'canonical',
        'id': 'legacy',
        'required_category': 'canonical-category',
        'category': 'legacy-category',
      });
      expect(task.id, 'canonical');
      expect(task.category, 'canonical-category');
    });
  });
}
