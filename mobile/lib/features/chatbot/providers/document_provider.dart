import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../data/chatbot_repository.dart';
import '../models/chatbot_models.dart';

final documentProvider =
    StateNotifierProvider<DocumentNotifier, AsyncValue<List<DocumentInfo>>>(
      (ref) => DocumentNotifier(ref.watch(chatbotRepositoryProvider)),
    );

class DocumentNotifier extends StateNotifier<AsyncValue<List<DocumentInfo>>> {
  DocumentNotifier(this._repository) : super(const AsyncLoading()) {
    fetchDocuments();
  }

  final ChatbotRepository _repository;

  Future<void> fetchDocuments() async {
    state = const AsyncLoading();
    try {
      final docs = await _repository.getDocuments();
      state = AsyncData(docs);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> uploadDocument() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'csv'],
      );

      if (result != null && result.files.single.path != null) {
        final path = result.files.single.path!;
        final name = result.files.single.name;
        await _repository.uploadDocument(path, name);
        await fetchDocuments();
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteDocument(int id) async {
    try {
      await _repository.deleteDocument(id);
      await fetchDocuments();
    } catch (e) {
      rethrow;
    }
  }
}

final selectedDocumentsProvider = StateProvider<List<int>>((ref) => []);
