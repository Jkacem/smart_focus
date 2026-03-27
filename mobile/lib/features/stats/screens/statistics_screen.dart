import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_focus/shared/widgets/index.dart';
import 'package:smart_focus/shared/widgets/starfield_painter.dart';
import '../widgets/general_score_card.dart';
import '../widgets/focus_chart_card.dart';
import '../widgets/sleep_chart_card.dart';
import '../widgets/recommendation_card.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({Key? key}) : super(key: key);

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  int _selectedIndex = 3; // Index for stats in BottomNav
  String _selectedPeriod = 'Semaine';

  void _onItemTapped(int index) {
    if (index == 0) {
      context.go('/dashboard');
    } else if (index == 1) {
      context.go('/planning');
    } else if (index == 2) {
      context.go('/chatbot');
    } else if (index == 3) {
      context.go('/statistics');
    } else if (index == 4) {
      context.go('/sleep');
    } else if (index == 5) {
      context.go('/settings');
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      appBar: CustomAppBar(
        title: 'Statistiques 📅',
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
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              children: [
                const SizedBox(height: 16),
                _buildPeriodFilter(),
                const SizedBox(height: 24),
                const GeneralScoreCard(),
                const SizedBox(height: 24),
                const FocusChartCard(),
                const SizedBox(height: 24),
                const SleepChartCard(),
                const SizedBox(height: 24),
                const RecommendationCard(),
                const SizedBox(height: 24),
                _buildDownloadReportButton(),
                const SizedBox(height: 100), // Nav Bar padding
              ],
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: ['Semaine', 'Mois', 'Année'].map((period) {
        final isSelected = _selectedPeriod == period;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                setState(() {
                  _selectedPeriod = period;
                });
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.blueAccent
                      : Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  period,
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

  Widget _buildDownloadReportButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: TextButton.icon(
        onPressed: () {
          // Action for downloading report
        },
        icon: const Icon(Icons.picture_as_pdf),
        label: const Text(
          'Télécharger PDF Rapport',
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
