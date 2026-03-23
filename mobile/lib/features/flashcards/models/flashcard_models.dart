class FlashcardModel {
  final int id;
  final String front;
  final String back;
  final double easeFactor;
  final int interval;
  final DateTime nextReview;
  final DateTime createdAt;

  FlashcardModel({
    required this.id,
    required this.front,
    required this.back,
    required this.easeFactor,
    required this.interval,
    required this.nextReview,
    required this.createdAt,
  });

  factory FlashcardModel.fromJson(Map<String, dynamic> json) {
    return FlashcardModel(
      id: json['id'],
      front: json['front'],
      back: json['back'],
      easeFactor: (json['ease_factor'] as num).toDouble(),
      interval: json['interval'],
      nextReview: DateTime.parse(json['next_review']),
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class FlashcardDeckModel {
  final int documentId;
  final String documentName;
  final int totalCards;
  final int dueCards;
  final List<FlashcardModel> cards;

  FlashcardDeckModel({
    required this.documentId,
    required this.documentName,
    required this.totalCards,
    required this.dueCards,
    required this.cards,
  });

  factory FlashcardDeckModel.fromJson(Map<String, dynamic> json) {
    var list = json['cards'] as List? ?? [];
    List<FlashcardModel> cardsList =
        list.map((i) => FlashcardModel.fromJson(i)).toList();

    return FlashcardDeckModel(
      documentId: json['document_id'],
      documentName: json['document_name'],
      totalCards: json['total_cards'],
      dueCards: json['due_cards'],
      cards: cardsList,
    );
  }
}
