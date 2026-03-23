import 'package:dio/dio.dart';
import '../../../core/router/api_client.dart';
import '../models/quiz_models.dart';

class QuizService {
  final Dio _dio = ApiClient.createDio();

  /// Generate a quiz for a specific document
  Future<QuizModel> generateQuiz(int documentId, {int numQuestions = 10}) async {
    final response = await _dio.post(
      '/quiz/generate',
      data: {
        'document_id': documentId,
        'num_questions': numQuestions,
      },
    );
    return QuizModel.fromJson(response.data);
  }

  /// List all quizzes for the current user
  Future<List<QuizModel>> getQuizzes() async {
    final response = await _dio.get('/quiz/list');
    List<dynamic> data = response.data;
    return data.map((e) => QuizModel.fromJson(e)).toList();
  }

  /// Get a single quiz (questions hide answers if not submitted)
  Future<QuizModel> getQuiz(int quizId) async {
    final response = await _dio.get('/quiz/$quizId');
    return QuizModel.fromJson(response.data);
  }

  /// Submit quiz answers and get the score
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
