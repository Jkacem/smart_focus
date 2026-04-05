import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/app_dio.dart';
import '../models/quiz_models.dart';

class QuizService {
  QuizService(this._dio);

  final Dio _dio;

  Future<QuizModel> generateQuiz(int documentId, {int numQuestions = 10}) async {
    return generateQuizForDocuments([documentId], numQuestions: numQuestions);
  }

  Future<QuizModel> generateQuizForDocuments(
    List<int> documentIds, {
    int numQuestions = 10,
  }) async {
    final response = await _dio.post(
      '/quiz/generate',
      data: {
        if (documentIds.length == 1) 'document_id': documentIds.first,
        'document_ids': documentIds,
        'num_questions': numQuestions,
      },
    );
    return QuizModel.fromJson(response.data);
  }

  Future<QuizModel> generateQuizFromSession(
    int sessionId, {
    int numQuestions = 10,
  }) async {
    final response = await _dio.post(
      '/quiz/generate-from-session/$sessionId',
      data: {
        'num_questions': numQuestions,
      },
    );
    return QuizModel.fromJson(response.data);
  }

  Future<List<QuizModel>> getQuizzes() async {
    final response = await _dio.get('/quiz/list');
    final data = response.data as List<dynamic>;
    return data.map((e) => QuizModel.fromJson(e)).toList();
  }

  Future<QuizModel> getQuiz(int quizId) async {
    final response = await _dio.get('/quiz/$quizId');
    return QuizModel.fromJson(response.data);
  }

  Future<QuizResultModel> submitQuiz(int quizId, List<int> answers) async {
    final response = await _dio.post(
      '/quiz/$quizId/submit',
      data: {
        'answers': answers,
      },
    );
    return QuizResultModel.fromJson(response.data);
  }
}

final quizServiceProvider = Provider<QuizService>((ref) {
  return QuizService(ref.watch(dioProvider));
});
