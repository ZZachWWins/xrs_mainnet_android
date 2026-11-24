import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:xeris_wallet/core/models/asset_model.dart';
import 'package:xeris_wallet/core/models/transaction_model.dart';
import 'package:xeris_wallet/core/services/xeris_api_service.dart';
import 'package:xeris_wallet/core/theme/app_theme.dart';
import 'package:xeris_wallet/core/providers/wallet_provider.dart';
import 'package:xeris_wallet/l10n/app_localizations.dart';
import 'package:xeris_wallet/core/services/notification_service.dart';
import 'package:xeris_wallet/core/services/wallet_service.dart';
import 'package:intl/intl.dart';
import 'package:xeris_wallet/core/utils/string_extensions.dart';
import 'dart:math';

class AssetDetailsScreen extends ConsumerStatefulWidget {
  final AssetModel asset;

  const AssetDetailsScreen({super.key, required this.asset});

  @override
  ConsumerState<AssetDetailsScreen> createState() => _AssetDetailsScreenState();
}

class _AssetDetailsScreenState extends ConsumerState<AssetDetailsScreen> {
  int? _holdersCount;
  num? _totalSupply;
  List<TransactionModel> _transactions = [];
  bool _isLoadingData = true;
  bool _isLoadingActivity = true;

  @override
  void initState() {
    super.initState();
    _fetchExtraData();
    _fetchActivity();
  }

