import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xeris_wallet/core/models/asset_model.dart';
import 'package:xeris_wallet/core/providers/wallet_provider.dart';
import 'package:xeris_wallet/core/theme/app_theme.dart';
import 'package:xeris_wallet/l10n/app_localizations.dart';

class AssetSelectionModal extends ConsumerStatefulWidget {
  final Function(AssetModel) onSelect;
  final List<String>? allowedSymbols;
  final String? title;
  final bool requireBalance;
  final bool showSearchField;

  const AssetSelectionModal({
    super.key,
    required this.onSelect,
    this.allowedSymbols,
    this.title,
    this.requireBalance = false,
    this.showSearchField = false,
  });

  @override
  ConsumerState<AssetSelectionModal> createState() => _AssetSelectionModalState();

  static void show(
    BuildContext context, {
    required Function(AssetModel) onSelect,
    List<String>? allowedSymbols,
    String? title,
    bool requireBalance = false,
    bool showSearchField = false,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => AssetSelectionModal(
        onSelect: onSelect,
        allowedSymbols: allowedSymbols,
        title: title,
        requireBalance: requireBalance,
        showSearchField: showSearchField,
      ),
    );
  }
}

class _AssetSelectionModalState extends ConsumerState<AssetSelectionModal> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allAssetsAsync = ref.watch(assetsProvider);
    final allAssets = allAssetsAsync.value ?? [];
    final l10n = AppLocalizations.of(context)!;

    var assets = widget.allowedSymbols == null
        ? allAssets
        : allAssets.where((a) {
            final upperSymbol = a.symbol.toUpperCase();
            final upperId = a.id.toUpperCase();
            return widget.allowedSymbols!.any((s) => s.toUpperCase() == upperSymbol || s.toUpperCase() == upperId);
          }).toList();
          
    if (widget.requireBalance) {
      assets = assets.where((a) => a.balance > 0).toList();
    }

    if (_searchQuery.isNotEmpty) {
      assets = assets.where((a) => 
        a.name.toLowerCase().contains(_searchQuery.toLowerCase()) || 
        a.symbol.toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    }

    return Container(
      padding: const EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 0),
      decoration: const BoxDecoration(
        color: AppColors.brandNavy,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(
              widget.title ?? l10n.selectToken,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (widget.showSearchField) ...[
              TextField(
                controller: _searchController,
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val;
                  });
                },
                decoration: InputDecoration(
                  hintText: l10n.searchTokenPlaceholder,
                  prefixIcon: const Icon(Icons.search, color: Colors.white54),
                  filled: true,
                  fillColor: AppColors.brandSpace,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                ),
              ),
              const SizedBox(height: 16),
            ],
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: assets.length,
                separatorBuilder: (_, __) => const Divider(color: Colors.white10),
                itemBuilder: (context, index) {
                  final item = assets[index];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    leading: item.iconPath != null
                        ? Image.asset(
                            item.iconPath!,
                            width: 32,
                            height: 32,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.circle, size: 32, color: Colors.grey),
                          )
                        : const Icon(Icons.circle, size: 32, color: Colors.grey),
                    title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(item.symbol, style: const TextStyle(color: AppColors.textBody)),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          item.balance.toString(),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        if (item.price > 0)
                          Text(
                            '\$${item.valueUsd.toStringAsFixed(2)}',
                            style: const TextStyle(color: AppColors.textBody, fontSize: 12),
                          ),
                      ],
                    ),
                    onTap: () {
                      widget.onSelect(item);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
