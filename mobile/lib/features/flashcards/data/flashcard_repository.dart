import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/flashcard_models.dart';
import '../services/flashcard_service.dart';

abstract class FlashcardRepository {
  Future<FlashcardDeckModel> generateFlashcards(
    int documentId, {
    int numCards = 15,
  });
  Future<FlashcardDeckModel> generateFlashcardsFromSession(
    int sessionId, {
    int numCards = 15,
  });
  Future<FlashcardDeckModel> getDeck(int documentId);
  Future<FlashcardDeckModel> getSessionDeck(int sessionId);
  Future<List<FlashcardModel>> getDueCards();
  Future<FlashcardModel> reviewCard(int cardId, int quality);
  Future<void> deleteCard(int cardId);
}

class FlashcardRepositoryImpl implements FlashcardRepository {
  FlashcardRepositoryImpl(this._service);

  final FlashcardService _service;

  @override
  Future<FlashcardDeckModel> generateFlashcards(
    int documentId, {
    int numCards = 15,
  }) {
    return _service.generateFlashcards(documentId, numCards: numCards);
  }

  @override
  Future<FlashcardDeckModel> generateFlashcardsFromSession(
    int sessionId, {
    int numCards = 15,
  }) {
    return _service.generateFlashcardsFromSession(sessionId, numCards: numCards);
  }

  @override
  Future<FlashcardDeckModel> getDeck(int documentId) {
    return _service.getDeck(documentId);
  }

  @override
  Future<FlashcardDeckModel> getSessionDeck(int sessionId) {
    return _service.getSessionDeck(sessionId);
  }

  @override
  Future<List<FlashcardModel>> getDueCards() {
    return _service.getDueCards();
  }

  @override
  Future<FlashcardModel> reviewCard(int cardId, int quality) {
    return _service.reviewCard(cardId, quality);
  }

  @override
  Future<void> deleteCard(int cardId) {
    return _service.deleteCard(cardId);
  }
}

final flashcardRepositoryProvider = Provider<FlashcardRepository>((ref) {
  return FlashcardRepositoryImpl(ref.watch(flashcardServiceProvider));
});
