import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/quiz_models.dart';
import '../services/quiz_service.dart';

abstract class QuizRepository {
  Future<QuizModel> generateQuiz(int documentId, {int numQuestions = 10});
  Future<QuizModel> generateQuizForDocuments(
    List<int> documentIds, {
    int numQuestions = 10,
  });
  Future<QuizModel> generateQuizFromSession(
    int sessionId, {
    int numQuestions = 10,
  });
  Future<List<QuizModel>> getQuizzes();
  Future<QuizModel> getQuiz(int quizId);
  Future<QuizResultModel> submitQuiz(int quizId, List<int> answers);
}

class QuizRepositoryImpl implements QuizRepository {
  QuizRepositoryImpl(this._service);

  final QuizService _service;

  @override
  Future<QuizModel> generateQuiz(int documentId, {int numQuestions = 10}) {
    return _service.generateQuiz(documentId, numQuestions: numQuestions);
  }

  @override
  Future<QuizModel> generateQuizForDocuments(
    List<int> documentIds, {
    int numQuestions = 10,
  }) {
    return _service.generateQuizForDocuments(
      documentIds,
      numQuestions: numQuestions,
    );
  }

  @override
  Future<QuizModel> generateQuizFromSession(
    int sessionId, {
    int numQuestions = 10,
  }) {
    return _service.generateQuizFromSession(sessionId, numQuestions: numQuestions);
  }

  @override
  Future<List<QuizModel>> getQuizzes() {
    return _service.getQuizzes();
  }

  @override
  Future<QuizModel> getQuiz(int quizId) {
    return _service.getQuiz(quizId);
  }

  @override
  Future<QuizResultModel> submitQuiz(int quizId, List<int> answers) {
    return _service.submitQuiz(quizId, answers);
  }
}

final quizRepositoryProvider = Provider<QuizRepository>((ref) {
  return QuizRepositoryImpl(ref.watch(quizServiceProvider));
});
