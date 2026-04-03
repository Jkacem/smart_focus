import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../data/chatbot_repository.dart';
import '../models/chatbot_models.dart';
import 'document_provider.dart';

final chatProvider =
    StateNotifierProvider<ChatNotifier, AsyncValue<List<ChatMessageInfo>>>(
      (ref) => ChatNotifier(ref.watch(chatbotRepositoryProvider), ref),
    );

class ChatNotifier extends StateNotifier<AsyncValue<List<ChatMessageInfo>>> {
  ChatNotifier(this._repository, this._ref) : super(const AsyncLoading()) {
    fetchHistory();
  }

  final ChatbotRepository _repository;
  final Ref _ref;

  Future<void> fetchHistory() async {
    state = const AsyncLoading();
    try {
      final history = await _repository.getHistory();
      state = AsyncData(history);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> sendMessage(String question) async {
    final selectedDocs = _ref.read(selectedDocumentsProvider);
    final currentState = state.value ?? [];

    final optimisticMsg = ChatMessageInfo(
      id: DateTime.now().millisecondsSinceEpoch,
      documentId: selectedDocs.isNotEmpty ? selectedDocs.first : null,
      question: question,
      answer: '',
      sources: const [],
      createdAt: DateTime.now(),
    );

    state = AsyncData([optimisticMsg, ...currentState]);

    try {
      final response = await _repository.chat(question, selectedDocs);
      final updatedMsg = ChatMessageInfo(
        id: response['message_id'] ?? optimisticMsg.id,
        documentId: selectedDocs.isNotEmpty ? selectedDocs.first : null,
        question: question,
        answer: response['answer'],
        sources: (response['sources'] as List)
            .map((e) => SourceCitation.fromJson(e))
            .toList(),
        createdAt: DateTime.now(),
      );

      final newState = List<ChatMessageInfo>.from(currentState);
      newState.insert(0, updatedMsg);
      state = AsyncData(newState);
    } catch (e) {
      state = AsyncData(currentState);
      rethrow;
    }
  }
}
