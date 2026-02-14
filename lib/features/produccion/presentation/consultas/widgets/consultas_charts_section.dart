import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../../../../app/theme/app_colors.dart';

class ConsultasChartsSection extends StatelessWidget {
  final Map<String, double> statsPorColor;
  final Map<String, double> produccionSemanal;

  const ConsultasChartsSection({
    super.key,
    required this.statsPorColor,
    required this.produccionSemanal,
  });

  @override
  Widget build(BuildContext context) {
    // Si no hay datos, no mostramos nada o mostramos placeholder
    if (statsPorColor.isEmpty && produccionSemanal.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (produccionSemanal.isNotEmpty) ...[
          const Text(
            'Producción por Semana',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: _WeeklyProductionChart(data: produccionSemanal),
          ),
          const SizedBox(height: 32),
        ],
        if (statsPorColor.isNotEmpty) ...[
          const Text(
            'Distribución por Color',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          _ColorDistributionChart(data: statsPorColor),
          const SizedBox(height: 16),
        ],
      ],
    );
  }
}

class _WeeklyProductionChart extends StatelessWidget {
  final Map<String, double> data;

  const _WeeklyProductionChart({required this.data});

  @override
  Widget build(BuildContext context) {
    final keys = data.keys.toList();
    // Limit to last 8 weeks for readability ?
    // Or sort them first. Keys are "Week-Year". Sorting strings might fail for 1 vs 10.
    // Let's assume naive sort or take last 8.

    final sortedKeys = keys
      ..sort((a, b) {
        final partsA = a.split('-');
        final partsB = b.split('-');
        final weekA = int.parse(partsA[0]);
        final yearA = int.parse(partsA[1]);
        final weekB = int.parse(partsB[0]);
        final yearB = int.parse(partsB[1]);
        if (yearA != yearB) return yearA.compareTo(yearB);
        return weekA.compareTo(weekB);
      });

    final displayKeys = sortedKeys.length > 8
        ? sortedKeys.sublist(sortedKeys.length - 8)
        : sortedKeys;

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: data.values.reduce((a, b) => a > b ? a : b) * 1.2,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => Colors.blueGrey,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                rod.toY.round().toString(),
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value < 0 || value >= displayKeys.length)
                  return const SizedBox.shrink();
                final key = displayKeys[value.toInt()];
                final week = key.split('-')[0];
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    'S$week',
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.textSecondary,
                    ),
                  ),
                );
              },
            ),
          ),
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(displayKeys.length, (index) {
          final key = displayKeys[index];
          final value = data[key]!;
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: value,
                color: AppColors.accent,
                width: 16,
                borderRadius: BorderRadius.circular(4),
                backDrawRodData: BackgroundBarChartRodData(
                  show: true,
                  toY: data.values.reduce((a, b) => a > b ? a : b) * 1.2,
                  color: Colors.grey.shade100,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

class _ColorDistributionChart extends StatelessWidget {
  final Map<String, double> data;

  const _ColorDistributionChart({required this.data});

  @override
  Widget build(BuildContext context) {
    final total = data.values.fold(0.0, (sum, val) => sum + val);

    return Row(
      children: [
        // Pie Chart
        Expanded(
          flex: 3,
          child: SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 40,
                sections: data.entries.map((entry) {
                  final colorHex = entry.key;
                  final value = entry.value;
                  final percentage = (value / total * 100);
                  final color = Color(
                    int.tryParse(colorHex.replaceFirst('#', '0xff')) ??
                        0xFFCCCCCC,
                  );

                  return PieChartSectionData(
                    color: color,
                    value: value,
                    title: '${percentage.toStringAsFixed(0)}%',
                    radius: 60,
                    titleStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  );
                }).toList(),
              ),
              swapAnimationDuration: const Duration(milliseconds: 800),
            ),
          ),
        ),
        const SizedBox(width: 24),
        // Legend
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: data.entries.map((entry) {
              final colorHex = entry.key;
              final value = entry.value;
              final color = Color(
                int.tryParse(colorHex.replaceFirst('#', '0xff')) ?? 0xFFCCCCCC,
              );
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${value.toStringAsFixed(0)} un',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
