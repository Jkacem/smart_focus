import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:smart_focus/features/planning/data/planning_repository.dart';
import 'package:smart_focus/features/planning/providers/planning_provider.dart';
import 'package:smart_focus/shared/widgets/custom_app_bar.dart';
import 'package:smart_focus/shared/widgets/frosted_glass_card.dart';
import 'package:smart_focus/shared/widgets/starfield_painter.dart';

import '../models/vision_models.dart';
import '../providers/vision_provider.dart';
import '../services/vision_service.dart';
import '../utils/session_utils.dart';

class SessionActiveScreen extends ConsumerStatefulWidget {
  const SessionActiveScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SessionActiveScreen> createState() =>
      _SessionActiveScreenState();
}

class _SessionActiveScreenState extends ConsumerState<SessionActiveScreen> {
  Timer? _uiTimer;
  bool _isStopping = false;
  bool _isSyncingSessionDiscovery = false;
  DateTime? _lastSessionSyncAt;

  VisionSnapshot? _minuteSnapshot;
  DateTime? _minuteSnapshotAt;

  @override
  void initState() {
    super.initState();
    final runtime = ref.read(activeSessionRuntimeProvider);
    ref.read(isLivePollingPausedProvider.notifier).state = runtime.isPaused;
    _uiTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      ref.read(activeSessionRuntimeProvider.notifier).tick();
      _syncActiveSessionIfNeeded();
      _refreshMinuteSnapshot();
      setState(() {});
    });

    WidgetsBinding.instance.addPostFrameCallback((_) => _ensureSession());
  }

  Future<void> _ensureSession() async {
    var currentId = ref.read(activeWorkSessionIdProvider);
    if (currentId != null && isSyntheticPlanningSessionId(currentId)) {
      ref.read(activeWorkSessionIdProvider.notifier).state = null;
      currentId = null;
      _clearMinuteSnapshotCache();
    }

    await _syncActiveSessionIfNeeded(force: true);

    currentId = ref.read(activeWorkSessionIdProvider);
    ref.read(activeSessionRuntimeProvider.notifier).attachSession(currentId);
    final isPaused = ref.read(activeSessionRuntimeProvider).isPaused;
    ref.read(isLivePollingPausedProvider.notifier).state = isPaused;

    await _resolvePlanningSessionTitleFromCalendar();
  }

  Future<void> _resolvePlanningSessionTitleFromCalendar() async {
    final planningId = ref.read(activePlanningSessionIdProvider);
    if (planningId == null) return;

    try {
      final day = await ref.read(planningRepositoryProvider).getToday();
      for (final session in day.sessions) {
        if (session.id == planningId && session.subject.trim().isNotEmpty) {
          ref.read(activePlanningSessionTitleProvider.notifier).state =
              session.subject.trim();
          return;
        }
      }
    } catch (_) {
      // Ignore resolution failures, keep generic fallback title.
    }
  }



  @override
  void deactivate() {
    _uiTimer?.cancel();
    _uiTimer = null;
    super.deactivate();
  }

  @override
  void activate() {
    super.activate();
    if (_uiTimer == null) {
      _uiTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        ref.read(activeSessionRuntimeProvider.notifier).tick();
        _syncActiveSessionIfNeeded();
        _refreshMinuteSnapshot();
        setState(() {});
      });
    }
  }

  @override
  void dispose() {
    _uiTimer?.cancel();
    super.dispose();
  }

  void _refreshMinuteSnapshot() {
    final latest = ref.read(liveSnapshotProvider).value;
    if (latest == null) return;

    final now = DateTime.now();
    final shouldSeed = _minuteSnapshot == null || _minuteSnapshotAt == null;
    final shouldRefresh = !shouldSeed &&
        now.difference(_minuteSnapshotAt!) >= const Duration(minutes: 1);

    if (shouldSeed || shouldRefresh) {
      _minuteSnapshot = latest;
      _minuteSnapshotAt = now;
    }
  }

  void _clearMinuteSnapshotCache() {
    _minuteSnapshot = null;
    _minuteSnapshotAt = null;
  }

  DateTime _sessionLocalStart(WorkSessionInfo session) {
    return session.startTime.isUtc ? session.startTime.toLocal() : session.startTime;
  }

  Future<void> _syncActiveSessionIfNeeded({bool force = false}) async {
    if (!mounted || _isSyncingSessionDiscovery) return;
    final now = DateTime.now();
    if (!force &&
        _lastSessionSyncAt != null &&
        now.difference(_lastSessionSyncAt!) < const Duration(seconds: 8)) {
      return;
    }

    _isSyncingSessionDiscovery = true;
    _lastSessionSyncAt = now;
    try {
      final service = ref.read(visionServiceProvider);
      final sessions = await service.listSessions(limit: 200);
      final activeSessions = sessions
          .where(
            (session) =>
                session.isActive && !isSyntheticPlanningSessionId(session.id),
          )
          .toList()
        ..sort(
          (a, b) => _sessionLocalStart(b).compareTo(_sessionLocalStart(a)),
        );

      final currentId = ref.read(activeWorkSessionIdProvider);
      WorkSessionInfo? currentSession;
      if (currentId != null) {
        for (final session in sessions) {
          if (session.id == currentId) {
            currentSession = session;
            break;
          }
        }
      }

      if (activeSessions.isEmpty) {
        if (currentSession != null && !currentSession.isActive) {
          ref.read(activeWorkSessionIdProvider.notifier).state = null;
          ref.read(activeSessionRuntimeProvider.notifier).clear();
          _clearMinuteSnapshotCache();
        }
        return;
      }

      final freshestActive = activeSessions.first;
      final shouldSwitch = currentSession == null ||
          !currentSession.isActive ||
          currentSession.id != freshestActive.id;
      if (!shouldSwitch) return;

      ref.read(activeWorkSessionIdProvider.notifier).state = freshestActive.id;
      final planningId = planningSessionIdFromMetadata(freshestActive.metadataJson);
      if (planningId != null) {
        ref.read(activePlanningSessionIdProvider.notifier).state = planningId;
      }
      final planningTitle = planningSessionTitleFromMetadata(freshestActive.metadataJson);
      if (planningTitle != null && planningTitle.trim().isNotEmpty) {
        ref.read(activePlanningSessionTitleProvider.notifier).state = planningTitle;
      }
      ref.read(activeSessionRuntimeProvider.notifier).attachSession(freshestActive.id);
      final isPaused = ref.read(activeSessionRuntimeProvider).isPaused;
      ref.read(isLivePollingPausedProvider.notifier).state = isPaused;
      _clearMinuteSnapshotCache();
    } catch (e) {
      debugPrint('[SessionActive] Session sync failed: $e');
    } finally {
      _isSyncingSessionDiscovery = false;
    }
  }

  String _formatElapsed(int elapsedSeconds) {
    final h = (elapsedSeconds ~/ 3600).toString().padLeft(2, '0');
    final m = ((elapsedSeconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final s = (elapsedSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  String _sessionStateLabel({
    required String? activeSessionId,
    required VisionSnapshot? snapshot,
    required bool isLoading,
    required bool isPaused,
  }) {
    if (_isStopping) return 'Finalisation en cours';
    if (isPaused) return 'Session en pause';
    if (activeSessionId == null) return 'Aucune session active';
    if (snapshot != null) return 'Session suivie en direct';
    if (isLoading) return 'Connexion au capteur...';
    return 'Session demarree (en attente de donnees)';
  }

  _SessionNotice _noticeFor({
    required VisionSnapshot? snapshot,
    required bool hasLiveData,
    required bool isPaused,
  }) {
    if (_isStopping) {
      return const _SessionNotice(
        title: 'Arret en cours',
        message: 'Sauvegarde des donnees de session.',
        icon: Icons.sync_rounded,
        color: Color(0xFFFFC857),
      );
    }

    if (isPaused) {
      return const _SessionNotice(
        title: 'Session en pause',
        message: 'Reprenez la session pour relancer le suivi automatique.',
        icon: Icons.pause_circle_outline_rounded,
        color: Color(0xFFFFC857),
      );
    }

    if (!hasLiveData) {
      return const _SessionNotice(
        title: 'Capteur non connecte',
        message: 'Lancez main_cv.py pour demarrer la collecte des signaux.',
        icon: Icons.sensors_off_rounded,
        color: Color(0xFFFFC857),
      );
    }

    final stress = snapshot?.stressRiskScore;
    if (stress != null && stress >= 60) {
      return const _SessionNotice(
        title: 'Alerte stress',
        message: 'Respirez 60 secondes puis reprenez votre rythme.',
        icon: Icons.warning_amber_rounded,
        color: Color(0xFFFB7185),
      );
    }

    final workMode = snapshot?.workMode?.toLowerCase();
    if (workMode == 'brief_off_task' ||
        workMode == 'phone_distraction' ||
        workMode == 'social_distraction') {
      return const _SessionNotice(
        title: 'Distraction detectee',
        message: 'Revenez sur la tache courante pour proteger le focus.',
        icon: Icons.notifications_active_outlined,
        color: Color(0xFFFFC857),
      );
    }

    final focus = snapshot?.globalFocusScore;
    if (focus != null && focus >= 80) {
      return const _SessionNotice(
        title: 'Bon rythme',
        message: 'Concentration stable. Continuez sur cette dynamique.',
        icon: Icons.check_circle_outline_rounded,
        color: Color(0xFF8BD3A8),
      );
    }

    return const _SessionNotice(
      title: 'Session stable',
      message: 'Stats mises a jour chaque minute pour un suivi clair.',
      icon: Icons.info_outline_rounded,
      color: Color(0xFF97CAD8),
    );
  }

  void _togglePause() {
    if (_isStopping) return;
    final runtime = ref.read(activeSessionRuntimeProvider);
    final notifier = ref.read(activeSessionRuntimeProvider.notifier);
    if (runtime.isPaused) {
      notifier.resume();
      ref.read(isLivePollingPausedProvider.notifier).state = false;
    } else {
      notifier.pause();
      ref.read(isLivePollingPausedProvider.notifier).state = true;
    }
  }

  Map<String, dynamic> _buildFinalizeSummary(
    VisionSnapshot? snapshot,
    ActiveSessionRuntimeState runtime,
  ) {
    final focus = snapshot?.globalFocusScore;
    final posture = snapshot?.postureScore;
    final stress = snapshot?.stressRiskScore;

    return {
      'session_duration': runtime.elapsedSeconds.toDouble(),
      'focus_time_ratio': focus != null ? (focus / 100).clamp(0.0, 1.0) : null,
      'posture_quality_score': posture,
      'final_score': focus,
      'breakdown': {
        'pause_count': runtime.pauseCount,
        if (stress != null) 'stress_risk_score': stress,
      },
    };
  }

  Future<void> _stopSessionAndExit(VisionSnapshot? snapshot) async {
    if (_isStopping) return;

    setState(() {
      _isStopping = true;
    });

    final workSessionId = ref.read(activeWorkSessionIdProvider);
    final planningSessionId = ref.read(activePlanningSessionIdProvider);
    final service = ref.read(visionServiceProvider);
    final runtimeNotifier = ref.read(activeSessionRuntimeProvider.notifier);
    runtimeNotifier.tick();
    final runtime = ref.read(activeSessionRuntimeProvider);

    WorkSessionInfo? finalizedSession;
    if (workSessionId != null) {
      try {
        finalizedSession = await service.finalizeSession(
          workSessionId,
          summary: _buildFinalizeSummary(snapshot, runtime),
        );
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Impossible de finaliser la session. Reessayez.'),
            ),
          );
          setState(() {
            _isStopping = false;
          });
        }
        return;
      }
    }

    if (planningSessionId != null) {
      try {
        await ref
            .read(planningRepositoryProvider)
            .updateSessionStatus(planningSessionId, 'completed');
      } catch (_) {
        // Keep local stop successful even if planning sync fails.
      }
    }

    runtimeNotifier.clear();
    ref.read(activeWorkSessionIdProvider.notifier).state = null;
    ref.read(activePlanningSessionIdProvider.notifier).state = null;
    ref.read(activePlanningSessionTitleProvider.notifier).state = null;
    ref.read(isLivePollingPausedProvider.notifier).state = false;

    ref.invalidate(todayVisionSummaryProvider);
    ref.invalidate(todayPlanningProvider);
    ref.invalidate(workSessionsProvider);

    if (mounted) {
      final avgFocusScore = _extractAvgFocusScore(finalizedSession);
      if (avgFocusScore != null) {
        await _showFocusScoreDialog(avgFocusScore);
      }
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  double? _extractAvgFocusScore(WorkSessionInfo? session) {
    final summary = session?.finalSummary;
    if (summary == null) return null;
    final raw = summary['avg_focus_score'] ?? summary['final_score'];
    if (raw is num) return raw.toDouble();
    if (raw is String) return double.tryParse(raw);
    return null;
  }

  Future<void> _showFocusScoreDialog(double avgFocusScore) async {
    if (!mounted) return;

    final scorePercent = avgFocusScore.round();
    final isLowFocus = avgFocusScore < 50;
    final scoreColor = avgFocusScore >= 70
        ? const Color(0xFF8BD3A8)
        : avgFocusScore >= 40
            ? const Color(0xFFFFC857)
            : const Color(0xFFFB7185);
    final scoreLabel = avgFocusScore >= 70
        ? 'Bonne concentration'
        : avgFocusScore >= 40
            ? 'Concentration moyenne'
            : 'Concentration faible';

    final shouldRegenerate = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        backgroundColor: const Color(0xFF0A1628),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: Colors.white.withOpacity(0.12)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: scoreColor.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Text(
                    '$scorePercent',
                    style: TextStyle(
                      color: scoreColor,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Session terminee',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.95),
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Score focus moyen: $scorePercent%\n$scoreLabel',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.72),
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              if (isLowFocus) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFC857).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFFFFC857).withOpacity(0.26),
                    ),
                  ),
                  child: Text(
                    'Votre concentration etait basse. Regenerer le planning '
                    'ajustera les prochaines sessions avec des durees plus '
                    'courtes et des pauses plus longues.',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white.withOpacity(0.7),
                        side: BorderSide(
                          color: Colors.white.withOpacity(0.2),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Fermer'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF97CAD8),
                        foregroundColor: const Color(0xFF0A1628),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text(
                        'Regenerer',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (shouldRegenerate == true && mounted) {
      try {
        final now = DateTime.now();
        // Use the default daily generation path so the backend resolves the
        // proper timetable source (latest CSV fallback) and avoids stale
        // dialog context (non-CSV doc / forced week type) after a session stop.
        await ref.read(planningRepositoryProvider).generatePlanning(
              date: DateTime(now.year, now.month, now.day),
            );
        ref.invalidate(todayPlanningProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Planning regenere avec votre profil de focus.'),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final snapshotAsync = ref.watch(liveSnapshotProvider);
    final liveSnapshot = snapshotAsync.value;
    final activeSessionId = ref.watch(activeWorkSessionIdProvider);
    final planningSessionTitle = ref.watch(activePlanningSessionTitleProvider);
    final runtime = ref.watch(activeSessionRuntimeProvider);
    final isPaused = runtime.isPaused;

    _refreshMinuteSnapshot();
    final displaySnapshot = _minuteSnapshot ?? liveSnapshot;
    final sessionStateLabel = _sessionStateLabel(
      activeSessionId: activeSessionId,
      snapshot: liveSnapshot,
      isLoading: snapshotAsync.isLoading,
      isPaused: isPaused,
    );
    final notice = _noticeFor(
      snapshot: displaySnapshot,
      hasLiveData: liveSnapshot != null,
      isPaused: isPaused,
    );
    final resolvedTitle = (planningSessionTitle != null &&
            planningSessionTitle.trim().isNotEmpty)
        ? planningSessionTitle.trim()
        : 'Session de concentration';

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
              icon:
                  isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
              color:
                  isPaused ? const Color(0xFF8BD3A8) : const Color(0xFFFFC857),
              onPressed: _togglePause,
            ),
            const SizedBox(width: 8),
            _SessionActionIcon(
              icon: Icons.stop_rounded,
              color: const Color(0xFFFB7185),
              onPressed: () => _stopSessionAndExit(liveSnapshot ?? displaySnapshot),
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
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 920),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 12),
                      _SessionHeroCard(
                        elapsed: _formatElapsed(runtime.elapsedSeconds),
                        sessionTitle: resolvedTitle,
                        stateLabel: sessionStateLabel,
                        isPaused: isPaused,
                        lastMinuteUpdate: _minuteSnapshotAt,
                      ),
                      const SizedBox(height: 18),
                      _SessionMinuteSummaryCard(
                        snapshot: displaySnapshot,
                        updatedAt: _minuteSnapshotAt,
                      ),
                      const SizedBox(height: 18),
                      _SessionStatusCard(
                        hasData: liveSnapshot != null,
                        sessionId: activeSessionId,
                        stateLabel: sessionStateLabel,
                        notice: notice,
                      ),
                      const SizedBox(height: 18),
                      _SessionActionsCard(
                        isPaused: isPaused,
                        isStopping: _isStopping,
                        onPauseToggle: _togglePause,
                        onStop: () =>
                            _stopSessionAndExit(liveSnapshot ?? displaySnapshot),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}



class _SessionHeroCard extends StatelessWidget {
  final String elapsed;
  final String sessionTitle;
  final String stateLabel;
  final bool isPaused;
  final DateTime? lastMinuteUpdate;

  const _SessionHeroCard({
    required this.elapsed,
    required this.sessionTitle,
    required this.stateLabel,
    required this.isPaused,
    required this.lastMinuteUpdate,
  });

  @override
  Widget build(BuildContext context) {
    final badgeColor =
        isPaused ? const Color(0xFFFFC857) : const Color(0xFF8BD3A8);

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
            crossAxisAlignment: CrossAxisAlignment.start,
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
                      sessionTitle,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.94),
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      stateLabel,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 12,
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
                  isPaused ? 'Pause' : 'Actif',
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
                  'Temps de focus cumule',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.64),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Text(
            lastMinuteUpdate == null
                ? 'Resume stats: en attente de donnees'
                : 'Resume stats mis a jour a ${_formatClock(lastMinuteUpdate!)}',
            style: TextStyle(
              color: Colors.white.withOpacity(0.62),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SessionMinuteSummaryCard extends StatelessWidget {
  final VisionSnapshot? snapshot;
  final DateTime? updatedAt;

  const _SessionMinuteSummaryCard({
    required this.snapshot,
    required this.updatedAt,
  });

  String _scoreLabel(double? value, {bool withPercent = false}) {
    if (value == null) return '--';
    final rounded = value.round();
    return withPercent ? '$rounded%' : '$rounded';
  }

  String _modeLabel(String? workMode) {
    if (workMode == null || workMode.isEmpty) return 'En attente';
    switch (workMode) {
      case 'focused':
        return 'Concentre';
      case 'focused_reading':
        return 'Lecture concentree';
      case 'focused_writing':
        return 'Ecriture concentree';
      case 'thinking':
        return 'Reflexion';
      case 'self_explaining':
        return 'Auto-explication';
      case 'brief_off_task':
        return 'Distraction courte';
      case 'phone_distraction':
        return 'Distraction telephone';
      case 'social_distraction':
        return 'Distraction sociale';
      default:
        return workMode;
    }
  }

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
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFF97CAD8).withOpacity(0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.monitor_heart_outlined,
                  color: Color(0xFF97CAD8),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Resume des stats (mise a jour 1 min)',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.92),
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (updatedAt != null)
                Text(
                  _formatClock(updatedAt!),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.56),
                    fontSize: 12,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          if (snapshot == null)
            Text(
              'Les mesures apparaitront ici des que le capteur enverra des donnees.',
              style: TextStyle(
                color: Colors.white.withOpacity(0.72),
                fontSize: 13,
                height: 1.35,
              ),
            )
          else
            Column(
              children: [
                _SummaryLine(
                  label: 'Mode',
                  value: _modeLabel(snapshot!.workMode),
                  color: const Color(0xFF97CAD8),
                ),
                _SummaryLine(
                  label: 'Focus global',
                  value: _scoreLabel(
                    snapshot!.globalFocusScore,
                    withPercent: true,
                  ),
                  color: const Color(0xFF8BD3A8),
                ),
                _SummaryLine(
                  label: 'Attention',
                  value: _scoreLabel(
                    snapshot!.attentionScore,
                    withPercent: true,
                  ),
                  color: const Color(0xFF97CAD8),
                ),
                _SummaryLine(
                  label: 'Posture',
                  value: _scoreLabel(
                    snapshot!.postureScore,
                    withPercent: true,
                  ),
                  color: const Color(0xFF8BD3A8),
                ),
                _SummaryLine(
                  label: 'Stress',
                  value: _scoreLabel(snapshot!.stressRiskScore),
                  color: const Color(0xFFFFC857),
                  showDivider: false,
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _SummaryLine extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool showDivider;

  const _SummaryLine({
    required this.label,
    required this.value,
    required this.color,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        if (showDivider) ...[
          const SizedBox(height: 8),
          Divider(color: Colors.white.withOpacity(0.1), height: 1),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _SessionStatusCard extends StatelessWidget {
  final bool hasData;
  final String? sessionId;
  final String stateLabel;
  final _SessionNotice notice;

  const _SessionStatusCard({
    required this.hasData,
    required this.sessionId,
    required this.stateLabel,
    required this.notice,
  });

  @override
  Widget build(BuildContext context) {
    final sensorColor =
        hasData ? const Color(0xFF8BD3A8) : const Color(0xFFFFC857);
    final sessionPrefix = sessionId == null
        ? 'N/A'
        : sessionId!.substring(0, sessionId!.length < 10 ? sessionId!.length : 10);

    return FrostedGlassCard(
      borderRadius: 22,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Etat et notifications',
            style: TextStyle(
              color: Colors.white.withOpacity(0.94),
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: sensorColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: sensorColor.withOpacity(0.24)),
            ),
            child: Row(
              children: [
                Icon(
                  hasData ? Icons.sensors_rounded : Icons.sensors_off_rounded,
                  color: sensorColor,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    stateLabel,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.88),
                      fontSize: 13,
                      height: 1.3,
                    ),
                  ),
                ),
                Text(
                  sessionPrefix,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.45),
                    fontSize: 11,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: notice.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: notice.color.withOpacity(0.26)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(notice.icon, color: notice.color),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notice.title,
                        style: TextStyle(
                          color: notice.color,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notice.message,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.76),
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
        ],
      ),
    );
  }
}

class _SessionActionsCard extends StatelessWidget {
  final bool isPaused;
  final bool isStopping;
  final VoidCallback onPauseToggle;
  final VoidCallback onStop;

  const _SessionActionsCard({
    required this.isPaused,
    required this.isStopping,
    required this.onPauseToggle,
    required this.onStop,
  });

  @override
  Widget build(BuildContext context) {
    return FrostedGlassCard(
      borderRadius: 22,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Actions session',
            style: TextStyle(
              color: Colors.white.withOpacity(0.94),
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: isStopping ? null : onPauseToggle,
                  icon: Icon(
                    isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                  ),
                  label: Text(
                    isPaused ? 'Reprendre' : 'Mettre en pause',
                  ),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: const Color(0xFF0A1628),
                    backgroundColor: const Color(0xFF97CAD8),
                    disabledBackgroundColor:
                        const Color(0xFF97CAD8).withOpacity(0.4),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: isStopping ? null : onStop,
                  icon: Icon(
                    isStopping ? Icons.sync_rounded : Icons.stop_rounded,
                  ),
                  label: Text(isStopping ? 'Arret...' : 'Terminer'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFFB7185),
                    side: BorderSide(
                      color: const Color(0xFFFB7185).withOpacity(0.45),
                    ),
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

class _SessionNotice {
  final String title;
  final String message;
  final IconData icon;
  final Color color;

  const _SessionNotice({
    required this.title,
    required this.message,
    required this.icon,
    required this.color,
  });
}

String _formatClock(DateTime dateTime) {
  final hour = dateTime.hour.toString().padLeft(2, '0');
  final minute = dateTime.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}
