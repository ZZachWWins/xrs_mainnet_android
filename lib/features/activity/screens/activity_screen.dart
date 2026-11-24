import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xeris_wallet/core/config/feature_flags.dart';
import 'package:xeris_wallet/core/models/transaction_model.dart';
import 'package:xeris_wallet/core/utils/string_extensions.dart';
import 'package:xeris_wallet/core/providers/wallet_provider.dart';
import 'package:xeris_wallet/core/providers/activity_provider.dart';
import 'package:xeris_wallet/core/theme/app_theme.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:xeris_wallet/l10n/app_localizations.dart';

enum _ActivityFilter { all, sent, received, swap, failed }

class ActivityScreen extends ConsumerStatefulWidget {
  const ActivityScreen({super.key});

  @override
  ConsumerState<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends ConsumerState<ActivityScreen> {
  _ActivityFilter _filter = _ActivityFilter.all;
  String _query = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<TransactionModel> _applyFilters(List<TransactionModel> txs) {
    final q = _query.trim().toLowerCase();
    return txs.where((tx) {
      switch (_filter) {
        case _ActivityFilter.all:
          break;
        case _ActivityFilter.sent:
          if (tx.type != TransactionType.send) return false;
          break;
        case _ActivityFilter.received:
          if (tx.type != TransactionType.receive) return false;
          break;
        case _ActivityFilter.swap:
          if (tx.type != TransactionType.swap) return false;
          break;
        case _ActivityFilter.failed:
          if (tx.status != TransactionStatus.failed) return false;
          break;
      }
      if (q.isEmpty) return true;
      return tx.id.toLowerCase().contains(q) ||
          tx.otherPartyAddress.toLowerCase().contains(q) ||
          tx.symbol.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final activityAsync = ref.watch(activityProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.brandNavy,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(accountBalancesProvider);
            return ref.refresh(activityProvider.future);
          },
          color: AppColors.brandVibrant,
          backgroundColor: AppColors.brandSpace,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                  child: Text(
                    l10n.activityTitle,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: _SearchField(
                  controller: _searchController,
                  hint: l10n.activitySearchHint,
                  onChanged: (v) => setState(() => _query = v),
                ),
              ),
              SliverToBoxAdapter(
                child: _FilterChipsRow(
                  selected: _filter,
                  labels: {
                    _ActivityFilter.all: l10n.activityFilterAll,
                    _ActivityFilter.sent: l10n.activityFilterSent,
                    _ActivityFilter.received: l10n.activityFilterReceived,
                    // Swap filter hidden on iOS (swap disabled for App Store).
                    if (FeatureFlags.swapEnabled)
                      _ActivityFilter.swap: l10n.activityFilterSwap,
                    _ActivityFilter.failed: l10n.activityFilterFailed,
                  },
                  onChanged: (f) => setState(() => _filter = f),
                ),
              ),
              activityAsync.when(
                data: (allTransactions) {
                  final transactions = _applyFilters(allTransactions);
                  if (allTransactions.isEmpty) {
                    return _buildEmptyState(l10n, isFiltered: false);
                  }
                  if (transactions.isEmpty) {
                    return _buildEmptyState(l10n, isFiltered: true);
                  }
                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final tx = transactions[index];
                        final currentAddress =
                            ref.watch(walletAddressProvider).value ?? '';
                        return _TransactionItem(
                          transaction: tx,
                          currentAddress: currentAddress,
                        ).animate()
                         .fadeIn(duration: 400.ms, delay: (index * 50).ms)
                         .slideX(begin: 0.1, duration: 400.ms, curve: Curves.easeOutQuad);
                      },
                      childCount: transactions.length,
                    ),
                  );
                },
                loading: () => const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.brandVibrant),
                  ),
                ),
                error: (err, stack) => SliverFillRemaining(
                  child: Center(
                    child: Text(
                      l10n.errorLoadingActivity,
                      style: const TextStyle(color: AppColors.brandError),
                    ),
                  ),
                ),
              ),
              const SliverPadding(padding: EdgeInsets.only(bottom: 120)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n, {required bool isFiltered}) {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 32),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: AppColors.brandMidnight.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: AppColors.brandSpace,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isFiltered ? Icons.search_off : Icons.receipt_long_outlined,
                  size: 48,
                  color: AppColors.brandVibrant,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                isFiltered ? l10n.activityNoMatches : l10n.noActivityYet,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isFiltered
                    ? l10n.activityNoMatchesDesc
                    : l10n.noActivityDesc,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textBody,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, duration: 400.ms, curve: Curves.easeOutQuad),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;

  const _SearchField({required this.controller, required this.hint, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 8),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.brandMidnight.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: TextField(
          controller: controller,
          onChanged: onChanged,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          cursorColor: AppColors.brandVibrant,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: AppColors.textBody, fontSize: 14),
            prefixIcon: const Icon(Icons.search, color: AppColors.textBody, size: 20),
            suffixIcon: controller.text.isEmpty
                ? null
                : IconButton(
                    icon: const Icon(Icons.close, color: AppColors.textBody, size: 18),
                    onPressed: () {
                      controller.clear();
                      onChanged('');
                    },
                  ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
    );
  }
}

