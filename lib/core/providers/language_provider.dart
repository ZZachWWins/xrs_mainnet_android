import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xeris_wallet/core/services/storage_service.dart';

class LanguageNotifier extends Notifier<Locale> {
  @override
  Locale build() {
    _init();
    return const Locale('en');
  }

  Future<void> _init() async {
    await _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    final langCode = await StorageService.getLanguage();
    state = Locale(langCode);
  }

  Future<void> setLanguage(String languageCode) async {
    await StorageService.setLanguage(languageCode);
    state = Locale(languageCode);
  }
}

final languageProvider = NotifierProvider<LanguageNotifier, Locale>(() {
  return LanguageNotifier();
});
