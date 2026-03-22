import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class SleepChartCard extends StatelessWidget {
  const SleepChartCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
          const Text(
            'Sommeil (7 jours)',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 150,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 10,
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
                      getTitlesWidget: (double value, TitleMeta meta) {
                        const style =
                            TextStyle(color: Colors.white70, fontSize: 12);
                        Widget text;
                        switch (value.toInt()) {
                          case 0:
                            text = const Text('L', style: style);
                            break;
                          case 1:
                            text = const Text('M', style: style);
                            break;
                          case 2:
                            text = const Text('M', style: style);
                            break;
                          case 3:
                            text = const Text('J', style: style);
                            break;
                          case 4:
                            text = const Text('V', style: style);
                            break;
                          case 5:
                            text = const Text('S', style: style);
                            break;
                          case 6:
                            text = const Text('D', style: style);
                            break;
                          default:
                            text = const Text('', style: style);
                            break;
                        }
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
                        if (value == 6 || value == 8) {
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
                barGroups: [
                  _buildBarGroup(0, 7.5),
                  _buildBarGroup(1, 6.5),
                  _buildBarGroup(2, 8.0),
                  _buildBarGroup(3, 7.0),
                  _buildBarGroup(4, 6.0),
                  _buildBarGroup(5, 8.5),
                  _buildBarGroup(6, 9.0),
                ],
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
          color: const Color(0xFF6A1B9A).withOpacity(0.8), // Purple matching theme
          width: 12,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(4),
            topRight: Radius.circular(4),
          ),
        ),
      ],
    );
  }
}
