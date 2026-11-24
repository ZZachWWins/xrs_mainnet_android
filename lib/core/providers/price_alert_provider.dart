import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xeris_wallet/core/models/price_alert.dart';
import 'package:xeris_wallet/core/providers/wallet_provider.dart';
import 'package:xeris_wallet/core/services/local_notification_service.dart';
import 'package:xeris_wallet/core/services/storage_service.dart';

/// Reactive list of price alerts — used by the UI screen.
final priceAlertsProvider = NotifierProvider<PriceAlertsNotifier, List<PriceAlert>>(() {
  return PriceAlertsNotifier();
});

class PriceAlertsNotifier extends Notifier<List<PriceAlert>> {
  @override
  List<PriceAlert> build() {
    _load();
    return [];
  }

  Future<void> _load() async {
    state = await StorageService.getPriceAlerts();
  }

  Future<void> addAlert(PriceAlert alert) async {
    final updated = [...state, alert];
    await StorageService.savePriceAlerts(updated);
    state = updated;
  }

  Future<void> removeAlert(int index) async {
    final updated = [...state]..removeAt(index);
    await StorageService.savePriceAlerts(updated);
    state = updated;
  }

  Future<void> reactivateAlert(int index) async {
    final updated = [...state];
    updated[index] = updated[index].copyWith(isActive: true);
    await StorageService.savePriceAlerts(updated);
    state = updated;
  }

  Future<void> reload() => _load();
}

/// Background polling provider — checks alerts every 60 seconds.
final priceAlertMonitorProvider = Provider<void>((ref) {
  Timer? timer;

  Future<void> check() async {
    final notificationsEnabled = await StorageService.getNotificationsEnabled();
    if (!notificationsEnabled) return;

    final alerts = await StorageService.getPriceAlerts();
    if (alerts.isEmpty) return;

    final pricesAsync = ref.read(tokenPricesProvider);
    final prices = pricesAsync.asData?.value;
    if (prices == null) return;

    bool anyTriggered = false;
    final updated = alerts.map((alert) {
      if (!alert.isActive) return alert;

      final price = prices[alert.tokenId] ?? 0.0;
      final triggered = alert.isAbove ? price >= alert.targetPrice : price <= alert.targetPrice;

      if (triggered) {
        anyTriggered = true;
        LocalNotificationService.showPriceAlert(
          symbol: alert.symbol,
          price: price,
          isAbove: alert.isAbove,
        );
        return alert.copyWith(isActive: false);
      }
      return alert;
    }).toList();

    if (anyTriggered) {
      await StorageService.savePriceAlerts(updated);
      ref.read(priceAlertsProvider.notifier).reload();
    }
  }

  timer = Timer.periodic(const Duration(minutes: 1), (_) => check());
  check();

  ref.onDispose(() => timer?.cancel());
});
