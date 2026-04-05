import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_focus/core/router/app_routes.dart';
import 'package:smart_focus/features/planning/models/planning_models.dart';
import 'package:smart_focus/features/planning/providers/planning_provider.dart';
import 'package:smart_focus/shared/widgets/index.dart';
import 'package:smart_focus/shared/widgets/starfield_painter.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    if (index == 0) {
      context.go(AppRoutes.dashboard);
    } else if (index == 1) {
      context.go(AppRoutes.planning);
    } else if (index == 2) {
      context.go(AppRoutes.chatbot);
    } else if (index == 3) {
      context.go(AppRoutes.statistics);
    } else if (index == 4) {
      context.go(AppRoutes.sleep);
    } else if (index == 5) {
      context.go(AppRoutes.settings);
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final todayPlanningAsync = ref.watch(todayPlanningProvider);
    final now = DateTime.now();

    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      appBar: CustomAppBar(
        title: 'Dashboard',
        trailingWidget: _DashboardStartSessionButton(
          onPressed: () {
            context.push(AppRoutes.session);
          },
        ),
      ),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0a1628),
                  Color(0xFF1a3a4a),
                  Color(0xFF0d2635),
                ],
              ),
            ),
          ),
          _buildStarfield(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  Text(
                    'Vue d ensemble du jour',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.94),
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      height: 1.05,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _formatLongDate(now),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.68),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const _DashboardHeroScoreCard(),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: _DashboardInsightCard(
                          icon: Icons.nights_stay_rounded,
                          title: 'Sommeil',
                          value: '7h30',
                          subtitle: 'Recuperation solide',
                          accent: const Color(0xFF97CAD8),
                          chipLabel: 'Score 82',
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _DashboardInsightCard(
                          icon: Icons.self_improvement_rounded,
                          title: 'Pauses',
                          value: '3',
                          subtitle: 'Bon rythme aujourd hui',
                          accent: const Color(0xFF8BD3A8),
                          chipLabel: 'faites',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  FrostedGlassCard(
                    borderRadius: 16,
                    padding: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.calendar_today, color: Colors.white),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Text(
                                  'Planning du jour',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: () => context.go(AppRoutes.planning),
                                style: TextButton.styleFrom(
                                  foregroundColor: const Color(0xFF97CAD8),
                                ),
                                child: const Text('Voir tout'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Sessions prevues pour aujourd hui',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 16),
                          todayPlanningAsync.when(
                            data: (planningDay) => _DashboardPlanningSection(
                              sessions: planningDay.sessions,
                              onOpenPlanning: () => context.go(AppRoutes.planning),
                            ),
                            loading: () => const Center(
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 20),
                                child: CircularProgressIndicator(
                                  color: Color(0xFF97CAD8),
                                ),
                              ),
                            ),
                            error: (error, stackTrace) => _DashboardPlanningError(
                              message: error.toString().replaceFirst('Exception: ', ''),
                              onRetry: () {
                                ref.invalidate(todayPlanningProvider);
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: CustomBottomNavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }

  Widget _buildStarfield() {
    return SizedBox.expand(child: CustomPaint(painter: StarfieldPainter()));
  }

  String _formatLongDate(DateTime date) {
    const weekdays = [
      'Lundi',
      'Mardi',
      'Mercredi',
      'Jeudi',
      'Vendredi',
      'Samedi',
      'Dimanche',
    ];
    const months = [
      'janvier',
      'fevrier',
      'mars',
      'avril',
      'mai',
      'juin',
      'juillet',
      'aout',
      'septembre',
      'octobre',
      'novembre',
      'decembre',
    ];

    final weekday = weekdays[date.weekday - 1];
    final month = months[date.month - 1];
    return '$weekday ${date.day} $month ${date.year}';
  }
}

class _DashboardStartSessionButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _DashboardStartSessionButton({
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF97CAD8),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.12)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.play_arrow_rounded,
                color: Color(0xFF0A1628),
                size: 18,
              ),
              SizedBox(width: 6),
              Text(
                'Session',
                style: TextStyle(
                  color: Color(0xFF0A1628),
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardHeroScoreCard extends StatelessWidget {
  const _DashboardHeroScoreCard();

  @override
  Widget build(BuildContext context) {
    const score = 78;
    const progress = 0.78;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF17304A),
            Color(0xFF13283E),
            Color(0xFF0B1220),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF97CAD8).withOpacity(0.24)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF97CAD8).withOpacity(0.12),
            blurRadius: 20,
            spreadRadius: 1,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFF97CAD8).withOpacity(0.18),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.track_changes_rounded,
                  color: Color(0xFF97CAD8),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Score du jour',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.92),
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Une lecture rapide de votre rythme, focus et posture.',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.68),
                        fontSize: 13,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'Stable',
                  style: TextStyle(
                    color: const Color(0xFF97CAD8),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              SizedBox(
                width: 110,
                height: 110,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 110,
                      height: 110,
                      child: CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 10,
                        backgroundColor: Colors.white.withOpacity(0.12),
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF97CAD8)),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$score',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 30,
                            fontWeight: FontWeight.w900,
                            height: 1,
                          ),
                        ),
                        Text(
                          '/100',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.65),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 18),
              const Expanded(
                child: Column(
                  children: [
                    _DashboardMetricStrip(
                      label: 'Focus',
                      value: '85%',
                      accent: Color(0xFF97CAD8),
                    ),
                    SizedBox(height: 12),
                    _DashboardMetricStrip(
                      label: 'Posture',
                      value: '72%',
                      accent: Color(0xFF8BD3A8),
                    ),
                    SizedBox(height: 12),
                    _DashboardMetricStrip(
                      label: 'Regularite',
                      value: 'Bonne',
                      accent: Color(0xFFFFC857),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DashboardInsightCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String subtitle;
  final String chipLabel;
  final Color accent;

  const _DashboardInsightCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.chipLabel,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withOpacity(0.16),
            const Color(0xFF112438),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withOpacity(0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: accent, size: 20),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  chipLabel,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              color: Colors.white.withOpacity(0.76),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.white.withOpacity(0.62),
              fontSize: 12,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardMetricStrip extends StatelessWidget {
  final String label;
  final String value;
  final Color accent;

  const _DashboardMetricStrip({
    required this.label,
    required this.value,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.72),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: accent.withOpacity(0.16),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            value,
            style: TextStyle(
              color: accent,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _DashboardPlanningSection extends StatelessWidget {
  final List<PlanningSessionModel> sessions;
  final VoidCallback onOpenPlanning;

  const _DashboardPlanningSection({
    required this.sessions,
    required this.onOpenPlanning,
  });

  @override
  Widget build(BuildContext context) {
    if (sessions.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Aucune session pour aujourd hui.',
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            TextButton.icon(
              onPressed: onOpenPlanning,
              icon: const Icon(Icons.auto_awesome),
              label: const Text('Ouvrir le planning'),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF97CAD8),
                padding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      );
    }

    final now = DateTime.now();
    final completedCount = sessions.where((session) => session.isCompleted).length;
    final pendingCount = sessions
        .where((session) => !session.isCompleted && !session.isCancelled)
        .length;
    final smartCount = sessions.where((session) => session.isAiGenerated).length;
    final featuredSession = _featuredSession(now);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _SessionMetricPill(
              label: 'Sessions',
              value: '${sessions.length}',
              accent: const Color(0xFF97CAD8),
            ),
            _SessionMetricPill(
              label: 'A faire',
              value: '$pendingCount',
              accent: const Color(0xFFFFC857),
            ),
            _SessionMetricPill(
              label: 'Terminees',
              value: '$completedCount',
              accent: const Color(0xFF4ADE80),
            ),
            if (smartCount > 0)
              _SessionMetricPill(
                label: 'IA',
                value: '$smartCount',
                accent: const Color(0xFF8B5CF6),
              ),
          ],
        ),
        const SizedBox(height: 14),
        if (featuredSession != null) ...[
          _DashboardFeaturedSessionCard(
            session: featuredSession,
            onOpenPlanning: onOpenPlanning,
          ),
          const SizedBox(height: 14),
        ],
        Container(
          width: double.infinity,
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
                'Timeline du jour',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.92),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              ...List.generate(
                sessions.length,
                (index) => Padding(
                  padding: EdgeInsets.only(bottom: index == sessions.length - 1 ? 0 : 12),
                  child: _DashboardPlanningItem(
                    session: sessions[index],
                    isLast: index == sessions.length - 1,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  PlanningSessionModel? _featuredSession(DateTime now) {
    for (final session in sessions) {
      final isCurrent = !session.isCompleted &&
          !session.isCancelled &&
          !now.isBefore(session.start) &&
          now.isBefore(session.end);
      if (isCurrent) {
        return session;
      }
    }

    for (final session in sessions) {
      final isUpcoming =
          !session.isCompleted && !session.isCancelled && session.end.isAfter(now);
      if (isUpcoming) {
        return session;
      }
    }

    return sessions.first;
  }
}

class _DashboardPlanningItem extends StatelessWidget {
  final PlanningSessionModel session;
  final bool isLast;

  const _DashboardPlanningItem({
    required this.session,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final accent = _statusColor(session);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 20,
          child: Column(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: accent,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: accent.withOpacity(0.45),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
              if (!isLast)
                Container(
                  width: 2,
                  height: 72,
                  margin: const EdgeInsets.only(top: 6),
                  color: Colors.white.withOpacity(0.12),
                ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: accent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: accent.withOpacity(0.24)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.16),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _statusIcon(session),
                    color: accent,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        session.subject,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${_formatTime(session.start)} - ${_formatTime(session.end)}',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.78),
                          fontSize: 13,
                        ),
                      ),
                      if (session.linkedDocumentSummary != null &&
                          session.linkedDocumentSummary!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          session.linkedDocumentSummary!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.58),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                      decoration: BoxDecoration(
                        color: accent.withOpacity(0.16),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        session.statusLabel,
                        style: TextStyle(
                          color: accent,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _formatDuration(session.duration),
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Color _statusColor(PlanningSessionModel session) {
    if (session.isCompleted) {
      return const Color(0xFF4ADE80);
    }
    if (session.isCancelled) {
      return const Color(0xFFFB7185);
    }
    if (session.isMissed) {
      return const Color(0xFFFFC857);
    }
    if (session.isAiGenerated) {
      return const Color(0xFF97CAD8);
    }
    return const Color(0xFFE2E8F0);
  }

  IconData _statusIcon(PlanningSessionModel session) {
    if (session.isCompleted) {
      return Icons.check_circle_outline;
    }
    if (session.isCancelled) {
      return Icons.close_rounded;
    }
    if (session.isMissed) {
      return Icons.history_toggle_off;
    }
    if (session.isAiGenerated) {
      return Icons.auto_awesome;
    }
    return Icons.schedule;
  }

  static String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  static String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    if (hours > 0 && minutes > 0) {
      return '${hours}h${minutes.toString().padLeft(2, '0')}';
    }
    if (hours > 0) {
      return '${hours}h';
    }
    return '${duration.inMinutes}min';
  }
}

class _DashboardFeaturedSessionCard extends StatelessWidget {
  final PlanningSessionModel session;
  final VoidCallback onOpenPlanning;

  const _DashboardFeaturedSessionCard({
    required this.session,
    required this.onOpenPlanning,
  });

  @override
  Widget build(BuildContext context) {
    final accent = _accentColor(session);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withOpacity(0.24),
            const Color(0xFF102235),
            const Color(0xFF0A1628),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withOpacity(0.32)),
        boxShadow: [
          BoxShadow(
            color: accent.withOpacity(0.16),
            blurRadius: 22,
            spreadRadius: 1,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  _headline(session),
                  style: TextStyle(
                    color: accent,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                _DashboardPlanningItem._formatTime(session.start),
                style: TextStyle(
                  color: Colors.white.withOpacity(0.74),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                session.subject,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${_DashboardPlanningItem._formatTime(session.start)} - ${_DashboardPlanningItem._formatTime(session.end)}  •  ${_DashboardPlanningItem._formatDuration(session.duration)}',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.76),
                  fontSize: 13,
                ),
              ),
              if (session.linkedDocumentSummary != null &&
                  session.linkedDocumentSummary!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    session.linkedDocumentSummary!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.56),
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onOpenPlanning,
              icon: const Icon(Icons.arrow_forward_rounded, size: 18),
              label: const Text('Ouvrir le planning'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.1),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(color: Colors.white.withOpacity(0.12)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _headline(PlanningSessionModel session) {
    if (session.isCompleted) {
      return 'TERMINEE';
    }
    if (session.isMissed) {
      return 'A REPRENDRE';
    }
    if (session.isAiGenerated) {
      return 'PROCHAIN FOCUS';
    }
    return 'PROCHAINE SESSION';
  }

  Color _accentColor(PlanningSessionModel session) {
    if (session.isCompleted) {
      return const Color(0xFF4ADE80);
    }
    if (session.isCancelled) {
      return const Color(0xFFFB7185);
    }
    if (session.isMissed) {
      return const Color(0xFFFFC857);
    }
    if (session.isAiGenerated) {
      return const Color(0xFF97CAD8);
    }
    return const Color(0xFFE2E8F0);
  }
}

class _SessionMetricPill extends StatelessWidget {
  final String label;
  final String value;
  final Color accent;

  const _SessionMetricPill({
    required this.label,
    required this.value,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: accent.withOpacity(0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.withOpacity(0.28)),
      ),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '$value ',
              style: TextStyle(
                color: accent,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
            TextSpan(
              text: label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.82),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardPlanningError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _DashboardPlanningError({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFB7185).withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFB7185).withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Planning indisponible',
            style: TextStyle(
              color: Color(0xFFFB7185),
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(
              color: Colors.white.withOpacity(0.82),
              fontSize: 13,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 10),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Reessayer'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
              padding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }
}
