import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_focus/shared/widgets/index.dart';
import 'package:smart_focus/shared/widgets/starfield_painter.dart';
import 'package:smart_focus/features/auth/providers/auth_provider.dart';
import 'package:smart_focus/features/chatbot/providers/chat_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  int _selectedIndex = 5; // Index for settings in BottomNav

  double _focusGoal = 90;
  bool _focusAlerts = true;
  bool _sleepReminders = true;
  bool _darkMode = true;

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
        title: 'Paramètres',
        trailingIcon: Icons.settings,
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
                _buildProfileCard(),
                const SizedBox(height: 24),
                _buildSectionTitle('Objectifs'),
                const SizedBox(height: 8),
                _buildObjectivesCard(),
                const SizedBox(height: 24),
                _buildSectionTitle('Boîtier IoT'),
                const SizedBox(height: 8),
                _buildIoTCard(),
                const SizedBox(height: 24),
                _buildSectionTitle('Notifications'),
                const SizedBox(height: 8),
                _buildNotificationsCard(),
                const SizedBox(height: 24),
                _buildDarkModeToggle(),
                const SizedBox(height: 24),
                _buildDisconnectButton(),
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

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildProfileCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 30,
            backgroundColor: Colors.blueAccent,
            child: Icon(Icons.person, size: 36, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Kacem jemni',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'kacem@student.blalbla',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.white54),
        ],
      ),
    );
  }

  Widget _buildObjectivesCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🎯', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Focus quotidien',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Text(
                '${_focusGoal.toInt()}min',
                style: const TextStyle(
                  color: Colors.blueAccent,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Slider(
            value: _focusGoal,
            min: 30,
            max: 240,
            divisions: 21,
            activeColor: Colors.blueAccent,
            inactiveColor: Colors.white24,
            onChanged: (value) {
              setState(() {
                _focusGoal = value;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildIoTCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('📡', style: TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ESP32-CAM',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: const [
                    Icon(Icons.circle, color: Colors.greenAccent, size: 12),
                    SizedBox(width: 6),
                    Text(
                      'Connecté',
                      style: TextStyle(
                        color: Colors.greenAccent,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'FW v1.2.3',
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
      ),
      child: Column(
        children: [
          _buildSwitchRow(
            '🔔',
            'Alertes Focus',
            _focusAlerts,
            (value) => setState(() => _focusAlerts = value),
          ),
          Divider(color: Colors.white.withOpacity(0.1), height: 24),
          _buildSwitchRow(
            '😴',
            'Rappel Sommeil',
            _sleepReminders,
            (value) => setState(() => _sleepReminders = value),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchRow(
    String emoji,
    String title,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: Colors.blueAccent,
        ),
      ],
    );
  }

  Widget _buildDarkModeToggle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: const [
              Text('🌙', style: TextStyle(fontSize: 20)),
              SizedBox(width: 12),
              Text(
                'Thème Sombre',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          Switch(
            value: _darkMode,
            onChanged: (value) {
              setState(() {
                _darkMode = value;
              });
            },
            activeColor: Colors.blueAccent,
          ),
        ],
      ),
    );
  }

  Widget _buildDisconnectButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: TextButton.icon(
        onPressed: () async {
          // Clear cached chat history before logging out
          ref.invalidate(chatProvider);
          await ref.read(authProvider.notifier).logout();
          if (mounted) context.go('/');
        },
        icon: const Icon(Icons.exit_to_app),
        label: const Text(
          'Se déconnecter',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        style: TextButton.styleFrom(
          foregroundColor: Colors.redAccent,
          backgroundColor: Colors.redAccent.withOpacity(0.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: Colors.redAccent.withOpacity(0.3),
              width: 1,
            ),
          ),
        ),
      ),
    );
  }
}
