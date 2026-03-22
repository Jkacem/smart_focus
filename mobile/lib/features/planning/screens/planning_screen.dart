import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_focus/shared/widgets/index.dart';
import 'package:smart_focus/features/planning/widgets/mini_date_picker.dart';
import 'package:smart_focus/features/planning/widgets/planning_session_card.dart';

class PlanningScreen extends StatefulWidget {
  const PlanningScreen({Key? key}) : super(key: key);

  @override
  State<PlanningScreen> createState() => _PlanningScreenState();
}

class _PlanningScreenState extends State<PlanningScreen> {
  // Navigation handling matching HomePage
  int _selectedIndex = 1; // 1 for calendar icon

  void _onItemTapped(int index) {
    if (index == 0) {
      context.go('/dashboard');
    } else if (index == 2) {
      context.go('/chatbot');
    } else if (index == 3) {
      context.go('/statistics');
    } else if (index == 4) {
      context.go('/settings');
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  // Dummy list of sessions
  final List<Map<String, dynamic>> sessions = [
    {
      'time': '09:00',
      'title': '📚 Mathématiques',
      'duration': '80min',
      'progress': 0.8,
      'priorityLabel': 'Haute priorité',
      'priorityIcon': '✅',
    },
    {
      'time': '11:00',
      'title': '⚗️ Physique',
      'duration': '60min',
      'progress': 0.6,
      'priorityLabel': 'Moyenne priorité',
      'priorityIcon': '🔵',
    },
    {
      'time': '14:00',
      'title': '🧬 Chimie',
      'duration': '45min',
      'progress': 0.4,
      'priorityLabel': 'Normale priorité',
      'priorityIcon': '⬜',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      appBar: CustomAppBar(
        title: 'Mon Planning',
        trailingWidget: Container(
          height: 36,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: const LinearGradient(
              colors: [
                Color(0xFF8A2387),
                Color(0xFFE94057),
                Color(0xFFF27121),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFE94057).withOpacity(0.3),
                blurRadius: 8,
                spreadRadius: 1,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                // AI Action logic goes here
              },
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'IA',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(
                      Icons.auto_awesome,
                      color: Colors.white,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          // Background Gradient matching Home
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
          // Starfield Background
          SizedBox.expand(child: CustomPaint(painter: StarfieldPainter())),
          // Main Content
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 16),
                // Mini Calendar / DatePicker
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: const MiniDatePicker(),
                ),
                const SizedBox(height: 24),
                // "Aujourd'hui" Section Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Divider(
                          color: Colors.white.withOpacity(0.3),
                          thickness: 1,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12.0),
                        child: Text(
                          "Aujourd'hui",
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Divider(
                          color: Colors.white.withOpacity(0.3),
                          thickness: 1,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Sessions List View
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    itemCount:
                        sessions.length +
                        1, // +1 for the AI Button at the bottom
                    itemBuilder: (context, index) {
                      if (index < sessions.length) {
                        final session = sessions[index];
                        return PlanningSessionCard(
                          time: session['time'],
                          title: session['title'],
                          duration: session['duration'],
                          progress: session['progress'],
                          priorityLabel: session['priorityLabel'],
                          priorityIcon: session['priorityIcon'],
                          onDismissed: () {
                            setState(() {
                              sessions.removeAt(index);
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('${session['title']} supprimé'),
                                backgroundColor: Colors.redAccent,
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                        );
                      } else {
                        // FAB replacement at the bottom of the list
                        return Column(
                          children: [
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: TextButton.icon(
                                onPressed: () {
                                  // Logic to add a session
                                },
                                icon: const Icon(Icons.add),
                                label: const Text(
                                  'Ajouter une session',
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
                            ),
                            const SizedBox(
                              height: 100,
                            ), // Spacing for bottom nav bar
                          ],
                        );
                      }
                    },
                  ),
                ),
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
}
