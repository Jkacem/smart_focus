import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/chatbot_models.dart';
import '../services/chatbot_service.dart';

abstract class ChatbotRepository {
  Future<Map<String, dynamic>> uploadDocument(String filePath, String fileName);
  Future<List<DocumentInfo>> getDocuments();
  Future<void> deleteDocument(int documentId);
  Future<Map<String, dynamic>> chat(String question, List<int> documentIds);
  Future<List<ChatMessageInfo>> getHistory({int limit = 20});
}

class ChatbotRepositoryImpl implements ChatbotRepository {
  ChatbotRepositoryImpl(this._service);

  final ChatbotService _service;

  @override
  Future<Map<String, dynamic>> uploadDocument(String filePath, String fileName) {
    return _service.uploadDocument(filePath, fileName);
  }

  @override
  Future<List<DocumentInfo>> getDocuments() {
    return _service.getDocuments();
  }

  @override
  Future<void> deleteDocument(int documentId) {
    return _service.deleteDocument(documentId);
  }

  @override
  Future<Map<String, dynamic>> chat(String question, List<int> documentIds) {
    return _service.chat(question, documentIds);
  }

  @override
  Future<List<ChatMessageInfo>> getHistory({int limit = 20}) {
    return _service.getHistory(limit: limit);
  }
}

final chatbotRepositoryProvider = Provider<ChatbotRepository>((ref) {
  return ChatbotRepositoryImpl(ref.watch(chatbotServiceProvider));
});
