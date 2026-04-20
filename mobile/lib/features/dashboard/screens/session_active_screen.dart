import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:smart_focus/shared/widgets/custom_app_bar.dart';
import 'package:smart_focus/shared/widgets/frosted_glass_card.dart';
import 'package:smart_focus/shared/widgets/starfield_painter.dart';

import '../models/vision_models.dart';
import '../providers/vision_provider.dart';
import '../services/vision_service.dart';

class SessionActiveScreen extends ConsumerStatefulWidget {
  const SessionActiveScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SessionActiveScreen> createState() =>
      _SessionActiveScreenState();
}

class _SessionActiveScreenState extends ConsumerState<SessionActiveScreen> {
  late final Stopwatch _stopwatch;
  Timer? _uiTimer;

  @override
  void initState() {
    super.initState();
    _stopwatch = Stopwatch()..start();
    _uiTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });

    // If no active session yet, pick the first active one from the backend
    WidgetsBinding.instance.addPostFrameCallback((_) => _ensureSession());
  }

  Future<void> _ensureSession() async {
    final currentId = ref.read(activeWorkSessionIdProvider);
    if (currentId != null) return;

    try {
      final service = ref.read(visionServiceProvider);
      final sessions = await service.listSessions(limit: 10);
      final active = sessions.where((s) => s.isActive).toList();
      if (active.isNotEmpty) {
        ref.read(activeWorkSessionIdProvider.notifier).state = active.first.id;
      }
    } catch (_) {
      // Silently fail — user can still see the static screen
    }
  }

  @override
  void dispose() {
    _uiTimer?.cancel();
    _stopwatch.stop();
    super.dispose();
  }

  String _formatElapsed() {
    final d = _stopwatch.elapsed;
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final snapshotAsync = ref.watch(liveSnapshotProvider);
    final snapshot = snapshotAsync.value;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: CustomAppBar(
        title: 'Session Active',
        leadingIcon: Icons.arrow_back_rounded,
        onLeadingPressed: () => Navigator.of(context).pop(),
        trailingWidget: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _SessionActionIcon(
              icon: Icons.pause_rounded,
              color: const Color(0xFFFFC857),
              onPressed: () {},
            ),
            const SizedBox(width: 8),
            _SessionActionIcon(
              icon: Icons.stop_rounded,
              color: const Color(0xFFFB7185),
              onPressed: () {
                ref.read(activeWorkSessionIdProvider.notifier).state = null;
                Navigator.of(context).pop();
              },
            ),
          ],
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
                  Color(0xFF0A1628),
                  Color(0xFF1A3A4A),
                  Color(0xFF0D2635),
                ],
              ),
            ),
          ),
          SizedBox.expand(child: CustomPaint(painter: StarfieldPainter())),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  _SessionHeroCard(
                    elapsed: _formatElapsed(),
                    snapshot: snapshot,
                  ),
                  const SizedBox(height: 18),
                  _SessionMetricsGrid(snapshot: snapshot),
                  const SizedBox(height: 18),
                  _SessionConnectionStatus(
                    hasData: snapshot != null,
                    sessionId: ref.watch(activeWorkSessionIdProvider),
                  ),
                  const SizedBox(height: 18),
                  const _SessionActionsCard(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ───────────────────────────────────────────────
// Hero Card (top)
// ───────────────────────────────────────────────

class _SessionHeroCard extends StatelessWidget {
  final String elapsed;
  final VisionSnapshot? snapshot;

  const _SessionHeroCard({required this.elapsed, this.snapshot});

  String _focusLabel(double? score) {
    if (score == null) return '--';
    return '${score.round()}%';
  }

  String _qualityLabel(String? workMode) {
    if (workMode == null) return '--';
    final wm = workMode.toLowerCase();
    if (wm.contains('focused') || wm == 'thinking' || wm == 'self_explaining') {
      return 'Haute';
    }
    if (wm == 'brief_off_task') return 'Moyenne';
    return 'Faible';
  }

  Color _qualityColor(String? workMode) {
    if (workMode == null) return const Color(0xFF97CAD8);
    final wm = workMode.toLowerCase();
    if (wm.contains('focused') || wm == 'thinking') return const Color(0xFF8BD3A8);
    if (wm == 'brief_off_task') return const Color(0xFFFFC857);
    return const Color(0xFFFB7185);
  }

  String _modeLabel(String? workMode) {
    if (workMode == null) return 'En attente du capteur...';
    const labels = {
      'focused': 'Concentré',
      'focused_reading': 'Lecture concentrée',
      'focused_writing': 'Écriture concentrée',
      'thinking': 'Réflexion',
      'self_explaining': 'Auto-explication',
      'brief_off_task': 'Brève distraction',
      'phone_distraction': 'Distraction téléphone',
      'social_distraction': 'Distraction sociale',
    };
    return labels[workMode] ?? workMode!;
  }

  String _statusBadge(String? workMode) {
    if (workMode == null) return 'Attente';
    final wm = workMode.toLowerCase();
    if (wm.contains('focused') || wm == 'thinking' || wm == 'self_explaining') {
      return 'Excellent';
    }
    if (wm == 'brief_off_task') return 'Attention';
    return 'Alerte';
  }

  Color _statusBadgeColor(String? workMode) {
    if (workMode == null) return const Color(0xFF97CAD8);
    final wm = workMode.toLowerCase();
    if (wm.contains('focused') || wm == 'thinking') return const Color(0xFF8BD3A8);
    if (wm == 'brief_off_task') return const Color(0xFFFFC857);
    return const Color(0xFFFB7185);
  }

  @override
  Widget build(BuildContext context) {
    final wm = snapshot?.workMode;
    final badgeColor = _statusBadgeColor(wm);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF17304A), Color(0xFF13283E), Color(0xFF0B1220)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF97CAD8).withOpacity(0.24)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF97CAD8).withOpacity(0.12),
            blurRadius: 22,
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
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFF97CAD8).withOpacity(0.18),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.timer_outlined, color: Color(0xFF97CAD8)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Session de concentration',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.94),
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _modeLabel(wm),
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.66),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: badgeColor.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  _statusBadge(wm),
                  style: TextStyle(
                    color: badgeColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Center(
            child: Column(
              children: [
                Text(
                  elapsed,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.98),
                    fontSize: 44,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.6,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Temps de focus cumulé',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.64),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _SessionHeroStat(
                  label: 'Focus',
                  value: _focusLabel(snapshot?.globalFocusScore),
                  accent: const Color(0xFF97CAD8),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SessionHeroStat(
                  label: 'Qualité',
                  value: _qualityLabel(wm),
                  accent: _qualityColor(wm),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SessionHeroStat(
                  label: 'Stress',
                  value: snapshot?.stressRiskScore != null
                      ? '${snapshot!.stressRiskScore!.round()}'
                      : '--',
                  accent: const Color(0xFFFFC857),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SessionHeroStat extends StatelessWidget {
  final String label;
  final String value;
  final Color accent;

  const _SessionHeroStat({
    required this.label,
    required this.value,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.64),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: accent,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

// ───────────────────────────────────────────────
// Live Metrics Grid (4 cards)
// ───────────────────────────────────────────────

class _SessionMetricsGrid extends StatelessWidget {
  final VisionSnapshot? snapshot;

  const _SessionMetricsGrid({this.snapshot});

  String _scoreStr(double? v) => v != null ? '${v.round()}' : '--';

  String _postureStatus(double? v) {
    if (v == null) return 'En attente...';
    if (v >= 80) return 'Bonne tenue';
    if (v >= 50) return 'À surveiller';
    return 'Mauvaise posture';
  }

  Color _postureColor(double? v) {
    if (v == null) return const Color(0xFF97CAD8);
    if (v >= 80) return const Color(0xFF8BD3A8);
    if (v >= 50) return const Color(0xFFFFC857);
    return const Color(0xFFFB7185);
  }

  String _fatigueStatus(double? v) {
    if (v == null) return 'En attente...';
    if (v >= 70) return 'Fatigue élevée';
    if (v >= 40) return 'Fatigue modérée';
    return 'Énergie stable';
  }

  Color _fatigueColor(double? v) {
    if (v == null) return const Color(0xFF97CAD8);
    if (v >= 70) return const Color(0xFFFB7185);
    if (v >= 40) return const Color(0xFFFFC857);
    return const Color(0xFF97CAD8);
  }

  String _attentionStatus(double? v) {
    if (v == null) return 'En attente...';
    if (v >= 80) return 'Excellente';
    if (v >= 50) return 'À surveiller';
    return 'Faible attention';
  }

  Color _attentionColor(double? v) {
    if (v == null) return const Color(0xFF97CAD8);
    if (v >= 80) return const Color(0xFF8BD3A8);
    if (v >= 50) return const Color(0xFFFFC857);
    return const Color(0xFFFB7185);
  }

  String _stressStatus(double? v) {
    if (v == null) return 'En attente...';
    if (v >= 60) return 'Stress élevé';
    if (v >= 30) return 'Stress modéré';
    return 'Détendu';
  }

  Color _stressColor(double? v) {
    if (v == null) return const Color(0xFF97CAD8);
    if (v >= 60) return const Color(0xFFFB7185);
    if (v >= 30) return const Color(0xFFFFC857);
    return const Color(0xFF8BD3A8);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _SessionMetricCard(
                title: 'Posture',
                value: _scoreStr(snapshot?.postureScore),
                status: _postureStatus(snapshot?.postureScore),
                accent: _postureColor(snapshot?.postureScore),
                icon: Icons.accessibility_new_rounded,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _SessionMetricCard(
                title: 'Fatigue',
                value: _scoreStr(snapshot?.vigilanceScore),
                status: _fatigueStatus(snapshot?.vigilanceScore != null
                    ? (100 - snapshot!.vigilanceScore!)
                    : null),
                accent: _fatigueColor(snapshot?.vigilanceScore != null
                    ? (100 - snapshot!.vigilanceScore!)
                    : null),
                icon: Icons.battery_charging_full_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _SessionMetricCard(
                title: 'Attention',
                value: _scoreStr(snapshot?.attentionScore),
                status: _attentionStatus(snapshot?.attentionScore),
                accent: _attentionColor(snapshot?.attentionScore),
                icon: Icons.visibility_outlined,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _SessionMetricCard(
                title: 'Stress',
                value: _scoreStr(snapshot?.stressRiskScore),
                status: _stressStatus(snapshot?.stressRiskScore),
                accent: _stressColor(snapshot?.stressRiskScore),
                icon: Icons.psychology_outlined,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SessionMetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String status;
  final Color accent;
  final IconData icon;

  const _SessionMetricCard({
    required this.title,
    required this.value,
    required this.status,
    required this.accent,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return FrostedGlassCard(
      borderRadius: 20,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.16),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: accent, size: 18),
              ),
              const Spacer(),
              Text(
                title,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.74),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
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
            status,
            style: TextStyle(
              color: accent,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ───────────────────────────────────────────────
// Connection Status (replaces old alerts card)
// ───────────────────────────────────────────────

class _SessionConnectionStatus extends StatelessWidget {
  final bool hasData;
  final String? sessionId;

  const _SessionConnectionStatus({
    required this.hasData,
    this.sessionId,
  });

  @override
  Widget build(BuildContext context) {
    return FrostedGlassCard(
      borderRadius: 22,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                hasData ? Icons.sensors_rounded : Icons.sensors_off_rounded,
                color: hasData ? const Color(0xFF8BD3A8) : const Color(0xFFFFC857),
              ),
              const SizedBox(width: 10),
              Text(
                hasData ? 'Capteur connecté' : 'En attente du capteur',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: (hasData ? const Color(0xFF8BD3A8) : const Color(0xFFFFC857))
                  .withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: (hasData ? const Color(0xFF8BD3A8) : const Color(0xFFFFC857))
                    .withOpacity(0.22),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: (hasData
                            ? const Color(0xFF8BD3A8)
                            : const Color(0xFFFFC857))
                        .withOpacity(0.16),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    hasData ? Icons.check_circle_outline : Icons.info_outline_rounded,
                    color: hasData ? const Color(0xFF8BD3A8) : const Color(0xFFFFC857),
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hasData
                            ? 'Données en temps réel'
                            : 'Lancez le capteur CV',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        hasData
                            ? 'Les métriques se mettent à jour automatiquement.'
                            : 'Exécutez main_cv.py pour démarrer le suivi en temps réel.',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.68),
                          fontSize: 12,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (sessionId != null) ...[
            const SizedBox(height: 10),
            Text(
              'Session: ${sessionId!.substring(0, sessionId!.length.clamp(0, 8))}...',
              style: TextStyle(
                color: Colors.white.withOpacity(0.4),
                fontSize: 11,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ───────────────────────────────────────────────
// Actions Card (bottom)
// ───────────────────────────────────────────────

class _SessionActionsCard extends StatelessWidget {
  const _SessionActionsCard();

  @override
  Widget build(BuildContext context) {
    return FrostedGlassCard(
      borderRadius: 22,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Actions rapides',
            style: TextStyle(
              color: Colors.white.withOpacity(0.94),
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.self_improvement_rounded),
              label: const Text('Prendre une pause'),
              style: ElevatedButton.styleFrom(
                foregroundColor: const Color(0xFF0A1628),
                backgroundColor: const Color(0xFF97CAD8),
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.flag_outlined),
                  label: const Text('Marquer'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(color: Colors.white.withOpacity(0.14)),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.notes_rounded),
                  label: const Text('Notes'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(color: Colors.white.withOpacity(0.14)),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SessionActionIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  const _SessionActionIcon({
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: color.withOpacity(0.14),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withOpacity(0.22)),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
      ),
    );
  }
}
