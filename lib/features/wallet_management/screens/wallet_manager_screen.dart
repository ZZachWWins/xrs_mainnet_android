import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:xeris_wallet/core/models/asset_model.dart';
import 'package:xeris_wallet/core/models/wallet_meta.dart';
import 'package:xeris_wallet/core/providers/wallet_provider.dart';
import 'package:xeris_wallet/core/services/xeris_api_service.dart';
import 'package:xeris_wallet/core/theme/app_theme.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:xeris_wallet/l10n/app_localizations.dart';
import 'package:xeris_wallet/core/utils/string_extensions.dart';

/// Fetches XRS balance for an arbitrary wallet address (not necessarily the active one).
final walletBalanceByAddressProvider = FutureProvider.family<double, String>((ref, address) async {
  final balances = await XerisApiService.getAccountBalances(address);
  return balances.nativeXrs;
});

class WalletManagerScreen extends ConsumerWidget {
  const WalletManagerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletListAsync = ref.watch(walletListProvider);
    final activeWalletAsync = ref.watch(activeWalletProvider);
    final pricesAsync = ref.watch(tokenPricesProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.myWalletsTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: AppColors.brandVibrant),
            onPressed: () => context.push('/add-wallet'),
          ),
        ],
      ),
      body: walletListAsync.when(
        data: (wallets) {
          if (wallets.isEmpty) {
            return Center(
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
                      decoration: const BoxDecoration(color: AppColors.brandSpace, shape: BoxShape.circle),
                      child: const Icon(Icons.account_balance_wallet_outlined, size: 48, color: AppColors.brandVibrant),
                    ),
                    const SizedBox(height: 24),
                    Text(l10n.noWallets, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(l10n.noWalletsDesc, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textBody, fontSize: 14, height: 1.5)),
                  ],
                ),
              ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, duration: 400.ms, curve: Curves.easeOutQuad),
            );
          }

          final activeId = activeWalletAsync.asData?.value?.id;
          final prices = pricesAsync.asData?.value ?? {};
          final xrsPrice = (prices['xrs_native'] ?? prices['xrs'] ?? 0.0);

          return Column(
            children: [
              // Portfolio summary header
              _PortfolioSummaryHeader(wallets: wallets, xrsPrice: xrsPrice),
              // Wallet list
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: wallets.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final wallet = wallets[index];
                    final isActive = wallet.id == activeId;
                    return _WalletCard(
                      wallet: wallet,
                      isActive: isActive,
                      xrsPrice: xrsPrice,
                      onSwitch: () async {
                        await ref.read(walletControllerProvider.notifier).switchWallet(wallet.id);
                        if (context.mounted) {
                          if (context.canPop()) context.pop();
                          else context.go('/home');
                        }
                      },
                      onRename: () => _showRenameDialog(context, ref, wallet, l10n),
                      onDelete: () async {
                        final confirm = await _confirmDelete(context, wallet, l10n);
                        if (confirm == true) {
                          await ref.read(walletControllerProvider.notifier).deleteWallet(wallet.id);
                        }
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text(l10n.errorPrefix(err.toString()))),
      ),
    );
  }

  Future<bool?> _confirmDelete(BuildContext context, WalletMeta wallet, AppLocalizations l10n) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.brandNavy,
        title: Text(l10n.deleteWalletPromptTitle, style: const TextStyle(color: Colors.white)),
        content: Text(l10n.deleteWalletPromptDesc(wallet.name), style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.cancel, style: const TextStyle(color: Colors.white60))),
          TextButton(onPressed: () => Navigator.pop(context, true), style: TextButton.styleFrom(foregroundColor: AppColors.error), child: Text(l10n.delete)),
        ],
      ),
    );
  }

  Future<void> _showRenameDialog(BuildContext context, WidgetRef ref, WalletMeta wallet, AppLocalizations l10n) async {
    final controller = TextEditingController(text: wallet.name);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.brandNavy,
        title: Text(l10n.renameWalletTitle, style: const TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: l10n.walletNameLabel,
            labelStyle: const TextStyle(color: Colors.white70),
            enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white38)),
            focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.brandVibrant)),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.cancel, style: const TextStyle(color: Colors.white60))),
          TextButton(
            onPressed: () { if (controller.text.trim().isNotEmpty) Navigator.pop(context, true); },
            child: Text(l10n.save, style: const TextStyle(color: AppColors.brandVibrant)),
          ),
        ],
      ),
    );
    if (confirm == true && controller.text.trim().isNotEmpty && context.mounted) {
      await ref.read(walletControllerProvider.notifier).renameWallet(wallet.id, controller.text.trim());
    }
  }
}

