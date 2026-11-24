import 'dart:collection';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:xeris_wallet/core/providers/wallet_provider.dart';
import 'package:xeris_wallet/core/theme/app_theme.dart';
import 'package:xeris_wallet/core/services/auth_service.dart';
import 'package:xeris_wallet/core/services/wallet_bridge.dart';
import 'package:xeris_wallet/core/services/wallet_service.dart';
import 'package:xeris_wallet/core/config/network_config.dart';
import 'package:xeris_wallet/core/services/storage_service.dart';
import 'package:xeris_wallet/core/utils/context_extensions.dart';
import 'package:xeris_wallet/features/dapp_browser/widgets/browser_homepage.dart';
import 'package:xeris_wallet/core/models/browser_bookmark.dart';

class DAppBrowserScreen extends ConsumerStatefulWidget {
  final String initialUrl;

  const DAppBrowserScreen({
    super.key,
    this.initialUrl = 'xeris://home',
  });

  @override
  ConsumerState<DAppBrowserScreen> createState() => _DAppBrowserScreenState();
}

class BrowserTab {
  InAppWebViewController? controller;
  final XerisWalletBridge bridge;
  String url;
  String? title;
  double progress;
  bool isSecure;
  bool isLoading;

  BrowserTab({
    this.controller,
    required this.bridge,
    required this.url,
    this.title,
    this.progress = 0.0,
    this.isSecure = false,
    this.isLoading = true,
  });

  bool get isHome => url == 'xeris://home';
}

class _DAppBrowserScreenState extends ConsumerState<DAppBrowserScreen> {
  late TextEditingController _urlController;
  final List<BrowserTab> _tabs = [];
  int _activeTabIndex = 0;
  bool _isDependenciesLoaded = false;
  String? _cachedProviderScript;

