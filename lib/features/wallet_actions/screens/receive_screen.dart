import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:xeris_wallet/core/theme/app_theme.dart';
import 'package:xeris_wallet/core/providers/wallet_provider.dart';
import 'package:xeris_wallet/core/providers/stealth_provider.dart';
import 'package:xeris_wallet/core/config/network_config.dart';
import 'package:xeris_wallet/core/providers/network_provider.dart';

class ReceiveScreen extends ConsumerStatefulWidget {
  const ReceiveScreen({super.key});

  @override
  ConsumerState<ReceiveScreen> createState() => _ReceiveScreenState();
}

class _ReceiveScreenState extends ConsumerState<ReceiveScreen> {
  bool _useStealth = false;

  @override
  Widget build(BuildContext context) {
    ref.watch(networkProvider);
    final activeWalletAsync = ref.watch(activeWalletProvider);
    final stealthMetaAsync = NetworkConfig.stealthEnabled
        ? ref.watch(stealthMetaAddressProvider)
        : null;

    return activeWalletAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, stack) => Scaffold(body: Center(child: Text('Error: $err'))),
      data: (activeWallet) {
        final baseAddress = activeWallet?.address ?? 'No wallet selected';

        // Resolve the display address based on stealth toggle
        String displayAddress;
        if (_useStealth && stealthMetaAsync != null) {
          displayAddress = stealthMetaAsync.when(
            data: (meta) => meta?.encode() ?? 'Generating...',
            loading: () => 'Generating...',
            error: (_, __) => 'Error generating stealth address',
          );
        } else {
          displayAddress = baseAddress;
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Receive'),
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                const SizedBox(height: 20),
                // QR Code Container
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: QrImageView(
                    data: displayAddress,
                    version: QrVersions.auto,
                    size: 240.0,
                    eyeStyle: const QrEyeStyle(
                      eyeShape: QrEyeShape.square,
                      color: AppColors.brandBlue,
                    ),
                    dataModuleStyle: const QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.square,
                      color: AppColors.brandBlue,
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Mainnet never advertises an undiscoverable receive address.
                if (NetworkConfig.stealthEnabled)
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.brandSpace,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: SegmentedButton<bool>(
                      segments: const [
                        ButtonSegment(
                          value: false,
                          label: Text('Standard'),
                          icon: Icon(Icons.account_balance_wallet),
                        ),
                        ButtonSegment(
                          value: true,
                          label: Text('Stealth'),
                          icon: Icon(Icons.visibility_off),
                        ),
                      ],
                      selected: {_useStealth},
                      onSelectionChanged: (Set<bool> newSelection) {
                        setState(() {
                          _useStealth = newSelection.first;
                        });
                      },
                      style: ButtonStyle(
                        backgroundColor:
                            WidgetStateProperty.resolveWith<Color>((states) {
                          if (states.contains(WidgetState.selected)) {
                            return AppColors.brandBlue;
                          }
                          return AppColors.brandSpace;
                        }),
                        foregroundColor:
                            WidgetStateProperty.resolveWith<Color>((states) {
                          if (states.contains(WidgetState.selected)) {
                            return Colors.white;
                          }
                          return AppColors.textBody;
                        }),
                      ),
                    ),
                  ),

                const SizedBox(height: 32),

                // Address Box
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.brandSpace,
                    borderRadius: BorderRadius.circular(20),
                    border:
                        Border.all(color: Colors.white.withValues(alpha: 0.05)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        _useStealth
                            ? 'YOUR STEALTH ADDRESS'
                            : 'YOUR PUBLIC ADDRESS',
                        style: const TextStyle(
                          color: AppColors.textBody,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        displayAddress,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _ActionButton(
                            icon: Icons.copy,
                            label: 'Copy',
                            onTap: () {
                              Clipboard.setData(
                                  ClipboardData(text: displayAddress));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content:
                                        Text('Address copied to clipboard')),
                              );
                            },
                          ),
                          const SizedBox(width: 24),
                          _ActionButton(
                            icon: Icons.share,
                            label: 'Share',
                            onTap: () {
                              SharePlus.instance.share(ShareParams(
                                  text: displayAddress,
                                  subject: 'My Xeris Wallet Address'));
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                if (_useStealth) ...[
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.brandBlue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: AppColors.brandBlue.withValues(alpha: 0.2)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline, color: AppColors.brandBlue),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Stealth addresses provide enhanced privacy by decoupling your identity from transactions. '
                            'Each sender derives a unique one-time address — only you can claim the funds.',
                            style:
                                TextStyle(color: Colors.white70, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.brandBlue.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.brandBlue),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
