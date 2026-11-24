import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class LocalNotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/launcher_icon');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
    );

    // Request Android 13+ permission
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  static Future<void> showTransactionReceived({
    required double amount,
    required String symbol,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'transactions',
      'Transactions',
      channelDescription: 'Notifications for incoming transactions',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/launcher_icon',
    );

    await _plugin.show(
      0,
      'Transaction Received',
      'You received ${amount.toStringAsFixed(4)} $symbol',
      const NotificationDetails(android: androidDetails, iOS: DarwinNotificationDetails()),
    );
  }

  static Future<void> showPriceAlert({
    required String symbol,
    required double price,
    required bool isAbove,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'price_alerts',
      'Price Alerts',
      channelDescription: 'Notifications when your price targets are hit',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/launcher_icon',
    );

    final direction = isAbove ? 'above' : 'below';
    await _plugin.show(
      price.hashCode & 0x7FFFFFFF,
      'Price Alert: $symbol',
      '$symbol is now $direction \$${price.toStringAsFixed(4)}',
      const NotificationDetails(android: androidDetails, iOS: DarwinNotificationDetails()),
    );
  }
}