  BrowserTab get _activeTab => _tabs[_activeTabIndex];

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController(text: widget.initialUrl == 'xeris://home' ? '' : widget.initialUrl);
    // Don't add the tab yet, we'll wait for the script in build()
  }

  void _addNewTab(String url, {bool loadImmediately = true}) {
    if (_tabs.length >= 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maximum tab limit reached (10). Please close some tabs.')),
      );
      return;
    }

    final bridge = XerisWalletBridge(
      getPublicKey: () => ref.read(walletAddressProvider).value ?? '',
      signTransaction: _signTx,
      signMessage: _signMsg,
      rpcUrl: NetworkConfig.rpcUrl,
    );

    final tab = BrowserTab(
      controller: null, // Will be set when InAppWebView is created
      bridge: bridge,
      url: url,
      isSecure: url.startsWith('https'),
      isLoading: url != 'xeris://home',
    );

    setState(() {
      _tabs.add(tab);
      _activeTabIndex = _tabs.length - 1;
      _urlController.text = url == 'xeris://home' ? '' : url;
    });

    if (loadImmediately && _isDependenciesLoaded && tab.controller != null && !tab.isHome) {
      _loadAndInject(tab);
    } else if (loadImmediately && _isDependenciesLoaded && _cachedProviderScript == null && !tab.isHome) {
      // If script not loaded yet, load it then the page will pick it up on rebuild
      _tabs.first.bridge.loadProviderScript(context).then((script) {
        if (mounted) {
          setState(() {
            _cachedProviderScript = script;
          });
          tab.controller?.loadUrl(urlRequest: URLRequest(url: WebUri(url)));
        }
      });
    }
  }

  Future<void> _loadAndInject(BrowserTab tab) async {
    if (_cachedProviderScript == null) {
      _cachedProviderScript = await tab.bridge.loadProviderScript(context);
      if (mounted) setState(() {});
    }
    if (tab.isHome) return;
    tab.controller?.loadUrl(urlRequest: URLRequest(url: WebUri(tab.url)));
  }

  void _closeTab(int index) {
    if (_tabs.length <= 1) return; // Don't close the last tab
    setState(() {
      _tabs.removeAt(index);
      if (_activeTabIndex >= _tabs.length) {
        _activeTabIndex = _tabs.length - 1;
      }
      _urlController.text = _activeTab.isHome ? '' : _activeTab.url;
    });
  }

  void _switchTab(int index) {
    setState(() {
      _activeTabIndex = index;
      _urlController.text = _activeTab.isHome ? '' : _activeTab.url;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isDependenciesLoaded) {
      _isDependenciesLoaded = true;
      // Load script once (all tabs share the same asset)
      // We load it directly from assets so it doesn't depend on having a tab/bridge instance yet
      DefaultAssetBundle.of(context)
          .loadString('assets/xeris_provider.js')
          .then((script) {
        if (mounted) {
          setState(() {
            _cachedProviderScript = script;
          });
        }
      });
    }
  }

  Future<SignResult> _signTx(String txBase64) async {
    if (!mounted) throw Exception('User rejected the transaction');
    final twoFactor = await StorageService.getTwoFactorEnabled();
    if (!mounted) throw Exception('User rejected the transaction');
    final ok = await AuthService.authenticate(context, requireTwoFactor: twoFactor);
    if (!ok) throw Exception('User rejected the transaction');
    final mnemonic = await StorageService.getMnemonic();
    if (mnemonic == null) throw Exception('No wallet connected');
    final result = await WalletService.signDAppTransaction(
      mnemonic: mnemonic,
      txBase64: txBase64,
    );
    return SignResult(
      signature: result['signature']!,
      signedTxBase64: result['signedTxBase64']!,
    );
  }

  Future<String> _signMsg(Uint8List message) async {
    if (!mounted) throw Exception('User rejected message signing');
    final twoFactor = await StorageService.getTwoFactorEnabled();
    if (!mounted) throw Exception('User rejected message signing');
    final ok = await AuthService.authenticate(context, requireTwoFactor: twoFactor);
    if (!ok) throw Exception('User rejected message signing');
    final mnemonic = await StorageService.getMnemonic();
    if (mnemonic == null) throw Exception('No wallet connected');
    return await WalletService.signDAppMessage(
      mnemonic: mnemonic,
      message: message,
    );
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _handleUrl(String url) async {
    setState(() {
      _urlController.text = url == 'xeris://home' ? '' : url;
    });
  }

  Future<void> _saveBookmark() async {
    if (_activeTab.isHome) return;
    
    final url = _activeTab.url;
    final title = _activeTab.title ?? 'Untitled Site';
    
    final bookmark = BrowserBookmark(
      title: title,
      url: url,
    );
    
    await StorageService.saveBookmark(bookmark);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Saved bookmark: $title')),
      );
    }
  }

  void _showTabsOverlay() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.brandMidnight,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Tabs',
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add, color: Colors.white),
                        onPressed: () {
                          Navigator.pop(context);
                          _addNewTab('xeris://home');
                        },
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: _tabs.length,
                    itemBuilder: (context, index) {
                      final tab = _tabs[index];
                      final isActive = index == _activeTabIndex;
                      return ListTile(
                        leading: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppColors.brandSpace,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: tab.isHome 
                              ? const Icon(Icons.home, color: AppColors.brandVibrant, size: 20)
                              : Text(
                                  tab.title?.isNotEmpty == true ? tab.title![0].toUpperCase() : '?',
                                  style: const TextStyle(color: AppColors.brandVibrant, fontWeight: FontWeight.bold),
                                ),
                          ),
                        ),
                        title: Text(
                          tab.isHome ? 'Xeris web4 browser' : (tab.title ?? tab.url),

                          style: TextStyle(color: isActive ? AppColors.brandVibrant : Colors.white),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          tab.isHome ? 'Tap to explore' : tab.url,
                          style: const TextStyle(color: Colors.white54),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.close, color: Colors.redAccent),
                          onPressed: () {
                            if (_tabs.length > 1) {
                              _closeTab(index);
                              setModalState(() {});
                            }
                          },
                        ),
                        onTap: () {
                          _switchTab(index);
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isDependenciesLoaded || _cachedProviderScript == null) {
      return const Scaffold(
        backgroundColor: AppColors.brandNavy,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_tabs.isEmpty) {
      // Add initial tab if it's missing (should only happen on first build after loading script)
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_tabs.isEmpty) {
          _addNewTab(widget.initialUrl);
        }
      });
      return const Scaffold(
        backgroundColor: AppColors.brandNavy,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // When the active wallet changes, force every dApp tab to drop its
    // session so trust is re-evaluated per-wallet (see security audit F5).
    ref.listen(walletAddressProvider, (prev, next) {
      final prevAddr = prev?.value;
      final nextAddr = next.value;
      if (prevAddr == null || nextAddr == null || prevAddr == nextAddr) return;
      for (final tab in _tabs) {
        tab.bridge.notifyAccountChanged(null);
      }
    });

    final l10n = context.l10n;
    return VisibilityDetector(
      key: const Key('dapp_browser'),
      onVisibilityChanged: (info) {
        // webview_flutter has no pause/resume
      },
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) async {
          if (didPop) return;
          if (_activeTab.controller != null && await _activeTab.controller!.canGoBack()) {
            await _activeTab.controller!.goBack();
          }
        },
        child: Scaffold(
          backgroundColor: AppColors.brandNavy,
          appBar: AppBar(
            backgroundColor: AppColors.brandMidnight,
            elevation: 0,
            titleSpacing: 0,
            title: Container(
              height: 40,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: AppColors.brandSpace,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: Row(
                children: [
                  Icon(
                    _activeTab.isSecure ? Icons.lock : Icons.lock_open,
                    size: 14,
                    color: _activeTab.isSecure ? Colors.green : Colors.orange,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _urlController,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: l10n.searchOrEnterUrl,
                        hintStyle: const TextStyle(color: Colors.white54, fontSize: 13),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      onSubmitted: (value) {
                        var url = value.trim();
                        if (url.isEmpty) return;
                        if (!url.contains('.') && !url.startsWith('http')) {
                          url = 'https://www.google.com/search?q=${Uri.encodeComponent(url)}';
                        } else if (!url.startsWith('http')) {
                          url = 'https://$url';
                        }
                        
                        setState(() {
                          _activeTab.url = url;
                          _activeTab.isSecure = url.startsWith('https');
                          _activeTab.isLoading = true;
                        });
                        
                        if (_activeTab.controller != null) {
                          _activeTab.controller!.loadUrl(urlRequest: URLRequest(url: WebUri(url)));
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.bookmark_add_outlined, color: Colors.white, size: 20),
                onPressed: _activeTab.isHome ? null : _saveBookmark,
              ),
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white, size: 20),
                onPressed: () {
                   if (_activeTab.controller != null) {
                      _activeTab.controller!.reload();
                   }
                },
              ),
            ],
          ),
          body: IndexedStack(
            index: _activeTabIndex,
            children: _tabs.map((tab) => Column(
              children: [
                if (tab.progress < 1.0 && !tab.isHome)
                  LinearProgressIndicator(
                    value: tab.progress,
                    backgroundColor: Colors.transparent,
                    color: AppColors.brandVibrant,
                    minHeight: 2,
                  ),
                Expanded(
                  child: tab.isHome 
                    ? BrowserHomepage(
                        onUrlSelected: (url) {
                          setState(() {
                            tab.url = url;
                            tab.isSecure = url.startsWith('https');
                            tab.isLoading = true;
                          });
                          if (tab.controller != null) {
                            tab.controller!.loadUrl(urlRequest: URLRequest(url: WebUri(url)));
                          }
                        },
                      )
                    : InAppWebView(
                        initialUrlRequest: URLRequest(url: WebUri(tab.url)),
                        initialSettings: InAppWebViewSettings(
                          javaScriptEnabled: true,
                          transparentBackground: false,
                          useOnLoadResource: true,
                          allowsInlineMediaPlayback: true,
                        ),
                        initialUserScripts: UnmodifiableListView<UserScript>([
                          if (_cachedProviderScript != null)
                            UserScript(
                              source: _cachedProviderScript!,
                              injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START,
                              forMainFrameOnly: true,
                            ),
                        ]),
                        onWebViewCreated: (controller) {
                          tab.controller = controller;
                          tab.bridge.attachToWebView(controller, context);
                        },
                        onLoadStart: (controller, url) {
                          if (url != null) {
                            final urlStr = url.toString();
                            debugPrint('[DAppBrowser] onLoadStart: $urlStr');
                            if (_tabs[_activeTabIndex] == tab) {
                               _handleUrl(urlStr);
                            }
                            setState(() {
                              tab.isLoading = true;
                              tab.url = urlStr;
                              tab.isSecure = urlStr.startsWith('https');
                            });
                          }
                        },
                        onLoadStop: (controller, url) async {
                          setState(() {
                            tab.isLoading = false;
                          });
                          final title = await controller.getTitle();
                          setState(() {
                            tab.title = title;
                          });
                        },
                        onProgressChanged: (controller, progress) {
                          setState(() {
                            tab.progress = progress / 100;
                          });
                        },
                        shouldOverrideUrlLoading: (controller, navigationAction) async {
                          final reqUrl = navigationAction.request.url?.toString();
                          if (reqUrl == null) return NavigationActionPolicy.ALLOW;
                          final uri = Uri.tryParse(reqUrl);

                          if (reqUrl.startsWith('wc:') || reqUrl.startsWith('walletconnect:')) {
                            return NavigationActionPolicy.CANCEL;
                          }
                          if (uri != null && uri.path.contains('/wc') && uri.queryParameters.containsKey('uri')) {
                            return NavigationActionPolicy.CANCEL;
                          }
                          if (uri != null && uri.scheme != 'http' && uri.scheme != 'https') {
                            return NavigationActionPolicy.CANCEL;
                          }

                          return NavigationActionPolicy.ALLOW;
                        },
                      ),
                ),
              ],
            )).toList(),
          ),
          bottomNavigationBar: Container(
            color: AppColors.brandMidnight,
            padding: const EdgeInsets.only(bottom: 100), // Add padding to clear floating nav
            child: SafeArea(
              top: false, 
              child: SizedBox(
                height: 50,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: Colors.white),
                      onPressed: () async {
                        if (_activeTab.controller != null && await _activeTab.controller!.canGoBack()) {
                          _activeTab.controller!.goBack();
                        }
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.arrow_forward_ios, size: 18, color: Colors.white),
                      onPressed: () async {
                        if (_activeTab.controller != null && await _activeTab.controller!.canGoForward()) {
                          _activeTab.controller!.goForward();
                        }
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.home_outlined, size: 24, color: Colors.white),
                      onPressed: () {
                        setState(() {
                          _activeTab.url = 'xeris://home';
                          _urlController.text = '';
                        });
                      },
                    ),
                    InkWell(
                      onTap: _showTabsOverlay,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white, width: 1.5),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${_tabs.length}',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.share_outlined, size: 22, color: Colors.white),
                      onPressed: () async {
                        final url = _activeTab.url;
                        if (url != 'xeris://home') {
                          // Share logic here
                          debugPrint('Sharing URL: $url');
                          // Simple share to clipboard as fallback if no share plugin
                          await Clipboard.setData(ClipboardData(text: url));
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('URL copied to clipboard')),
                            );
                          }
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
