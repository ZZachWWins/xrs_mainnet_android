import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:xeris_wallet/core/config/network_config.dart';
import 'base_api_service.dart';
import 'wallet_service.dart';
import '../utils/context_extensions.dart';
import 'storage_service.dart';
import 'xeris_api_service.dart';

// ============================================================================
// XERIS WALLET BRIDGE
//
// Handles communication between the injected JS provider (xeris_provider.js)
// and the native Flutter wallet.
//
// INTEGRATION STEPS:
//   1. Copy this file into your Flutter project (e.g., lib/wallet_bridge.dart)
//   2. Copy xeris_provider.js into assets/ folder
//   3. In your WebView screen, create the bridge and attach it
//   4. See XerisDAppBrowser widget at the bottom for a complete example
//
// DEPENDENCIES (add to pubspec.yaml):
//   flutter_inappwebview: ^6.0.0
//   http: ^1.1.0
//   (your existing keypair/crypto packages)
// ============================================================================

/// Represents a pending request from a dApp waiting for user approval/signing
class DAppRequest {
  final int id;
  final String method;
  final Map<String, dynamic> params;
  final String dappOrigin;

  DAppRequest({
    required this.id,
    required this.method,
    required this.params,
    required this.dappOrigin,
  });
}

/// The core bridge that handles messages from the injected JS provider.
///
/// Usage:
///   final bridge = XerisWalletBridge(
///     getPublicKey: () => myWallet.publicKey,
///     signTransaction: (txBase64) => myWallet.sign(txBase64),
///     rpcUrl: 'http://138.197.116.81:56001',
///   );
///   bridge.attachToWebView(webViewController);
class XerisWalletBridge {
  /// Returns the user's current public key (base58 string)
  final String Function() getPublicKey;

  /// Signs a base64-encoded transaction and returns the signed tx as base64
  /// along with the signature. The wallet should show an approval dialog
  /// before calling this.
  final Future<SignResult> Function(String txBase64) signTransaction;

  /// Signs an arbitrary message and returns the signature as base64.
  final Future<String> Function(Uint8List message) signMessage;

  /// The RPC endpoint URL for the Xeris node
  final String rpcUrl;
  final String _networkScope;

  /// Called when a dApp requests approval. Show your custom UI here.
  /// Return true to approve, false to reject.
  final Future<bool> Function(BuildContext context, DAppRequest request)?
      onApprovalRequired;

  /// BuildContext for showing dialogs (set via attachToWebView)
  BuildContext? _context;

  /// The WebViewController to send responses back to JS
  InAppWebViewController? _controller;

  /// The JS provider script content (loaded from assets)
  String? _providerScript;

  String? get providerScript => _providerScript;

  XerisWalletBridge({
    required this.getPublicKey,
    required this.signTransaction,
    required this.signMessage,
    required this.rpcUrl,
    this.onApprovalRequired,
  }) : _networkScope = NetworkConfig.cacheKey;

  /// Returns true if the given origin is currently trusted for the active wallet.
  /// Looked up per-call so wallet switches immediately revoke trust.
  Future<bool> _isConnected(String origin) async {
    final walletId = await StorageService.getActiveWalletId();
    if (walletId == null) return false;
    final sites = await StorageService.getConnectedSites(walletId);
    return sites.contains(origin);
  }

  Future<void> _persistConnect(String origin) async {
    final walletId = await StorageService.getActiveWalletId();
    if (walletId == null) return;
    await StorageService.addConnectedSite(walletId, origin);
  }

  Future<void> _persistDisconnect(String origin) async {
    final walletId = await StorageService.getActiveWalletId();
    if (walletId == null) return;
    await StorageService.removeConnectedSite(walletId, origin);
  }

  /// Load the provider JS from assets. Call once at startup.
  Future<String> loadProviderScript(BuildContext context) async {
    _providerScript = await DefaultAssetBundle.of(context)
        .loadString('assets/xeris_provider.js');
    return _providerScript!;
  }

  /// Alternatively, set the script directly (if you bundle it as a string)
  void setProviderScript(String script) {
    _providerScript = script;
  }

