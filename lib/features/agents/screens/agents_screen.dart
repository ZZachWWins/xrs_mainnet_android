import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:xeris_wallet/core/models/agent_models.dart';
import 'package:xeris_wallet/core/providers/agent_provider.dart';
// AgentRunnerStatus imported via agent_models.dart
import 'package:xeris_wallet/core/theme/app_theme.dart';
import 'package:xeris_wallet/l10n/app_localizations.dart';
import 'package:xeris_wallet/features/agents/widgets/agent_widgets.dart';
import 'package:xeris_wallet/core/services/wallet_service.dart';
import 'package:xeris_wallet/core/services/storage_service.dart';
import 'package:xeris_wallet/core/services/xeris_api_service.dart';
import 'package:xeris_wallet/core/services/auth_service.dart';
import 'package:xeris_wallet/core/services/agent_runner_service.dart';
import 'package:xeris_wallet/core/providers/agent_runner_provider.dart';

class AgentsScreen extends ConsumerWidget {
  const AgentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final agentsAsync = ref.watch(agentsProvider);
    final tasksAsync = ref.watch(openTasksProvider);
    final runnerState = ref.watch(agentRunnerProvider);
    final localKeysAsync = ref.watch(localAgentKeysProvider);

    return Scaffold(
      backgroundColor: Colors.transparent, // Background provided by HomeScreen
      appBar: AppBar(
        title: Text(
          l10n.agentsTitle,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: InkWell(
              onTap: () {
                context.push('/agents/register');
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.brandBlue.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.brandBlue.withValues(alpha: 0.5)),
                ),
                child: const Icon(Icons.add, color: AppColors.brandVibrant, size: 20),
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(agentsProvider);
          ref.invalidate(openTasksProvider);
          await ref.read(agentsProvider.future);
          await ref.read(openTasksProvider.future);
        },
        color: AppColors.brandVibrant,
        backgroundColor: AppColors.brandSpace,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(left: 24, right: 24, top: 16, bottom: 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- COMMAND CENTER DASHBOARD ---
              _buildCommandDashboard(agentsAsync.value ?? []),
              
              const SizedBox(height: 32),

              // Your Agents Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.yourAgents,
                    style: const TextStyle(
                      color: AppColors.brandLight,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (agentsAsync.value != null && agentsAsync.value!.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        l10n.activeAgentsStatus(agentsAsync.value!.where((a) => a.status.toLowerCase() == 'active').length),
                        style: const TextStyle(
                          color: Colors.greenAccent,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              agentsAsync.when(
                data: (agents) {
                  if (agents.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 32.0),
                        child: Text(
                          l10n.noAgentsRegistered,
                          style: TextStyle(color: AppColors.textBody),
                        ),
                      ),
                    );
                  }
                  final localKeys = localKeysAsync.value ?? [];
                  return Column(
                    children: agents.map((agent) => AgentCard(
                      agent: agent,
                      hasLocalKey: localKeys.contains(agent.pubkey),
                      isRunnerActive: runnerState.agentStatuses[agent.pubkey] == AgentRunnerStatus.running,
                      onToggleRunner: () async {
                        if (runnerState.agentStatuses[agent.pubkey] == AgentRunnerStatus.running) {
                          ref.read(agentRunnerProvider.notifier).stopAgent(agent.pubkey);
                        } else {
                          final authenticated = await AuthService.authenticate(context);
                          if (!authenticated) return;
                          await ref.read(agentRunnerProvider.notifier).startAgent(agent);
                        }
                      },
                      onRevoke: () async {
                        final authenticated = await AuthService.authenticate(context);
                        if (!authenticated) return;
                        try {
                          final mnemonic = await StorageService.getMnemonic();
                          if (mnemonic == null) throw Exception('No wallet found');
                          final keyPair = await WalletService.getKeyPair(mnemonic);
                          final ixData = XerisApiService.buildRevokeAgent(
                             agentPubkey: agent.pubkey
                          );
                          await XerisApiService.submitXerisInstruction(
                             keyPair: keyPair, instructionData: ixData
                          );
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Agent revoked')));
                          ref.invalidate(agentsProvider);
                        } catch (e) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
                        }
                      },
                    )).toList(),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.red))),
              ),

              const SizedBox(height: 32),
              Divider(color: Colors.white.withValues(alpha: 0.05)),
              const SizedBox(height: 24),

              // Mission Board (formerly Open Tasks)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mission Board',
                        style: const TextStyle(
                          color: AppColors.brandLight,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Opportunities for you and your agents',
                        style: TextStyle(
                          color: AppColors.textBody.withValues(alpha: 0.5),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: () {
                      ref.invalidate(openTasksProvider);
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.brandBlue,
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(50, 30),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(l10n.refresh, style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              tasksAsync.when(
                data: (tasks) {
                  if (tasks.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 32.0),
                        child: Text(
                          l10n.noOpenTasks,
                          style: TextStyle(color: AppColors.textBody),
                        ),
                      ),
                    );
                  }
                  return Column(
                    children: tasks.map((task) => TaskCard(
                      task: task,
                      onClaim: () async {
                        final authenticated = await AuthService.authenticate(context);
                        if (!authenticated) return;
                        try {
                          final mnemonic = await StorageService.getMnemonic();
                          if (mnemonic == null) throw Exception('No wallet found');
                          final keyPair = await WalletService.getKeyPair(mnemonic);
                          final scope = await AgentRunnerService.ensureActiveIdentity(keyPair.address);
                          final ixData = XerisApiService.buildClaimTask(
                            taskId: task.id,
                            claimantIdentity: keyPair.address,
                          );
                          await XerisApiService.submitXerisInstruction(
                            keyPair: keyPair,
                            instructionData: ixData,
                            expectedNetworkScope: scope,
                          );
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Task claim submitted')));
                          ref.invalidate(openTasksProvider);
                        } catch (e) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
                        }
                      },
                    )).toList(),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.red))),
              ),

