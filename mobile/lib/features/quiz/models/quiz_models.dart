import 'package:smart_focus/shared/utils/document_link_utils.dart';

class QuizQuestionModel {
  final int id;
  final String questionText;
  final List<String> options;
  final int? correctIndex;
  final String? explanation;
  final int? userAnswerIndex;

  QuizQuestionModel({
    required this.id,
    required this.questionText,
    required this.options,
    this.correctIndex,
    this.explanation,
    this.userAnswerIndex,
  });

  factory QuizQuestionModel.fromJson(Map<String, dynamic> json) {
    return QuizQuestionModel(
      id: json['id'],
      questionText: json['question_text'],
      options: List<String>.from(json['options'] ?? []),
      correctIndex: json['correct_index'],
      explanation: json['explanation'],
      userAnswerIndex: json['user_answer_index'],
    );
  }
}

class QuizModel {
  final int id;
  final int? documentId;
  final List<int> documentIds;
  final List<String> documentNames;
  final int? sessionId;
  final String title;
  final int numQuestions;
  final int? score;
  final DateTime? completedAt;
  final DateTime createdAt;
  final List<QuizQuestionModel> questions;

  QuizModel({
    required this.id,
    required this.documentId,
    required this.documentIds,
    required this.documentNames,
    this.sessionId,
    required this.title,
    required this.numQuestions,
    this.score,
    this.completedAt,
    required this.createdAt,
    required this.questions,
  });

  factory QuizModel.fromJson(Map<String, dynamic> json) {
    var list = json['questions'] as List? ?? [];
    List<QuizQuestionModel> questionsList =
        list.map((i) => QuizQuestionModel.fromJson(i)).toList();

    return QuizModel(
      id: json['id'],
      documentId: json['document_id'],
      documentIds: List<int>.from(json['document_ids'] ?? const []),
      documentNames: List<String>.from(json['document_names'] ?? const []),
      sessionId: json['session_id'] as int?,
      title: json['title'],
      numQuestions: json['num_questions'],
      score: json['score'],
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'])
          : null,
      createdAt: DateTime.parse(json['created_at']),
      questions: questionsList,
    );
  }

  String get sourceLabel {
    return summarizeDocumentNames(documentNames);
  }
}

class QuizResultModel {
  final int quizId;
  final int score;
  final int total;
  final double percentage;
  final List<QuizQuestionModel> questions;

  QuizResultModel({
    required this.quizId,
    required this.score,
    required this.total,
    required this.percentage,
    required this.questions,
  });

  factory QuizResultModel.fromQuiz(QuizModel quiz) {
    final total = quiz.questions.length;
    final score =
        quiz.score ??
        quiz.questions.where((question) {
          return question.correctIndex != null &&
              question.userAnswerIndex != null &&
              question.correctIndex == question.userAnswerIndex;
        }).length;

    return QuizResultModel(
      quizId: quiz.id,
      score: score,
      total: total,
      percentage: total == 0 ? 0 : (score / total) * 100,
      questions: quiz.questions,
    );
  }

  factory QuizResultModel.fromJson(Map<String, dynamic> json) {
    var list = json['questions'] as List? ?? [];
    List<QuizQuestionModel> questionsList =
        list.map((i) => QuizQuestionModel.fromJson(i)).toList();

    return QuizResultModel(
      quizId: json['quiz_id'],
      score: json['score'],
      total: json['total'],
      percentage: (json['percentage'] as num).toDouble(),
      questions: questionsList,
    );
  }
}
