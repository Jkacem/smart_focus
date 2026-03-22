import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:smart_focus/shared/widgets/frosted_glass_card.dart';
import 'package:smart_focus/shared/widgets/starfield_painter.dart';

class SessionActiveScreen extends StatelessWidget {
  const SessionActiveScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Session Active',
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'SF Pro',
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.pause, color: Colors.amber),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.stop, color: Colors.redAccent),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          // Background Gradient base
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0a1628), // Deep blue-black
                  Color(0xFF1a3a4a), // Deep teal
                  Color(0xFF0d2635), // Dark teal
                ],
              ),
            ),
          ),

          // Starfield Layer
          _buildStarfield(),

          // Main Content Layer
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 20,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 10),

                  // Timer (⏱ 00:42:17)
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.timer_outlined,
                          color: Colors.white70,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          '00:42:17',
                          style: TextStyle(
                            fontFamily: 'SF Pro Black',
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2.0,
                            fontSize: 48,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Score Focus Frosted Glass Card
                  _buildFrostedContainer(
                    child: Column(
                      children: [
                        const Text(
                          'SCORE FOCUS',
                          style: TextStyle(
                            fontFamily: 'SF Pro',
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.5,
                            fontSize: 14,
                            color: Color(0xFF97CAD8), // Theme cyan
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Fake progress dots (●●●●●●●●○○)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(10, (index) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4.0,
                              ),
                              child: Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: index < 8
                                      ? const Color(0xFF6C63FF) // Theme Purple
                                      : Colors.white.withOpacity(0.15),
                                ),
                              ),
                            );
                          }),
                        ),
                        const SizedBox(height: 16),

                        // Large Percentage
                        const Text(
                          '87%',
                          style: TextStyle(
                            fontFamily: 'SF Pro Black',
                            fontWeight: FontWeight.w900,
                            fontSize: 56,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Context Badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF4CAF50,
                            ).withOpacity(0.2), // Success green translucent
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xFF4CAF50).withOpacity(0.5),
                            ),
                          ),
                          child: const Text(
                            '🤩 Excellent !',
                            style: TextStyle(
                              fontFamily: 'SF Pro',
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: Color(0xFF4CAF50),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Metric Mini-cards (Grid/Row)
                  Row(
                    children: [
                      Expanded(child: _buildMetricCard('Posture', '🟢 85')),
                      const SizedBox(width: 16),
                      Expanded(child: _buildMetricCard('Fatigue', '🟢 Low')),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _buildMetricCard('Attention', '🟡 72')),
                      const SizedBox(width: 16),
                      const Spacer(), // Empty space to match the shape provided
                    ],
                  ),

                  const SizedBox(height: 40),

                  // Recent Alerts Header
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Divider(color: Colors.white30, endIndent: 12),
                      ),
                      Text(
                        'Alertes Récentes',
                        style: TextStyle(
                          fontFamily: 'SF Pro',
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: Colors.white70,
                          letterSpacing: 1.0,
                        ),
                      ),
                      Expanded(
                        child: Divider(color: Colors.white30, indent: 12),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // ListView Alerts
                  _buildFrostedContainer(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      children: [
                        _buildAlertTile(
                          '12:34',
                          'Posture corriger',
                          icon: '⚠️',
                        ),
                        Divider(
                          color: Colors.white.withOpacity(0.1),
                          height: 1,
                        ),
                        _buildAlertTile(
                          '12:21',
                          '30min sans pause',
                          icon: '⚠️',
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Pause Suggestion Button
                  SizedBox(
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Text('🧘', style: TextStyle(fontSize: 20)),
                      label: const Text(
                        'Prendre une pause',
                        style: TextStyle(
                          fontFamily: 'SF Pro Black',
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(
                          0xFF6C63FF,
                        ), // Primary Purple
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // A generic frosted glass container builder
  Widget _buildFrostedContainer({
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(24),
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withOpacity(0.15),
              width: 1.5,
            ),
          ),
          child: child,
        ),
      ),
    );
  }

  // Mini-metric card builder
  Widget _buildMetricCard(String title, String value) {
    return FrostedGlassCard(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'SF Pro',
              fontWeight: FontWeight.w500,
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'SF Pro Black',
              fontWeight: FontWeight.w800,
              fontSize: 18,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // Alert tile builder
  Widget _buildAlertTile(String time, String message, {required String icon}) {
    return ListTile(
      leading: Text(icon, style: const TextStyle(fontSize: 20)),
      title: Row(
        children: [
          Text(
            time,
            style: const TextStyle(
              fontFamily: 'SF Pro',
              fontWeight: FontWeight.w700,
              color: Color(0xFF97CAD8), // Cyan theme
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            message,
            style: const TextStyle(
              fontFamily: 'SF Pro',
              fontWeight: FontWeight.w500,
              color: Colors.white,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStarfield() {
    return SizedBox.expand(child: CustomPaint(painter: StarfieldPainter()));
  }
}
