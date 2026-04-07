List<int> resolveDocumentIds(
  List<int> documentIds, {
  int? primaryDocumentId,
}) {
  if (documentIds.isNotEmpty) {
    return List<int>.unmodifiable(documentIds);
  }
  if (primaryDocumentId != null) {
    return List<int>.unmodifiable(<int>[primaryDocumentId]);
  }
  return const <int>[];
}

String summarizeDocumentNames(
  List<String> documentNames, {
  String? fallbackName,
  String fallbackLabel = 'Document',
}) {
  if (documentNames.isNotEmpty) {
    if (documentNames.length == 1) {
      return documentNames.first;
    }
    return '${documentNames.first} +${documentNames.length - 1} docs';
  }
  return fallbackName ?? fallbackLabel;
}

Map<String, dynamic> buildLinkedDocumentPayload(List<int> documentIds) {
  return {
    'document_id': documentIds.isEmpty ? null : documentIds.first,
    'document_ids': documentIds,
  };
}
