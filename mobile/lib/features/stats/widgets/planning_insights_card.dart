import 'package:flutter/material.dart';

import 'package:smart_focus/features/planning/models/planning_models.dart';

class PlanningInsightsCard extends StatelessWidget {
  final PlanningInsightsModel insights;

  const PlanningInsightsCard({
    Key? key,
    required this.insights,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final accent = _correlationColor(insights.sleepStudyCorrelation);
    final adaptiveAccent = insights.hasAdaptiveSchedulingHistory
        ? const Color(0xFF8B5CF6)
        : const Color(0xFFFFC857);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withOpacity(0.16),
            const Color(0xFF0f2234).withOpacity(0.9),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: accent.withOpacity(0.4), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.insights_outlined, color: accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Insights Planning',
                      style: TextStyle(
                        color: accent,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Resume ${insights.periodLabel.toLowerCase()} de vos sessions, quiz et sommeil.',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _MetricTile(
                  label: 'Temps etudie',
                  value: insights.studyHoursLabel,
                  hint: '${insights.completedSessions} sessions validees',
                  accent: const Color(0xFF97CAD8),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MetricTile(
                  label: 'Completion',
                  value: '${insights.completionRatePercent}%',
                  hint: '${insights.skippedSessions} sessions sautees',
                  accent: const Color(0xFF4ADE80),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _MetricTile(
                  label: 'Sommeil moyen',
                  value: insights.avgSleepHoursLabel,
                  hint: insights.avgSleepScore == null
                      ? insights.sleepCorrelationLabel
                      : 'Score moyen ${insights.avgSleepScore!.toStringAsFixed(0)}',
                  accent: const Color(0xFFFFC857),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MetricTile(
                  label: 'Sujet fragile',
                  value: insights.weakestSubject ?? '--',
                  hint: 'Sujet fort: ${insights.strongestSubject ?? '--'}',
                  accent: const Color(0xFFFB7185),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: adaptiveAccent.withOpacity(0.14),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: adaptiveAccent.withOpacity(0.35),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: adaptiveAccent.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.schedule_outlined,
                    color: adaptiveAccent,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        insights.adaptiveSchedulingLabel,
                        style: TextStyle(
                          color: adaptiveAccent,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        insights.adaptiveSchedulingHint,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.84),
                          fontSize: 13,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.12),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.lightbulb_outline, color: accent, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Recommendation',
                      style: TextStyle(
                        color: accent,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  insights.recommendation,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.88),
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _correlationColor(String value) {
    switch (value) {
      case 'positive':
        return const Color(0xFF4ADE80);
      case 'negative':
        return const Color(0xFFFB7185);
      case 'neutral':
        return const Color(0xFF97CAD8);
      default:
        return const Color(0xFFFFC857);
    }
  }
}

class _MetricTile extends StatelessWidget {
  final String label;
  final String value;
  final String hint;
  final Color accent;

  const _MetricTile({
    required this.label,
    required this.value,
    required this.hint,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: accent,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            hint,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withOpacity(0.72),
              fontSize: 12,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}
