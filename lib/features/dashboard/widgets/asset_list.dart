import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:xeris_wallet/core/providers/wallet_provider.dart';
import 'package:xeris_wallet/core/services/xeris_api_service.dart';
import 'package:xeris_wallet/core/models/asset_model.dart';
import 'package:xeris_wallet/core/theme/app_theme.dart';
import 'package:xeris_wallet/core/utils/string_extensions.dart';
import 'package:xeris_wallet/l10n/app_localizations.dart';

class AssetList extends ConsumerWidget {
  const AssetList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final assetsAsync = ref.watch(dashboardAssetsSnapshotProvider);
    final snapshot = assetsAsync.value;
    final assets = snapshot?.assets ?? <AssetModel>[];
    final visibility = snapshot?.visibility ?? <String, bool>{};
    final isSwitching = ref.watch(walletControllerProvider).isLoading;

    final visibleAssets = assets.where((a) {
      return visibility[a.id] ?? (a.balance > 0);
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(context)!.tokensTitle,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                  fontWeight: FontWeight.w600,
                ),
              ),
              TextButton(
                onPressed: () {
                  _showManageCoinsSheet(context, ref, assets, visibility);
                },
                child: Text(AppLocalizations.of(context)!.manageCoins,
                    style: TextStyle(color: colorScheme.secondary)),
              ),
            ],
          ),
        ),
        if ((assetsAsync.isLoading && !assetsAsync.hasValue) || isSwitching)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 32.0),
            child: Center(
              child: Column(
                children: [
                  CircularProgressIndicator(color: colorScheme.secondary),
                  const SizedBox(height: 16),
                  Text(
                    'Updating balances...',
                    style: TextStyle(
                        color: colorScheme.onSurface.withValues(alpha: 0.6)),
                  ),
                ],
              ),
            ),
          )
        else if (assetsAsync.hasError && !assetsAsync.hasValue)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Column(
              children: [
                const Text('Unable to load balances. Please try again.',
                    textAlign: TextAlign.center),
                TextButton.icon(
                  onPressed: () => _retryBalances(ref),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          )
        else ...[
          if (snapshot?.isStale == true)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Row(
                children: [
                  const Expanded(
                      child: Text(
                          'Showing previous balances. They may be out of date.')),
                  TextButton(
                      onPressed: () => _retryBalances(ref),
                      child: const Text('Retry')),
                ],
              ),
            )
          else if (snapshot != null && !snapshot.hasValuation)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Text(
                  'Balances loaded. Prices or staking information are unavailable or still updating.'),
            ),
          if (visibleAssets.isEmpty)
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.inventory_2_outlined,
                        color: colorScheme.onSurface.withValues(alpha: 0.3),
                        size: 48),
                    const SizedBox(height: 16),
                    Text(
                      'No assets found yet.\nTry Refreshing or tap Manage to unhide.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: colorScheme.onSurface.withValues(alpha: 0.6)),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              itemCount: visibleAssets.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                return AssetTile(asset: visibleAssets[index])
                    .animate(delay: (index * 100).ms)
                    .fade()
                    .moveX(begin: 10, end: 0);
              },
            ),
        ],
      ],
    );
  }

  void _retryBalances(WidgetRef ref) {
    XerisApiService.clearBalanceCache();
    ref.invalidate(accountBalancesProvider);
    ref.invalidate(stakingInfoProvider);
    ref.invalidate(tokenPricesProvider);
  }

  void _showManageCoinsSheet(BuildContext context, WidgetRef ref,
      List<AssetModel> allAssets, Map<String, bool> visibility) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => const _ManageCoinsSheet(),
    );
  }
}

class _ManageCoinsSheet extends ConsumerStatefulWidget {
  const _ManageCoinsSheet();

  @override
  ConsumerState<_ManageCoinsSheet> createState() => _ManageCoinsSheetState();
}

