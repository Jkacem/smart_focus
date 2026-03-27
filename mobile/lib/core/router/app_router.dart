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

// Quiz & Flashcards
import 'package:smart_focus/features/quiz/models/quiz_models.dart';
import 'package:smart_focus/features/quiz/screens/quiz_generate_screen.dart';
import 'package:smart_focus/features/quiz/screens/quiz_play_screen.dart';
import 'package:smart_focus/features/quiz/screens/quiz_result_screen.dart';
import 'package:smart_focus/features/flashcards/screens/flashcard_generate_screen.dart';
import 'package:smart_focus/features/flashcards/screens/flashcard_deck_screen.dart';
import 'package:smart_focus/features/flashcards/screens/flashcard_review_screen.dart';

// Sleep
import 'package:smart_focus/features/sleep/screens/sleep_dashboard_screen.dart';
import 'package:smart_focus/features/sleep/screens/alarm_settings_screen.dart';
import 'package:smart_focus/features/sleep/screens/alarm_ring_screen.dart';
import 'package:alarm/alarm.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();

final goRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
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

      // ===== QUIZ ROUTES =====
      GoRoute(
        path: '/quiz/generate/:docId',
        builder: (context, state) {
          final docId = int.parse(state.pathParameters['docId']!);
          final title = state.uri.queryParameters['title'] ?? 'Document';
          return QuizGenerateScreen(documentId: docId, documentTitle: title);
        },
      ),
      GoRoute(
        path: '/quiz/play/:quizId',
        builder: (context, state) {
          final quizId = int.parse(state.pathParameters['quizId']!);
          return QuizPlayScreen(quizId: quizId);
        },
      ),
      GoRoute(
        path: '/quiz/result/:quizId',
        builder: (context, state) {
          final quizId = int.parse(state.pathParameters['quizId']!);
          final result = state.extra as QuizResultModel;
          return QuizResultScreen(quizId: quizId, result: result);
        },
      ),

      // ===== FLASHCARD ROUTES =====
      GoRoute(
        path: '/flashcards/generate/:docId',
        builder: (context, state) {
          final docId = int.parse(state.pathParameters['docId']!);
          final title = state.uri.queryParameters['title'] ?? 'Document';
          return FlashcardGenerateScreen(documentId: docId, documentTitle: title);
        },
      ),
      GoRoute(
        path: '/flashcards/deck/:docId',
        builder: (context, state) {
          final docId = int.parse(state.pathParameters['docId']!);
          return FlashcardDeckScreen(documentId: docId);
        },
      ),
      GoRoute(
        path: '/flashcards/review',
        builder: (context, state) {
          final docIdStr = state.uri.queryParameters['documentId'];
          final docId = docIdStr != null ? int.tryParse(docIdStr) : null;
          return FlashcardReviewScreen(documentId: docId);
        },
      ),

      // ===== SLEEP ROUTES =====
      GoRoute(
        path: '/sleep',
        builder: (context, state) => const SleepDashboardScreen(),
      ),
      GoRoute(
        path: '/sleep/alarm',
        builder: (context, state) => const AlarmSettingsScreen(),
      ),
      GoRoute(
        path: '/alarm-ring',
        builder: (context, state) {
          final alarmSettings = state.extra as AlarmSettings;
          return AlarmRingScreen(alarmSettings: alarmSettings);
        },
      ),
    ],
  );
});
