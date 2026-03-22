import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../services/chatbot_service.dart';
import '../models/chatbot_models.dart';
import 'document_provider.dart';

final chatProvider =
    StateNotifierProvider<ChatNotifier, AsyncValue<List<ChatMessageInfo>>>((
      ref,
    ) {
      return ChatNotifier(ref.watch(chatbotServiceProvider), ref);
    });

class ChatNotifier extends StateNotifier<AsyncValue<List<ChatMessageInfo>>> {
  final ChatbotService _service;
  final Ref _ref;

  ChatNotifier(this._service, this._ref) : super(const AsyncLoading()) {
    fetchHistory();
  }

  Future<void> fetchHistory() async {
    state = const AsyncLoading();
    try {
      final history = await _service.getHistory();
      // Keep history newest-first because ListView is reversed
      state = AsyncData(history);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> sendMessage(String question) async {
    final selectedDocs = _ref.read(selectedDocumentsProvider);

    final currentState = state.value ?? [];

    // Optimistically add user message
    final optimisticMsg = ChatMessageInfo(
      id: DateTime.now().millisecondsSinceEpoch,
      documentId: selectedDocs.isNotEmpty ? selectedDocs.first : null,
      question: question,
      answer: '', // Will show loading on UI if answer is empty
      sources: [],
      createdAt: DateTime.now(),
    );

    state = AsyncData([optimisticMsg, ...currentState]);

    try {
      final response = await _service.chat(question, selectedDocs);

      // Update the message with the real answer and sources
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
      // Revert optimistic insert on error or show error message
      state = AsyncData(currentState);
      rethrow;
    }
  }
}
