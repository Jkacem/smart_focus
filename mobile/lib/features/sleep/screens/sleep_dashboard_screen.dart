// lib/features/sleep/screens/sleep_dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:smart_focus/core/router/app_routes.dart';
import '../../../shared/widgets/index.dart';
import '../../../shared/widgets/starfield_painter.dart';
import '../providers/sleep_provider.dart';
import '../models/sleep_models.dart';

class SleepDashboardScreen extends ConsumerStatefulWidget {
  const SleepDashboardScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SleepDashboardScreen> createState() =>
      _SleepDashboardScreenState();
}

class _SleepDashboardScreenState extends ConsumerState<SleepDashboardScreen> {
  int _selectedIndex =
      4; // Assuming 4 is the sleep tab if we add one, or adjust as needed. We will adjust home_page later.

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
    final statsAsync = ref.watch(sleepStatsProvider);
    final historyAsync = ref.watch(sleepHistoryProvider);
    final manualSleepSession = ref.watch(manualSleepSessionProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      appBar: CustomAppBar(
        title: 'Sommeil 🌙',
        trailingIcon: Icons.alarm,
        onTrailingPressed: () => context.push(AppRoutes.sleepAlarm),
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
          SizedBox.expand(child: CustomPaint(painter: StarfieldPainter())),
          SafeArea(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.read(sleepStatsProvider.notifier).fetchStats();
                ref.read(sleepHistoryProvider.notifier).fetchHistory();
                await ref.read(manualSleepSessionProvider.notifier).refresh();
              },
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                children: [
                  const SizedBox(height: 16),
                  _buildManualSleepCard(manualSleepSession),
                  const SizedBox(height: 24),
                  _buildPeriodFilter(),
                  const SizedBox(height: 24),
                  _buildStatsCard(statsAsync),
                  const SizedBox(height: 24),
                  _buildCurrentAlarmCard(),
                  const SizedBox(height: 24),
                  const Text(
                    'Historique (Nuits enregistrées)',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildHistoryList(historyAsync),
                  const SizedBox(height: 32),
                  _buildConfigureAlarmButton(),
                  const SizedBox(height: 100), // Nav Bar padding
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: CustomBottomNavBar(
        selectedIndex: 4, 
        onItemTapped: _onItemTapped,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(AppRoutes.sleepAlarm),
        backgroundColor: Colors.blueAccent,
        child: const Icon(Icons.alarm_add, color: Colors.white),
      ),
    );
  }

  Widget _buildManualSleepCard(ManualSleepSessionState sessionState) {
    final sleepStart = sessionState.sleepStart;
    final now = DateTime.now();
    final duration = sleepStart == null ? null : now.difference(sleepStart);
    final actionLabel = sessionState.isSleeping
        ? "I'm awake"
        : "I'm going to sleep";
    final actionIcon = sessionState.isSleeping
        ? Icons.wb_sunny_rounded
        : Icons.nights_stay_rounded;
    final actionColor = sessionState.isSleeping
        ? const Color(0xFF8BD3A8)
        : const Color(0xFF97CAD8);

    return FrostedGlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: actionColor.withOpacity(0.16),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(actionIcon, color: actionColor, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Manual Sleep Tracking',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      sessionState.isSleeping
                          ? 'Sleep start is saved locally. Wake up will send the record to the backend.'
                          : 'Tap once before sleep, then tap again when you wake up.',
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
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildManualSleepInfoRow(
                  'Status',
                  sessionState.isSleeping ? 'Sleeping' : 'Awake',
                ),
                const SizedBox(height: 10),
                _buildManualSleepInfoRow(
                  'Sleep start',
                  sleepStart == null
                      ? 'Not started yet'
                      : DateFormat('dd MMM yyyy • HH:mm').format(sleepStart),
                ),
                if (duration != null) ...[
                  const SizedBox(height: 10),
                  _buildManualSleepInfoRow(
                    'Elapsed',
                    _formatDuration(duration),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 58,
            child: ElevatedButton.icon(
              onPressed: sessionState.isLoading || sessionState.isSubmitting
                  ? null
                  : () async {
                      if (sessionState.isSleeping) {
                        await _finishManualSleep();
                        return;
                      }
                      await _startManualSleep();
                    },
              icon: sessionState.isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: Color(0xFF0A1628),
                      ),
                    )
                  : Icon(actionIcon),
              label: Text(
                sessionState.isSubmitting ? 'Saving...' : actionLabel,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: ElevatedButton.styleFrom(
                foregroundColor: const Color(0xFF0A1628),
                backgroundColor: actionColor,
                disabledBackgroundColor: Colors.white.withOpacity(0.18),
                disabledForegroundColor: Colors.white54,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManualSleepInfoRow(String label, String value) {
    return Row(
      children: [
        SizedBox(
          width: 88,
          child: Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.64),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _startManualSleep() async {
    try {
      final sleepStart = await ref
          .read(manualSleepSessionProvider.notifier)
          .startSleep();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Sleep started at ${DateFormat('HH:mm').format(sleepStart)}.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Future<void> _finishManualSleep() async {
    try {
      final record = await ref
          .read(manualSleepSessionProvider.notifier)
          .finishSleep();
      if (!mounted) return;

      final totalHours = record.totalHours?.toStringAsFixed(1);
      final message = totalHours == null
          ? 'Sleep record saved successfully.'
          : 'Sleep record saved: $totalHours h.';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Widget _buildPeriodFilter() {
    final selectedPeriod = ref.watch(sleepPeriodProvider);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: ['week', 'month'].map((period) {
        final isSelected = selectedPeriod == period;
        final label = period == 'week' ? 'Semaine' : 'Mois';
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                ref.read(sleepPeriodProvider.notifier).state = period;
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.blueAccent
                      : Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: isSelected ? [BoxShadow(color: Colors.blueAccent.withOpacity(0.5), blurRadius: 8)] : [],
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.white70,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStatsCard(AsyncValue statsAsync) {
    return statsAsync.when(
      data: (stats) {
        if (stats == null) return const SizedBox.shrink();
        IconData trendIcon;
        Color trendColor;
        if (stats.trend == 'improving') {
          trendIcon = Icons.trending_up;
          trendColor = Colors.greenAccent;
        } else if (stats.trend == 'declining') {
          trendIcon = Icons.trending_down;
          trendColor = Colors.redAccent;
        } else {
          trendIcon = Icons.trending_flat;
          trendColor = Colors.orangeAccent;
        }

        return FrostedGlassCard(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Text(
                'Moyenne de Sommeil',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 120,
                    height: 120,
                    child: CircularProgressIndicator(
                      value: stats.avgHours / 10, // Assuming 10 is max ideal sleep
                      backgroundColor: Colors.white.withOpacity(0.1),
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.blueAccent),
                      strokeWidth: 8,
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${stats.avgHours}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text('heures', style: TextStyle(color: Colors.white70, fontSize: 14)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStatPill('Score', '${stats.scoreAvg ?? '-'}'),
                  Container(height: 40, width: 1, color: Colors.white.withOpacity(0.2)),
                  _buildStatPill(
                    'Tendance',
                    stats.trend,
                    icon: trendIcon,
                    iconColor: trendColor,
                  ),
                ],
              ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, st) =>
          Text('Erreur: $err', style: const TextStyle(color: Colors.red)),
    );
  }

  Widget _buildStatPill(
    String label,
    String value, {
    IconData? icon,
    Color? iconColor,
  }) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: iconColor, size: 16),
              const SizedBox(width: 4),
            ],
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCurrentAlarmCard() {
    final alarmAsync = ref.watch(alarmProvider);
    return alarmAsync.when(
      data: (config) {
        if (config == null) return const SizedBox.shrink();
        return FrostedGlassCard(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.alarm_on, color: Colors.amberAccent, size: 32),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Alarme Actuelle', style: TextStyle(color: Colors.white70, fontSize: 14)),
                    const SizedBox(height: 4),
                    Text(
                      config.alarmTime,
                      style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              Switch(
                value: config.isActive,
                onChanged: (val) {
                  final newConfig = AlarmConfig(
                    id: config.id,
                    userId: config.userId,
                    alarmTime: config.alarmTime,
                    isActive: val,
                    wakeMode: config.wakeMode,
                    lightIntensity: config.lightIntensity,
                    soundEnabled: config.soundEnabled,
                  );
                  ref.read(alarmProvider.notifier).updateAlarm(newConfig);
                },
                activeColor: Colors.blueAccent,
              )
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildHistoryList(AsyncValue historyAsync) {
    return historyAsync.when(
      data: (records) {
        if (records == null || records.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                "Aucune donnée de sommeil.",
                style: TextStyle(color: Colors.white54),
              ),
            ),
          );
        }
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: records.length,
          itemBuilder: (context, index) {
            final record = records[index];
            final dateStr = DateFormat('dd MMM yyyy').format(record.sleepStart);
            final hoursStr = record.totalHours != null
                ? '${record.totalHours} h'
                : 'En cours...';

            return Card(
              color: Colors.white.withOpacity(0.05),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: ListTile(
                leading: const Icon(
                  Icons.nightlight_round,
                  color: Colors.blueAccent,
                ),
                title: Text(
                  dateStr,
                  style: const TextStyle(color: Colors.white),
                ),
                subtitle: Text(
                  hoursStr,
                  style: const TextStyle(color: Colors.white70),
                ),
                trailing: record.sleepScore != null
                    ? Chip(
                        label: Text('${record.sleepScore}'),
                        backgroundColor: _getScoreColor(record.sleepScore!),
                        labelStyle: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, st) =>
          Text('Erreur: $err', style: const TextStyle(color: Colors.red)),
    );
  }

  Color _getScoreColor(int score) {
    if (score >= 80) return Colors.greenAccent;
    if (score >= 60) return Colors.orangeAccent;
    return Colors.redAccent;
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes.toString().padLeft(2, '0')}m';
    }
    return '${duration.inMinutes}m';
  }

  Widget _buildConfigureAlarmButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: () => context.push(AppRoutes.sleepAlarm),
        icon: const Icon(Icons.alarm),
        label: const Text(
          'Configurer le Réveil Intelligent',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: Colors.blueAccent.withOpacity(0.8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}