  /// Attach this bridge to a WebViewController.
  /// Call this after creating the controller but before loading any URL.
  void attachToWebView(
      InAppWebViewController controller, BuildContext context) {
    _controller = controller;
    _context = context;

    // Register the JavaScript handler for flutter_inappwebview
    controller.addJavaScriptHandler(
      handlerName: 'XerisWallet',
      callback: (args) {
        debugPrint('[XerisWalletBridge] Received message: $args');
        if (args.isNotEmpty) {
          // inappwebview passing args as a list
          final dynamic message = args[0];
          if (message is String) {
            _handleMessage(message);
          } else if (message is Map) {
            _handleMessage(jsonEncode(message));
          }
        }
        return null; // Handlers can return a value to JS
      },
    );
  }

  /// Inject the JS provider into the current page
  Future<void> injectProvider() async {
    if (_controller == null || _providerScript == null) return;
    await _controller!.evaluateJavascript(source: _providerScript!);
  }

  /// Handle an incoming message from the JS provider
  Future<void> _handleMessage(String messageStr) async {
    try {
      final Map<String, dynamic> message = jsonDecode(messageStr);
      final int id = message['id'] as int;
      final String method = message['method'] as String;
      if (_networkScope != NetworkConfig.cacheKey) {
        _sendError(
            id, 'Network changed. Open a new browser tab to connect again.');
        return;
      }
      final Map<String, dynamic> params =
          (message['params'] as Map<String, dynamic>?) ?? {};

      // Detect origin from the current URL if available
      String? origin;
      if (_controller != null) {
        final url = await _controller!.getUrl();
        if (url != null) {
          origin = url.origin;
        }
      }

      final currentOrigin = origin ?? 'unknown';

      switch (method) {
        case 'connect':
          await _handleConnect(id, params, currentOrigin);
          break;
        case 'disconnect':
          await _handleDisconnect(id, currentOrigin);
          break;
        case 'signTransaction':
          await _handleSignTransaction(id, params, currentOrigin);
          break;
        case 'signAllTransactions':
          await _handleSignAllTransactions(id, params, currentOrigin);
          break;
        case 'signAndSendTransaction':
          await _handleSignAndSendTransaction(id, params, currentOrigin);
          break;
        case 'signMessage':
          await _handleSignMessage(id, params, currentOrigin);
          break;
        case 'getRpcUrl':
          if (!await _isConnected(currentOrigin)) {
            _sendError(id, 'DApp not connected');
            break;
          }
          _sendResponse(id, {'rpcUrl': rpcUrl});
          break;
        case 'requestAirdrop':
          if (!await _isConnected(currentOrigin)) {
            _sendError(id, 'DApp not connected');
            break;
          }
          await _handleRequestAirdrop(id, params);
          break;
        case 'getBalances':
          if (!await _isConnected(currentOrigin)) {
            _sendError(id, 'DApp not connected');
            break;
          }
          await _handleGetBalances(id);
          break;
        default:
          _sendError(id, 'Unknown method: $method');
      }
    } catch (e) {
      debugPrint('[XerisWalletBridge] Error handling message: $e');
    }
  }

  // ==========================================================================
  // METHOD HANDLERS
  // ==========================================================================

  Future<void> _handleConnect(
      int id, Map<String, dynamic> params, String origin) async {
    final publicKey = getPublicKey();
    if (publicKey.isEmpty) {
      _sendError(id, 'No wallet configured');
      return;
    }

    final onlyIfTrusted = params['onlyIfTrusted'] == true;
    final alreadyConnected = await _isConnected(origin);

    // If the dApp only wants to reconnect (no popup), check if already connected
    if (onlyIfTrusted && !alreadyConnected) {
      _sendError(id, 'User has not previously connected');
      return;
    }

    // Show approval dialog for new connections
    if (!alreadyConnected) {
      final approved = await _requestApproval(DAppRequest(
        id: id,
        method: 'connect',
        params: params,
        dappOrigin: origin,
      ));
      if (!approved) {
        _sendError(id, 'User rejected the connection');
        return;
      }
      await _persistConnect(origin);
    }

    _sendResponse(id, {
      'publicKey': publicKey,
      'network': 'xeris-${NetworkConfig.currentNetwork.name}',
    });
  }

  Future<void> _handleDisconnect(int id, String origin) async {
    await _persistDisconnect(origin);
    _sendResponse(id, {'disconnected': true});
  }

