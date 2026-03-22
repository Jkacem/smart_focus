class DocumentInfo {
  final int id;
  final String filename;
  final String filePath;
  final int pageCount;
  final DateTime createdAt;

  DocumentInfo({
    required this.id,
    required this.filename,
    required this.filePath,
    required this.pageCount,
    required this.createdAt,
  });

  factory DocumentInfo.fromJson(Map<String, dynamic> json) {
    return DocumentInfo(
      id: json['id'],
      filename: json['filename'],
      filePath: json['file_path'] ?? '',
      pageCount: json['page_count'] ?? 0,
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class SourceCitation {
  final String filename;
  final int? page;
  final String? excerpt;

  SourceCitation({
    required this.filename,
    this.page,
    this.excerpt,
  });

  factory SourceCitation.fromJson(Map<String, dynamic> json) {
    return SourceCitation(
      filename: json['filename'],
      page: json['page'],
      excerpt: json['excerpt'],
    );
  }
}

class ChatMessageInfo {
  final int id;
  final int? documentId;
  final String question;
  final String answer;
  final List<SourceCitation> sources;
  final DateTime createdAt;

  ChatMessageInfo({
    required this.id,
    this.documentId,
    required this.question,
    required this.answer,
    required this.sources,
    required this.createdAt,
  });

  factory ChatMessageInfo.fromJson(Map<String, dynamic> json) {
    var list = json['sources'] as List? ?? [];
    List<SourceCitation> sourcesList = list.map((i) => SourceCitation.fromJson(i)).toList();

    return ChatMessageInfo(
      id: json['id'],
      documentId: json['document_id'],
      question: json['question'],
      answer: json['answer'],
      sources: sourcesList,
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
