import 'package:alarm/alarm.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'app_routes.dart';
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
import 'package:smart_focus/features/quiz/models/quiz_models.dart';
import 'package:smart_focus/features/quiz/screens/quiz_generate_screen.dart';
import 'package:smart_focus/features/quiz/screens/quiz_play_screen.dart';
import 'package:smart_focus/features/quiz/screens/quiz_result_screen.dart';
import 'package:smart_focus/features/flashcards/screens/flashcard_generate_screen.dart';
import 'package:smart_focus/features/flashcards/screens/flashcard_deck_screen.dart';
import 'package:smart_focus/features/flashcards/screens/flashcard_review_screen.dart';
import 'package:smart_focus/features/sleep/screens/sleep_dashboard_screen.dart';
import 'package:smart_focus/features/sleep/screens/alarm_settings_screen.dart';
import 'package:smart_focus/features/sleep/screens/alarm_ring_screen.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();

final goRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: AppRoutes.welcome,
    debugLogDiagnostics: true,
    routes: [
      GoRoute(
        path: AppRoutes.welcome,
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.authOptions,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginFormScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const SignFormScreen(),
      ),
      GoRoute(
        path: AppRoutes.dashboard,
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: AppRoutes.planning,
        builder: (context, state) => const PlanningScreen(),
      ),
      GoRoute(
        path: AppRoutes.chatbot,
        builder: (context, state) => const ChatbotScreen(),
      ),
      GoRoute(
        path: AppRoutes.statistics,
        builder: (context, state) => const StatisticsScreen(),
      ),
      GoRoute(
        path: AppRoutes.settings,
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.session,
        builder: (context, state) => const SessionActiveScreen(),
      ),
      GoRoute(
        path: AppRoutes.quizGenerateMultiPattern,
        builder: (context, state) {
          final title = state.uri.queryParameters['title'] ?? 'Documents';
          final rawDocIds = state.uri.queryParameters['docIds'] ?? '';
          final documentIds = rawDocIds
              .split(',')
              .where((item) => item.isNotEmpty)
              .map(int.parse)
              .toList();
          return QuizGenerateScreen(
            documentIds: documentIds,
            documentTitle: title,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.quizGenerateDocumentPattern,
        builder: (context, state) {
          final docId = int.parse(state.pathParameters['docId']!);
          final title = state.uri.queryParameters['title'] ?? 'Document';
          return QuizGenerateScreen(documentId: docId, documentTitle: title);
        },
      ),
      GoRoute(
        path: AppRoutes.quizGenerateSessionPattern,
        builder: (context, state) {
          final sessionId = int.parse(state.pathParameters['sessionId']!);
          final title = state.uri.queryParameters['title'] ?? 'Session';
          return QuizGenerateScreen(sessionId: sessionId, documentTitle: title);
        },
      ),
      GoRoute(
        path: AppRoutes.quizPlayPattern,
        builder: (context, state) {
          final quizId = int.parse(state.pathParameters['quizId']!);
          return QuizPlayScreen(quizId: quizId);
        },
      ),
      GoRoute(
        path: AppRoutes.quizResultPattern,
        builder: (context, state) {
          final quizId = int.parse(state.pathParameters['quizId']!);
          final result = state.extra as QuizResultModel;
          return QuizResultScreen(quizId: quizId, result: result);
        },
      ),
      GoRoute(
        path: AppRoutes.flashcardsGenerateDocumentPattern,
        builder: (context, state) {
          final docId = int.parse(state.pathParameters['docId']!);
          final title = state.uri.queryParameters['title'] ?? 'Document';
          return FlashcardGenerateScreen(documentId: docId, documentTitle: title);
        },
      ),
      GoRoute(
        path: AppRoutes.flashcardsGenerateSessionPattern,
        builder: (context, state) {
          final sessionId = int.parse(state.pathParameters['sessionId']!);
          final title = state.uri.queryParameters['title'] ?? 'Session';
          return FlashcardGenerateScreen(
            sessionId: sessionId,
            documentTitle: title,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.flashcardsDeckDocumentPattern,
        builder: (context, state) {
          final docId = int.parse(state.pathParameters['docId']!);
          return FlashcardDeckScreen(documentId: docId);
        },
      ),
      GoRoute(
        path: AppRoutes.flashcardsDeckSessionPattern,
        builder: (context, state) {
          final sessionId = int.parse(state.pathParameters['sessionId']!);
          return FlashcardDeckScreen(sessionId: sessionId);
        },
      ),
      GoRoute(
        path: AppRoutes.flashcardsReviewPattern,
        builder: (context, state) {
          final docIdStr = state.uri.queryParameters['documentId'];
          final docId = docIdStr != null ? int.tryParse(docIdStr) : null;
          final sessionIdStr = state.uri.queryParameters['sessionId'];
          final sessionId = sessionIdStr != null ? int.tryParse(sessionIdStr) : null;
          return FlashcardReviewScreen(documentId: docId, sessionId: sessionId);
        },
      ),
      GoRoute(
        path: AppRoutes.sleep,
        builder: (context, state) => const SleepDashboardScreen(),
      ),
      GoRoute(
        path: AppRoutes.sleepAlarm,
        builder: (context, state) => const AlarmSettingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.alarmRing,
        builder: (context, state) {
          final alarmSettings = state.extra as AlarmSettings;
          return AlarmRingScreen(alarmSettings: alarmSettings);
        },
      ),
    ],
  );
});
