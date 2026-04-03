import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/app_dio.dart';
import '../models/flashcard_models.dart';

class FlashcardService {
  FlashcardService(this._dio);

  final Dio _dio;

  Future<FlashcardDeckModel> generateFlashcards(
    int documentId, {
    int numCards = 15,
  }) async {
    final response = await _dio.post(
      '/flashcards/generate',
      data: {
        'document_id': documentId,
        'num_cards': numCards,
      },
    );
    return FlashcardDeckModel.fromJson(response.data);
  }

  Future<FlashcardDeckModel> generateFlashcardsFromSession(
    int sessionId, {
    int numCards = 15,
  }) async {
    final response = await _dio.post(
      '/flashcards/generate-from-session/$sessionId',
      data: {
        'num_cards': numCards,
      },
    );
    return FlashcardDeckModel.fromJson(response.data);
  }

  Future<FlashcardDeckModel> getDeck(int documentId) async {
    final response = await _dio.get('/flashcards/deck/$documentId');
    return FlashcardDeckModel.fromJson(response.data);
  }

  Future<FlashcardDeckModel> getSessionDeck(int sessionId) async {
    final response = await _dio.get('/flashcards/deck/session/$sessionId');
    return FlashcardDeckModel.fromJson(response.data);
  }

  Future<List<FlashcardModel>> getDueCards() async {
    final response = await _dio.get('/flashcards/due');
    final data = response.data as List<dynamic>;
    return data.map((e) => FlashcardModel.fromJson(e)).toList();
  }

  Future<FlashcardModel> reviewCard(int cardId, int quality) async {
    final response = await _dio.post(
      '/flashcards/$cardId/review',
      data: {
        'quality': quality,
      },
    );
    return FlashcardModel.fromJson(response.data);
  }

  Future<void> deleteCard(int cardId) async {
    await _dio.delete('/flashcards/$cardId');
  }
}

final flashcardServiceProvider = Provider<FlashcardService>((ref) {
  return FlashcardService(ref.watch(dioProvider));
});
