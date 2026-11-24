import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xeris_wallet/core/providers/wallet_provider.dart';
import 'package:xeris_wallet/core/theme/app_theme.dart';
import 'package:xeris_wallet/features/wallet_actions/providers/staking_provider.dart';
import 'package:xeris_wallet/l10n/app_localizations.dart';
import 'package:xeris_wallet/core/utils/string_extensions.dart';
import 'package:xeris_wallet/core/utils/amount_utils.dart';

class UnstakeScreen extends ConsumerStatefulWidget {
  const UnstakeScreen({super.key});

  @override
  ConsumerState<UnstakeScreen> createState() => _UnstakeScreenState();
}

class _UnstakeScreenState extends ConsumerState<UnstakeScreen> {
  final _amountController = TextEditingController();
  final _addressController = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _setPercentageAmount(double percentage, double stakedBalance) {
    final amount = stakedBalance * percentage;
    _amountController.text = amount.toStringAsFixed(4);
  }

  void _showConfirmation(BuildContext context, String validator, double amount) {
    final l10n = AppLocalizations.of(context)!;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.brandNavy,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.confirmUnstakeTitle, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Text(
              l10n.confirmUnstakeDesc(amount.toStringAsFixed(4), validator.safeSubstring(0, 8)),
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.timer, color: Colors.amber, size: 20),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Unstaking takes 7 days. Tokens are locked during unbonding.',
                      style: TextStyle(color: Colors.amber, fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  ref.read(stakingProvider.notifier).unstakeXrs(validator, amount);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brandVibrant,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Confirm & Unstake', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(stakingProvider);
    final stakedBalance = ref.watch(stakedBalanceProvider).value ?? 0.0;
    final userAddress = ref.watch(walletAddressProvider).value;
    final l10n = AppLocalizations.of(context)!;

    if (_addressController.text.isEmpty && userAddress != null && userAddress != 'No Wallet') {
      _addressController.text = userAddress;
    }

    final stakingInfo = ref.watch(stakingInfoProvider).value;
    final unbondingBalance = stakingInfo?.unbonding ?? 0;
    final unlockAt = stakingInfo?.unlockAt;

    return Scaffold(
      backgroundColor: AppColors.brandNavy,
      appBar: AppBar(
        title: Text(l10n.unstake),
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 7-Day Notice Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.timer, color: Colors.amber, size: 24),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        l10n.unbondingNotice,
                        style: const TextStyle(color: Colors.amber, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              if (unbondingBalance > 0)
                Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.brandSpace,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.brandVibrant.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Pending Release', style: TextStyle(color: Colors.white70, fontSize: 14)),
                            Text('${(unbondingBalance / 1e9).toStringAsFixed(4)} XRS', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        if (unlockAt != null) ...[
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Unlock At Slot', style: TextStyle(color: Colors.white54, fontSize: 12)),
                              Text('$unlockAt', style: const TextStyle(color: AppColors.brandVibrant, fontSize: 12, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              
              const Text('Target Validator', style: TextStyle(color: Colors.white70, fontSize: 14)),
              const SizedBox(height: 8),
              TextField(
                controller: _addressController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white10,
                  hintText: 'Validator Address',
                ),
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
              const SizedBox(height: 24),

              const Text('Amount to Unstake', style: TextStyle(color: Colors.white70, fontSize: 14)),
              const SizedBox(height: 8),
              TextField(
                controller: _amountController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white10,
                  suffixText: 'XRS',
                  suffixStyle: TextStyle(color: Colors.white54),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [25, 50, 75, 100].map((p) => _buildPercentButton(p / 100, '$p%', stakedBalance)).toList(),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: Text('Currently Staked: ${stakedBalance.toStringAsFixed(4)} XRS', style: const TextStyle(color: Colors.white54, fontSize: 12)),
              ),
  
              const SizedBox(height: 40),
  
              if (state.error != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(color: AppColors.brandError.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text(state.error!, style: const TextStyle(color: AppColors.brandError), textAlign: TextAlign.center),
                ),
              
              if (state.resultMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(color: AppColors.brandSuccess.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text(state.resultMessage!, style: const TextStyle(color: AppColors.brandSuccess), textAlign: TextAlign.center),
                ),
  
               SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: state.isLoading ? null : () async {
                      final amount = parseAmount(_amountController.text) ?? 0;
                      final address = _addressController.text;
                      if (amount > 0 && address.isNotEmpty) {
                          _showConfirmation(context, address, amount);
                      }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brandVibrant,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: state.isLoading 
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                      : const Text('Continue', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPercentButton(double percentage, String label, double balance) {
    return InkWell(
      onTap: () => _setPercentageAmount(percentage, balance),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white10,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white10),
        ),
        child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
