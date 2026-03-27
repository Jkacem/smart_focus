import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_focus/shared/widgets/starfield_painter.dart';

// feature-specific widgets

import 'package:smart_focus/shared/widgets/index.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

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
      appBar: const CustomAppBar(
        title: 'Bonjour, Kacem 👋',
        trailingIcon: Icons.add_a_photo,
      ),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF0a1628),
                  const Color(0xFF1a3a4a),
                  const Color(0xFF0d2635),
                ],
              ),
            ),
          ),
          _buildStarfield(),
          SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 20),
                  Text(
                    'Dimanche 01 Mars 2026',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  SizedBox(height: 20),
                  // Score du Jour Card
                  FrostedGlassCard(
                    borderRadius: 16,
                    padding: EdgeInsets.zero,
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Icon(Icons.adjust, color: Colors.white),
                              SizedBox(width: 8),
                              Text(
                                'Score du Jour',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 16),
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              SizedBox(
                                width: 100,
                                height: 100,
                                child: CircularProgressIndicator(
                                  value: 0.78,
                                  backgroundColor: Colors.white.withOpacity(
                                    0.2,
                                  ),
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.green,
                                  ),
                                  strokeWidth: 8,
                                ),
                              ),
                              Text(
                                '78 / 100',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Column(
                                children: [
                                  Text(
                                    'Focus',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    '🟢 85%',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                children: [
                                  Text(
                                    'Posture',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    '🟡 72%',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  // Row of cards: Sommeil and Pause
                  Row(
                    children: [
                      Expanded(
                        child: FrostedGlassCard(
                          borderRadius: 12,
                          padding: EdgeInsets.zero,
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Column(
                              children: [
                                Text(
                                  '😴 Sommeil',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  '7h30',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  'Score 82',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: FrostedGlassCard(
                          borderRadius: 12,
                          padding: EdgeInsets.zero,
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Column(
                              children: [
                                Text(
                                  '🧘 Pause',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  '3 faites',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  'auj.',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  // Planning Card
                  FrostedGlassCard(
                    borderRadius: 16,
                    padding: EdgeInsets.zero,
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Icon(Icons.calendar_today, color: Colors.white),
                              SizedBox(width: 8),
                              Text(
                                'Planning Auj.',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 16),
                          _buildPlanningItem('✅ Mathématiques', '9h'),
                          _buildPlanningItem('🔵 Physique', '11h'),
                          _buildPlanningItem('⬜ Chimie', '14h'),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 80), // Space for FAB
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          context.push('/session');
        },
        label: Text(
          '🎯 Démarrer Session',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white.withOpacity(0.15),
        foregroundColor: Colors.white,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      bottomNavigationBar: CustomBottomNavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }

  Widget _buildPlanningItem(String subject, String time) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(subject, style: TextStyle(color: Colors.white, fontSize: 16)),
          Text(time, style: TextStyle(color: Colors.white, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildStarfield() {
    return SizedBox.expand(child: CustomPaint(painter: StarfieldPainter()));
  }
}
