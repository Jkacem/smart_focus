import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../data/flashcard_repository.dart';
import '../models/flashcard_models.dart';

final flashcardDeckProvider =
    FutureProvider.family.autoDispose<FlashcardDeckModel, int>(
      (ref, documentId) async {
        final repository = ref.watch(flashcardRepositoryProvider);
        return repository.getDeck(documentId);
      },
    );

final sessionFlashcardDeckProvider =
    FutureProvider.family.autoDispose<FlashcardDeckModel, int>(
      (ref, sessionId) async {
        final repository = ref.watch(flashcardRepositoryProvider);
        return repository.getSessionDeck(sessionId);
      },
    );

final dueFlashcardsProvider = FutureProvider.autoDispose<List<FlashcardModel>>((
  ref,
) async {
  final repository = ref.watch(flashcardRepositoryProvider);
  return repository.getDueCards();
});

class FlashcardGeneratorNotifier
    extends StateNotifier<AsyncValue<FlashcardDeckModel?>> {
  FlashcardGeneratorNotifier(this._repository)
    : super(const AsyncValue.data(null));

  final FlashcardRepository _repository;

  void reset() {
    state = const AsyncValue.data(null);
  }

  Future<FlashcardDeckModel?> generateFlashcards(
    int documentId,
    int numCards,
  ) async {
    state = const AsyncValue.loading();
    try {
      final deck = await _repository.generateFlashcards(
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
      final deck = await _repository.generateFlashcardsFromSession(
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

final flashcardGeneratorProvider = StateNotifierProvider.autoDispose<
  FlashcardGeneratorNotifier,
  AsyncValue<FlashcardDeckModel?>
>((ref) {
  final repository = ref.watch(flashcardRepositoryProvider);
  return FlashcardGeneratorNotifier(repository);
});

final reviewFlashcardProvider =
    Provider<Future<FlashcardModel> Function(int, int)>((ref) {
      final repository = ref.watch(flashcardRepositoryProvider);
      return (int cardId, int quality) {
        return repository.reviewCard(cardId, quality);
      };
    });
