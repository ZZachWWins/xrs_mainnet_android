import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xeris_wallet/core/services/xeris_api_service.dart';
import 'package:intl/intl.dart';

class BalancePoint {
  final String label;
  final double value;
  final int index;

  BalancePoint({required this.label, required this.value, required this.index});
}

final balanceHistoryProvider = FutureProvider<List<BalancePoint>>((ref) async {
  final history = await XerisApiService.fetchPriceHistory('xrs_usdc_pool', limit: 50);
  if (history.isEmpty) return [];

  final fmt = DateFormat('HH:mm');

  return history.asMap().entries.map((entry) {
    final i = entry.key;
    final point = entry.value;
    final tsMs = (point['timestamp_ms'] as num?)?.toInt() ?? 0;
    final price = (point['price'] as num?)?.toDouble() ?? 0.0;
    final label = tsMs > 0
        ? fmt.format(DateTime.fromMillisecondsSinceEpoch(tsMs))
        : '$i';
    return BalancePoint(label: label, value: price, index: i);
  }).toList();
});