class _FilterChipsRow extends StatelessWidget {
  final _ActivityFilter selected;
  final Map<_ActivityFilter, String> labels;
  final ValueChanged<_ActivityFilter> onChanged;

  const _FilterChipsRow({
    required this.selected,
    required this.labels,
    required this.onChanged,
  });

  static const _order = <_ActivityFilter>[
    _ActivityFilter.all,
    _ActivityFilter.sent,
    _ActivityFilter.received,
    _ActivityFilter.swap,
    _ActivityFilter.failed,
  ];

  @override
  Widget build(BuildContext context) {
    final order = _order.where(labels.containsKey).toList();
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
        itemCount: order.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final value = order[i];
          final label = labels[value] ?? '';
          final isSelected = value == selected;
          return GestureDetector(
            onTap: () => onChanged(value),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.brandVibrant.withValues(alpha: 0.18)
                    : AppColors.brandMidnight.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? AppColors.brandVibrant.withValues(alpha: 0.6)
                      : Colors.white.withValues(alpha: 0.05),
                ),
              ),
              child: Center(
                child: Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? AppColors.brandVibrant : Colors.white70,
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _TransactionItem extends StatelessWidget {
  final TransactionModel transaction;
  final String currentAddress;

  const _TransactionItem({
    required this.transaction,
    required this.currentAddress,
  });

  String _shortenAddress(String address, AppLocalizations l10n) {
    if (address.isEmpty) return l10n.unknownAddress;
    if (address.length <= 10) return address;
    return '${address.safeSubstring(0, 4)}...${address.safeSubstring(address.length - 4)}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isReceive = transaction.type == TransactionType.receive;
    final isFailed = transaction.status == TransactionStatus.failed;
    final isSwap = transaction.type == TransactionType.swap;
    final isWrap = transaction.symbol == 'Wrap XRS';
    final isUnwrap = transaction.symbol == 'Unwrap XRS';

    final amountPrefix = (isSwap || isReceive) ? (isReceive ? '+' : '') : '-';
    final amountColor = isFailed
        ? AppColors.textBody
        : (isReceive ? AppColors.brandSuccess : (isSwap ? AppColors.brandVibrant : Colors.white));

    IconData icon;
    if (isFailed) {
      icon = Icons.error_outline;
    } else if (isWrap) {
      icon = Icons.layers;
    } else if (isUnwrap) {
      icon = Icons.layers_clear;
    } else if (isSwap) {
      icon = Icons.swap_horiz;
    } else if (isReceive) {
      icon = Icons.arrow_downward;
    } else {
      icon = Icons.arrow_upward;
    }

    return GestureDetector(
      onTap: () {
        Clipboard.setData(ClipboardData(text: transaction.id));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.txHashCopied),
            duration: const Duration(seconds: 2),
          ),
        );
      },
      onLongPress: () {
        Clipboard.setData(ClipboardData(text: transaction.id));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.txHashCopied),
            duration: const Duration(seconds: 2),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.brandMidnight.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isFailed
                  ? AppColors.brandError.withValues(alpha: 0.1)
                  : (isReceive ? AppColors.brandSuccess.withValues(alpha: 0.1) : AppColors.brandBlue.withValues(alpha: 0.1)),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: isFailed
                  ? AppColors.brandError
                  : (isReceive ? AppColors.brandSuccess : AppColors.brandBlue),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),

          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isWrap
                      ? l10n.wrapXrs
                      : (isUnwrap ? l10n.unwrapXrs : (isSwap ? (transaction.symbol != 'Swap' ? transaction.symbol : l10n.swapLabel) : (isReceive ? l10n.receivedAsset(transaction.symbol) : l10n.sentAsset(transaction.symbol)))),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                // Addresses
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.fromAddress(_shortenAddress(isReceive ? transaction.otherPartyAddress : currentAddress, l10n)),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      l10n.toAddress(_shortenAddress(isReceive ? currentAddress : transaction.otherPartyAddress, l10n)),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _formatDate(transaction.date, l10n),
                  style: const TextStyle(
                    color: AppColors.textBody,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          // Amount
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                (isSwap && !isWrap && !isUnwrap)
                    ? l10n.interactLabel
                    : (isWrap || isUnwrap ? '${isWrap ? '-' : '+'}${transaction.amount.toStringAsFixed(2)} XRS' : '$amountPrefix${transaction.amount.toStringAsFixed(2)} ${transaction.symbol}'),
                style: TextStyle(
                  color: amountColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
               if (isFailed)
                Text(
                  l10n.failedStatus,
                  style: const TextStyle(
                    color: AppColors.brandError,
                    fontSize: 12,
                  ),
                ),
            ],
          ),
        ],
      ),
    ),
    );
  }

  String _formatDate(String isoString, AppLocalizations l10n) {
    final date = DateTime.parse(isoString).toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final txDate = DateTime(date.year, date.month, date.day);

    if (txDate == today) {
      return l10n.todayAt(DateFormat('h:mm a').format(date));
    } else if (txDate == yesterday) {
      return l10n.yesterdayAt(DateFormat('h:mm a').format(date));
    } else {
      return DateFormat('MMM d, h:mm a').format(date);
    }
  }
}
