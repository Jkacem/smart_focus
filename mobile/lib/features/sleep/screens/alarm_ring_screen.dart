import 'package:flutter/material.dart';
import 'package:alarm/alarm.dart';

class AlarmRingScreen extends StatelessWidget {
  final AlarmSettings alarmSettings;

  const AlarmRingScreen({Key? key, required this.alarmSettings})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0a1628),
              Color(0xFF1a3a4a),
              Color(0xFF0d2635),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Pulsing alarm icon
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.8, end: 1.2),
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeInOut,
                builder: (context, scale, child) {
                  return Transform.scale(scale: scale, child: child);
                },
                onEnd: () {},
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.blueAccent.withOpacity(0.2),
                    border: Border.all(
                      color: Colors.blueAccent.withOpacity(0.5),
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blueAccent.withOpacity(0.3),
                        blurRadius: 30,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.alarm,
                    size: 60,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 40),
              const Text(
                '⏰ Réveil !',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Il est temps de se réveiller !',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 60),
              // Stop alarm button
              GestureDetector(
                onTap: () async {
                  await Alarm.stop(alarmSettings.id);
                  if (context.mounted) {
                    Navigator.of(context).pop();
                  }
                },
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFFFF6B6B),
                        Color(0xFFEE5A24),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.redAccent.withOpacity(0.4),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.alarm_off,
                        size: 60,
                        color: Colors.white,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'ARRÊTER',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),
              // Snooze button
              TextButton.icon(
                onPressed: () async {
                  final now = DateTime.now();
                  final snoozeTime = now.add(const Duration(minutes: 5));
                  final snoozeSettings = alarmSettings.copyWith(
                    dateTime: snoozeTime,
                  );
                  await Alarm.stop(alarmSettings.id);
                  await Alarm.set(alarmSettings: snoozeSettings);
                  if (context.mounted) {
                    Navigator.of(context).pop();
                  }
                },
                icon: const Icon(Icons.snooze, color: Colors.white70),
                label: const Text(
                  'Répéter dans 5 min',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
