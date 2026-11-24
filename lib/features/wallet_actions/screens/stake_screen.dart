import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xeris_wallet/core/models/xeris_api_models.dart';
import 'package:xeris_wallet/core/providers/wallet_provider.dart';
import 'package:xeris_wallet/core/theme/app_theme.dart';
import 'package:xeris_wallet/features/wallet_actions/providers/staking_provider.dart';
import 'package:xeris_wallet/l10n/app_localizations.dart';
import 'package:xeris_wallet/core/utils/string_extensions.dart';
import 'package:xeris_wallet/core/utils/amount_utils.dart';

class StakeScreen extends ConsumerStatefulWidget {
  final String validatorAddress;

  const StakeScreen({super.key, required this.validatorAddress});

  @override
  ConsumerState<StakeScreen> createState() => _StakeScreenState();
}

class _StakeScreenState extends ConsumerState<StakeScreen> {
  final _amountController = TextEditingController();
  final _addressController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.validatorAddress.isNotEmpty) {
      _addressController.text = widget.validatorAddress;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _setPercentageAmount(double percentage, double balance) {
    // Leave a little for fees if 100%
    final amount = percentage == 1.0 ? (balance > 0.01 ? balance - 0.01 : 0.0) : balance * percentage;
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
            Text(l10n.confirmStakeTitle, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Text(
              l10n.confirmStakeDesc(amount.toStringAsFixed(4), validator.safeSubstring(0, 8)),
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
                  const Icon(Icons.info_outline, color: Colors.amber, size: 20),
                  const SizedBox(width: 12),
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
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  ref.read(stakingProvider.notifier).stakeXrs(validator, amount);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brandVibrant,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Confirm & Stake', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
    final balance = ref.watch(walletBalanceProvider).value ?? 0.0;
    final l10n = AppLocalizations.of(context)!;

    final XerisValidator? selectedValidator = state.validators.isEmpty 
      ? null 
      : state.validators.firstWhere(
          (v) => v.address == _addressController.text,
          orElse: () => state.validators.first,
        );

    return Scaffold(
      backgroundColor: AppColors.brandNavy,
      appBar: AppBar(
        title: Text(l10n.stake),
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Validator Info
              if (selectedValidator != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: AppColors.brandSpace,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        backgroundColor: AppColors.brandNavy,
                        child: Icon(Icons.security, color: AppColors.brandVibrant),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.validatorAddress(selectedValidator.address.safeSubstring(0, 8)),
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              l10n.commissionLabel(selectedValidator.commission.toStringAsFixed(0)),
                              style: const TextStyle(color: AppColors.brandVibrant, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

              TextField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Validator Address',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white10,
                ),
                readOnly: widget.validatorAddress.isNotEmpty, 
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 16),
              
              const Text('Amount to Stake', style: TextStyle(color: Colors.white70, fontSize: 14)),
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
                children: [25, 50, 75, 100].map((p) => _buildPercentButton(p / 100, '$p%', balance)).toList(),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: Text('Available: ${balance.toStringAsFixed(4)} XRS', style: const TextStyle(color: Colors.white54, fontSize: 12)),
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
                  onPressed: state.isLoading ? null : () {
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
                      ? const CircularProgressIndicator(color: Colors.white) 
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
