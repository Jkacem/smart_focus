import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../models/flashcard_models.dart';
import '../services/flashcard_service.dart';

final flashcardServiceProvider = Provider<FlashcardService>((ref) {
  return FlashcardService();
});

// Provides the deck of flashcards for a specific document
final flashcardDeckProvider = FutureProvider.family
    .autoDispose<FlashcardDeckModel, int>((ref, documentId) async {
      final service = ref.watch(flashcardServiceProvider);
      return await service.getDeck(documentId);
    });

// Provides the list of globally due flashcards
final dueFlashcardsProvider = FutureProvider.autoDispose<List<FlashcardModel>>((
  ref,
) async {
  final service = ref.watch(flashcardServiceProvider);
  return await service.getDueCards();
});

// StateNotifier for generating flashcards
class FlashcardGeneratorNotifier
    extends StateNotifier<AsyncValue<FlashcardDeckModel?>> {
  final FlashcardService _service;

  FlashcardGeneratorNotifier(this._service)
    : super(const AsyncValue.data(null));

  Future<FlashcardDeckModel?> generateFlashcards(
    int documentId,
    int numCards,
  ) async {
    state = const AsyncValue.loading();
    try {
      final deck = await _service.generateFlashcards(
        documentId,
        numCards: numCards,
      );
      state = AsyncValue.data(deck);
      return deck;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<FlashcardDeckModel?> generateFlashcardsFromSession(
    int sessionId,
    int numCards,
  ) async {
    state = const AsyncValue.loading();
    try {
      final deck = await _service.generateFlashcardsFromSession(
        sessionId,
        numCards: numCards,
      );
      state = AsyncValue.data(deck);
      return deck;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

final flashcardGeneratorProvider =
    StateNotifierProvider<
      FlashcardGeneratorNotifier,
      AsyncValue<FlashcardDeckModel?>
    >((ref) {
      final service = ref.watch(flashcardServiceProvider);
      return FlashcardGeneratorNotifier(service);
    });

// Provides a way to submit single reviews
final reviewFlashcardProvider =
    Provider<Future<FlashcardModel> Function(int, int)>((ref) {
      final service = ref.watch(flashcardServiceProvider);
      return (int cardId, int quality) async {
        return await service.reviewCard(cardId, quality);
      };
    });
