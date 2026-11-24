import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:xeris_wallet/core/theme/app_theme.dart';
import 'package:xeris_wallet/features/wallet_actions/providers/staking_provider.dart';
import 'package:xeris_wallet/core/providers/wallet_provider.dart';
import 'package:xeris_wallet/core/utils/string_extensions.dart';
import 'package:xeris_wallet/l10n/app_localizations.dart';

class ValidatorsScreen extends ConsumerStatefulWidget {
  const ValidatorsScreen({super.key});

  @override
  ConsumerState<ValidatorsScreen> createState() => _ValidatorsScreenState();
}

class _ValidatorsScreenState extends ConsumerState<ValidatorsScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(stakingProvider);
    final l10n = AppLocalizations.of(context)!;

    final filteredValidators = state.validators.where((v) {
      return v.address.toLowerCase().contains(_searchQuery) ||
             v.nodePubkey.toLowerCase().contains(_searchQuery);
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.brandNavy,
      appBar: AppBar(
        title: Text(l10n.earnRewardsTitle),
        backgroundColor: Colors.transparent,
      ),
      body: state.isLoading && state.validators.isEmpty
          ? const Center(child: CircularProgressIndicator(color: AppColors.brandVibrant))
          : state.error != null && state.validators.isEmpty
              ? Center(child: Text(state.error!, style: const TextStyle(color: AppColors.brandError)))
              : Column(
                  children: [
                    // Staked Balance Summary
                    Consumer(
                      builder: (context, ref, child) {
                        final stakedBalance = ref.watch(stakedBalanceProvider).value ?? 0.0;
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppColors.brandSpace, AppColors.brandMidnight],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white10),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      l10n.stakedBalance,
                                      style: const TextStyle(color: Colors.white70, fontSize: 14),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${stakedBalance.toStringAsFixed(4)} XRS',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              ElevatedButton(
                                onPressed: () => context.push('/unstake'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white10,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: const BorderSide(color: Colors.white24),
                                  ),
                                ),
                                child: Text(l10n.unstake),
                              ),
                            ],
                          ),
                        );
                      },
                    ),

                    // Search Field
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: l10n.searchValidators,
                          prefixIcon: const Icon(Icons.search, color: Colors.white54),
                          filled: true,
                          fillColor: Colors.white10,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),

                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: filteredValidators.isEmpty ? 1 : filteredValidators.length,
                        itemBuilder: (context, index) {
                          if (state.validators.isEmpty) {
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.all(32.0),
                                child: Text(
                                  l10n.noValidatorsFound,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(color: Colors.white70),
                                ),
                              ),
                            );
                          }

                          if (filteredValidators.isEmpty) {
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.all(32.0),
                                child: Text(
                                  l10n.noMatchingValidators,
                                  style: const TextStyle(color: Colors.white70),
                                ),
                              ),
                            );
                          }

                          final validator = filteredValidators[index];
                          return Card(
                            color: AppColors.brandMidnight,
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Colors.white10)),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Row(
                                children: [
                                  const CircleAvatar(
                                    backgroundColor: AppColors.brandSpace,
                                    child: Icon(Icons.security, color: AppColors.brandVibrant),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          l10n.validatorAddress(validator.address.safeSubstring(0, 4)),
                                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Text(
                                              l10n.stakeAmount((validator.stake / 1e9).toStringAsFixed(0)),
                                              style: const TextStyle(color: Colors.white70, fontSize: 12),
                                            ),
                                            const SizedBox(width: 12),
                                            Text(
                                              l10n.commissionLabel(validator.commission.toStringAsFixed(0)),
                                              style: const TextStyle(color: AppColors.brandVibrant, fontSize: 12, fontWeight: FontWeight.bold),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  ElevatedButton(
                                    onPressed: () {
                                      context.push('/stake', extra: validator.address);
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.brandVibrant,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                      padding: const EdgeInsets.symmetric(horizontal: 16),
                                    ),
                                    child: Text(l10n.stake, style: const TextStyle(color: Colors.white)),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
       floatingActionButton: state.validators.isEmpty ? FloatingActionButton.extended(
          onPressed: () {
               context.push('/stake', extra: '');
          },
          label: Text(l10n.directStake),
          icon: const Icon(Icons.generating_tokens),
          backgroundColor: AppColors.brandVibrant,
       ) : null,
    );
  }
}
