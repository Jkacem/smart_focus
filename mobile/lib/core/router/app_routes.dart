class AppRoutes {
  const AppRoutes._();

  static const welcome = '/';
  static const authOptions = '/auth_options';
  static const login = '/login';
  static const register = '/register';
  static const dashboard = '/dashboard';
  static const planning = '/planning';
  static const chatbot = '/chatbot';
  static const statistics = '/statistics';
  static const settings = '/settings';
  static const session = '/session';
  static const sleep = '/sleep';
  static const sleepAlarm = '/sleep/alarm';
  static const alarmRing = '/alarm-ring';

  static const quizGenerateDocumentPattern = '/quiz/generate/:docId';
  static const quizGenerateSessionPattern = '/quiz/generate/session/:sessionId';
  static const quizPlayPattern = '/quiz/play/:quizId';
  static const quizResultPattern = '/quiz/result/:quizId';

  static const flashcardsGenerateDocumentPattern = '/flashcards/generate/:docId';
  static const flashcardsGenerateSessionPattern =
      '/flashcards/generate/session/:sessionId';
  static const flashcardsDeckDocumentPattern = '/flashcards/deck/:docId';
  static const flashcardsDeckSessionPattern =
      '/flashcards/deck/session/:sessionId';
  static const flashcardsReviewPattern = '/flashcards/review';

  static String quizGenerateDocument(int documentId, {String? title}) {
    return _withQuery('/quiz/generate/$documentId', {'title': title});
  }

  static String quizGenerateSession(int sessionId, {String? title}) {
    return _withQuery('/quiz/generate/session/$sessionId', {'title': title});
  }

  static String quizPlay(int quizId) => '/quiz/play/$quizId';

  static String quizResult(int quizId) => '/quiz/result/$quizId';

  static String flashcardsGenerateDocument(int documentId, {String? title}) {
    return _withQuery('/flashcards/generate/$documentId', {'title': title});
  }

  static String flashcardsGenerateSession(int sessionId, {String? title}) {
    return _withQuery(
      '/flashcards/generate/session/$sessionId',
      {'title': title},
    );
  }

  static String flashcardsDeckDocument(int documentId) {
    return '/flashcards/deck/$documentId';
  }

  static String flashcardsDeckSession(int sessionId) {
    return '/flashcards/deck/session/$sessionId';
  }

  static String flashcardsReview({
    int? documentId,
    int? sessionId,
  }) {
    return _withQuery(
      flashcardsReviewPattern,
      {
        'documentId': documentId?.toString(),
        'sessionId': sessionId?.toString(),
      },
    );
  }

  static String _withQuery(
    String path,
    Map<String, String?> queryParameters,
  ) {
    final filtered = <String, String>{};

    for (final entry in queryParameters.entries) {
      final value = entry.value;
      if (value != null && value.isNotEmpty) {
        filtered[entry.key] = value;
      }
    }

    if (filtered.isEmpty) {
      return path;
    }

    return Uri(path: path, queryParameters: filtered).toString();
  }
}
