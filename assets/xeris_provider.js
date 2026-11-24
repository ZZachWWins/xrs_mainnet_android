/**
 * XerisCoin Wallet Provider — Injected into WebView by the Xeris DeFi Wallet
 * 
 * dApps access this via `window.xeris` or `window.solana` (Solana-compatible).
 * 
 * Usage in a dApp:
 *   const provider = window.xeris || window.solana;
 *   const resp = await provider.connect();
 *   console.log("Connected:", resp.publicKey.toString());
 *   const signed = await provider.signAndSendTransaction(transaction);
 * 
 * INTEGRATION:
 *   In Flutter, inject this script into WebView before page load.
 *   Set up a JavaScriptChannel named "XerisWallet" to receive messages.
 *   Respond via controller.runJavaScript("window.__xerisResponse(id, result, error)")
 */

(function () {
  'use strict';

  // Prevent double-injection
  if (window.__xerisProviderInjected) return;
  window.__xerisProviderInjected = true;

  // =========================================================================
  // REQUEST/RESPONSE PLUMBING
  // =========================================================================

  let _requestId = 0;
  const _pending = new Map(); // id -> { resolve, reject }
  let _connected = false;
  let _publicKey = null;
  const _listeners = {};

  /**
   * Send a request to the native wallet and return a Promise.
   * The native side calls window.__xerisResponse(id, result, error) to resolve.
   */
  function sendToNative(method, params) {
    return new Promise((resolve, reject) => {
      const id = ++_requestId;
      _pending.set(id, { resolve, reject });

      const message = JSON.stringify({ id, method, params: params || {} });

      // Flutter InAppWebView: callHandler
      if (window.flutter_inappwebview && window.flutter_inappwebview.callHandler) {
        window.flutter_inappwebview.callHandler('XerisWallet', message)
          .then(result => {
            // If the handler returns a value directly (not common with our current bridge)
          })
          .catch(err => {
            console.error('Xeris bridge error:', err);
            reject(err);
          });
      }
      // Legacy Flutter JavaScriptChannel (webview_flutter)
      else if (window.XerisWallet && window.XerisWallet.postMessage) {
        window.XerisWallet.postMessage(message);
      }
      // Fallback: webkit message handler (iOS WKWebView)
      else if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.XerisWallet) {
        window.webkit.messageHandlers.XerisWallet.postMessage(message);
      }
      // Fallback: Android JSInterface
      else if (window.XerisWalletAndroid) {
        window.XerisWalletAndroid.postMessage(message);
      }
      else {
        // If we haven't found a bridge yet, maybe it's still loading
        console.warn('Xeris Wallet native bridge not FOUND yet (initialization?)');
        // We'll still wait for the timeout instead of immediate reject
      }

      // Timeout after 120s (user may be slow to approve)
      setTimeout(() => {
        if (_pending.has(id)) {
          _pending.get(id).reject(new Error('Request timed out'));
          _pending.delete(id);
        }
      }, 120000);
    });
  }

  /**
   * Called by the native wallet to resolve/reject a pending request.
   * Flutter calls: controller.runJavaScript("window.__xerisResponse(1, {...}, null)")
   */
  window.__xerisResponse = function (id, result, error) {
    const pending = _pending.get(id);
    if (!pending) return;
    _pending.delete(id);
    if (error) {
      pending.reject(new Error(typeof error === 'string' ? error : JSON.stringify(error)));
    } else {
      pending.resolve(result);
    }
  };

  // =========================================================================
  // PUBLIC KEY WRAPPER (mimics Solana web3.js PublicKey interface)
  // =========================================================================

  class XerisPublicKey {
    constructor(keyStr) {
      this._key = keyStr;
    }
    toString() { return this._key; }
    toBase58() { return this._key; } // Solana pubkeys are base58
    toJSON() { return this._key; }
    toBytes() {
      // Base58 decode — simplified, dApps typically use their own web3 lib
      return this._key;
    }
    equals(other) {
      if (!other) return false;
      return this.toString() === other.toString();
    }
  }

  // =========================================================================
  // EVENT SYSTEM
  // =========================================================================

  function on(event, callback) {
    if (!_listeners[event]) _listeners[event] = [];
    _listeners[event].push(callback);
  }

  function off(event, callback) {
    if (!_listeners[event]) return;
    _listeners[event] = _listeners[event].filter(cb => cb !== callback);
  }

  function emit(event, data) {
    if (!_listeners[event]) return;
    _listeners[event].forEach(cb => {
      try { cb(data); } catch (e) { console.error('Xeris event handler error:', e); }
    });
  }

  /** Called by native wallet when account changes (e.g., user switches wallet) */
  window.__xerisAccountChanged = function (newPublicKey) {
    if (newPublicKey) {
      _publicKey = new XerisPublicKey(newPublicKey);
      _connected = true;
    } else {
      _publicKey = null;
      _connected = false;
    }
    emit('accountChanged', _publicKey);
  };

  // =========================================================================
  // PROVIDER API
  // =========================================================================

  const provider = {
    // --- Identity ---
    isXeris: true,
    isPhantom: false, // Don't impersonate, but some dApps check this
    isConnected: false,
    publicKey: null,

    /**
     * Connect to the wallet. Shows approval popup on first call.
     * Returns: { publicKey: XerisPublicKey }
     */
    connect: async function (opts) {
      if (_connected && _publicKey) {
        const address = _publicKey.toString();
        // Return a String object that has a publicKey property to satisfy both xerisTx.js and Solana standard
        const result = new String(address);
        result.publicKey = _publicKey;
        // Some dApps might call result.toBase58() directly on the returned value
        result.toBase58 = () => address;
        return result;
      }
      const result = await sendToNative('connect', {
        onlyIfTrusted: opts && opts.onlyIfTrusted,
      });
      _publicKey = new XerisPublicKey(result.publicKey);
      _connected = true;
      provider.isConnected = true;
      provider.publicKey = _publicKey;
      provider._network = result.network || null;
      emit('connect', { publicKey: _publicKey });

      const address = _publicKey.toString();
      const response = new String(address);
      response.publicKey = _publicKey;
      response.toBase58 = () => address;
      return response;
    },

    /**
     * Disconnect from the wallet.
     */
    disconnect: async function () {
      await sendToNative('disconnect', {});
      _publicKey = null;
      _connected = false;
      provider.isConnected = false;
      provider.publicKey = null;
      emit('disconnect');
    },

    /**
     * Sign a transaction without sending it.
     * @param {object} transaction - Serialized transaction (base64 or object)
     * Returns: { signature: string, signedTransaction: string (base64) }
     */
    signTransaction: async function (transaction) {
      if (!_connected) throw new Error('Wallet not connected');

      // Serialize to base64 if it's an object
      let txData;
      if (typeof transaction === 'string') {
        txData = transaction; // Already base64
      } else if (transaction.serialize) {
        // Solana web3.js Transaction object
        const serialized = transaction.serialize({ requireAllSignatures: false });
        txData = btoa(String.fromCharCode.apply(null, serialized));
      } else if (transaction instanceof Uint8Array) {
        txData = btoa(String.fromCharCode.apply(null, transaction));
      } else {
        txData = JSON.stringify(transaction);
      }

      const result = await sendToNative('signTransaction', {
        transaction: txData,
      });

      return {
        signature: result.signature,
        signedTransaction: result.signedTransaction,
      };
    },

    /**
     * Sign multiple transactions.
     * @param {Array} transactions
     * Returns: Array of signed transactions
     */
    signAllTransactions: async function (transactions) {
      if (!_connected) throw new Error('Wallet not connected');

      const serialized = transactions.map(tx => {
        if (typeof tx === 'string') return tx;
        if (tx.serialize) {
          const s = tx.serialize({ requireAllSignatures: false });
          return btoa(String.fromCharCode.apply(null, s));
        }
        return JSON.stringify(tx);
      });

      const result = await sendToNative('signAllTransactions', {
        transactions: serialized,
      });

      return result.signedTransactions;
    },

    /**
     * Sign and submit a transaction to the network.
     * @param {object} transaction
     * Returns: { signature: string }
     */
    signAndSendTransaction: async function (transaction, opts) {
      if (!_connected) throw new Error('Wallet not connected');

      let txData;
      if (typeof transaction === 'string') {
        txData = transaction;
      } else if (transaction.serialize) {
        const serialized = transaction.serialize({ requireAllSignatures: false });
        txData = btoa(String.fromCharCode.apply(null, serialized));
      } else if (transaction instanceof Uint8Array) {
        txData = btoa(String.fromCharCode.apply(null, transaction));
      } else {
        txData = JSON.stringify(transaction);
      }

      const result = await sendToNative('signAndSendTransaction', {
        transaction: txData,
        options: opts || {},
      });

      return { signature: result.signature };
    },

    /**
     * Sign an arbitrary message (for authentication, etc.)
     * @param {Uint8Array|string} message
     * Returns: { signature: Uint8Array }
     */
    signMessage: async function (message) {
      if (!_connected) throw new Error('Wallet not connected');

      let msgData;
      if (message instanceof Uint8Array) {
        msgData = btoa(String.fromCharCode.apply(null, message));
      } else {
        msgData = btoa(message);
      }

      const result = await sendToNative('signMessage', {
        message: msgData,
      });

      // Return as Uint8Array to match Solana wallet-standard
      const sigBytes = atob(result.signature);
      const sigArray = new Uint8Array(sigBytes.length);
      for (let i = 0; i < sigBytes.length; i++) {
        sigArray[i] = sigBytes.charCodeAt(i);
      }
      return { signature: sigArray };
    },

    // --- RPC helpers (convenience for dApps) ---

    /**
     * Get the RPC endpoint URL.
     * dApps can use this to configure their Solana Connection object.
     */
    getRpcUrl: async function () {
      const result = await sendToNative('getRpcUrl', {});
      return result.rpcUrl;
    },

    /**
     * Request airdrop (testnet only).
     */
    requestAirdrop: async function (amount) {
      if (!_connected) throw new Error('Wallet not connected');
      const result = await sendToNative('requestAirdrop', {
        amount: amount,
      });
      return result;
    },

    // --- Event system ---
    on: on,
    off: off,
    removeListener: off,
    addListener: on,

    // --- Metadata ---
    _network: null,
    _version: '1.0.1',
    isXerisWallet: true,
  };

  // --- Aliases for better compatibility ---
  provider.sign = provider.signTransaction;
  provider.send = provider.signAndSendTransaction;

  // =========================================================================
  // EXPOSE GLOBALLY
  // =========================================================================

  // Primary: window.xeris
  Object.defineProperty(window, 'xeris', {
    value: provider,
    writable: false,
    configurable: false,
  });

  // Secondary: window.solana (for Solana dApp compatibility)
  // Only set if no other wallet (like Phantom) has already claimed it
  if (!window.solana) {
    Object.defineProperty(window, 'solana', {
      value: provider,
      writable: false,
      configurable: false,
    });
  } else if (window.solana.isXeris === undefined) {
    // If something else is there but we want to mark it as Xeris-compatible
    try {
      window.solana.isXeris = true;
      window.solana.isXerisWallet = true;
    } catch (e) { }
  }

  // Announce to dApps that a wallet is available
  // (Solana wallet-standard event)
  try {
    window.dispatchEvent(new Event('wallet-standard:app-ready'));
  } catch (e) { /* older webviews may not support this */ }

  console.log('[XerisCoin] Wallet provider injected (v1.0.0)');
})();
