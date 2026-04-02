import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../models/quiz_models.dart';
import '../services/quiz_service.dart';

final quizServiceProvider = Provider<QuizService>((ref) {
  return QuizService();
});

// Provides the list of quizzes for the current user
final quizzesProvider = FutureProvider.autoDispose<List<QuizModel>>((
  ref,
) async {
  final service = ref.watch(quizServiceProvider);
  return await service.getQuizzes();
});

// Provides a specific quiz by ID
final quizDetailProvider = FutureProvider.family.autoDispose<QuizModel, int>((
  ref,
  quizId,
) async {
  final service = ref.watch(quizServiceProvider);
  return await service.getQuiz(quizId);
});

// StateNotifier for generating a new quiz (handles loading state)
class QuizGeneratorNotifier extends StateNotifier<AsyncValue<QuizModel?>> {
  final QuizService _service;

  QuizGeneratorNotifier(this._service) : super(const AsyncValue.data(null));

  Future<QuizModel?> generateQuiz(int documentId, int numQuestions) async {
    state = const AsyncValue.loading();
    try {
      final quiz = await _service.generateQuiz(
        documentId,
        numQuestions: numQuestions,
      );
      state = AsyncValue.data(quiz);
      return quiz;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<QuizModel?> generateQuizFromSession(int sessionId, int numQuestions) async {
    state = const AsyncValue.loading();
    try {
      final quiz = await _service.generateQuizFromSession(
        sessionId,
        numQuestions: numQuestions,
      );
      state = AsyncValue.data(quiz);
      return quiz;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

final quizGeneratorProvider =
    StateNotifierProvider<QuizGeneratorNotifier, AsyncValue<QuizModel?>>((ref) {
      final service = ref.watch(quizServiceProvider);
      return QuizGeneratorNotifier(service);
    });

// StateNotifier for submitting a quiz
class QuizSubmitNotifier extends StateNotifier<AsyncValue<QuizResultModel?>> {
  final QuizService _service;

  QuizSubmitNotifier(this._service) : super(const AsyncValue.data(null));

  Future<QuizResultModel?> submitQuiz(int quizId, List<int> answers) async {
    state = const AsyncValue.loading();
    try {
      final result = await _service.submitQuiz(quizId, answers);
      state = AsyncValue.data(result);
      return result;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

final quizSubmitProvider =
    StateNotifierProvider<QuizSubmitNotifier, AsyncValue<QuizResultModel?>>((
      ref,
    ) {
      final service = ref.watch(quizServiceProvider);
      return QuizSubmitNotifier(service);
    });