              // Runner Logs
              if (runnerState.logs.isNotEmpty) ...[
                const SizedBox(height: 32),
                Divider(color: Colors.white.withValues(alpha: 0.05)),
                const SizedBox(height: 24),
                Text(
                  'Runner Logs',
                  style: const TextStyle(
                    color: AppColors.brandLight,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                ...runnerState.logs.take(20).map((log) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.brandMidnight,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.03)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        _logIcon(log.type),
                        size: 16,
                        color: _logColor(log.type),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              log.message,
                              style: TextStyle(color: AppColors.brandLight, fontSize: 12),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${log.timestamp.hour.toString().padLeft(2, '0')}:${log.timestamp.minute.toString().padLeft(2, '0')}:${log.timestamp.second.toString().padLeft(2, '0')}',
                              style: TextStyle(color: AppColors.textBody.withValues(alpha: 0.5), fontSize: 10),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )),
              ],
            ],
          ),
        ),
      ),
    );
  }

  static IconData _logIcon(String type) {
    switch (type) {
      case 'heartbeat': return Icons.favorite;
      case 'task_claimed': return Icons.check_circle;
      case 'error': return Icons.error_outline;
      case 'started': return Icons.play_arrow;
      case 'stopped': return Icons.stop;
      default: return Icons.info_outline;
    }
  }

  static Color _logColor(String type) {
    switch (type) {
      case 'heartbeat': return Colors.greenAccent;
      case 'task_claimed': return Colors.orangeAccent;
      case 'error': return Colors.redAccent;
      case 'started': return Colors.greenAccent;
      case 'stopped': return Colors.grey;
      default: return AppColors.textBody;
    }
  }

  Widget _buildCommandDashboard(List<AgentModel> agents) {
    final activeAgents = agents.where((a) => a.status.toLowerCase() == 'active').length;
    double totalDailyBudget = 0;
    for (var a in agents) {
      totalDailyBudget += a.dailyBudgetXrs;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.brandBlue.withValues(alpha: 0.15),
            AppColors.brandSpace.withValues(alpha: 0.3),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.brandBlue.withValues(alpha: 0.2), width: 1.5),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.brandVibrant.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.hub_outlined, color: AppColors.brandVibrant, size: 28),
              ),
              const SizedBox(width: 16),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Agent Command Center',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                  ),
                  Text(
                    'Autonomous Delegation Active',
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              _buildDashboardStat('ACTIVE', activeAgents.toString(), Colors.greenAccent),
              _buildDivider(),
              _buildDashboardStat('DAILY CAP', totalDailyBudget.toStringAsFixed(1), AppColors.brandVibrant),
              _buildDivider(),
              _buildDashboardStat('MISSIONS', '3 Available', Colors.orangeAccent),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardStat(String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.w900, fontFamily: 'monospace'),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 30,
      width: 1,
      color: Colors.white.withValues(alpha: 0.05),
    );
  }
}
