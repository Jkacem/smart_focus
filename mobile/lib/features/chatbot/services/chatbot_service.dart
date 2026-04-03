import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/app_dio.dart';
import '../models/chatbot_models.dart';

class ChatbotService {
  ChatbotService(this._dio);

  final Dio _dio;

  Future<Map<String, dynamic>> uploadDocument(
    String filePath,
    String fileName,
  ) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath, filename: fileName),
    });

    final response = await _dio.post('/chatbot/upload', data: formData);
    return response.data;
  }

  Future<List<DocumentInfo>> getDocuments() async {
    final response = await _dio.get('/chatbot/documents');
    final data = response.data as List<dynamic>;
    return data.map((e) => DocumentInfo.fromJson(e)).toList();
  }

  Future<void> deleteDocument(int documentId) async {
    await _dio.delete('/chatbot/documents/$documentId');
  }

  Future<Map<String, dynamic>> chat(String question, List<int> documentIds) async {
    final response = await _dio.post(
      '/chatbot/chat',
      data: {
        'question': question,
        'document_ids': documentIds,
      },
      options: Options(contentType: Headers.jsonContentType),
    );
    return response.data;
  }

  Future<List<ChatMessageInfo>> getHistory({int limit = 20}) async {
    final response = await _dio.get(
      '/chatbot/history',
      queryParameters: {'limit': limit},
    );
    final data = response.data as List<dynamic>;
    return data.map((e) => ChatMessageInfo.fromJson(e)).toList();
  }
}

final chatbotServiceProvider = Provider<ChatbotService>((ref) {
  return ChatbotService(ref.watch(dioProvider));
});
