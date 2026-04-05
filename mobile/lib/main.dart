import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:smart_focus/core/router/app_router.dart';
import 'package:alarm/alarm.dart';
import 'package:smart_focus/features/sleep/screens/alarm_ring_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize local alarm service
  await Alarm.init();

  // Initialize Hive for token storage
  await Hive.initFlutter();
  await Hive.openBox('auth');

  runApp(const ProviderScope(child: KaranApp()));
}

class KaranApp extends ConsumerStatefulWidget {
  const KaranApp({Key? key}) : super(key: key);

  @override
  ConsumerState<KaranApp> createState() => _KaranAppState();
}

class _KaranAppState extends ConsumerState<KaranApp> {
  StreamSubscription<AlarmSettings>? _ringSubscription;

  @override
  void initState() {
    super.initState();
    _ringSubscription = Alarm.ringStream.stream.listen((alarmSettings) {
      // When the alarm fires, push the ring screen via the root navigator
      rootNavigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (_) => AlarmRingScreen(alarmSettings: alarmSettings),
        ),
      );
    });
  }

  @override
  void dispose() {
    _ringSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final goRouter = ref.watch(goRouterProvider);

    return MaterialApp.router(
      title: 'KARAN - Smart Focus Assistant',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      routerConfig: goRouter,
      debugShowCheckedModeBanner: false,
    );
  }
}