class _ManageCoinsSheetState extends ConsumerState<_ManageCoinsSheet> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Tokens the user already holds / has enabled — cheap, always available.
    // The full token registry is NOT watched here; it is fetched lazily only
    // once the user types a search query (see the token-list section below).
    final ownedAssets =
        ref.watch(dashboardAssetsSnapshotProvider).value?.assets ??
            <AssetModel>[];
    final tokenBalances = ref.watch(tokenBalancesProvider).value ?? {};
    final visibility = ref.watch(coinVisibilityProvider).value ?? {};
    final l10n = AppLocalizations.of(context)!;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.65,
      maxChildSize: 0.92,
      minChildSize: 0.4,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Drag handle
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.onSurface.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Title
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                child: Text(
                  l10n.manageCoins,
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface),
                ),
              ),

              // Search field
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: TextField(
                  controller: _searchController,
                  style: TextStyle(color: colorScheme.onSurface),
                  onChanged: (val) =>
                      setState(() => _query = val.toLowerCase()),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: theme.cardTheme.color,
                    hintText: 'Search tokens...',
                    hintStyle: TextStyle(
                        color: colorScheme.onSurface.withValues(alpha: 0.3)),
                    prefixIcon: Icon(Icons.search,
                        color: colorScheme.onSurface.withValues(alpha: 0.4)),
                    suffixIcon: _query.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear,
                                color: colorScheme.onSurface
                                    .withValues(alpha: 0.4)),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _query = '');
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: theme.cardTheme.shape
                              is RoundedRectangleBorder
                          ? (theme.cardTheme.shape as RoundedRectangleBorder)
                              .side
                          : BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),

              // Token list. The full token registry is a large payload, so it is
              // fetched ONLY once the user starts searching. Until then we show
              // just the tokens the user already holds or has enabled.
              Expanded(
                child: Builder(
                  builder: (context) {
                    Widget renderList(List<_TokenEntry> entries,
                        {Widget? footer}) {
                      if (entries.isEmpty) {
                        return Center(
                          child: Text(
                            _query.isEmpty
                                ? 'No tokens to show'
                                : 'No tokens match "$_query"',
                            style: TextStyle(
                                color: colorScheme.onSurface
                                    .withValues(alpha: 0.5)),
                          ),
                        );
                      }
                      final hasFooter = footer != null;
                      return ListView.separated(
                        controller: scrollController,
                        itemCount: entries.length + (hasFooter ? 1 : 0),
                        separatorBuilder: (_, __) => Divider(
                            color: colorScheme.onSurface.withValues(alpha: 0.1),
                            height: 1),
                        itemBuilder: (context, index) {
                          if (hasFooter && index == entries.length) {
                            return footer;
                          }
                          final entry = entries[index];
                          final isVisible = entry.id == 'xrs'
                              ? true
                              : (visibility[entry.id] ?? (entry.balance > 0));

                          return ListTile(
                            leading: entry.iconPath != null
                                ? Image.asset(entry.iconPath!,
                                    width: 32,
                                    height: 32,
                                    errorBuilder: (_, __, ___) =>
                                        _tokenIcon(entry.symbol, theme))
                                : _tokenIcon(entry.symbol, theme),
                            title: Text(
                                entry.name.isNotEmpty
                                    ? entry.name
                                    : l10n.unknownToken,
                                style: TextStyle(color: colorScheme.onSurface)),
                            subtitle: Text(
                              entry.symbol.isNotEmpty
                                  ? entry.symbol
                                  : entry.id.safeSubstring(0, 8),
                              style: TextStyle(
                                  color: colorScheme.onSurface
                                      .withValues(alpha: 0.45)),
                            ),
                            trailing: entry.id == 'xrs'
                                ? Icon(Icons.lock_outline,
                                    color: colorScheme.onSurface
                                        .withValues(alpha: 0.2),
                                    size: 20)
                                : Switch(
                                    value: isVisible,
                                    activeThumbColor: colorScheme.secondary,
                                    activeTrackColor: colorScheme.primary
                                        .withValues(alpha: 0.3),
                                    onChanged: (visible) {
                                      ref
                                          .read(hiddenCoinsControllerProvider
                                              .notifier)
                                          .toggleCoinVisibility(
                                              entry.id, visible);
                                    },
                                  ),
                          );
                        },
                      );
                    }

                    // Idle: show owned/enabled tokens without fetching the registry.
                    if (_query.isEmpty) {
                      final entries = ownedAssets
                          .map((a) => _TokenEntry(
                                id: a.id,
                                name: a.name,
                                symbol: a.symbol,
                                iconPath: a.iconPath,
                                balance: a.balance,
                              ))
                          .toList();
                      return renderList(
                        entries,
                        footer: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            'Search to find and add more tokens',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: colorScheme.onSurface
                                    .withValues(alpha: 0.4),
                                fontSize: 12),
                          ),
                        ),
                      );
                    }

                    // Searching: NOW load the full token registry and filter it.
                    final allTokensAsync = ref.watch(availableTokensProvider);
                    return allTokensAsync.when(
                      loading: () => Center(
                          child: CircularProgressIndicator(
                              color: colorScheme.secondary)),
                      error: (e, _) => Center(
                          child: Text('Error: $e',
                              style: const TextStyle(color: AppColors.error))),
                      data: (allTokens) {
                        final entries = allTokens
                            .where((t) => t.id != 'xrs' && t.id != 'xrs_native')
                            .where((t) =>
                                t.name.toLowerCase().contains(_query) ||
                                t.symbol.toLowerCase().contains(_query))
                            .map((t) => _TokenEntry(
                                  id: t.id,
                                  name: t.name,
                                  symbol: t.symbol,
                                  balance: tokenBalances[t.id] ?? 0.0,
                                ))
                            .toList();
                        return renderList(entries);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _tokenIcon(String symbol, ThemeData theme) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          symbol.isNotEmpty ? symbol[0] : '?',
          style: TextStyle(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.bold,
              fontSize: 13),
        ),
      ),
    );
  }
}

