import 'package:alarm/alarm.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'app_routes.dart';
import 'app_transitions.dart';
import 'router_notifier.dart';
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
  final notifier = ref.watch(routerNotifierProvider);
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: AppRoutes.welcome,
    debugLogDiagnostics: kDebugMode,
    refreshListenable: notifier,
    redirect: notifier.redirect,
    routes: [
      GoRoute(
        path: AppRoutes.welcome,
        pageBuilder: (context, state) => AppTransitions.page(
          state: state,
          child: const WelcomeScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.authOptions,
        pageBuilder: (context, state) => AppTransitions.page(
          state: state,
          child: const LoginScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.login,
        pageBuilder: (context, state) => AppTransitions.page(
          state: state,
          child: const LoginFormScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.register,
        pageBuilder: (context, state) => AppTransitions.page(
          state: state,
          child: const SignFormScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.dashboard,
        pageBuilder: (context, state) => AppTransitions.page(
          state: state,
          child: const HomePage(),
        ),
      ),
      GoRoute(
        path: AppRoutes.planning,
        pageBuilder: (context, state) => AppTransitions.page(
          state: state,
          child: const PlanningScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.chatbot,
        pageBuilder: (context, state) => AppTransitions.page(
          state: state,
          child: const ChatbotScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.statistics,
        pageBuilder: (context, state) => AppTransitions.page(
          state: state,
          child: const StatisticsScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.settings,
        pageBuilder: (context, state) => AppTransitions.page(
          state: state,
          child: const SettingsScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.session,
        pageBuilder: (context, state) => AppTransitions.page(
          state: state,
          child: const SessionActiveScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.quizGenerateMultiPattern,
        pageBuilder: (context, state) {
          final title = state.uri.queryParameters['title'] ?? 'Documents';
          final rawDocIds = state.uri.queryParameters['docIds'] ?? '';
          final documentIds = rawDocIds
              .split(',')
              .where((item) => item.isNotEmpty)
              .map(int.parse)
              .toList();

          return AppTransitions.page(
            state: state,
            child: QuizGenerateScreen(
              documentIds: documentIds,
              documentTitle: title,
            ),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.quizGenerateDocumentPattern,
        pageBuilder: (context, state) {
          final docId = int.parse(state.pathParameters['docId']!);
          final title = state.uri.queryParameters['title'] ?? 'Document';

          return AppTransitions.page(
            state: state,
            child: QuizGenerateScreen(documentId: docId, documentTitle: title),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.quizGenerateSessionPattern,
        pageBuilder: (context, state) {
          final sessionId = int.parse(state.pathParameters['sessionId']!);
          final title = state.uri.queryParameters['title'] ?? 'Session';

          return AppTransitions.page(
            state: state,
            child: QuizGenerateScreen(sessionId: sessionId, documentTitle: title),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.quizPlayPattern,
        pageBuilder: (context, state) {
          final quizId = int.parse(state.pathParameters['quizId']!);

          return AppTransitions.page(
            state: state,
            child: QuizPlayScreen(quizId: quizId),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.quizResultPattern,
        pageBuilder: (context, state) {
          final quizId = int.parse(state.pathParameters['quizId']!);

          return AppTransitions.page(
            state: state,
            child: QuizResultScreen(quizId: quizId),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.flashcardsGenerateDocumentPattern,
        pageBuilder: (context, state) {
          final docId = int.parse(state.pathParameters['docId']!);
          final title = state.uri.queryParameters['title'] ?? 'Document';

          return AppTransitions.page(
            state: state,
            child: FlashcardGenerateScreen(documentId: docId, documentTitle: title),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.flashcardsGenerateSessionPattern,
        pageBuilder: (context, state) {
          final sessionId = int.parse(state.pathParameters['sessionId']!);
          final title = state.uri.queryParameters['title'] ?? 'Session';

          return AppTransitions.page(
            state: state,
            child: FlashcardGenerateScreen(
              sessionId: sessionId,
              documentTitle: title,
            ),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.flashcardsDeckDocumentPattern,
        pageBuilder: (context, state) {
          final docId = int.parse(state.pathParameters['docId']!);

          return AppTransitions.page(
            state: state,
            child: FlashcardDeckScreen(documentId: docId),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.flashcardsDeckSessionPattern,
        pageBuilder: (context, state) {
          final sessionId = int.parse(state.pathParameters['sessionId']!);

          return AppTransitions.page(
            state: state,
            child: FlashcardDeckScreen(sessionId: sessionId),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.flashcardsReviewPattern,
        pageBuilder: (context, state) {
          final docIdStr = state.uri.queryParameters['documentId'];
          final docId = docIdStr != null ? int.tryParse(docIdStr) : null;
          final sessionIdStr = state.uri.queryParameters['sessionId'];
          final sessionId = sessionIdStr != null ? int.tryParse(sessionIdStr) : null;

          return AppTransitions.page(
            state: state,
            child: FlashcardReviewScreen(documentId: docId, sessionId: sessionId),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.sleep,
        pageBuilder: (context, state) => AppTransitions.page(
          state: state,
          child: const SleepDashboardScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.sleepAlarm,
        pageBuilder: (context, state) => AppTransitions.page(
          state: state,
          child: const AlarmSettingsScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.alarmRing,
        pageBuilder: (context, state) {
          final alarmSettings = state.extra as AlarmSettings;

          return AppTransitions.page(
            state: state,
            child: AlarmRingScreen(alarmSettings: alarmSettings),
          );
        },
      ),
    ],
  );
});
