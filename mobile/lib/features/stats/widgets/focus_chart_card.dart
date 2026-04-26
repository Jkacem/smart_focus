import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class FocusChartCard extends StatelessWidget {
  final List<String> labels;
  final List<double> values;
  final String periodLabel;

  const FocusChartCard({
    Key? key,
    required this.labels,
    required this.values,
    required this.periodLabel,
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
              'Aucune donnee focus disponible',
              style: TextStyle(color: Colors.white70),
            ),
          ),
        ),
      );
    }

    final chartValues = values.length == 1 ? [values.first, values.first] : values;
    final chartLabels = labels.length == 1 ? [labels.first, labels.first] : labels;

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
            'Graphique Focus',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Completion quotidienne - $periodLabel',
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Colors.white.withOpacity(0.1),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles:
                      const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles:
                      const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= chartLabels.length) {
                          return const SizedBox.shrink();
                        }
                        if (!_shouldShowLabel(index, chartLabels.length)) {
                          return const SizedBox.shrink();
                        }

                        final label = chartLabels[index];
                        if (label.isNotEmpty) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              label,
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 12),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        if (value % 20 == 0) {
                          return Text(
                            value.toInt().toString(),
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
                minX: 0,
                maxX: (chartValues.length - 1).toDouble(),
                minY: 0,
                maxY: 100,
                lineBarsData: [
                  LineChartBarData(
                    spots: List<FlSpot>.generate(chartValues.length, (index) {
                      return FlSpot(
                        index.toDouble(),
                        chartValues[index].clamp(0, 100).toDouble(),
                      );
                    }),
                    isCurved: true,
                    color: const Color(0xFF4ADE80),
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: const Color(0xFF4ADE80).withOpacity(0.2),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
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
