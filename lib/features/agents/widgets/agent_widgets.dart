import 'package:flutter/material.dart';
import 'package:xeris_wallet/core/models/agent_models.dart';
import 'package:xeris_wallet/core/theme/app_theme.dart';
import 'package:xeris_wallet/core/utils/string_extensions.dart';
import 'package:xeris_wallet/l10n/app_localizations.dart';

class AgentCard extends StatefulWidget {
  final AgentModel agent;
  final VoidCallback onRevoke;
  final bool hasLocalKey;
  final bool isRunnerActive;
  final VoidCallback? onToggleRunner;

  const AgentCard({
    super.key,
    required this.agent,
    required this.onRevoke,
    this.hasLocalKey = false,
    this.isRunnerActive = false,
    this.onToggleRunner,
  });

  @override
  State<AgentCard> createState() => _AgentCardState();
}

class _AgentCardState extends State<AgentCard> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final agent = widget.agent;
    final l10n = AppLocalizations.of(context)!;
    final bool isActive = agent.status.toLowerCase() == 'active';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.brandMidnight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive ? Colors.green.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.05),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.brandBlue.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.brandBlue.withValues(alpha: 0.5)),
                ),
                child: const Icon(Icons.psychology, color: AppColors.brandVibrant, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      agent.name,
                      style: const TextStyle(
                        color: AppColors.brandLight,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _truncatePubkey(agent.pubkey),
                      style: TextStyle(
                        color: AppColors.textBody,
                        fontSize: 12,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
              isActive 
                ? AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) => Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.greenAccent,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.greenAccent.withValues(alpha: 0.4 * _pulseController.value),
                            blurRadius: 10 + (10 * _pulseController.value),
                            spreadRadius: 2 * _pulseController.value,
                          ),
                        ],
                      ),
                    ),
                  )
                : Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.redAccent,
                    ),
                  ),
            ],
          ),
          const SizedBox(height: 16),
          _buildScopeSection(),
          if (widget.hasLocalKey) ...[
            const SizedBox(height: 12),
            _buildRunnerToggle(),
          ],
          const SizedBox(height: 16),
          Divider(color: Colors.white.withValues(alpha: 0.05)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${l10n.lastHeartbeatPrefix}${agent.lastHeartbeat}',
                style: TextStyle(
                  color: AppColors.textBody.withValues(alpha: 0.7),
                  fontSize: 12,
                ),
              ),
              GestureDetector(
                onTap: widget.onRevoke,
                child: Row(
                  children: [
                    const Icon(Icons.delete_outline, color: Colors.redAccent, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      l10n.revokeAgentBtn,
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRunnerToggle() {
    final running = widget.isRunnerActive;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: running
            ? Colors.green.withValues(alpha: 0.08)
            : AppColors.brandBlue.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: running
              ? Colors.green.withValues(alpha: 0.3)
              : Colors.white.withValues(alpha: 0.05),
        ),
      ),
      child: Row(
        children: [
          Icon(
            running ? Icons.play_circle_filled : Icons.play_circle_outline,
            color: running ? Colors.greenAccent : AppColors.textBody,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              running ? 'Runner Active' : 'Runner Stopped',
              style: TextStyle(
                color: running ? Colors.greenAccent : AppColors.textBody,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(
            height: 30,
            child: OutlinedButton(
              onPressed: widget.onToggleRunner,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                side: BorderSide(
                  color: running
                      ? Colors.redAccent.withValues(alpha: 0.5)
                      : Colors.greenAccent.withValues(alpha: 0.5),
                ),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                backgroundColor: running
                    ? Colors.redAccent.withValues(alpha: 0.1)
                    : Colors.greenAccent.withValues(alpha: 0.1),
              ),
              child: Text(
                running ? 'Stop' : 'Start',
                style: TextStyle(
                  color: running ? Colors.redAccent : Colors.greenAccent,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScopeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'DELEGATION SCOPE',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.4),
            fontSize: 9,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildPill('Max ${widget.agent.maxPerTxXrs.toStringAsFixed(1)} XRS/tx'),
            _buildPill('Daily ${widget.agent.dailyBudgetXrs.toStringAsFixed(1)} XRS'),
            ...widget.agent.allowedContracts.map((c) => _buildPill(c)),
          ],
        ),
      ],
    );
  }

  Widget _buildPill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.brandBlue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.brandMuted.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: AppColors.textBody,
          fontSize: 12,
          fontFamily: 'monospace',
        ),
      ),
    );
  }

  String _truncatePubkey(String pubkey) {
    if (pubkey.length <= 10) return pubkey;
    return '${pubkey.safeSubstring(0, 4)}...${pubkey.safeSubstring(pubkey.length - 4)}';
  }
}

class TaskCard extends StatelessWidget {
  final AgentTask task;
  final VoidCallback onClaim;

  const TaskCard({
    super.key,
    required this.task,
    required this.onClaim,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.brandMidnight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: const TextStyle(
                    color: AppColors.brandLight,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  task.category.toLowerCase(),
                  style: TextStyle(
                    color: AppColors.textBody.withValues(alpha: 0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '+${task.rewardXrs.toStringAsFixed(1)} XRS',
                style: const TextStyle(
                  color: Colors.greenAccent,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 30,
                child: OutlinedButton(
                  onPressed: onClaim,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    side: BorderSide(color: AppColors.brandBlue.withValues(alpha: 0.5)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    backgroundColor: AppColors.brandBlue.withValues(alpha: 0.1),
                  ),
                  child: Text(
                    l10n.claimTaskBtn,
                    style: const TextStyle(
                      color: AppColors.brandLight,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