class _TokenEntry {
  final String id;
  final String name;
  final String symbol;
  final String? iconPath;
  final double balance;

  const _TokenEntry({
    required this.id,
    required this.name,
    required this.symbol,
    this.iconPath,
    required this.balance,
  });
}

class AssetTile extends ConsumerWidget {
  final AssetModel asset;

  const AssetTile({super.key, required this.asset});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final isPrivacyMode = ref.watch(privacyModeProvider);

    return InkWell(
      onTap: () => context.push('/asset-details', extra: asset),
      borderRadius: BorderRadius.circular(2),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardTheme.color,
          borderRadius: BorderRadius.circular(2),
          border: theme.cardTheme.shape is RoundedRectangleBorder
              ? Border.fromBorderSide(
                  (theme.cardTheme.shape as RoundedRectangleBorder).side)
              : Border.all(
                  color: colorScheme.onSurface.withValues(alpha: 0.05)),
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                image: asset.iconPath != null
                    ? DecorationImage(
                        image: AssetImage(asset.iconPath!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: asset.iconPath == null
                  ? Center(
                      child: Text(
                        asset.symbol.isNotEmpty ? asset.symbol[0] : '?',
                        style: textTheme.titleMedium
                            ?.copyWith(color: colorScheme.onSurface),
                      ),
                    )
                  : null,
            ),

            const SizedBox(width: 16),

            // Name and Symbol
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    asset.name.isNotEmpty ? asset.name : 'Unknown Token',
                    style: textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    asset.symbol.isNotEmpty ? asset.symbol : 'TOKEN',
                    style: textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.5),
                      letterSpacing: 0,
                    ),
                  ),
                ],
              ),
            ),

            // Balance and Price
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  isPrivacyMode
                      ? '••••'
                      : (asset.price.isFinite && asset.price > 0
                          ? '\$${asset.valueUsd.toStringAsFixed(2)}'
                          : '—'),
                  style: textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isPrivacyMode
                          ? '•••• ${asset.symbol}'
                          : '${asset.formattedBalance} ${asset.symbol}',
                      style: textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.5),
                        letterSpacing: 0,
                      ),
                    ),
                    if (asset.changePercentage24h != 0) ...[
                      const SizedBox(width: 8),
                      Text(
                        '${asset.changePercentage24h >= 0 ? '+' : ''}${asset.changePercentage24h}%',
                        style: textTheme.labelSmall?.copyWith(
                          color: asset.changePercentage24h >= 0
                              ? AppColors.success
                              : AppColors.error,
                          letterSpacing: 0,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
