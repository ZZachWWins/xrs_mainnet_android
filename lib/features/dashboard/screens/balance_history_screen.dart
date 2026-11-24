import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xeris_wallet/core/theme/app_theme.dart';
import 'package:xeris_wallet/core/providers/wallet_provider.dart';
import 'package:xeris_wallet/features/dashboard/providers/balance_provider.dart';
import 'package:xeris_wallet/l10n/app_localizations.dart';

class BalanceHistoryScreen extends ConsumerWidget {
  const BalanceHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balanceAsync = ref.watch(totalBalanceUsdProvider);
    final historyAsync = ref.watch(balanceHistoryProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.balanceHistoryTitle),
        backgroundColor: AppColors.brandNavy,
      ),
      backgroundColor: AppColors.brandNavy,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Total Balance Header
              Text(
                l10n.totalBalanceTitle,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppColors.textBody,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                '\$${balanceAsync.value?.toStringAsFixed(2) ?? "0.00"}',
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  fontSize: 40,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              // Chart Area
              Expanded(
                child: historyAsync.when(
                  data: (points) {
                    if (points.isEmpty) {
                      return Center(child: Text(l10n.noHistoryAvailable, style: const TextStyle(color: AppColors.textBody)));
                    }

                    // Calculate Min/Max for Y Axis to add padding
                    final values = points.map((e) => e.value).toList();
                    final minY = values.reduce((a, b) => a < b ? a : b) * 0.95;
                    final maxY = values.reduce((a, b) => a > b ? a : b) * 1.05;

                    return LineChart(
                      LineChartData(
                        gridData: FlGridData(show: false),
                        titlesData: FlTitlesData(
                          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                final index = value.toInt();
                                if (index >= 0 && index < points.length) {
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Text(
                                      points[index].label,
                                      style: const TextStyle(
                                        color: AppColors.textBody,
                                        fontSize: 12,
                                      ),
                                    ),
                                  );
                                }
                                return const SizedBox();
                              },
                              interval: 1,
                            ),
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        minX: 0,
                        maxX: (points.length - 1).toDouble(),
                        minY: minY,
                        maxY: maxY,
                        lineBarsData: [
                          LineChartBarData(
                            spots: points.map((p) => FlSpot(p.index.toDouble(), p.value)).toList(),
                            isCurved: true,
                            color: AppColors.brandVibrant,
                            barWidth: 3,
                            isStrokeCapRound: true,
                            dotData: FlDotData(show: true), // Show dots for interaction visibility
                            belowBarData: BarAreaData(
                              show: true,
                              color: AppColors.brandVibrant.withValues(alpha: 0.1),
                            ),
                          ),
                        ],
                        lineTouchData: LineTouchData(
                            touchTooltipData: LineTouchTooltipData(
                                // tooltipBgColor: AppColors.brandSpace, // Deprecated in newer fl_chart, use getTooltipColor
                                getTooltipColor: (_) => AppColors.brandSpace,
                                getTooltipItems: (touchedSpots) {
                                    return touchedSpots.map((spot) {
                                        return LineTooltipItem(
                                            '\$${spot.y.toStringAsFixed(2)}',
                                            const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                        );
                                    }).toList();
                                }
                            ),
                        ),
                      ),
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator(color: AppColors.brandVibrant)),
                  error: (err, stack) => Center(child: Text(l10n.errorPrefix(err.toString()), style: const TextStyle(color: AppColors.error))),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