  Future<void> _handleSignTransaction(
      int id, Map<String, dynamic> params, String origin) async {
    final txBase64 = params['transaction'] as String?;
    if (txBase64 == null || txBase64.isEmpty) {
      _sendError(id, 'Missing transaction data');
      return;
    }

    // Ensure connected first
    if (!await _isConnected(origin)) {
      _sendError(id, 'DApp not connected');
      return;
    }

    // Show approval dialog
    final approved = await _requestApproval(DAppRequest(
      id: id,
      method: 'signTransaction',
      params: params,
      dappOrigin: origin,
    ));
    if (!approved) {
      _sendError(id, 'User rejected the transaction');
      return;
    }

    try {
      final result = await signTransaction(txBase64);
      _sendResponse(id, {
        'signature': result.signature,
        'signedTransaction': result.signedTxBase64,
      });
    } catch (e) {
      _sendError(id, 'Signing failed: $e');
    }
  }

  Future<void> _handleSignAllTransactions(
      int id, Map<String, dynamic> params, String origin) async {
    final transactions = (params['transactions'] as List?)?.cast<String>();
    if (transactions == null || transactions.isEmpty) {
      _sendError(id, 'Missing transactions');
      return;
    }

    if (!await _isConnected(origin)) {
      _sendError(id, 'DApp not connected');
      return;
    }

    final approved = await _requestApproval(DAppRequest(
      id: id,
      method: 'signAllTransactions',
      params: {'count': transactions.length},
      dappOrigin: origin,
    ));
    if (!approved) {
      _sendError(id, 'User rejected the transactions');
      return;
    }

    try {
      final List<String> signed = [];
      for (final tx in transactions) {
        final result = await signTransaction(tx);
        signed.add(result.signedTxBase64);
      }
      _sendResponse(id, {'signedTransactions': signed});
    } catch (e) {
      _sendError(id, 'Signing failed: $e');
    }
  }

  Future<void> _handleSignAndSendTransaction(
      int id, Map<String, dynamic> params, String origin) async {
    final txBase64 = params['transaction'] as String?;
    if (txBase64 == null || txBase64.isEmpty) {
      _sendError(id, 'Missing transaction data');
      return;
    }

    if (!await _isConnected(origin)) {
      _sendError(id, 'DApp not connected');
      return;
    }

    final approved = await _requestApproval(DAppRequest(
      id: id,
      method: 'signAndSendTransaction',
      params: params,
      dappOrigin: origin,
    ));
    if (!approved) {
      _sendError(id, 'User rejected the transaction');
      return;
    }

    try {
      if (_networkScope != NetworkConfig.cacheKey) {
        throw StateError(
            'Network changed before signing. Open a new browser tab.');
      }
      final result = await signTransaction(txBase64);
      if (_networkScope != NetworkConfig.cacheKey) {
        throw StateError(
            'Network changed before submission. Transaction was not sent.');
      }
      final signature =
          await WalletService.submitTransaction(result.signedTxBase64);
      _sendResponse(id, {'signature': signature});
    } catch (e) {
      _sendError(id, 'Sign and send failed: $e');
    }
  }

  Future<void> _handleSignMessage(
      int id, Map<String, dynamic> params, String origin) async {
    final msgBase64 = params['message'] as String?;
    if (msgBase64 == null || msgBase64.isEmpty) {
      _sendError(id, 'Missing message');
      return;
    }

    if (!await _isConnected(origin)) {
      _sendError(id, 'DApp not connected');
      return;
    }

    final approved = await _requestApproval(DAppRequest(
      id: id,
      method: 'signMessage',
      params: {'message': '(${msgBase64.length} bytes)'},
      dappOrigin: origin,
    ));
    if (!approved) {
      _sendError(id, 'User rejected message signing');
      return;
    }

    try {
      final messageBytes = base64Decode(msgBase64);
      final signature = await signMessage(Uint8List.fromList(messageBytes));
      _sendResponse(id, {'signature': signature});
    } catch (e) {
      _sendError(id, 'Message signing failed: $e');
    }
  }

  Future<void> _handleRequestAirdrop(
      int id, Map<String, dynamic> params) async {
    if (NetworkConfig.currentNetwork != XerisNetwork.testnet) {
      _sendError(id, 'Airdrops are available only on testnet.');
      return;
    }
    final requestedAmount = (params['amount'] as num?)?.toInt() ?? 10;
    final amount = requestedAmount.clamp(1, 10);
    final publicKey = getPublicKey();
    try {
      final response = await BaseApiService.get(
        '${NetworkConfig.controlUrl}/airdrop/$publicKey/$amount',
      );
      _sendResponse(id, response);
    } catch (e) {
      _sendError(id, 'Airdrop request failed: $e');
    }
  }

