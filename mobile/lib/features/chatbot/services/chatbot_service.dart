import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_focus/core/network/app_dio.dart';

import '../models/chatbot_models.dart';

class ChatbotService {
  ChatbotService(this._dio);

  final Dio _dio;

  Future<Map<String, dynamic>> uploadDocument(PlatformFile file) async {
    final formData = await _buildUploadFormData(file);

    final response = await _dio.post(
      '/chatbot/upload',
      data: formData,
      options: Options(
        extra: {'retry_data_factory': () => _buildUploadFormData(file)},
      ),
    );
    return response.data;
  }

  Future<FormData> _buildUploadFormData(PlatformFile file) async {
    final multipartFile = await _buildMultipartFile(file);
    return FormData.fromMap({'file': multipartFile});
  }

  Future<MultipartFile> _buildMultipartFile(PlatformFile file) async {
    if (file.bytes != null) {
      return MultipartFile.fromBytes(file.bytes!, filename: file.name);
    }

    if (file.path != null) {
      return MultipartFile.fromFile(file.path!, filename: file.name);
    }

    throw Exception(
      'Impossible de lire ce fichier depuis votre appareil. '
      'Reessayez avec un autre document ou emplacement.',
    );
  }

  Future<List<DocumentInfo>> getDocuments() async {
    final response = await _dio.get('/chatbot/documents');
    final data = response.data as List<dynamic>;
    return data.map((e) => DocumentInfo.fromJson(e)).toList();
  }

  Future<void> deleteDocument(int documentId) async {
    await _dio.delete('/chatbot/documents/$documentId');
  }

  Future<Map<String, dynamic>> chat(
    String question,
    List<int> documentIds,
  ) async {
    final response = await _dio.post(
      '/chatbot/chat',
      data: {'question': question, 'document_ids': documentIds},
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
