import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/chatbot_models.dart';
import '../providers/document_provider.dart';

class DocumentSection extends ConsumerStatefulWidget {
  const DocumentSection({Key? key}) : super(key: key);

  @override
  ConsumerState<DocumentSection> createState() => _DocumentSectionState();
}

class _DocumentSectionState extends ConsumerState<DocumentSection> {
  static const double _maxExpandedHeight = 260;

  bool _isExpanded = true;
  late final ScrollController _documentsScrollController;

  @override
  void initState() {
    super.initState();
    _documentsScrollController = ScrollController();
  }

  @override
  void dispose() {
    _documentsScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final docsState = ref.watch(documentProvider);
    final selectedDocs = ref.watch(selectedDocumentsProvider);
    final selectedCount = selectedDocs.length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.15), width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              onTap: () {
                setState(() {
                  _isExpanded = !_isExpanded;
                });
              },
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Mes Documents ($selectedCount selectionnes)',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
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
              if (selectedDocs.isNotEmpty)
                _SelectedDocumentsSummary(selectedCount: selectedCount),
              docsState.when(
                data: (docs) {
                  if (docs.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(8),
                      child: Text(
                        'Aucun document uploade.',
                        style: TextStyle(color: Colors.white54),
                      ),
                    );
                  }

                  return ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: _maxExpandedHeight),
                    child: Scrollbar(
                      controller: _documentsScrollController,
                      thumbVisibility: docs.length > 4,
                      child: ListView.separated(
                        controller: _documentsScrollController,
                        primary: false,
                        shrinkWrap: true,
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        itemCount: docs.length,
                        separatorBuilder: (context, index) => Divider(
                          color: Colors.white.withOpacity(0.06),
                          height: 1,
                          indent: 16,
                          endIndent: 16,
                        ),
                        itemBuilder: (context, index) {
                          return _buildDocItem(docs[index], selectedDocs);
                        },
                      ),
                    ),
                  );
                },
                loading: () => const Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ),
                error: (err, st) => Padding(
                  padding: const EdgeInsets.all(8),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          Checkbox(
            value: isSelected,
            onChanged: (val) {
              final notifier = ref.read(selectedDocumentsProvider.notifier);
              if (val == true) {
                notifier.state = [...selectedDocs, doc.id];
              } else {
                notifier.state = selectedDocs.where((id) => id != doc.id).toList();
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
              maxLines: 2,
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            const Icon(
              Icons.add_circle_outline,
              color: Colors.blueAccent,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Uploader PDF ou CSV',
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

class _SelectedDocumentsSummary extends StatelessWidget {
  final int selectedCount;

  const _SelectedDocumentsSummary({
    required this.selectedCount,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.blueAccent.withOpacity(0.14),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: Colors.blueAccent.withOpacity(0.35),
            ),
          ),
          child: Text(
            '$selectedCount document${selectedCount > 1 ? 's' : ''} actif${selectedCount > 1 ? 's' : ''}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
