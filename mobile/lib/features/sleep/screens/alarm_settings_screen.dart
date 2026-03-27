// lib/features/sleep/screens/alarm_settings_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/widgets/index.dart';
import '../../../shared/widgets/starfield_painter.dart';
import '../models/sleep_models.dart';
import '../providers/sleep_provider.dart';
import 'package:alarm/alarm.dart';

class AlarmSettingsScreen extends ConsumerStatefulWidget {
  const AlarmSettingsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<AlarmSettingsScreen> createState() => _AlarmSettingsScreenState();
}

class _AlarmSettingsScreenState extends ConsumerState<AlarmSettingsScreen> {
  TimeOfDay _selectedTime = const TimeOfDay(hour: 7, minute: 0);
  String _wakeMode = 'gradual';
  double _lightIntensity = 50;
  bool _soundEnabled = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final alarmAsync = ref.read(alarmProvider);
      if (alarmAsync is AsyncData && alarmAsync.value != null) {
        final config = alarmAsync.value!;
        final parts = config.alarmTime.split(':');
        setState(() {
          _selectedTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
          _wakeMode = config.wakeMode;
          _lightIntensity = config.lightIntensity.toDouble();
          _soundEnabled = config.soundEnabled;
        });
      }
    });
  }

  Future<void> _pickTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _saveAlarm() async {
    final String timeStr = '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}';
    
    final config = AlarmConfig(
      id: 0, // Ignored on PUT
      userId: 0, // Ignored on PUT
      alarmTime: timeStr,
      isActive: true,
      wakeMode: _wakeMode,
      lightIntensity: _lightIntensity.toInt(),
      soundEnabled: _soundEnabled,
    );

    try {
      await ref.read(alarmProvider.notifier).updateAlarm(config);
      
      // Schedule the local phone alarm
      final now = DateTime.now();
      var alarmDateTime = DateTime(
        now.year,
        now.month,
        now.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );
      if (alarmDateTime.isBefore(now)) {
        alarmDateTime = alarmDateTime.add(const Duration(days: 1));
      }

      final alarmSettings = AlarmSettings(
        id: 42,
        dateTime: alarmDateTime,
        assetAudioPath: 'assets/audio/alarm.wav',
        loopAudio: true,
        vibrate: true,
        volumeSettings: VolumeSettings.fade(
          volume: _soundEnabled ? 1.0 : 0.0,
          fadeDuration: const Duration(seconds: 3),
        ),
        notificationSettings: const NotificationSettings(
          title: 'SmartFocus Réveil',
          body: 'Il est temps de se réveiller!',
        ),
        warningNotificationOnKill: true,
      );
      
      await Alarm.set(alarmSettings: alarmSettings);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Réveil programmé avec succès!', style: TextStyle(color: Colors.white)), backgroundColor: Colors.green),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e', style: const TextStyle(color: Colors.white)), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const CustomAppBar(
        title: 'Réveil',
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
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  FrostedGlassCard(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Heure du Réveil',
                          style: TextStyle(color: Colors.white70, fontSize: 16),
                        ),
                        const SizedBox(height: 16),
                        Center(
                          child: InkWell(
                            onTap: _pickTime,
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                              decoration: BoxDecoration(
                                color: Colors.blueAccent.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(color: Colors.blueAccent.withOpacity(0.5)),
                                boxShadow: [BoxShadow(color: Colors.blueAccent.withOpacity(0.2), blurRadius: 10)],
                              ),
                              child: Text(
                                _selectedTime.format(context),
                                style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        const Text('Mode de réveil', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: SegmentedButton<String>(
                            segments: const [
                              ButtonSegment(value: 'gradual', label: Text('Graduel', style: TextStyle(fontSize: 13))),
                              ButtonSegment(value: 'normal', label: Text('Normal', style: TextStyle(fontSize: 13))),
                              ButtonSegment(value: 'silent', label: Text('Silencieux', style: TextStyle(fontSize: 13))),
                            ],
                            selected: {_wakeMode},
                            onSelectionChanged: (Set<String> newSelection) {
                              setState(() {
                                _wakeMode = newSelection.first;
                              });
                            },
                            style: ButtonStyle(
                              backgroundColor: WidgetStateProperty.resolveWith<Color>((Set<WidgetState> states) {
                                return states.contains(WidgetState.selected) ? Colors.blueAccent : Colors.white.withOpacity(0.05);
                              }),
                              foregroundColor: WidgetStateProperty.all(Colors.white),
                              side: WidgetStateProperty.all(BorderSide(color: Colors.white.withOpacity(0.2))),
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        const Text('Intensité lumineuse', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: Colors.amberAccent,
                            inactiveTrackColor: Colors.white.withOpacity(0.2),
                            thumbColor: Colors.amberAccent,
                            overlayColor: Colors.amberAccent.withOpacity(0.2),
                          ),
                          child: Slider(
                            value: _lightIntensity,
                            min: 0,
                            max: 100,
                            divisions: 10,
                            label: '${_lightIntensity.round()}%',
                            onChanged: (double value) {
                              setState(() {
                                _lightIntensity = value;
                              });
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white.withOpacity(0.1)),
                          ),
                          child: SwitchListTile(
                            title: const Text('Activer le son', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                            activeColor: Colors.blueAccent,
                            value: _soundEnabled,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            onChanged: (bool value) {
                              setState(() {
                                _soundEnabled = value;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _saveAlarm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 8,
                        shadowColor: Colors.blueAccent.withOpacity(0.5),
                      ),
                      child: const Text('Enregistrer le Réveil', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
