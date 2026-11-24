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
 *   Register the native-origin WebMessageListener "XerisWalletNative" before load.
 *   Responses are accepted only in the same nonce-bound top-level document.
 */

(function () {
  'use strict';
  if (window.top !== window.self) return;

  // Prevent double-injection
  if (window.__xerisProviderInjected) return;
  window.__xerisProviderInjected = true;

  // =========================================================================
  // REQUEST/RESPONSE PLUMBING
  // =========================================================================

  let _requestId = 0;
  const _pending = new Map();
  let _connected = false;
  let _publicKey = null;
  const _listeners = {};
  let _documentId = null;
  try {
    _documentId = Array.from(window.crypto.getRandomValues(new Uint8Array(16)), byte => byte.toString(16).padStart(2, '0')).join('');
    Object.defineProperty(window, '__xerisDocumentId', { value: _documentId });
  } catch (_) { /* A browser without secure session nonces cannot connect. */ }

  function rejectPending(message) {
    for (const pending of _pending.values()) { clearTimeout(pending.timer); pending.reject(new Error(message)); }
    _pending.clear();
  }

  function sendToNative(method, params) {
    return new Promise((resolve, reject) => {
      if (!_documentId || window.location.protocol !== 'https:' || typeof window.XerisWalletNative?.postMessage !== 'function') {
        reject(new Error('Secure wallet communication is unavailable. Open an HTTPS page and update Android System WebView if needed.'));
        return;
      }
      if (_pending.size >= 16) { reject(new Error('Too many pending wallet requests.')); return; }
      const id = ++_requestId;
      const timer = setTimeout(() => {
        const pending = _pending.get(id);
        if (pending) { _pending.delete(id); pending.reject(new Error('Wallet request timed out.')); }
      }, 120000);
      _pending.set(id, { resolve, reject, timer });
      try {
        const message = JSON.stringify({ id, document_id: _documentId, method, params: params || {} });
        if (message.length > 65536) throw new Error();
        // No callHandler, JavaScriptInterface or unverified legacy fallback.
        window.XerisWalletNative.postMessage(message);
      } catch (_) {
        clearTimeout(timer); _pending.delete(id);
        reject(new Error('The secure wallet request could not be sent.'));
      }
    });
  }

  Object.defineProperty(window, '__xerisNativeResponse', { value: function (response) {
    const pending = _pending.get(response?.id);
    if (!pending) return;
    _pending.delete(response.id); clearTimeout(pending.timer);
    if (response.error) pending.reject(new Error(typeof response.error === 'string' ? response.error : 'Wallet request rejected.'));
    else pending.resolve(response.result);
  }});
  window.addEventListener('pagehide', () => {
    rejectPending('The requesting page was closed.');
    _connected = false; _publicKey = null;
    provider.isConnected = false; provider.publicKey = null;
    emit('disconnect');
  });

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
    rejectPending('The active wallet changed.');
    if (newPublicKey) {
      _publicKey = new XerisPublicKey(newPublicKey);
      _connected = true;
    } else {
      _publicKey = null;
      _connected = false;
    }
    provider.publicKey = _publicKey;
    provider.isConnected = _connected;
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
        if (typeof message !== 'string') throw new Error('Provide message bytes or UTF-8 text.');
        msgData = btoa(String.fromCharCode.apply(null, new TextEncoder().encode(message)));
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
  }

  // Announce to dApps that a wallet is available
  // (Solana wallet-standard event)
  try {
    window.dispatchEvent(new Event('wallet-standard:app-ready'));
  } catch (e) { /* older webviews may not support this */ }

  console.log('[XerisCoin] Wallet provider injected (v1.0.0)');
})();