  Future<void> _handleGetBalances(int id) async {
    try {
      final address = getPublicKey();
      final account = await XerisApiService.getAccountBalances(address);
      final result = [
        {
          'tokenId': 'xrs_native',
          'symbol': 'XRS',
          'name': 'Xeris XRS',
          'balance': (account.nativeXrs * 1e9).round(),
          'balanceXrs': account.nativeXrs,
        },
        ...account.tokenBalances.map((b) => {
              'tokenId': b.tokenId,
              'balance': b.balance,
              'balanceXrs': b.balanceXrs,
            }),
      ];
      _sendResponse(id, result);
    } catch (e) {
      _sendError(id, 'Failed to fetch balances: $e');
    }
  }

  // ==========================================================================
  // APPROVAL UI
  // ==========================================================================

  Future<bool> _requestApproval(DAppRequest request) async {
    // If a custom approval handler is provided, use it
    if (onApprovalRequired != null && _context != null) {
      return await onApprovalRequired!(_context!, request);
    }

    // Default: show a simple Material dialog
    if (_context == null) return false;

    return await showDialog<bool>(
          context: _context!,
          barrierDismissible: false,
          builder: (ctx) => _DefaultApprovalDialog(request: request),
        ) ??
        false;
  }

  // ==========================================================================
  // RESPONSE HELPERS
  // ==========================================================================

  void _sendResponse(int id, dynamic result) {
    if (_controller == null) return;
    final resultJson = jsonEncode(result);
    _controller!.evaluateJavascript(
      source: 'window.__xerisResponse($id, $resultJson, null)',
    );
  }

  void _sendError(int id, String error) {
    if (_controller == null) return;
    final errorJson = jsonEncode(error);
    _controller!.evaluateJavascript(
      source: 'window.__xerisResponse($id, null, $errorJson)',
    );
  }

  /// Notify the dApp that the account has changed (e.g., user switches wallet)
  void notifyAccountChanged(String? newPublicKey) {
    if (_controller == null) return;
    if (newPublicKey != null) {
      _controller!.evaluateJavascript(
        source: 'window.__xerisAccountChanged("$newPublicKey")',
      );
    } else {
      _controller!
          .evaluateJavascript(source: 'window.__xerisAccountChanged(null)');
    }
  }
}

/// Result of signing a transaction
class SignResult {
  final String signature; // Base58 signature string
  final String signedTxBase64; // Full signed transaction, base64 encoded

  SignResult({required this.signature, required this.signedTxBase64});
}

// ============================================================================
// DEFAULT APPROVAL DIALOG
// ============================================================================

class _DefaultApprovalDialog extends StatelessWidget {
  final DAppRequest request;
  const _DefaultApprovalDialog({required this.request});

  String _getTitle(BuildContext context) {
    final l10n = context.l10n;
    switch (request.method) {
      case 'connect':
        return l10n.connectToDapp(request.params['name'] ?? '');
      case 'signTransaction':
        return l10n.signTransactionTitle;
      case 'signAndSendTransaction':
        return l10n.signAndSendTransactionTitle;
      case 'signAllTransactions':
        return l10n.signAllTransactionsTitle(request.params['count'] ?? 0);
      case 'signMessage':
        return l10n.signMessageTitle;
      default:
        return l10n.reviewTransaction;
    }
  }

  String _getDescription(BuildContext context) {
    final l10n = context.l10n;
    switch (request.method) {
      case 'connect':
        return l10n.connectToDappDesc;
      case 'signTransaction':
      case 'signAndSendTransaction':
        return l10n.signTransactionDesc;
      case 'signAllTransactions':
        return l10n.signAllTransactionsDesc(request.params['count'] ?? 0);
      case 'signMessage':
        return l10n.signMessageDesc;
      default:
        return l10n.dappRequestUnknown;
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _getTitle(context);
    final description = _getDescription(context);
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          const Icon(Icons.shield_outlined, color: Colors.amber, size: 28),
          const SizedBox(width: 12),
          Expanded(child: Text(title, style: const TextStyle(fontSize: 18))),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(description),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.language, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    request.dappOrigin,
                    style: TextStyle(color: Colors.grey[700], fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(context.l10n.reject,
              style: const TextStyle(color: Colors.red)),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6C63FF), // Xeris brand purple
            foregroundColor: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: Text(context.l10n.approve),
        ),
      ],
    );
  }
}

// ============================================================================
// END OF XERIS WALLET BRIDGE
// ============================================================================
