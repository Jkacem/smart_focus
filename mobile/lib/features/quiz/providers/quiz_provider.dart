import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../data/quiz_repository.dart';
import '../models/quiz_models.dart';

final quizzesProvider = FutureProvider.autoDispose<List<QuizModel>>((ref) async {
  final repository = ref.watch(quizRepositoryProvider);
  return repository.getQuizzes();
});

final quizDetailProvider = FutureProvider.family.autoDispose<QuizModel, int>((
  ref,
  quizId,
) async {
  final repository = ref.watch(quizRepositoryProvider);
  return repository.getQuiz(quizId);
});

class QuizGeneratorNotifier extends StateNotifier<AsyncValue<QuizModel?>> {
  QuizGeneratorNotifier(this._repository) : super(const AsyncValue.data(null));

  final QuizRepository _repository;

  void reset() {
    state = const AsyncValue.data(null);
  }

  Future<QuizModel?> generateQuiz(int documentId, int numQuestions) async {
    state = const AsyncValue.loading();
    try {
      final quiz = await _repository.generateQuiz(
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
      final quiz = await _repository.generateQuizFromSession(
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

final quizGeneratorProvider = StateNotifierProvider.autoDispose<
  QuizGeneratorNotifier,
  AsyncValue<QuizModel?>
>((ref) {
  final repository = ref.watch(quizRepositoryProvider);
  return QuizGeneratorNotifier(repository);
});

class QuizSubmitNotifier extends StateNotifier<AsyncValue<QuizResultModel?>> {
  QuizSubmitNotifier(this._repository) : super(const AsyncValue.data(null));

  final QuizRepository _repository;

  Future<QuizResultModel?> submitQuiz(int quizId, List<int> answers) async {
    state = const AsyncValue.loading();
    try {
      final result = await _repository.submitQuiz(quizId, answers);
      state = AsyncValue.data(result);
      return result;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

final quizSubmitProvider =
    StateNotifierProvider<QuizSubmitNotifier, AsyncValue<QuizResultModel?>>(
      (ref) {
        final repository = ref.watch(quizRepositoryProvider);
        return QuizSubmitNotifier(repository);
      },
    );
