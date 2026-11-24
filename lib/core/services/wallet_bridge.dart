import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dapp_session_guard.dart';
import 'dapp_transaction_review.dart';
import 'dapp_network_verifier.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:xeris_wallet/core/config/network_config.dart';
import 'base_api_service.dart';
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
  final DAppTransactionReview? transactionReview;

  DAppRequest({
    required this.id,
    required this.method,
    required this.params,
    required this.dappOrigin,
    this.transactionReview,
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
typedef DAppEnsureCurrent = Future<void> Function();

class _PendingDAppRequest {
  final int wireId;
  final DAppRequestScope scope;
  _PendingDAppRequest(this.wireId, this.scope);
}

class XerisWalletBridge {
  /// Returns the user's current public key (base58 string)
  final String Function() getPublicKey;

  /// Signs a base64-encoded transaction and returns the signed tx as base64
  /// along with the signature. The wallet should show an approval dialog
  /// before calling this.
  final Future<SignResult> Function(String txBase64,
      {required DAppEnsureCurrent ensureCurrent,
      required DAppTransactionReview review}) signTransaction;

  /// Signs an arbitrary message and returns the signature as base64.
  final Future<String> Function(Uint8List message,
      {required DAppEnsureCurrent ensureCurrent,
      required String expectedSigner}) signMessage;

  /// The RPC endpoint URL for the Xeris node
  final String rpcUrl;
  final bool Function()? isActive;
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
  DAppSessionGuard? _sessionGuard;
  final _requests = <int, _PendingDAppRequest>{};
  final _reservations = <String, Object>{};
  int _nextNativeId = 0;
  bool _approvalPending = false;

  String? get providerScript => _providerScript;

  XerisWalletBridge({
    required this.getPublicKey,
    required this.signTransaction,
    required this.signMessage,
    required this.rpcUrl,
    this.isActive,
    this.onApprovalRequired,
  }) : _networkScope = NetworkConfig.cacheKey;

  Future<void> _ensureCurrent(int id) async {
    final request = _requests[id];
    if (request == null || _sessionGuard == null) {
      throw StateError('The wallet request is no longer active.');
    }
    await _sessionGuard!.ensureCurrent(request.scope);
    if (_requests[id] != request) {
      throw StateError('The wallet request was replaced.');
    }
  }

  Future<bool> _isConnected(int id, String origin) async {
    await _ensureCurrent(id);
    final walletId = _requests[id]!.scope.walletId;
    if (walletId == null) return false;
    final sites = await StorageService.getConnectedSites(walletId);
    await _ensureCurrent(id);
    return sites.contains(origin);
  }

  Future<void> _persistConnect(int id, String origin) async {
    await _ensureCurrent(id);
    final walletId = _requests[id]!.scope.walletId;
    if (walletId == null) return;
    await persistDAppConnection(
      ensureCurrent: () => _ensureCurrent(id),
      contains: () async =>
          (await StorageService.getConnectedSites(walletId)).contains(origin),
      add: () => StorageService.addConnectedSite(walletId, origin),
      remove: () => StorageService.removeConnectedSite(walletId, origin),
    );
  }

  Future<void> _persistDisconnect(int id, String origin) async {
    await _ensureCurrent(id);
    final walletId = _requests[id]!.scope.walletId;
    if (walletId == null) return;
    await StorageService.removeConnectedSite(walletId, origin);
    await _ensureCurrent(id);
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
  Future<bool> attachToWebView(
      InAppWebViewController controller, BuildContext context) async {
    _controller = controller;
    _context = context;
    _sessionGuard = DAppSessionGuard(
      networkScope: _networkScope,
      isActive: isActive,
      currentNetworkScope: () => NetworkConfig.cacheKey,
      currentPublicKey: getPublicKey,
      currentWalletId: StorageService.getActiveWalletId,
      currentTopLevelUrl: () async {
        final url = await controller.getUrl();
        return url == null ? null : Uri.tryParse(url.toString());
      },
      isCurrentDocument: (documentId) async =>
          await controller.evaluateJavascript(
            source: 'window.__xerisDocumentId === ${jsonEncode(documentId)}',
          ) ==
          true,
    );
    if (defaultTargetPlatform == TargetPlatform.android &&
        !await WebViewFeature.isFeatureSupported(
            WebViewFeature.WEB_MESSAGE_LISTENER)) {
      return false; // Read-only browsing; no insecure callHandler fallback.
    }
    await controller.addWebMessageListener(WebMessageListener(
      jsObjectName: 'XerisWalletNative',
      // This is a general dApp browser. All callers are still checked below:
      // native main frame, HTTPS, current top origin, active wallet and consent.
      allowedOriginRules: {'*'},
      onPostMessage: (message, sourceOrigin, isMainFrame, replyProxy) {
        final data = message?.data;
        if (data is! String || data.length > 65536) return;
        _handleMessage(
          data,
          sourceOrigin: sourceOrigin == null
              ? null
              : Uri.tryParse(sourceOrigin.toString()),
          isMainFrame: isMainFrame,
        );
      },
    ));
    return true;
  }

  void navigationStarted() {
    _sessionGuard?.navigationStarted();
    _requests.clear();
    _reservations.clear();
  }

  void close() {
    _sessionGuard?.close();
    _requests.clear();
    _reservations.clear();
    _controller = null;
    _context = null;
  }

  Future<void> injectProvider() async {
    if (_controller == null || _providerScript == null) return;
    await _controller!.evaluateJavascript(source: _providerScript!);
  }

  Future<void> _handleMessage(
    String messageStr, {
    required Uri? sourceOrigin,
    required bool isMainFrame,
  }) async {
    String? reservationKey;
    Object? reservation;
    int? nativeId;
    try {
      final message = jsonDecode(messageStr);
      if (message is! Map<String, dynamic>) return;
      final wireId = message['id'];
      final documentId = message['document_id'];
      final method = message['method'];
      final params = message['params'];
      if (wireId is! int ||
          wireId < 1 ||
          wireId > 2147483647 ||
          documentId is! String ||
          method is! String ||
          params is! Map<String, dynamic> ||
          _sessionGuard == null) {
        return;
      }
      reservationKey = '$documentId:$wireId';
      if (_reservations.containsKey(reservationKey) ||
          _reservations.length >= 16) {
        return;
      }
      reservation = Object();
      _reservations[reservationKey] = reservation;
      final scope = await _sessionGuard!.pin(
        sourceOrigin: sourceOrigin,
        isMainFrame: isMainFrame,
        documentId: documentId,
      );
      nativeId = ++_nextNativeId;
      _requests[nativeId] = _PendingDAppRequest(wireId, scope);
      final id = nativeId;
      final currentOrigin = scope.origin;
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
          if (!await _isConnected(id, currentOrigin)) {
            _sendError(id, 'DApp not connected');
            break;
          }
          _sendResponse(id, {'rpcUrl': rpcUrl});
          break;
        case 'requestAirdrop':
          if (!await _isConnected(id, currentOrigin)) {
            _sendError(id, 'DApp not connected');
            break;
          }
          await _handleRequestAirdrop(id, params);
          break;
        case 'getBalances':
          if (!await _isConnected(id, currentOrigin)) {
            _sendError(id, 'DApp not connected');
            break;
          }
          await _handleGetBalances(id);
          break;
        default:
          _sendError(id, 'Unsupported wallet method.');
      }
    } catch (_) {
      if (nativeId != null) {
        _sendError(nativeId,
            'The page, wallet or network changed, or the request was rejected. Review again.');
      }
    } finally {
      if (nativeId != null) _requests.remove(nativeId);
      if (reservationKey != null &&
          _reservations[reservationKey] == reservation) {
        _reservations.remove(reservationKey);
      }
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
    final alreadyConnected = await _isConnected(id, origin);

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
      await _persistConnect(id, origin);
    }

    _sendResponse(id, {
      'publicKey': publicKey,
      'network': 'xeris-${NetworkConfig.currentNetwork.name}',
    });
  }

  Future<void> _handleDisconnect(int id, String origin) async {
    await _persistDisconnect(id, origin);
    _sendResponse(id, {'disconnected': true});
  }

  Future<void> _handleSignTransaction(
      int id, Map<String, dynamic> params, String origin) async {
    final txBase64 = params['transaction'] as String?;
    if (txBase64 == null || txBase64.isEmpty || txBase64.length > 16384) {
      _sendError(id, 'Missing transaction data');
      return;
    }

    // Ensure connected first
    if (!await _isConnected(id, origin)) {
      _sendError(id, 'DApp not connected');
      return;
    }

    final review =
        DAppTransactionReview.parse(txBase64, _requests[id]!.scope.publicKey);
    await DAppMainnetVerifier.verify(review.blockhash);
    await _ensureCurrent(id);
    final approved = await _requestApproval(DAppRequest(
      id: id,
      method: 'signTransaction',
      params: const {},
      transactionReview: review,
      dappOrigin: origin,
    ));
    if (!approved) {
      _sendError(id, 'User rejected the transaction');
      return;
    }

    try {
      final result = await signTransaction(txBase64,
          ensureCurrent: () => _ensureCurrent(id), review: review);
      await _ensureCurrent(id);
      _sendResponse(id, {
        'signature': result.signature,
        'signedTransaction': result.signedTxBase64,
      });
    } catch (e) {
      _sendError(id, 'Signing was rejected or could not be completed.');
    }
  }

  Future<void> _handleSignAllTransactions(
      int id, Map<String, dynamic> params, String origin) async {
    _sendError(
        id, 'Batch signing is unavailable. Review one transaction at a time.');
  }

  Future<void> _handleSignAndSendTransaction(
      int id, Map<String, dynamic> params, String origin) async {
    _sendError(id,
        'Automatic submission is unavailable. Use signTransaction with tracked submission and receipt recovery.');
  }

  Future<void> _handleSignMessage(
      int id, Map<String, dynamic> params, String origin) async {
    final msgBase64 = params['message'] as String?;
    if (msgBase64 == null || msgBase64.isEmpty || msgBase64.length > 10924) {
      _sendError(id, 'Missing message');
      return;
    }

    if (!await _isConnected(id, origin)) {
      _sendError(id, 'DApp not connected');
      return;
    }

    late final Uint8List messageBytes;
    String preview;
    try {
      messageBytes = base64Decode(msgBase64);
      if (messageBytes.isEmpty ||
          messageBytes.length > 8192 ||
          base64Encode(messageBytes) != msgBase64) {
        throw const FormatException();
      }
      preview = reviewDAppMessage(messageBytes);
    } catch (_) {
      _sendError(id, 'Invalid or oversized message.');
      return;
    }

    await DAppMainnetVerifier.verifyIdentity();
    await _ensureCurrent(id);
    final approved = await _requestApproval(DAppRequest(
      id: id,
      method: 'signMessage',
      params: {'message': preview},
      dappOrigin: origin,
    ));
    if (!approved) {
      _sendError(id, 'User rejected message signing');
      return;
    }

    try {
      final signature = await signMessage(Uint8List.fromList(messageBytes),
          ensureCurrent: () => _ensureCurrent(id),
          expectedSigner: _requests[id]!.scope.publicKey);
      await _ensureCurrent(id);
      _sendResponse(id, {'signature': signature});
    } catch (e) {
      _sendError(id, 'Message signing was rejected or could not be completed.');
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
    await _ensureCurrent(request.id);
    if (_approvalPending || _context == null) return false;
    _approvalPending = true;
    try {
      final approved = onApprovalRequired != null
          ? await onApprovalRequired!(_context!, request)
          : await showDialog<bool>(
                context: _context!,
                barrierDismissible: false,
                builder: (ctx) => _DefaultApprovalDialog(request: request),
              ) ??
              false;
      await _ensureCurrent(request.id);
      return approved;
    } finally {
      _approvalPending = false;
    }
  }

  // ==========================================================================
  // RESPONSE HELPERS
  // ==========================================================================

  void _sendResponse(int id, dynamic result) => _reply(id, result, null);
  void _sendError(int id, String error) => _reply(id, null, error);

  void _reply(int id, dynamic result, String? error) {
    final request = _requests[id];
    if (request == null ||
        _controller == null ||
        _sessionGuard?.isCurrentSynchronously(request.scope) != true) {
      return;
    }
    // Stable plugin6.1.5 reuses its native reply proxy for the last caller.
    // Never use that mutable proxy for signing responses. Main-frame evaluation
    // plus the per-document nonce prevents a late reply reaching a new page.
    final documentId = jsonEncode(request.scope.documentId);
    final response =
        jsonEncode({'id': request.wireId, 'result': result, 'error': error});
    _controller!.evaluateJavascript(
        source:
            'if(window.__xerisDocumentId === $documentId && window.__xerisNativeResponse) { window.__xerisNativeResponse($response); }');
  }

  /// Notify the dApp that the account has changed (e.g., user switches wallet)
  void notifyAccountChanged(String? newPublicKey) {
    navigationStarted();
    if (_controller == null) return;
    if (newPublicKey != null) {
      _controller!.evaluateJavascript(
        source: 'window.__xerisAccountChanged(${jsonEncode(newPublicKey)})',
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
      content: SingleChildScrollView(
          child: Column(
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
          if (request.transactionReview != null) ...[
            const SizedBox(height: 16),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 280),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: request.transactionReview!.display.entries
                      .map((entry) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(entry.key,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600)),
                                  SelectableText(entry.value),
                                ]),
                          ))
                      .toList(),
                ),
              ),
            ),
          ],
          if (request.method == 'signMessage') ...[
            const SizedBox(height: 16),
            const Text('Message to sign',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 240),
              child: SingleChildScrollView(
                child:
                    SelectableText(request.params['message'] as String? ?? ''),
              ),
            ),
          ],
        ],
      )),
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
