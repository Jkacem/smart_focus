import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// Screens
import 'package:smart_focus/features/auth/screens/welcome_screen.dart';
import 'package:smart_focus/features/auth/screens/login_form.dart';
import 'package:smart_focus/features/auth/screens/sign_form.dart';
import 'package:smart_focus/features/auth/screens/login_screen.dart';
import 'package:smart_focus/features/dashboard/screens/home_page.dart';
import 'package:smart_focus/features/planning/screens/planning_screen.dart';
import 'package:smart_focus/features/chatbot/screens/chatbot_screen.dart';
import 'package:smart_focus/features/stats/screens/statistics_screen.dart';
import 'package:smart_focus/features/settings/screens/settings_screen.dart';
import 'package:smart_focus/features/dashboard/screens/session_active_screen.dart';

final goRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: true,
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: '/auth_options',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginFormScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const SignFormScreen(),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: '/planning',
        builder: (context, state) => const PlanningScreen(),
      ),
      GoRoute(
        path: '/chatbot',
        builder: (context, state) => const ChatbotScreen(),
      ),
      GoRoute(
        path: '/statistics',
        builder: (context, state) => const StatisticsScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/session',
        builder: (context, state) => const SessionActiveScreen(),
      ),
    ],
  );
});
