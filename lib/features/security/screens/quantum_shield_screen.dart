import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:xeris_wallet/core/config/network_config.dart';
import 'package:xeris_wallet/core/providers/privacy_provider.dart';
import 'package:xeris_wallet/core/providers/wallet_provider.dart';
import 'package:xeris_wallet/core/services/pqc_service.dart';
import 'package:xeris_wallet/core/services/storage_service.dart';
import 'package:xeris_wallet/core/services/auth_service.dart';
import 'package:xeris_wallet/core/services/screen_security.dart';
import 'package:xeris_wallet/core/theme/app_theme.dart';
import 'package:xeris_wallet/l10n/app_localizations.dart';
import 'package:xeris_wallet/core/utils/secure_clipboard.dart';

class QuantumShieldScreen extends ConsumerStatefulWidget {
  const QuantumShieldScreen({super.key});

  @override
  ConsumerState<QuantumShieldScreen> createState() =>
      _QuantumShieldScreenState();
}

class _QuantumShieldScreenState extends ConsumerState<QuantumShieldScreen> {
  PqRegistrationStatus _registration = PqRegistrationStatus.unavailable;
  bool get _isRegistered => _registration == PqRegistrationStatus.registered;
  bool _isLoading = true;
  bool _isEnabling = false;

  // Start at 0 so nothing fabricated is shown if the network stats fetch fails;
  // real values are loaded from /pq/status and /zk/stats in _fetchNetworkStats.
  int _zkProofsUsed = 0;
  int _pqKeysRegistered = 0;

  @override
  void initState() {
    super.initState();
    ScreenSecurity.enable();
    _checkStatus();
    _fetchNetworkStats();
  }

  Future<void> _checkStatus() async {
    final address = await ref.read(walletAddressProvider.future);
    if (address != 'No Wallet' && address.isNotEmpty) {
      // Registration is not proof of post-quantum transaction enforcement.
      final status = await PqcService.getRegistrationStatus(address);
      if (mounted) {
        setState(() {
          _registration = status;
          _isLoading = false;
        });
      }
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchNetworkStats() async {
    try {
      final pkResponse =
          await http.get(Uri.parse('${NetworkConfig.controlUrl}/pq/status'));
      if (pkResponse.statusCode == 200) {
        final data = jsonDecode(pkResponse.body);
        if (mounted && data['total_registered'] != null) {
          setState(() {
            _pqKeysRegistered =
                data['total_registered'] is int ? data['total_registered'] : 0;
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching PQ status: $e');
    }

    try {
      final zkResponse =
          await http.get(Uri.parse('${NetworkConfig.controlUrl}/zk/stats'));
      if (zkResponse.statusCode == 200) {
        final data = jsonDecode(zkResponse.body);
        if (mounted && data['total_verified'] != null) {
          setState(() {
            _zkProofsUsed =
                data['total_verified'] is int ? data['total_verified'] : 0;
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching ZK stats: $e');
    }
  }

  Future<bool> _showBackupDialog(String pqPk, String pqSk) async {
    final authenticated = await AuthService.authenticate(context,
        reason: 'Authenticate to reveal your post-quantum backup key');
    if (!authenticated || !mounted) return false;
    bool confirmed = false;
    final l10n = AppLocalizations.of(context)!;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          backgroundColor: AppColors.brandMidnight,
          title: Text(l10n.quantumBackupTitle,
              style: const TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.warning_amber_rounded,
                  color: Colors.orange, size: 48),
              const SizedBox(height: 16),
              Text(
                l10n.quantumBackupWarning,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8), fontSize: 13),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        pqSk,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Colors.white54,
                            fontFamily: 'monospace',
                            fontSize: 10),
                      ),
                    ),
                    IconButton(
                      icon:
                          const Icon(Icons.copy, color: AppColors.brandVibrant),
                      onPressed: () {
                        copySensitiveToClipboard(pqSk);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(l10n.copiedToClipboard)),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              CheckboxListTile(
                value: confirmed,
                onChanged: (v) => setModalState(() => confirmed = v ?? false),
                title: Text(
                  l10n.backupConfirmedLabel,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                controlAffinity: ListTileControlAffinity.leading,
                activeColor: AppColors.brandVibrant,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: confirmed ? () => Navigator.pop(context) : null,
              child: Text(l10n.ok.toUpperCase(),
                  style: TextStyle(
                      color:
                          confirmed ? AppColors.brandVibrant : Colors.white24)),
            ),
          ],
        ),
      ),
    );
    return confirmed;
  }

  Future<void> _enableProtection() async {
    setState(() => _isEnabling = true);
    try {
      final mnemonic = await ref.read(walletMnemonicProvider.future);

      // 1. Derive the PQ keypair deterministically from the wallet seed so it
      //    can be reproduced on any device that holds the recovery phrase.
      final keypair = await PqcService.derivePqcKeypair(mnemonic);
      final pqPk = base64Encode(keypair.publicKey);
      final pqSk = base64Encode(keypair.secretKey);

      // 2. Force backup step
      if (!mounted || !await _showBackupDialog(pqPk, pqSk)) return;

      // 3. Register on-chain after backup confirmation
      final success = await PqcService.registerPqcOnChain(
          mnemonic: mnemonic, pqPk: keypair.publicKey, pqSk: keypair.secretKey);

      if (mounted && success) {
        ref.invalidate(privacyMetricsProvider);
        await _checkStatus();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'PQ key registration submitted. Transfer protection is unchanged.')),
        );
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(l10n.failedToEnablePq(e.toString())),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isEnabling = false);
      }
    }
  }

