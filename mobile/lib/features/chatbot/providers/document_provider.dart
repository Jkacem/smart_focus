import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../services/chatbot_service.dart';
import '../models/chatbot_models.dart';

final chatbotServiceProvider = Provider((ref) => ChatbotService());

final documentProvider =
    StateNotifierProvider<DocumentNotifier, AsyncValue<List<DocumentInfo>>>((
      ref,
    ) {
      return DocumentNotifier(ref.watch(chatbotServiceProvider));
    });

class DocumentNotifier extends StateNotifier<AsyncValue<List<DocumentInfo>>> {
  final ChatbotService _service;

  DocumentNotifier(this._service) : super(const AsyncLoading()) {
    fetchDocuments();
  }

  Future<void> fetchDocuments() async {
    state = const AsyncLoading();
    try {
      final docs = await _service.getDocuments();
      state = AsyncData(docs);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> uploadDocument() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null && result.files.single.path != null) {
        final path = result.files.single.path!;
        final name = result.files.single.name;

        // Show loading state while keeping old data if needed, or just refresh after
        await _service.uploadDocument(path, name);
        await fetchDocuments(); // Refresh the list
      }
    } catch (e) {
      // Could show a snackbar here or pass error to UI
      rethrow;
    }
  }

  Future<void> deleteDocument(int id) async {
    try {
      await _service.deleteDocument(id);
      await fetchDocuments();
    } catch (e) {
      rethrow;
    }
  }
}

// Provider to keep track of which documents are currently selected for the chat context
final selectedDocumentsProvider = StateProvider<List<int>>((ref) => []);
