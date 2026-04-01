import 'package:dio/dio.dart';
import '../../../core/router/api_client.dart';
import '../models/chatbot_models.dart';

class ChatbotService {
  final Dio _dio = ApiClient.createDio();

  /// Upload a PDF or CSV document
  Future<Map<String, dynamic>> uploadDocument(String filePath, String fileName) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath, filename: fileName),
    });

    final response = await _dio.post(
      '/chatbot/upload',
      data: formData,
    );
    return response.data;
  }

  /// List all documents for the current user
  Future<List<DocumentInfo>> getDocuments() async {
    final response = await _dio.get('/chatbot/documents');
    List<dynamic> data = response.data;
    return data.map((e) => DocumentInfo.fromJson(e)).toList();
  }

  /// Delete a document
  Future<void> deleteDocument(int documentId) async {
    await _dio.delete('/chatbot/documents/$documentId');
  }

  /// Ask a question based on selected documents
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

  /// Get chat history
  Future<List<ChatMessageInfo>> getHistory({int limit = 20}) async {
    final response = await _dio.get(
      '/chatbot/history',
      queryParameters: {'limit': limit},
    );
    List<dynamic> data = response.data;
    return data.map((e) => ChatMessageInfo.fromJson(e)).toList();
  }
}
