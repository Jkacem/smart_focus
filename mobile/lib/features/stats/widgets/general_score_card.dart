import 'package:flutter/material.dart';

class GeneralScoreCard extends StatelessWidget {
  final int focusCompletionPercent;
  final int completedMinutes;
  final int plannedMinutes;
  final double avgSleepHours;
  final double? avgSleepScore;
  final String periodLabel;

  const GeneralScoreCard({
    Key? key,
    required this.focusCompletionPercent,
    required this.completedMinutes,
    required this.plannedMinutes,
    required this.avgSleepHours,
    required this.avgSleepScore,
    required this.periodLabel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildScoreColumn(
            'Focus',
            '$focusCompletionPercent%',
            '${_formatMinutes(completedMinutes)} / ${_formatMinutes(plannedMinutes)}',
            periodLabel,
            const Color(0xFF4ADE80),
          ),
          Container(
            width: 1,
            height: 50,
            color: Colors.white.withOpacity(0.2),
          ),
          _buildScoreColumn(
            'Sommeil',
            avgSleepScore == null ? '--' : '${avgSleepScore!.toStringAsFixed(0)}/100',
            '${avgSleepHours.toStringAsFixed(1)} h moyennes',
            periodLabel,
            const Color(0xFF97CAD8),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreColumn(
    String title,
    String score,
    String details,
    String periodLabel,
    Color accent,
  ) {
    return Column(
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          score,
          style: TextStyle(
            color: accent,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          details,
          style: const TextStyle(
            color: Colors.white70,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          periodLabel,
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  String _formatMinutes(int minutes) {
    final hours = minutes ~/ 60;
    final mins = minutes % 60;

    if (hours > 0 && mins > 0) {
      return '${hours}h${mins.toString().padLeft(2, '0')}';
    }
    if (hours > 0) {
      return '${hours}h';
    }
    return '${mins}min';
  }
}
