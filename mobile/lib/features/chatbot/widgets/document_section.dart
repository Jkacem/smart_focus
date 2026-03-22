import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/document_provider.dart';
import '../models/chatbot_models.dart';

class DocumentSection extends ConsumerStatefulWidget {
  const DocumentSection({Key? key}) : super(key: key);

  @override
  ConsumerState<DocumentSection> createState() => _DocumentSectionState();
}

class _DocumentSectionState extends ConsumerState<DocumentSection> {
  bool _isExpanded = true;

  @override
  Widget build(BuildContext context) {
    final docsState = ref.watch(documentProvider);
    final selectedDocs = ref.watch(selectedDocumentsProvider);
    final selectedCount = selectedDocs.length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.15), width: 1),
        ),
        child: Column(
          children: [
            InkWell(
              onTap: () {
                setState(() {
                  _isExpanded = !_isExpanded;
                });
              },
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 12.0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Mes Documents ($selectedCount sélectionnés)',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Icon(
                      _isExpanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
            ),
            if (_isExpanded) ...[
              Divider(color: Colors.white.withOpacity(0.1), height: 1),
              docsState.when(
                data: (docs) {
                  if (docs.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text(
                        'Aucun document uploadé.',
                        style: TextStyle(color: Colors.white54),
                      ),
                    );
                  }
                  return Column(
                    children: docs
                        .map((doc) => _buildDocItem(doc, selectedDocs))
                        .toList(),
                  );
                },
                loading: () => const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                ),
                error: (err, st) => Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    'Erreur: $err',
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                ),
              ),
              _buildAddDocButton(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDocItem(DocumentInfo doc, List<int> selectedDocs) {
    final isSelected = selectedDocs.contains(doc.id);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          Checkbox(
            value: isSelected,
            onChanged: (val) {
              final notifier = ref.read(selectedDocumentsProvider.notifier);
              if (val == true) {
                notifier.state = [...selectedDocs, doc.id];
              } else {
                notifier.state = selectedDocs
                    .where((id) => id != doc.id)
                    .toList();
              }
            },
            fillColor: MaterialStateProperty.resolveWith(
              (states) => states.contains(MaterialState.selected)
                  ? Colors.blueAccent
                  : Colors.white24,
            ),
          ),
          const Icon(Icons.description, color: Colors.white70, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              doc.filename,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.delete_outline,
              color: Colors.white54,
              size: 18,
            ),
            onPressed: () {
              ref.read(documentProvider.notifier).deleteDocument(doc.id);
              // Also remove from selected if deleted
              if (isSelected) {
                ref.read(selectedDocumentsProvider.notifier).state =
                    selectedDocs.where((id) => id != doc.id).toList();
              }
            },
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildAddDocButton() {
    return InkWell(
      onTap: () {
        ref.read(documentProvider.notifier).uploadDocument();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          children: [
            const Icon(
              Icons.add_circle_outline,
              color: Colors.blueAccent,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Uploader un cours',
              style: TextStyle(
                color: Colors.blueAccent.withOpacity(0.9),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
