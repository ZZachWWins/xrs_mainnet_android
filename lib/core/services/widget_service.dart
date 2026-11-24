import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';

class WidgetService {
  static const _appGroupId = 'group.io.xeris.wallet';
  static const _androidWidgetName = 'XerisBalanceWidget';

  static Future<void> init() async {
    try {
      await HomeWidget.setAppGroupId(_appGroupId);
    } catch (e) {
      debugPrint('WidgetService.init error: $e');
    }
  }

  static Future<void> updateBalance({
    required double xrsBalance,
    required double usdValue,
  }) async {
    try {
      final balanceStr = '${_formatBalance(xrsBalance)} XRS';
      final usdStr = '\$${_formatBalance(usdValue)}';
      final timeStr = 'Updated ${DateFormat('HH:mm').format(DateTime.now())}';

      await HomeWidget.saveWidgetData<String>('xrs_balance', balanceStr);
      await HomeWidget.saveWidgetData<String>('usd_value', usdStr);
      await HomeWidget.saveWidgetData<String>('updated_at', timeStr);

      await HomeWidget.updateWidget(androidName: _androidWidgetName);
    } catch (e) {
      debugPrint('WidgetService.updateBalance error: $e');
    }
  }

  static String _formatBalance(double value) {
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(2)}M';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(2)}K';
    return value.toStringAsFixed(value < 1 ? 4 : 2);
  }
}
