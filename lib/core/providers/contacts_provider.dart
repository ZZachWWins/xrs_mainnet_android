import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xeris_wallet/core/models/contact.dart';
import 'package:xeris_wallet/core/providers/wallet_provider.dart';
import 'package:xeris_wallet/core/services/storage_service.dart';

/// Provides the contact list for the active wallet.
final contactsProvider = FutureProvider<List<Contact>>((ref) async {
  final activeWallet = await ref.watch(activeWalletProvider.future);
  if (activeWallet == null) return [];
  return StorageService.getContacts(activeWallet.id);
});

class ContactsNotifier extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() => null;

  Future<String?> _activeWalletId() async {
    final wallet = await ref.read(activeWalletProvider.future);
    return wallet?.id;
  }

  Future<void> addContact(Contact contact) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final walletId = await _activeWalletId();
      if (walletId == null) return;
      final contacts = await StorageService.getContacts(walletId);
      contacts.add(contact);
      await StorageService.saveContacts(walletId, contacts);
      ref.invalidate(contactsProvider);
    });
  }

  Future<void> updateContact(Contact updated) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final walletId = await _activeWalletId();
      if (walletId == null) return;
      final contacts = await StorageService.getContacts(walletId);
      final index = contacts.indexWhere((c) => c.id == updated.id);
      if (index != -1) {
        contacts[index] = updated;
        await StorageService.saveContacts(walletId, contacts);
        ref.invalidate(contactsProvider);
      }
    });
  }

  Future<void> deleteContact(String id) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final walletId = await _activeWalletId();
      if (walletId == null) return;
      final contacts = await StorageService.getContacts(walletId);
      contacts.removeWhere((c) => c.id == id);
      await StorageService.saveContacts(walletId, contacts);
      ref.invalidate(contactsProvider);
    });
  }

  Future<String> exportJson() async {
    final walletId = await _activeWalletId();
    if (walletId == null) return '[]';
    return StorageService.exportContactsJson(walletId);
  }

  Future<void> importJson(String jsonStr) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final walletId = await _activeWalletId();
      if (walletId == null) return;
      await StorageService.importContactsJson(walletId, jsonStr);
      ref.invalidate(contactsProvider);
    });
  }
}

final contactsNotifierProvider = AsyncNotifierProvider<ContactsNotifier, void>(() {
  return ContactsNotifier();
});
