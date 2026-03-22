import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:smart_focus/core/router/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive for token storage
  await Hive.initFlutter();
  await Hive.openBox('auth');

  runApp(
    const ProviderScope(
      // ← Required by Riverpod
      child: KaranApp(),
    ),
  );
}

class KaranApp extends ConsumerWidget {
  const KaranApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goRouter = ref.watch(goRouterProvider);

    return MaterialApp.router(
      title: 'KARAN - Smart Focus Assistant',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      routerConfig: goRouter,
      debugShowCheckedModeBanner: false,
    );
  }
}
