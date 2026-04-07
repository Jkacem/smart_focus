import 'package:smart_focus/shared/utils/document_link_utils.dart';

class FlashcardModel {
  final int id;
  final String front;
  final String back;
  final double easeFactor;
  final int interval;
  final int repetitions;
  final DateTime nextReview;
  final DateTime createdAt;
  final int? sourceSessionId;

  FlashcardModel({
    required this.id,
    required this.front,
    required this.back,
    required this.easeFactor,
    required this.interval,
    required this.repetitions,
    required this.nextReview,
    required this.createdAt,
    this.sourceSessionId,
  });

  factory FlashcardModel.fromJson(Map<String, dynamic> json) {
    return FlashcardModel(
      id: json['id'],
      front: json['front'],
      back: json['back'],
      easeFactor: (json['ease_factor'] as num).toDouble(),
      interval: json['interval'],
      repetitions: json['repetitions'] ?? 0,
      nextReview: DateTime.parse(json['next_review']),
      createdAt: DateTime.parse(json['created_at']),
      sourceSessionId: json['source_session_id'] as int?,
    );
  }
}

class FlashcardDeckModel {
  final int? documentId;
  final String documentName;
  final List<int> documentIds;
  final List<String> documentNames;
  final int? sessionId;
  final String? sessionSubject;
  final int totalCards;
  final int dueCards;
  final int reviewedCards;
  final List<FlashcardModel> cards;

  FlashcardDeckModel({
    required this.documentId,
    required this.documentName,
    required this.documentIds,
    required this.documentNames,
    this.sessionId,
    this.sessionSubject,
    required this.totalCards,
    required this.dueCards,
    required this.reviewedCards,
    required this.cards,
  });

  factory FlashcardDeckModel.fromJson(Map<String, dynamic> json) {
    var list = json['cards'] as List? ?? [];
    List<FlashcardModel> cardsList =
        list.map((i) => FlashcardModel.fromJson(i)).toList();

    return FlashcardDeckModel(
      documentId: json['document_id'],
      documentName: json['document_name'],
      documentIds: List<int>.from(json['document_ids'] ?? const []),
      documentNames: List<String>.from(json['document_names'] ?? const []),
      sessionId: json['session_id'] as int?,
      sessionSubject: json['session_subject']?.toString(),
      totalCards: json['total_cards'],
      dueCards: json['due_cards'],
      reviewedCards: json['reviewed_cards'] ?? 0,
      cards: cardsList,
    );
  }

  String get sourceLabel {
    return summarizeDocumentNames(
      documentNames,
      fallbackName: documentName,
      fallbackLabel: 'Documents',
    );
  }
}