class _PortfolioSummaryHeader extends ConsumerWidget {
  final List<WalletMeta> wallets;
  final double xrsPrice;

  const _PortfolioSummaryHeader({required this.wallets, required this.xrsPrice});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch balance for all wallets
    double total = 0;
    bool anyLoading = false;

    for (final wallet in wallets) {
      final balanceAsync = ref.watch(walletBalanceByAddressProvider(wallet.address));
      balanceAsync.when(
        data: (b) => total += b * xrsPrice,
        loading: () => anyLoading = true,
        error: (_, __) {},
      );
    }

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.brandNavy, AppColors.brandSpace],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.brandVibrant.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Total Portfolio', style: TextStyle(color: AppColors.textBody, fontSize: 13)),
          const SizedBox(height: 6),
          anyLoading && total == 0
              ? const SizedBox(height: 32, child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.brandVibrant)))
              : Text(
                  '\$${AssetModel.formatValue(total)}',
                  style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                ),
          const SizedBox(height: 4),
          Text(
            '${wallets.length} wallet${wallets.length == 1 ? '' : 's'}',
            style: const TextStyle(color: AppColors.textBody, fontSize: 12),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }
}

class _WalletCard extends ConsumerWidget {
  final WalletMeta wallet;
  final bool isActive;
  final double xrsPrice;
  final VoidCallback onSwitch;
  final VoidCallback onRename;
  final VoidCallback onDelete;

  const _WalletCard({
    required this.wallet,
    required this.isActive,
    required this.xrsPrice,
    required this.onSwitch,
    required this.onRename,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balanceAsync = ref.watch(walletBalanceByAddressProvider(wallet.address));

    return Container(
      decoration: BoxDecoration(
        color: AppColors.brandSpace,
        borderRadius: BorderRadius.circular(12),
        border: isActive ? Border.all(color: AppColors.brandVibrant, width: 2) : null,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: isActive ? AppColors.brandVibrant : AppColors.brandNavy,
          child: Icon(Icons.account_balance_wallet, color: isActive ? Colors.white : Colors.white54),
        ),
        title: Text(
          wallet.name,
          style: TextStyle(fontWeight: FontWeight.bold, color: isActive ? Colors.white : Colors.white70),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_shortenAddress(wallet.address), style: const TextStyle(color: Colors.white38, fontSize: 12)),
            const SizedBox(height: 2),
            balanceAsync.when(
              data: (xrs) => Text(
                '${AssetModel.formatValue(xrs)} XRS${xrsPrice > 0 ? '  ·  \$${AssetModel.formatValue(xrs * xrsPrice)}' : ''}',
                style: const TextStyle(color: AppColors.brandVibrant, fontSize: 12, fontWeight: FontWeight.w600),
              ),
              loading: () => const SizedBox(height: 12, width: 80, child: LinearProgressIndicator(color: AppColors.brandVibrant, backgroundColor: AppColors.brandNavy)),
              error: (_, __) => const Text('Balance unavailable', style: TextStyle(color: Colors.white38, fontSize: 12)),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.edit_outlined, color: isActive ? AppColors.brandVibrant : Colors.white38),
              onPressed: onRename,
            ),
            if (isActive)
              const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Icon(Icons.check_circle, color: AppColors.brandVibrant))
            else
              IconButton(icon: const Icon(Icons.delete_outline, color: Colors.white38), onPressed: onDelete),
          ],
        ),
        onTap: isActive ? null : onSwitch,
      ),
    );
  }

  String _shortenAddress(String address) {
    if (address.length <= 10) return address;
    return '${address.safeSubstring(0, 6)}...${address.safeSubstring(address.length - 4)}';
  }
}
