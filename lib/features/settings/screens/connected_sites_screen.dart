import 'package:flutter/material.dart';
import 'package:xeris_wallet/core/services/storage_service.dart';
import 'package:xeris_wallet/core/theme/app_theme.dart';
import 'package:xeris_wallet/core/services/notification_service.dart';
import 'package:xeris_wallet/l10n/app_localizations.dart';

class ConnectedSitesScreen extends StatefulWidget {
  const ConnectedSitesScreen({super.key});

  @override
  State<ConnectedSitesScreen> createState() => _ConnectedSitesScreenState();
}

class _ConnectedSitesScreenState extends State<ConnectedSitesScreen> {
  List<String> _connectedSites = [];
  bool _isLoading = true;
  String? _walletId;

  @override
  void initState() {
    super.initState();
    _loadSites();
  }

  Future<void> _loadSites() async {
    final walletId = await StorageService.getActiveWalletId();
    final sites = walletId == null
        ? <String>[]
        : await StorageService.getConnectedSites(walletId);
    if (mounted) {
      setState(() {
        _walletId = walletId;
        _connectedSites = sites;
        _isLoading = false;
      });
    }
  }

  Future<void> _revokeSite(String origin) async {
    final walletId = _walletId;
    if (walletId == null) return;
    await StorageService.removeConnectedSite(walletId, origin);
    if (mounted) {
      setState(() {
        _connectedSites.remove(origin);
      });
      NotificationService.show(
        context,
        AppLocalizations.of(context)!.connectedSiteRevoked,
      );
    }
  }

  Future<void> _revokeAll() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(l10n.revokeAllSitesTitle),
        content: Text(l10n.revokeAllSitesDesc),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              l10n.revokeAll,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final walletId = _walletId;
      if (walletId == null) return;
      await StorageService.clearAllConnectedSites(walletId);
      if (mounted) {
        setState(() => _connectedSites.clear());
        NotificationService.show(context, l10n.allSitesRevoked);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          l10n.connectedSitesTitle,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          if (_connectedSites.isNotEmpty)
            TextButton(
              onPressed: _revokeAll,
              child: Text(
                l10n.revokeAll,
                style: const TextStyle(color: Colors.red, fontSize: 13),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.brandVibrant),
            )
          : _connectedSites.isEmpty
              ? _buildEmptyState(l10n, theme)
              : _buildSitesList(l10n, theme),
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n, ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.brandSpace,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.language_rounded,
                size: 48,
                color: AppColors.textBody,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              l10n.noConnectedSites,
              style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.noConnectedSitesDesc,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textBody, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSitesList(AppLocalizations l10n, ThemeData theme) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _connectedSites.length,
      itemBuilder: (context, index) {
        final origin = _connectedSites[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: theme.cardTheme.color,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.05),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.brandBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.language_rounded,
                    color: theme.brightness == Brightness.dark
                        ? AppColors.brandLight
                        : AppColors.brandBlue,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _extractDomain(origin),
                        style: TextStyle(
                          color: theme.colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        origin,
                        style: TextStyle(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                          fontSize: 11,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () => _revokeSite(origin),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    l10n.revoke,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _extractDomain(String origin) {
    try {
      final uri = Uri.parse(origin);
      return uri.host.isNotEmpty ? uri.host : origin;
    } catch (_) {
      return origin;
    }
  }
}
