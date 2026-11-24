import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:xeris_wallet/core/config/network_config.dart';
import 'package:uuid/uuid.dart';
import 'package:xeris_wallet/core/models/wallet_meta.dart';
import 'package:xeris_wallet/core/models/browser_bookmark.dart';
import 'package:xeris_wallet/core/models/contact.dart';
import 'package:xeris_wallet/core/models/price_alert.dart';
import 'package:xeris_wallet/core/services/wallet_service.dart';
import 'package:xeris_wallet/core/theme/app_theme.dart';
import 'package:xeris_wallet/core/utils/pin_hasher.dart';

class StorageService {
  static const _storage = FlutterSecureStorage(
    // resetOnError:false — NEVER silently wipe secure storage (which holds every
    // wallet's only copy of the mnemonic) on a keystore decryption error. Such
    // errors can happen after OS upgrades or keystore corruption; surfacing the
    // error lets the user recover from their backup instead of losing funds to a
    // silent wipe.
    aOptions: AndroidOptions(resetOnError: false),
    // Bind Keychain items to this device (not restorable onto another device via
    // an encrypted iTunes/Finder backup) and only after the first unlock.
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  // Legacy keys
  static const _keyMnemonic = 'mnemonic';

  // New keys
  static const _keyWalletsMeta = 'wallets_meta';
  static const _keyActiveWalletId = 'active_wallet_id';
  static const _keyBiometricsEnabled = 'biometrics_enabled';
  static const _keyNotificationsEnabled = 'notifications_enabled';
  static const _keyCurrency = 'currency';
  static const _keyLanguage = 'language';
  static const _keyPinCode = 'pin_code';
  static const _keyUsePin = 'use_pin';
  static const _keyPrivacyMode = 'privacy_mode';
  static const _keyPanicPin = 'panic_pin';
  static const _keyBookmarks = 'browser_bookmarks';
  static const _keyPqEnabled = 'pq_protection_active';
  static const _keyPqPk = 'pq_key_pk';
  static const _keyPqSk = 'pq_key_sk';
  static const _keyNetwork = 'current_network';
  static const _keyThemeMode = 'theme_mode_v2';
  static const _keyTwoFactorEnabled = 'two_factor_enabled';
  static const _keyTwoFactorSendThreshold = 'two_factor_send_threshold';
  static const _keyTwoFactorThresholdCurrency = 'two_factor_threshold_currency';

  /// Migrates legacy single-wallet storage to multi-wallet format if needed.
  static Future<void> checkAndMigrate() async {
    final legacyMnemonic = await _storage.read(key: _keyMnemonic);
    final walletsMetaJson = await _storage.read(key: _keyWalletsMeta);

    // If we have a legacy mnemonic but no new meta, migrate
    if (legacyMnemonic != null && walletsMetaJson == null) {
      debugPrint('Migrating legacy wallet to multi-wallet storage...');

      final id = const Uuid().v4();
      final keyPair = await WalletService.getKeyPair(legacyMnemonic);

      final newWallet = WalletMeta(
        id: id,
        name: 'Main Wallet',
        address: keyPair.address,
      );

      // Save mnemonic with new key format: mnemonic_{id}
      await _storage.write(key: 'mnemonic_$id', value: legacyMnemonic);

      // Set active
      await _storage.write(key: _keyActiveWalletId, value: id);

      // Save meta last, so if it crashes before this, migration will rerun.
      final List<WalletMeta> wallets = [newWallet];
      await _storage.write(key: _keyWalletsMeta, value: jsonEncode(wallets));

      // We opt NOT to delete the legacy key immediately in case of issues,
      // or we can delete it to ensure clean state. Let's keep it for safety strictly speaking,
      // but to avoid confusion "legacyMnemonic != null" check again, we should probably rename or delete.
      // For this implementation, let's delete it to strictly switch to new mode.
      await _storage.delete(key: _keyMnemonic);

      debugPrint('Migration complete.');
    }
  }

  /// Saves a new wallet and returns its ID.
  static Future<String> saveWallet(String name, String mnemonic) async {
    // Ensure migration is checked first just in case
    await checkAndMigrate();

    final id = const Uuid().v4();
    final keyPair = await WalletService.getKeyPair(mnemonic);

    final newWallet = WalletMeta(id: id, name: name, address: keyPair.address);

    // Get existing
    final wallets = await getWallets();
    wallets.add(newWallet);

    // Save meta
    await _storage.write(key: _keyWalletsMeta, value: jsonEncode(wallets));

    // Save mnemonic
    await _storage.write(key: 'mnemonic_$id', value: mnemonic);

    // If it's the first wallet, make it active
    if (wallets.length == 1) {
      await setActiveWalletId(id);
    }

    return id;
  }

  /// Gets list of all wallets.
  static Future<List<WalletMeta>> getWallets() async {
    final jsonStr = await _storage.read(key: _keyWalletsMeta);
    if (jsonStr == null) return [];

    final List<dynamic> decoded = jsonDecode(jsonStr);
    return decoded.map((e) => WalletMeta.fromJson(e)).toList();
  }

  /// Gets the ID of the active wallet.
  static Future<String?> getActiveWalletId() async {
    // Ensure a migration check happens if we access this
    // But ideally migration runs at app startup.
    // We'll rely on the Provider to call migration or main.dart.
    return await _storage.read(key: _keyActiveWalletId);
  }

  /// Sets the active wallet ID.
  static Future<void> setActiveWalletId(String id) async {
    await _storage.write(key: _keyActiveWalletId, value: id);
  }

  /// Retrieves the mnemonic for the ACTIVE wallet.
  /// Modified to work with multi-wallet.
  static Future<String?> getMnemonic() async {
    // 1. Try new active wallet flow
    final activeId = await getActiveWalletId();
    if (activeId != null) {
      return await _storage.read(key: 'mnemonic_$activeId');
    }

    // 2. Fallback to legacy if migration hasn't run or failed?
    // Ideally we should always migrate. But for safety:
    return await _storage.read(key: _keyMnemonic);
  }

  /// Retrieves mnemonic by specific ID (internal use mostly).
  static Future<String?> getMnemonicById(String id) async {
    return await _storage.read(key: 'mnemonic_$id');
  }

  /// Saves biometric preference.
  static Future<void> setBiometricsEnabled(bool enabled) async {
    await _storage.write(key: _keyBiometricsEnabled, value: enabled.toString());
  }

  /// Retrieves biometric preference. Defaults to false.
  static Future<bool> getBiometricsEnabled() async {
    final value = await _storage.read(key: _keyBiometricsEnabled);
    return value == 'true';
  }

  /// Saves notifications preference.
  static Future<void> setNotificationsEnabled(bool enabled) async {
    await _storage.write(
      key: _keyNotificationsEnabled,
      value: enabled.toString(),
    );
  }

  /// Retrieves notifications preference. Defaults to true.
  static Future<bool> getNotificationsEnabled() async {
    final value = await _storage.read(key: _keyNotificationsEnabled);
    return value != 'false'; // Default to true
  }

  /// Saves currency preference.
  static Future<void> setCurrency(String currency) async {
    await _storage.write(key: _keyCurrency, value: currency);
  }

  /// Retrieves currency preference. Defaults to 'USD'.
  static Future<String> getCurrency() async {
    final value = await _storage.read(key: _keyCurrency);
    return value ?? 'USD';
  }

  /// Saves language preference.
  static Future<void> setLanguage(String languageCode) async {
    await _storage.write(key: _keyLanguage, value: languageCode);
  }

  /// Retrieves language preference. Defaults to 'en'.
  static Future<String> getLanguage() async {
    final value = await _storage.read(key: _keyLanguage);
    return value ?? 'en';
  }

  /// Saves the unlock PIN as a salted hash (never plaintext).
  static Future<void> setPinCode(String pin) async {
    await _storage.write(key: _keyPinCode, value: await PinHasher.hash(pin));
  }

  /// Returns the stored PIN value (a hash). For existence checks only —
  /// use [verifyPinCode] to check an entered PIN.
  static Future<String?> getPinCode() async {
    return await _storage.read(key: _keyPinCode);
  }

  /// Verifies [entered] against the stored PIN, transparently migrating a legacy
  /// plaintext value to a hash on the first successful match.
  static Future<bool> verifyPinCode(String entered) async {
    final stored = await _storage.read(key: _keyPinCode);
    if (stored == null || stored.isEmpty) return false;
    final ok = await PinHasher.verify(entered, stored);
    if (ok && !PinHasher.isHashed(stored)) {
      await _storage.write(
        key: _keyPinCode,
        value: await PinHasher.hash(entered),
      );
    }
    return ok;
  }

  /// Saves PIN preference.
  static Future<void> setUsePin(bool enabled) async {
    await _storage.write(key: _keyUsePin, value: enabled.toString());
  }

  /// Retrieves PIN preference.
  static Future<bool> getUsePin() async {
    final value = await _storage.read(key: _keyUsePin);
    return value == 'true';
  }

  /// Saves Privacy Mode preference.
  static Future<void> setPrivacyMode(bool enabled) async {
    await _storage.write(key: _keyPrivacyMode, value: enabled.toString());
  }

  /// Retrieves Privacy Mode preference.
  static Future<bool> getPrivacyMode() async {
    final value = await _storage.read(key: _keyPrivacyMode);
    return value == 'true';
  }

  /// Saves the panic PIN as a salted hash (never plaintext).
  static Future<void> setPanicPin(String pin) async {
    await _storage.write(key: _keyPanicPin, value: await PinHasher.hash(pin));
  }

  /// Returns the stored panic PIN value (a hash). For existence checks only —
  /// use [verifyPanicPin] to check an entered PIN.
  static Future<String?> getPanicPin() async {
    return await _storage.read(key: _keyPanicPin);
  }

  /// Verifies [entered] against the stored panic PIN (false if none set),
  /// migrating a legacy plaintext value on the first successful match.
  static Future<bool> verifyPanicPin(String entered) async {
    final stored = await _storage.read(key: _keyPanicPin);
    if (stored == null || stored.isEmpty) return false;
    final ok = await PinHasher.verify(entered, stored);
    if (ok && !PinHasher.isHashed(stored)) {
      await _storage.write(
        key: _keyPanicPin,
        value: await PinHasher.hash(entered),
      );
    }
    return ok;
  }

  // --- PIN brute-force protection ---

  static const _keyPinFailureCount = 'pin_failure_count';
  static const _keyPinLockoutUntilMs = 'pin_lockout_until_ms';

  static Future<int> getPinFailureCount() async {
    final raw = await _storage.read(key: _keyPinFailureCount);
    return int.tryParse(raw ?? '') ?? 0;
  }

  static Future<void> setPinFailureCount(int count) async {
    await _storage.write(key: _keyPinFailureCount, value: count.toString());
  }

  /// Returns the millisecondsSinceEpoch until which PIN entry is locked,
  /// or null if not locked.
  static Future<int?> getPinLockoutUntilMs() async {
    final raw = await _storage.read(key: _keyPinLockoutUntilMs);
    return raw == null ? null : int.tryParse(raw);
  }

  static Future<void> setPinLockoutUntilMs(int? ms) async {
    if (ms == null) {
      await _storage.delete(key: _keyPinLockoutUntilMs);
    } else {
      await _storage.write(key: _keyPinLockoutUntilMs, value: ms.toString());
    }
  }

  static Future<void> resetPinFailures() async {
    await _storage.delete(key: _keyPinFailureCount);
    await _storage.delete(key: _keyPinLockoutUntilMs);
  }

  // --- Two-Factor Authentication ---

  /// Whether 2FA is enabled for sensitive actions (requires both biometric
  /// AND PIN). Caller is responsible for ensuring both factors are configured
  /// before allowing this to be turned on.
  static Future<bool> getTwoFactorEnabled() async {
    final value = await _storage.read(key: _keyTwoFactorEnabled);
    return value == 'true';
  }

  static Future<void> setTwoFactorEnabled(bool enabled) async {
    await _storage.write(key: _keyTwoFactorEnabled, value: enabled.toString());
  }

  /// Fiat threshold above which a send transaction must pass 2FA.
  /// 0 means "always require 2FA on sends" when 2FA is enabled.
  static Future<double> getTwoFactorSendThreshold() async {
    final value = await _storage.read(key: _keyTwoFactorSendThreshold);
    return double.tryParse(value ?? '') ?? 0.0;
  }

  static Future<void> setTwoFactorSendThreshold(double amount) async {
    await _storage.write(
      key: _keyTwoFactorSendThreshold,
      value: amount.toString(),
    );
  }

  /// Currency code the threshold was set in (e.g. 'USD'). Used so the value
  /// is interpreted consistently if the user later switches display currency.
  static Future<String> getTwoFactorThresholdCurrency() async {
    final value = await _storage.read(key: _keyTwoFactorThresholdCurrency);
    return value ?? 'USD';
  }

  static Future<void> setTwoFactorThresholdCurrency(String code) async {
    await _storage.write(key: _keyTwoFactorThresholdCurrency, value: code);
  }

  /// Counts the total number of ZK Proofs generated and stored locally.
  static Future<int> getZkProofCount() async {
    final all = await _storage.readAll();
    return all.keys.where((k) => k.startsWith('zkp_tx_')).length;
  }

  /// Checks if Quantum Protection (Dilithium3) is active by checking for registered key meta.
  static Future<bool> isQuantumProtected() async {
    final enabled = await _storage.read(key: _keyPqEnabled);
    if (enabled == 'true') return true;

    // Fallback/Legacy check
    final all = await _storage.readAll();
    return all.keys.any((k) => k.startsWith('pq_key_')) ||
        all.containsKey('pqc_enabled');
  }

  static Future<void> setPqProtectionActive(bool active) async {
    await _storage.write(key: _keyPqEnabled, value: active.toString());
  }

  static Future<void> savePqKeys(String pk, String sk) async {
    await _storage.write(key: _keyPqPk, value: pk);
    await _storage.write(key: _keyPqSk, value: sk);
  }

  static Future<String?> getPqPk() => _storage.read(key: _keyPqPk);
  static Future<String?> getPqSk() => _storage.read(key: _keyPqSk);

  // --- Stealth Address Keys ---

  /// Saves the X25519 scan key seed (base58) for a wallet.
  static Future<void> saveStealthScanKey(
    String walletId,
    String seedB58,
  ) async {
    await _storage.write(key: 'stealth_scan_$walletId', value: seedB58);
  }

  /// Retrieves the stealth scan key seed for a wallet.
  static Future<String?> getStealthScanKey(String walletId) async {
    return await _storage.read(key: 'stealth_scan_$walletId');
  }

  /// Saves a stealth announcement (indexed by receiver scan pubkey).
  static Future<void> saveStealthAnnouncement(
    String walletId,
    Map<String, dynamic> announcementJson,
  ) async {
    final existing = await getStealthAnnouncementsRaw(walletId);
    // Deduplicate by stealth_address
    existing.removeWhere(
      (a) => a['stealth_address'] == announcementJson['stealth_address'],
    );
    existing.add(announcementJson);
    await _storage.write(
      key: 'stealth_announcements_$walletId',
      value: jsonEncode(existing),
    );
  }

  /// Retrieves all stealth announcements for a wallet.
  static Future<List<Map<String, dynamic>>> getStealthAnnouncementsRaw(
    String walletId,
  ) async {
    final jsonStr = await _storage.read(key: 'stealth_announcements_$walletId');
    if (jsonStr == null) return [];
    final List<dynamic> decoded = jsonDecode(jsonStr);
    return decoded.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  /// Marks a stealth address as swept.
  static Future<void> markStealthSwept(
    String walletId,
    String stealthAddress,
  ) async {
    final existing = await getStealthAnnouncementsRaw(walletId);
    for (final a in existing) {
      if (a['stealth_address'] == stealthAddress) {
        a['swept'] = true;
      }
    }
    await _storage.write(
      key: 'stealth_announcements_$walletId',
      value: jsonEncode(existing),
    );
  }

  /// Saves current network preference ('testnet' or 'mainnet').
  static Future<void> setNetwork(String network) async {
    await _storage.write(key: _keyNetwork, value: network);
  }

  /// Retrieves the network preference, defaulting to the configured build.
  static Future<String> getNetwork() async {
    // Mainnet builds must not inherit a saved testnet selection while hiding
    // the development network switch. This does not touch wallet key storage.
    if (NetworkConfig.defaultNetwork == XerisNetwork.mainnet) return 'mainnet';
    final value = await _storage.read(key: _keyNetwork);
    return value ?? NetworkConfig.defaultNetwork.name;
  }

  /// Saves theme mode preference.
  static Future<void> setThemeMode(AppThemeMode mode) async {
    await _storage.write(key: _keyThemeMode, value: mode.name);
  }

  /// Retrieves theme mode preference. Defaults to AppThemeMode.dark.
  static Future<AppThemeMode> getThemeMode() async {
    final value = await _storage.read(key: _keyThemeMode);
    if (value == null) return AppThemeMode.dark;
    return AppThemeMode.values.firstWhere(
      (e) => e.name == value,
      orElse: () => AppThemeMode.dark,
    );
  }

  /// Gets a map of coin visibility overrides (id -> isVisible)
  static Future<Map<String, bool>> getCoinVisibility(String walletId) async {
    final jsonStr = await _storage.read(key: 'coin_visibility_$walletId');
    if (jsonStr == null) {
      // Migrate from old hidden coins list if it exists
      final oldHidden = await _getHiddenCoinsInternal(walletId);
      if (oldHidden.isNotEmpty) {
        final Map<String, bool> migrated = {
          for (var id in oldHidden) id: false,
        };
        await setCoinVisibility(walletId, migrated);
        return migrated;
      }
      return {};
    }
    final Map<String, dynamic> decoded = jsonDecode(jsonStr);
    return decoded.map((key, value) => MapEntry(key, value as bool));
  }

  /// Internal helper for migration
  static Future<List<String>> _getHiddenCoinsInternal(String walletId) async {
    final jsonStr = await _storage.read(key: 'hidden_coins_$walletId');
    if (jsonStr == null) return [];
    final List<dynamic> decoded = jsonDecode(jsonStr);
    return decoded.cast<String>();
  }

  /// Sets coin visibility overrides
  static Future<void> setCoinVisibility(
    String walletId,
    Map<String, bool> visibility,
  ) async {
    await _storage.write(
      key: 'coin_visibility_$walletId',
      value: jsonEncode(visibility),
    );
  }

  /// Deletes a wallet by ID.
  static Future<void> deleteWallet(String id) async {
    final wallets = await getWallets();
    wallets.removeWhere((w) => w.id == id);

    // Update meta
    await _storage.write(key: _keyWalletsMeta, value: jsonEncode(wallets));

    // Remove mnemonic
    await _storage.delete(key: 'mnemonic_$id');

    // Remove contacts for this wallet
    await _storage.delete(key: 'contacts_$id');

    // Check if we deleted the active wallet
    final activeId = await getActiveWalletId();
    if (activeId == id) {
      if (wallets.isNotEmpty) {
        await setActiveWalletId(wallets.first.id);
      } else {
        await _storage.delete(key: _keyActiveWalletId);
      }
    }
  }

  /// Renames a wallet by ID.
  static Future<void> renameWallet(String id, String newName) async {
    final wallets = await getWallets();
    final index = wallets.indexWhere((w) => w.id == id);
    if (index != -1) {
      final oldWallet = wallets[index];
      wallets[index] = WalletMeta(
        id: oldWallet.id,
        name: newName,
        address: oldWallet.address,
      );
      await _storage.write(key: _keyWalletsMeta, value: jsonEncode(wallets));
    }
  }

  /// Clears all secure storage (for logout/reset).
  static Future<void> clearAll() async {
    await _storage.deleteAll();
  }

  // --- Agent Key Seeds ---

  static const _agentSeedPrefix = 'agent_seed_';

  static Future<void> saveAgentSeed(
    String walletId,
    String agentPubkey,
    String seedBase58,
  ) async {
    await _storage.write(
      key: '$_agentSeedPrefix${walletId}_$agentPubkey',
      value: seedBase58,
    );
  }

  static Future<String?> getAgentSeed(
    String walletId,
    String agentPubkey,
  ) async {
    return await _storage.read(
      key: '$_agentSeedPrefix${walletId}_$agentPubkey',
    );
  }

  static Future<void> deleteAgentSeed(
    String walletId,
    String agentPubkey,
  ) async {
    await _storage.delete(key: '$_agentSeedPrefix${walletId}_$agentPubkey');
  }

  static Future<List<String>> getAgentPubkeysForWallet(String walletId) async {
    final all = await _storage.readAll();
    final prefix = '$_agentSeedPrefix${walletId}_';
    return all.keys
        .where((k) => k.startsWith(prefix))
        .map((k) => k.substring(prefix.length))
        .toList();
  }

  // --- Browser Bookmarks ---

  static Future<List<BrowserBookmark>> getBookmarks() async {
    final jsonStr = await _storage.read(key: _keyBookmarks);
    if (jsonStr == null) {
      // Default bookmarks
      return [
        BrowserBookmark(
          title: 'Xeris Web',
          url: 'https://xerisweb.com',
          isDefault: true,
        ),
        BrowserBookmark(
          title: 'Xeris DEX',
          url: 'https://dex.xerisweb.com',
          isDefault: true,
        ),
        BrowserBookmark(
          title: 'Mainnet network status',
          url: 'https://mainnetrpc.xerisweb.com/v2/stats',
          isDefault: true,
        ),
      ];
    }

    final List<dynamic> decoded = jsonDecode(jsonStr);
    return decoded.map((e) {
      final bookmark = BrowserBookmark.fromJson(e);
      // Update only built-in links; user-created bookmarks keep their URLs.
      if (bookmark.isDefault &&
          bookmark.url == 'https://xeris-dex.vercel.app') {
        return BrowserBookmark(
          title: 'Xeris DEX',
          url: 'https://dex.xerisweb.com',
          isDefault: true,
        );
      }
      if (bookmark.isDefault &&
          bookmark.url == 'https://explorer.xerisweb.com') {
        return BrowserBookmark(
          title: 'Mainnet network status',
          url: 'https://mainnetrpc.xerisweb.com/v2/stats',
          isDefault: true,
        );
      }
      return bookmark;
    }).toList();
  }

  static Future<void> saveBookmark(BrowserBookmark bookmark) async {
    final bookmarks = await getBookmarks();
    // Check if already exists
    final index = bookmarks.indexWhere((b) => b.url == bookmark.url);
    if (index != -1) {
      bookmarks[index] = bookmark;
    } else {
      bookmarks.add(bookmark);
    }
    await _storage.write(key: _keyBookmarks, value: jsonEncode(bookmarks));
  }

  static Future<void> removeBookmark(String url) async {
    final bookmarks = await getBookmarks();
    bookmarks.removeWhere((b) => b.url == url && !b.isDefault);
    await _storage.write(key: _keyBookmarks, value: jsonEncode(bookmarks));
  }

  // --- Contacts ---

  static Future<List<Contact>> getContacts(String walletId) async {
    final jsonStr = await _storage.read(key: 'contacts_$walletId');
    if (jsonStr == null) return [];
    final List<dynamic> decoded = jsonDecode(jsonStr);
    return decoded.map((e) => Contact.fromJson(e)).toList();
  }

  static Future<void> saveContacts(
    String walletId,
    List<Contact> contacts,
  ) async {
    await _storage.write(
      key: 'contacts_$walletId',
      value: jsonEncode(contacts.map((c) => c.toJson()).toList()),
    );
  }

  static Future<String> exportContactsJson(String walletId) async {
    final contacts = await getContacts(walletId);
    return jsonEncode(contacts.map((c) => c.toJson()).toList());
  }

  // --- Connected Sites (dApp Permissions) ---
  //
  // Permissions are scoped per wallet so that switching wallets does not
  // grant a previously-trusted dApp access to a different wallet's keys.
  // The legacy unscoped key is migrated on first read into the active
  // wallet's bucket so existing connections remain trusted for that wallet.

  static const _keyConnectedSitesLegacy = 'connected_sites';

  static String _connectedSitesKey(String walletId) =>
      'connected_sites_$walletId';

  static Future<void> _migrateLegacyConnectedSitesIfNeeded(
    String walletId,
  ) async {
    final legacy = await _storage.read(key: _keyConnectedSitesLegacy);
    if (legacy == null) return;
    final scoped = await _storage.read(key: _connectedSitesKey(walletId));
    if (scoped == null) {
      await _storage.write(key: _connectedSitesKey(walletId), value: legacy);
    }
    await _storage.delete(key: _keyConnectedSitesLegacy);
  }

  static Future<List<String>> getConnectedSites(String walletId) async {
    await _migrateLegacyConnectedSitesIfNeeded(walletId);
    final jsonStr = await _storage.read(key: _connectedSitesKey(walletId));
    if (jsonStr == null) return [];
    final List<dynamic> decoded = jsonDecode(jsonStr);
    return decoded.cast<String>();
  }

  static Future<void> addConnectedSite(String walletId, String origin) async {
    final sites = await getConnectedSites(walletId);
    if (!sites.contains(origin)) {
      sites.add(origin);
      await _storage.write(
        key: _connectedSitesKey(walletId),
        value: jsonEncode(sites),
      );
    }
  }

  static Future<void> removeConnectedSite(
    String walletId,
    String origin,
  ) async {
    final sites = await getConnectedSites(walletId);
    sites.remove(origin);
    await _storage.write(
      key: _connectedSitesKey(walletId),
      value: jsonEncode(sites),
    );
  }

  static Future<void> clearAllConnectedSites(String walletId) async {
    await _storage.delete(key: _connectedSitesKey(walletId));
  }

  // --- UI Scale ---

  static const _keyUiScale = 'ui_scale';

  static Future<double> getUiScale() async {
    final value = await _storage.read(key: _keyUiScale);
    return double.tryParse(value ?? '') ?? 0.85;
  }

  static Future<void> setUiScale(double scale) async {
    await _storage.write(key: _keyUiScale, value: scale.toString());
  }

  // --- Price Alerts ---

  static const _keyPriceAlerts = 'price_alerts';

  static Future<List<PriceAlert>> getPriceAlerts() async {
    final jsonStr = await _storage.read(key: _keyPriceAlerts);
    if (jsonStr == null) return [];
    final List<dynamic> decoded = jsonDecode(jsonStr);
    return decoded
        .map((e) => PriceAlert.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<void> savePriceAlerts(List<PriceAlert> alerts) async {
    await _storage.write(
      key: _keyPriceAlerts,
      value: jsonEncode(alerts.map((a) => a.toJson()).toList()),
    );
  }

  static Future<List<Contact>> importContactsJson(
    String walletId,
    String jsonStr,
  ) async {
    final List<dynamic> decoded = jsonDecode(jsonStr);
    final imported = decoded.map((e) => Contact.fromJson(e)).toList();

    final existing = await getContacts(walletId);
    final existingAddresses = existing.map((c) => c.address).toSet();

    // Merge: skip duplicates by address
    final merged = [
      ...existing,
      ...imported.where((c) => !existingAddresses.contains(c.address)),
    ];

    await saveContacts(walletId, merged);
    return merged;
  }
}