  Future<void> _fetchExtraData() async {
    try {
      // getTokenHoldersCount is no longer supported via core RPC
      final tokens = await XerisApiService.getTokens();
      final tokenInfo = (tokens == null) ? null : tokens.where((t) => t.id == widget.asset.id).firstOrNull;
      
      if (mounted) {
        setState(() {
          _holdersCount = 0; // Not available via node RPC currently
          _totalSupply = tokenInfo?.totalSupply;
          _isLoadingData = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingData = false);
    }
  }

  Future<void> _fetchActivity() async {
    try {
      final address = await ref.read(walletAddressProvider.future);
      // Fetch transactions using the RPC-based WalletService
      final transactions = await WalletService.getTransactions(address);
      
      if (mounted) {
        setState(() {
          _transactions = transactions.where((tx) => 
            tx.symbol.toLowerCase() == widget.asset.symbol.toLowerCase() || 
            (widget.asset.symbol == 'XRS' && tx.symbol == 'XRS')
          ).toList();
          _isLoadingActivity = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingActivity = false);
    }
  }

  String _formatNumber(num? number) {
    if (number == null) return '---';
    return NumberFormat.compact().format(number);
  }

  String _formatFiat(double amount) {
    final currency = ref.watch(currencyProvider);
    final symbol = currencySymbol(currency);
    final converted = amount * fiatMultiplier(currency);
    return NumberFormat.currency(symbol: symbol, decimalDigits: 2).format(converted);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final actualPrice = widget.asset.price;
    final double? calculatedMarketCap = (_totalSupply != null) 
      ? (_totalSupply!.toDouble() / pow(10, widget.asset.decimals)) * actualPrice 
      : null;

    return Scaffold(
      backgroundColor: AppColors.brandNavy,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(widget.asset.name, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          children: [
            const SizedBox(height: 24),
            
            // Asset Icon and Symbol
            Center(
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.brandDeep,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.brandVibrant.withValues(alpha: 0.2),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                  image: widget.asset.iconPath != null 
                      ? DecorationImage(
                          image: AssetImage(widget.asset.iconPath!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: widget.asset.iconPath == null 
                    ? Center(
                        child: Text(
                          widget.asset.symbol.isNotEmpty ? widget.asset.symbol[0] : '?',
                          style: const TextStyle(fontSize: 32, color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ) 
                    : null,
              ),
            ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
            
            const SizedBox(height: 16),
            
            Text(
              widget.asset.symbol,
              style: TextStyle(
                color: AppColors.textBody.withValues(alpha: 0.7),
                fontSize: 16,
                letterSpacing: 2,
                fontWeight: FontWeight.w500,
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Balance Display
            Column(
              children: [
                Text(
                  '${widget.asset.formattedBalance} ${widget.asset.symbol}',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '≈ ${_formatFiat(widget.asset.valueUsd)}',
                  style: const TextStyle(
                    fontSize: 18,
                    color: AppColors.textBody,
                  ),
                ),
              ],
            ).animate().fadeIn(),

            const SizedBox(height: 24),

            // Send & Receive Buttons
            Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    icon: Icons.arrow_upward_rounded,
                    label: l10n.actionSend,
                    onTap: () => context.push('/send/input', extra: {
                      'initialAsset': widget.asset,
                    }),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ActionButton(
                    icon: Icons.arrow_downward_rounded,
                    label: l10n.actionReceive,
                    onTap: () => context.push('/receive'),
                  ),
                ),
              ],
            ).animate().fadeIn(delay: 100.ms),

            const SizedBox(height: 32),

            // Stats Grid
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              childAspectRatio: 1.6,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                _StatTile(
                  label: l10n.marketCap,
                  value: calculatedMarketCap != null ? _formatFiat(calculatedMarketCap) : '---',
                  isLoading: _isLoadingData,
                ),
                _StatTile(
                  label: l10n.totalHolders,
                  value: _holdersCount != null ? _formatNumber(_holdersCount) : '---',
                  isLoading: _isLoadingData,
                ),
                _StatTile(
                  label: l10n.tokenDecimals,
                  value: widget.asset.decimals.toString(),
                  isLoading: false,
                ),
                _StatTile(
                  label: l10n.price,
                  value: _formatFiat(widget.asset.price),
                  isLoading: false,
                ),
              ],
            ),
            
            const SizedBox(height: 32),

            // Explorer Button Removed

            const SizedBox(height: 40),

            // Token Activity
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                l10n.recentActivity,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 16),
            if (_isLoadingActivity)
              const Center(child: CircularProgressIndicator(color: AppColors.brandVibrant))
            else if (_transactions.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24.0),
                child: Text(l10n.noActivityForToken, style: const TextStyle(color: AppColors.textBody)),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _transactions.length.clamp(0, 5),
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) => _ActivityTile(tx: _transactions[index]),
              ),

            const SizedBox(height: 40),

            // Full Metadata
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                l10n.details,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 16),
            _MetadataRow(label: l10n.tokenStandard, value: 'XTS-1'),
            _MetadataRow(
              label: l10n.mintAddress, 
              value: widget.asset.id, 
              canCopy: true,
              onCopy: () {
                Clipboard.setData(ClipboardData(text: widget.asset.id));
                NotificationService.show(context, l10n.addressCopied);
              },
            ),
            _MetadataRow(label: l10n.totalSupply, value: _totalSupply != null ? _formatNumber(_totalSupply! / pow(10, widget.asset.decimals)) : '---'),
            
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final bool isLoading;

  const _StatTile({required this.label, required this.value, required this.isLoading});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.brandSpace,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textBody, fontSize: 12)),
          const SizedBox(height: 4),
          if (isLoading)
            const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.brandVibrant))
          else
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

class _MetadataRow extends StatelessWidget {
  final String label;
  final String value;
  final bool canCopy;
  final VoidCallback? onCopy;

  const _MetadataRow({required this.label, required this.value, this.canCopy = false, this.onCopy});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textBody, fontSize: 14)),
          const SizedBox(width: 16),
          Expanded(
            child: GestureDetector(
              onTap: canCopy ? onCopy : null,
              child: Text(
                value, 
                style: TextStyle(
                  color: Colors.white, 
                  fontSize: 14, 
                  fontFamily: canCopy ? 'Monospace' : null,
                ),
                textAlign: TextAlign.right,
              ),
            ),
          ),
          if (canCopy) ...[
            const SizedBox(width: 8),
            Icon(Icons.copy, size: 14, color: AppColors.brandVibrant.withValues(alpha: 0.5)),
          ]
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.brandSpace,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.brandVibrant.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: AppColors.brandVibrant, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  final TransactionModel tx;

  const _ActivityTile({required this.tx});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isReceived = tx.type == TransactionType.receive;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.brandSpace.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (isReceived ? Colors.green : Colors.orange).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isReceived ? Icons.arrow_downward : Icons.arrow_upward,
              size: 16,
              color: isReceived ? Colors.green : Colors.orange,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isReceived ? l10n.receivedAsset(tx.symbol) : l10n.sentAsset(tx.symbol),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                Text(
                  '${tx.id.safeSubstring(0, 12)}... · ${DateFormat('MMM d, h:mm a').format(DateTime.parse(tx.date).toLocal())}',
                  style: const TextStyle(color: AppColors.textBody, fontSize: 10),
                ),
              ],
            ),
          ),
          Text(
            '${isReceived ? '+' : '-'}${tx.amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isReceived ? Colors.green : Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

