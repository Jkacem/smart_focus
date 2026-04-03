import 'package:flutter/material.dart';

import 'package:smart_focus/shared/widgets/custom_app_bar.dart';
import 'package:smart_focus/shared/widgets/frosted_glass_card.dart';
import 'package:smart_focus/shared/widgets/starfield_painter.dart';

class SessionActiveScreen extends StatelessWidget {
  const SessionActiveScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
              onPressed: () {},
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
                children: const [
                  SizedBox(height: 12),
                  _SessionHeroCard(),
                  SizedBox(height: 18),
                  _SessionMetricsGrid(),
                  SizedBox(height: 18),
                  _SessionAlertsCard(),
                  SizedBox(height: 18),
                  _SessionActionsCard(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SessionHeroCard extends StatelessWidget {
  const _SessionHeroCard();

  @override
  Widget build(BuildContext context) {
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
                child: const Icon(
                  Icons.timer_outlined,
                  color: Color(0xFF97CAD8),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bloc de concentration en cours',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.94),
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Maths avancees - Rythme stable',
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
                  color: const Color(0xFF8BD3A8).withOpacity(0.18),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'Excellent',
                  style: TextStyle(
                    color: Color(0xFF8BD3A8),
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
                  '00:42:17',
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
          const SizedBox(height: 24),
          Row(
            children: const [
              Expanded(
                child: _SessionHeroStat(
                  label: 'Focus',
                  value: '87%',
                  accent: Color(0xFF97CAD8),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _SessionHeroStat(
                  label: 'Qualite',
                  value: 'Haute',
                  accent: Color(0xFF8BD3A8),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _SessionHeroStat(
                  label: 'Pause',
                  value: 'dans 18m',
                  accent: Color(0xFFFFC857),
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

class _SessionMetricsGrid extends StatelessWidget {
  const _SessionMetricsGrid();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        Row(
          children: [
            Expanded(
              child: _SessionMetricCard(
                title: 'Posture',
                value: '85',
                status: 'Bonne tenue',
                accent: Color(0xFF8BD3A8),
                icon: Icons.accessibility_new_rounded,
              ),
            ),
            SizedBox(width: 14),
            Expanded(
              child: _SessionMetricCard(
                title: 'Fatigue',
                value: 'Low',
                status: 'Charge stable',
                accent: Color(0xFF97CAD8),
                icon: Icons.battery_charging_full_rounded,
              ),
            ),
          ],
        ),
        SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _SessionMetricCard(
                title: 'Attention',
                value: '72',
                status: 'A surveiller',
                accent: Color(0xFFFFC857),
                icon: Icons.visibility_outlined,
              ),
            ),
            SizedBox(width: 14),
            Expanded(
              child: _SessionMetricCard(
                title: 'Hydratation',
                value: 'Ok',
                status: 'Rappel fait',
                accent: Color(0xFF97CAD8),
                icon: Icons.water_drop_outlined,
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

class _SessionAlertsCard extends StatelessWidget {
  const _SessionAlertsCard();

  @override
  Widget build(BuildContext context) {
    return FrostedGlassCard(
      borderRadius: 22,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Row(
            children: [
              Icon(Icons.notifications_active_outlined, color: Color(0xFFFFC857)),
              SizedBox(width: 10),
              Text(
                'Alertes recentes',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          SizedBox(height: 14),
          _SessionAlertRow(
            time: '12:34',
            title: 'Posture a corriger',
            subtitle: 'Epaules legerement fermees depuis 2 min.',
            accent: Color(0xFFFFC857),
          ),
          SizedBox(height: 12),
          _SessionAlertRow(
            time: '12:21',
            title: 'Pause bientot recommandee',
            subtitle: 'Bloc long detecte. Encore 18 min avant la pause ideale.',
            accent: Color(0xFF97CAD8),
          ),
        ],
      ),
    );
  }
}

class _SessionAlertRow extends StatelessWidget {
  final String time;
  final String title;
  final String subtitle;
  final Color accent;

  const _SessionAlertRow({
    required this.time,
    required this.title,
    required this.subtitle,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accent.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withOpacity(0.22)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: accent.withOpacity(0.16),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.info_outline_rounded, color: accent, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.68),
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            time,
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
