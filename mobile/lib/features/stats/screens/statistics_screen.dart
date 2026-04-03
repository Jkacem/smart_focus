import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_focus/core/router/app_routes.dart';
import 'package:smart_focus/features/planning/providers/planning_provider.dart';
import 'package:smart_focus/shared/widgets/index.dart';
import 'package:smart_focus/shared/widgets/starfield_painter.dart';

import '../widgets/focus_chart_card.dart';
import '../widgets/general_score_card.dart';
import '../widgets/planning_insights_card.dart';
import '../widgets/sleep_chart_card.dart';

class StatisticsScreen extends ConsumerStatefulWidget {
  const StatisticsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends ConsumerState<StatisticsScreen> {
  int _selectedIndex = 3;
  String _selectedPeriod = 'week';

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
    final insightsAsync = ref.watch(planningInsightsProvider(_selectedPeriod));

    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      appBar: const CustomAppBar(
        title: 'Statistiques',
        trailingIcon: Icons.date_range,
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
              color: Colors.black,
              onRefresh: () async {
                ref.invalidate(planningInsightsProvider(_selectedPeriod));
                await ref.read(planningInsightsProvider(_selectedPeriod).future);
              },
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                children: [
                  const SizedBox(height: 16),
                  _buildPeriodFilter(),
                  const SizedBox(height: 24),
                  insightsAsync.when(
                    loading: () => _buildInsightsLoadingCard(),
                    error: (error, stackTrace) => _buildInsightsErrorCard(error),
                    data: (insights) => PlanningInsightsCard(insights: insights),
                  ),
                  const SizedBox(height: 24),
                  const GeneralScoreCard(),
                  const SizedBox(height: 24),
                  const FocusChartCard(),
                  const SizedBox(height: 24),
                  const SleepChartCard(),
                  const SizedBox(height: 24),
                  _buildOpenPlanningButton(),
                  const SizedBox(height: 100),
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

  Widget _buildPeriodFilter() {
    const periods = {
      'week': 'Semaine',
      'month': 'Mois',
    };

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: periods.entries.map((entry) {
        final isSelected = _selectedPeriod == entry.key;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                setState(() {
                  _selectedPeriod = entry.key;
                });
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF97cad8)
                      : Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  entry.value,
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

  Widget _buildInsightsLoadingCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: const Center(
        child: CircularProgressIndicator(color: Color(0xFF97cad8)),
      ),
    );
  }

  Widget _buildInsightsErrorCard(Object error) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFB7185).withOpacity(0.08),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFFB7185).withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Insights indisponibles',
            style: TextStyle(
              color: Color(0xFFFB7185),
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error.toString().replaceFirst('Exception: ', ''),
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 14,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: () {
              ref.invalidate(planningInsightsProvider(_selectedPeriod));
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Reessayer'),
            style: TextButton.styleFrom(foregroundColor: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildOpenPlanningButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: TextButton.icon(
        onPressed: () {
          context.go(AppRoutes.planning);
        },
        icon: const Icon(Icons.calendar_month_outlined),
        label: const Text(
          'Ouvrir le planning',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: TextButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: Colors.white.withOpacity(0.15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: Colors.white.withOpacity(0.3),
              width: 1,
            ),
          ),
        ),
      ),
    );
  }
}
