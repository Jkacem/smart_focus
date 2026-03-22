import 'package:flutter/material.dart';

class GeneralScoreCard extends StatelessWidget {
  const GeneralScoreCard({Key? key}) : super(key: key);

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
          _buildScoreColumn('Focus', '78%', '+5%', true),
          Container(
            width: 1,
            height: 50,
            color: Colors.white.withOpacity(0.2),
          ),
          _buildScoreColumn('Posture', '72%', '-3%', false),
        ],
      ),
    );
  }

  Widget _buildScoreColumn(
      String title, String score, String trend, bool isPositive) {
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
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isPositive ? Icons.arrow_upward : Icons.arrow_downward,
              color: isPositive ? Colors.greenAccent : Colors.redAccent,
              size: 16,
            ),
            const SizedBox(width: 4),
            Text(
              trend,
              style: TextStyle(
                color: isPositive ? Colors.greenAccent : Colors.redAccent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
