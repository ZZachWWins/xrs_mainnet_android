import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:xeris_wallet/core/services/dapp_network_verifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:xeris_wallet/core/services/base_api_service.dart';
import 'package:xeris_wallet/core/services/storage_service.dart';
import 'package:xeris_wallet/core/services/wallet_bridge.dart';
import 'package:xeris_wallet/features/dapp_browser/browser_tab_lifecycle.dart';

bool featureSupported = true;
int apiCalls = 0;
final fixture = (jsonDecode(
        File('test/fixtures/dapp-signing-vectors.json').readAsStringSync())
    as Map)['positives'][0] as Map;
final signer = fixture['signer'] as String;
final unsigned = fixture['transaction'] as String;

class Feature extends PlatformWebViewFeature {
  Feature()
      : super.implementation(const PlatformWebViewFeatureCreationParams());
  @override
  Future<bool> isFeatureSupported(WebViewFeature feature) async =>
      featureSupported;
}

class ListenerPlatform extends InAppWebViewPlatform {
  @override
  PlatformWebViewFeature createPlatformWebViewFeatureStatic() => Feature();
  @override
  PlatformWebMessageListener createPlatformWebMessageListener(
          PlatformWebMessageListenerCreationParams params) =>
      Listener(params);
}

class Listener extends PlatformWebMessageListener {
  Listener(super.params) : super.implementation();
}

class NeverReplyProxy extends Fake implements PlatformJavaScriptReplyProxy {
  @override
  Future<void> postMessage(WebMessage message) async => fail(
      'The mutable per-listener reply proxy must never carry wallet responses.');
}

class Controller extends Fake implements InAppWebViewController {
  WebUri? url = WebUri('https://dex.xerisweb.com/?network=mainnet');
  String documentId = 'a' * 32;
  WebMessageListener? listener;
  final responses = <String>[];
  @override
  Future<WebUri?> getUrl() async => url;
  @override
  Future<void> addWebMessageListener(WebMessageListener value) async {
    listener = value;
  }

  @override
  Future<dynamic> evaluateJavascript(
      {required String source, ContentWorld? contentWorld}) async {
    if (source.startsWith('window.__xerisDocumentId ===')) {
      return source.contains(jsonEncode(documentId));
    }
    responses.add(source);
    return null;
  }

  void call(String method,
      {int id = 1,
      Map<String, dynamic> params = const {},
      String origin = 'https://dex.xerisweb.com',
      bool main = true}) {
    listener!.onPostMessage!(
        WebMessage(
            data: jsonEncode({
          'id': id,
          'document_id': documentId,
          'method': method,
          'params': params
        })),
        WebUri(origin),
        main,
        NeverReplyProxy());
  }
}

