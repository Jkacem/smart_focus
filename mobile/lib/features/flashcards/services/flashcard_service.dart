import 'package:dio/dio.dart';
import '../../../core/router/api_client.dart';
import '../models/flashcard_models.dart';

class FlashcardService {
  final Dio _dio = ApiClient.createDio();

  /// Generate flashcards for a specific document
  Future<FlashcardDeckModel> generateFlashcards(int documentId, {int numCards = 15}) async {
    final response = await _dio.post(
      '/flashcards/generate',
      data: {
        'document_id': documentId,
        'num_cards': numCards,
      },
    );
    return FlashcardDeckModel.fromJson(response.data);
  }

  /// Get the full deck of flashcards for a specific document
  Future<FlashcardDeckModel> getDeck(int documentId) async {
    final response = await _dio.get('/flashcards/deck/$documentId');
    return FlashcardDeckModel.fromJson(response.data);
  }

  /// Get all flashcards currently due for review
  Future<List<FlashcardModel>> getDueCards() async {
    final response = await _dio.get('/flashcards/due');
    List<dynamic> data = response.data;
    return data.map((e) => FlashcardModel.fromJson(e)).toList();
  }

  /// Review a specific flashcard (SM-2 update)
  /// Quality rating: 0 (Blackout) to 5 (Perfect)
  Future<FlashcardModel> reviewCard(int cardId, int quality) async {
    final response = await _dio.post(
      '/flashcards/$cardId/review',
      data: {
        'quality': quality,
      },
    );
    return FlashcardModel.fromJson(response.data);
  }

  /// Delete a specific flashcard
  Future<void> deleteCard(int cardId) async {
    await _dio.delete('/flashcards/$cardId');
  }
}