  @override
  void dispose() {
    ScreenSecurity.disable();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.brandNavy,
        body: Center(
            child: CircularProgressIndicator(color: AppColors.brandVibrant)),
      );
    }

    final shieldColor =
        _isRegistered ? Colors.greenAccent[400]! : AppColors.brandVibrant;
    final shieldGlow = _isRegistered
        ? Colors.greenAccent.withValues(alpha: 0.1)
        : AppColors.brandBlue.withValues(alpha: 0.1);

    return Scaffold(
      backgroundColor: AppColors.brandNavy,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(color: Colors.white),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              // Shield Icon
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.rectangle,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                      color: shieldColor.withValues(alpha: 0.3), width: 1.5),
                  color: shieldGlow,
                  boxShadow: [
                    BoxShadow(
                      color: shieldColor.withValues(alpha: 0.2),
                      blurRadius: 40,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.shield_outlined,
                  size: 40,
                  color: shieldColor,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                PqcService.registrationTitle,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                PqcService.registrationExplanation,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 32),

              // Status Card
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: AppColors.brandSpace,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _isRegistered
                        ? Colors.green.withValues(alpha: 0.3)
                        : Colors.white.withValues(alpha: 0.05),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _isRegistered
                            ? Colors.greenAccent[400]
                            : Colors.redAccent,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: (_isRegistered
                                    ? Colors.greenAccent[400]!
                                    : Colors.redAccent)
                                .withValues(alpha: 0.5),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            PqcService.registrationLabel(_registration),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            PqcService.registrationExplanation,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.5),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: _isRegistered
                              ? Colors.green.withValues(alpha: 0.5)
                              : Colors.orange.withValues(alpha: 0.5),
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _isRegistered ? 'Registered' : 'Unconfirmed',
                        style: TextStyle(
                          color: _isRegistered
                              ? Colors.greenAccent[400]
                              : Colors.orange[300],
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Stats Row
              Row(
                children: [
                  Expanded(
                      child:
                          _buildStatCard('$_zkProofsUsed', l10n.zkProofsUsed)),
                  const SizedBox(width: 12),
                  Expanded(
                      child: _buildStatCard(
                          '$_pqKeysRegistered', l10n.pqKeysRegistered)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildStatCard('4s', l10n.blockTimeStat)),
                ],
              ),

              const SizedBox(height: 40),

              // Warning / Success Box
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _isRegistered
                      ? Colors.green.withValues(alpha: 0.1)
                      : Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _isRegistered
                        ? Colors.green.withValues(alpha: 0.3)
                        : Colors.orange.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      _isRegistered ? Icons.check : Icons.lock_clock,
                      size: 16,
                      color: _isRegistered
                          ? Colors.green[300]
                          : Colors.orange[300],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        PqcService.registrationExplanation,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              if (_isRegistered) ...[
                const SizedBox(height: 16),
                TextButton.icon(
                  onPressed: () async {
                    final sk = await StorageService.getPqSk();
                    if (sk != null && mounted) {
                      _showBackupDialog("...", sk);
                    }
                  },
                  icon: const Icon(Icons.key, color: Colors.white70),
                  label: Text(l10n.viewRecoveryKey,
                      style: const TextStyle(color: Colors.white70)),
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.05),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // Bottom Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isEnabling || _isRegistered
                      ? null
                      : () {
                          if (_registration ==
                              PqRegistrationStatus.unavailable) {
                            _checkStatus();
                          } else {
                            _enableProtection();
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brandVibrant,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _isEnabling
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : Text(
                          _isRegistered
                              ? 'PQ transfers unavailable'
                              : _registration ==
                                      PqRegistrationStatus.unavailable
                                  ? 'Refresh registration status'
                                  : 'Register PQ key',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String value, String label) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.brandSpace,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w900,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 12,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}