void main() {
  setUp(() {
    featureSupported = true;
    apiCalls = 0;
    DAppMainnetVerifier.readOverride = (path) async {
      final now = DateTime.now().millisecondsSinceEpoch;
      return path.contains('/slot/')
          ? {
              'success': true,
              'data': {
                'slot': 27201,
                'hash': DAppMainnetVerifier.checkpointHash
              },
              'attestation': {
                'chain_id': 'xeris-mainnet-v4',
                'generation': 'a' * 64,
                'prefix_verified_at_ms': now,
                'observed_at_ms': now
              }
            }
          : {
              'success': true,
              'data': [
                {'slot': 27202, 'hash': 'a' * 64, 'poh_timestamp': now}
              ]
            };
    };
    InAppWebViewPlatform.instance = ListenerPlatform();
    FlutterSecureStorage.setMockInitialValues({});
    BaseApiService.clientOverride = MockClient((_) async {
      apiCalls++;
      return http.Response('{}', 500);
    });
  });
  tearDown(() {
    expect(apiCalls, 0);
    BaseApiService.clientOverride = null;
    DAppMainnetVerifier.readOverride = null;
  });

  Future<BuildContext> context(WidgetTester tester) async {
    late BuildContext result;
    await tester.pumpWidget(MaterialApp(home: Builder(builder: (ctx) {
      result = ctx;
      return const SizedBox();
    })));
    await StorageService.setActiveWalletId('fixture-wallet');
    await StorageService.addConnectedSite(
        'fixture-wallet', 'https://dex.xerisweb.com');
    return result;
  }

  testWidgets(
      'iframe and different actual origins never trigger approval or signing',
      (tester) async {
    final ctx = await context(tester), controller = Controller();
    var approvals = 0, signs = 0;
    final bridge = XerisWalletBridge(
        getPublicKey: () => signer,
        rpcUrl: 'https://mainnetrpc.xerisweb.com',
        signTransaction: (tx, {required ensureCurrent, required review}) async {
          signs++;
          return SignResult(signature: 'fixture', signedTxBase64: tx);
        },
        signMessage: (message,
            {required ensureCurrent, required expectedSigner}) async {
          signs++;
          return 'fixture';
        },
        onApprovalRequired: (ctx, request) async {
          approvals++;
          return true;
        });
    await bridge.attachToWebView(controller, ctx);
    controller.call('signTransaction',
        params: {'transaction': unsigned}, main: false);
    controller.call('signTransaction',
        id: 2,
        params: {'transaction': unsigned},
        origin: 'https://evil.example');
    controller.call('connect', id: 3, origin: 'http://dex.xerisweb.com');
    await tester.pump();
    expect(approvals, 0);
    expect(signs, 0);
    expect(controller.responses, isEmpty);
    bridge.close();
  });
  testWidgets(
      'trusted sign-only call is guarded and replies only to original document nonce',
      (tester) async {
    final ctx = await context(tester), controller = Controller();
    var signs = 0;
    final bridge = XerisWalletBridge(
        getPublicKey: () => signer,
        rpcUrl: 'https://mainnetrpc.xerisweb.com',
        signTransaction: (tx, {required ensureCurrent, required review}) async {
          await ensureCurrent();
          signs++;
          return SignResult(signature: 'fixture', signedTxBase64: tx);
        },
        signMessage: (message,
                {required ensureCurrent, required expectedSigner}) async =>
            'fixture',
        onApprovalRequired: (ctx, request) async => true);
    await bridge.attachToWebView(controller, ctx);
    controller
        .call('signTransaction', id: 17, params: {'transaction': unsigned});
    await tester.pump();
    expect(signs, 1);
    expect(controller.responses.length, 1);
    expect(controller.responses.single,
        contains(jsonEncode(controller.documentId)));
    expect(controller.responses.single, contains('"id":17'));
    expect(controller.responses.single, contains('signedTransaction'));
    bridge.close();
  });
  testWidgets(
      'navigation and wallet changes during approval prevent signer access',
      (tester) async {
    for (final changeWallet in [false, true]) {
      final ctx = await context(tester),
          controller = Controller(),
          approval = Completer<bool>();
      var signs = 0, approvals = 0;
      final bridge = XerisWalletBridge(
          getPublicKey: () => signer,
          rpcUrl: 'https://mainnetrpc.xerisweb.com',
          signTransaction: (tx,
              {required ensureCurrent, required review}) async {
            signs++;
            return SignResult(signature: 'fixture', signedTxBase64: tx);
          },
          signMessage: (message,
                  {required ensureCurrent, required expectedSigner}) async =>
              'fixture',
          onApprovalRequired: (ctx, request) {
            approvals++;
            return approval.future;
          });
      await bridge.attachToWebView(controller, ctx);
      controller.call('signTransaction', params: {'transaction': unsigned});
      await tester.pump();
      expect(approvals, 1);
      if (changeWallet) {
        await StorageService.setActiveWalletId('another-wallet');
      } else {
        bridge.navigationStarted();
        controller.documentId = 'b' * 32;
        controller.url = WebUri('https://another.example');
      }
      approval.complete(true);
      await tester.pump();
      expect(signs, 0);
      if (changeWallet) {
        expect(controller.responses.join(), contains('"result":null'));
        expect(
            controller.responses.join(), isNot(contains('signedTransaction')));
      } else {
        expect(controller.responses, isEmpty);
      }
      bridge.close();
    }
  });
  testWidgets(
      'sign-and-send is unavailable before approval, signing or submission',
      (tester) async {
    final ctx = await context(tester), controller = Controller();
    var signs = 0, prompts = 0;
    final bridge = XerisWalletBridge(
        getPublicKey: () => signer,
        rpcUrl: 'https://mainnetrpc.xerisweb.com',
        signTransaction: (tx, {required ensureCurrent, required review}) async {
          signs++;
          throw StateError('unexpected');
        },
        signMessage: (message,
                {required ensureCurrent, required expectedSigner}) async =>
            throw StateError('unexpected'),
        onApprovalRequired: (ctx, request) async {
          prompts++;
          return true;
        });
    await bridge.attachToWebView(controller, ctx);
    controller
        .call('signAndSendTransaction', params: {'transaction': unsigned});
    await tester.pump();
    expect(signs, 0);
    expect(prompts, 0);
    expect(apiCalls, 0);
    expect(controller.responses.single,
        contains('Use signTransaction with tracked submission'));
    bridge.close();
  });
  testWidgets(
      'ownership approval receives complete decoded message and duplicate requests do not duplicate prompts',
      (tester) async {
    final ctx = await context(tester),
        controller = Controller(),
        approval = Completer<bool>();
    var approvals = 0;
    String? preview;
    final bridge = XerisWalletBridge(
        getPublicKey: () => signer,
        rpcUrl: 'https://mainnetrpc.xerisweb.com',
        signTransaction: (tx,
                {required ensureCurrent, required review}) async =>
            SignResult(signature: 'fixture', signedTxBase64: tx),
        signMessage: (message,
            {required ensureCurrent, required expectedSigner}) async {
          fail('Rejected proof must not sign.');
        },
        onApprovalRequired: (ctx, request) {
          approvals++;
          preview = request.params['message'] as String;
          return approval.future;
        });
    await bridge.attachToWebView(controller, ctx);
    const message =
        'Xeris settlement ownership proof\nrecipient: fixture-destination\namount_raw: 500000';
    final params = {'message': base64Encode(utf8.encode(message))};
    controller.call('signMessage', params: params);
    controller.call('signMessage', params: params);
    await tester.pump();
    expect(approvals, 1);
    expect(preview, message);
    approval.complete(false);
    await tester.pump();
    expect(controller.responses.length, 1);
    bridge.close();
  });

  testWidgets(
      'unsupported native caller-metadata feature leaves browsing read-only without an insecure fallback',
      (tester) async {
    final ctx = await context(tester), controller = Controller();
    featureSupported = false;
    final bridge = XerisWalletBridge(
      getPublicKey: () => signer,
      rpcUrl: 'https://mainnetrpc.xerisweb.com',
      signTransaction: (tx, {required ensureCurrent, required review}) async =>
          throw StateError('Must not sign.'),
      signMessage: (message,
              {required ensureCurrent, required expectedSigner}) async =>
          throw StateError('Must not sign.'),
    );
    expect(await bridge.attachToWebView(controller, ctx), false);
    expect(controller.listener, isNull);
    bridge.close();
  });
  testWidgets(
      'native approval contains complete exact effects without dApp supplied labels',
      (tester) async {
    final ctx = await context(tester), controller = Controller();
    Map<String, String>? effects;
    final bridge = XerisWalletBridge(
        getPublicKey: () => signer,
        rpcUrl: 'https://mainnetrpc.xerisweb.com',
        signTransaction: (tx,
                {required ensureCurrent, required review}) async =>
            throw StateError('Rejected before signing'),
        signMessage: (message,
                {required ensureCurrent, required expectedSigner}) async =>
            throw StateError('Rejected before signing'),
        onApprovalRequired: (ctx, request) async {
          effects = request.transactionReview!.display;
          expect(request.params, isEmpty);
          return false;
        });
    await bridge.attachToWebView(controller, ctx);
    controller.call('signTransaction', params: {
      'transaction': unsigned,
      'amount': '0',
      'recipient': 'malicious label'
    });
    await tester.pump();
    expect(effects!['Amount'], '1000.000001 xUSDC');
    expect(effects!['Minimum received'], '0.000999999 wXRS');
    expect(effects!['Recipient'], signer);
    expect(effects!['Pool'], 'xrs-xusdc-mainnet-v1');
    expect(effects!['Network fee'], '0.001 native XRS');
    bridge.close();
  });
  testWidgets(
      'malformed transactions, batch signing and hidden/binary messages never prompt',
      (tester) async {
    final ctx = await context(tester), controller = Controller();
    var prompts = 0, signs = 0;
    final bridge = XerisWalletBridge(
        getPublicKey: () => signer,
        rpcUrl: 'https://mainnetrpc.xerisweb.com',
        signTransaction: (tx, {required ensureCurrent, required review}) async {
          signs++;
          throw StateError('unexpected');
        },
        signMessage: (message,
            {required ensureCurrent, required expectedSigner}) async {
          signs++;
          return 'unexpected';
        },
        onApprovalRequired: (ctx, request) async {
          prompts++;
          return true;
        });
    await bridge.attachToWebView(controller, ctx);
    controller.call('signTransaction', params: {'transaction': 'AQ=='});
    controller.call('signAllTransactions', id: 2, params: {
      'transactions': [unsigned]
    });
    controller.call('signMessage', id: 3, params: {
      'message': base64Encode([1, 0, 0])
    });
    controller.call('signMessage', id: 4, params: {
      'message': base64Encode(utf8.encode('recipient:\u200b hidden'))
    });
    await tester.pump();
    expect(prompts, 0);
    expect(signs, 0);
    expect(controller.responses.length, 4);
    bridge.close();
  });
  testWidgets('inactive native tab rejects even a valid connected request',
      (tester) async {
    final ctx = await context(tester), controller = Controller();
    var prompts = 0;
    final bridge = XerisWalletBridge(
        getPublicKey: () => signer,
        rpcUrl: 'https://mainnetrpc.xerisweb.com',
        isActive: () => false,
        signTransaction: (tx,
                {required ensureCurrent, required review}) async =>
            throw StateError('unexpected'),
        signMessage: (message,
                {required ensureCurrent, required expectedSigner}) async =>
            throw StateError('unexpected'),
        onApprovalRequired: (ctx, request) async {
          prompts++;
          return true;
        });
    await bridge.attachToWebView(controller, ctx);
    controller.call('signTransaction', params: {'transaction': unsigned});
    await tester.pump();
    expect(prompts, 0);
    expect(controller.responses, isEmpty);
    bridge.close();
  });
  testWidgets(
      'leaving parent Web4 while approval awaits cannot sign after returning',
      (tester) async {
    final ctx = await context(tester),
        controller = Controller(),
        selected = ValueNotifier(true),
        approval = Completer<bool>();
    var signs = 0, prompts = 0;
    late final XerisWalletBridge bridge;
    final activity = BrowserPageActivity(
        selected: selected, onHidden: () => bridge.navigationStarted());
    bridge = XerisWalletBridge(
        getPublicKey: () => signer,
        rpcUrl: 'https://mainnetrpc.xerisweb.com',
        isActive: () => activity.isSelected,
        signTransaction: (tx, {required ensureCurrent, required review}) async {
          signs++;
          throw StateError('unexpected');
        },
        signMessage: (message,
            {required ensureCurrent, required expectedSigner}) async {
          signs++;
          return 'unexpected';
        },
        onApprovalRequired: (ctx, request) {
          prompts++;
          return approval.future;
        });
    await bridge.attachToWebView(controller, ctx);
    controller.call('signTransaction', params: {'transaction': unsigned});
    await tester.pump();
    expect(prompts, 1);
    selected.value = false;
    selected.value = true;
    approval.complete(true);
    await tester.pump();
    expect(signs, 0);
    expect(apiCalls, 0);
    expect(controller.responses, isEmpty);
    activity.dispose();
    selected.dispose();
    bridge.close();
  });
}
