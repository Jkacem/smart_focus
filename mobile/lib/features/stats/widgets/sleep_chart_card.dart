import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class SleepChartCard extends StatelessWidget {
  final List<String> labels;
  final List<double> values;
  final String periodLabel;
  final int recordsCount;

  const SleepChartCard({
    Key? key,
    required this.labels,
    required this.values,
    required this.periodLabel,
    required this.recordsCount,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty || labels.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.15)),
        ),
        child: const SizedBox(
          height: 120,
          child: Center(
            child: Text(
              'Aucune donnee sommeil disponible',
              style: TextStyle(color: Colors.white70),
            ),
          ),
        ),
      );
    }

    final maxRecordedHours = values.reduce((a, b) => a > b ? a : b);
    final chartMaxY = (maxRecordedHours < 8 ? 8.0 : (maxRecordedHours + 1))
        .clamp(6.0, 14.0)
        .toDouble();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sommeil ($periodLabel)',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$recordsCount nuits enregistrees',
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 150,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: chartMaxY,
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles:
                      const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles:
                      const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 24,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= labels.length) {
                          return const SizedBox.shrink();
                        }
                        if (!_shouldShowLabel(index, labels.length)) {
                          return const SizedBox.shrink();
                        }

                        const style = TextStyle(color: Colors.white70, fontSize: 12);
                        final text = Text(labels[index], style: style);
                        return Padding(
                            padding: const EdgeInsets.only(top: 8), child: text);
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (value, meta) {
                        if (value % 2 == 0 && value > 0 && value <= chartMaxY) {
                          return Text(
                            '${value.toInt()}h',
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 12),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Colors.white.withOpacity(0.1),
                    strokeWidth: 1,
                  ),
                ),
                barGroups: List<BarChartGroupData>.generate(values.length, (index) {
                  return _buildBarGroup(index, values[index]);
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  BarChartGroupData _buildBarGroup(int x, double y) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: const Color(0xFF97CAD8).withOpacity(0.88),
          width: 12,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(4),
            topRight: Radius.circular(4),
          ),
        ),
      ],
    );
  }

  bool _shouldShowLabel(int index, int total) {
    if (total <= 8) {
      return true;
    }

    final step = total <= 16 ? 2 : 5;
    return index == 0 || index == total - 1 || index % step == 0;
  }
}
