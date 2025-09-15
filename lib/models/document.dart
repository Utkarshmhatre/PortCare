enum DocumentType {
  prescription('prescription', 'Prescription'),
  labReport('lab_report', 'Lab Report'),
  xray('xray', 'X-Ray'),
  mri('mri', 'MRI'),
  ct('ct', 'CT Scan'),
  insurance('insurance', 'Insurance'),
  vaccination('vaccination', 'Vaccination Record'),
  other('other', 'Other');

  const DocumentType(this.value, this.displayName);

  final String value;
  final String displayName;

  static DocumentType? fromString(String? value) {
    if (value == null) return null;
    for (DocumentType type in DocumentType.values) {
      if (type.value == value) return type;
    }
    return null;
  }
}

class Document {
  final String id;
  final String userId;
  final String name;
  final DocumentType type;
  final String fileUrl;
  final String? thumbnailUrl;
  final int fileSizeBytes;
  final String mimeType;
  final String? description;
  final DateTime? documentDate; // Date the document was issued/created
  final List<String> tags;
  final bool isEncrypted;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Document({
    required this.id,
    required this.userId,
    required this.name,
    required this.type,
    required this.fileUrl,
    this.thumbnailUrl,
    required this.fileSizeBytes,
    required this.mimeType,
    this.description,
    this.documentDate,
    this.tags = const [],
    this.isEncrypted = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Document.fromMap(Map<String, dynamic> map) {
    return Document(
      id: map['id'] as String,
      userId: map['userId'] as String,
      name: map['name'] as String,
      type:
          DocumentType.fromString(map['type'] as String?) ?? DocumentType.other,
      fileUrl: map['fileUrl'] as String,
      thumbnailUrl: map['thumbnailUrl'] as String?,
      fileSizeBytes: map['fileSizeBytes'] as int,
      mimeType: map['mimeType'] as String,
      description: map['description'] as String?,
      documentDate: map['documentDate'] != null
          ? DateTime.parse(map['documentDate'] as String)
          : null,
      tags: List<String>.from(map['tags'] as List? ?? []),
      isEncrypted: map['isEncrypted'] as bool? ?? false,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'type': type.value,
      'fileUrl': fileUrl,
      'thumbnailUrl': thumbnailUrl,
      'fileSizeBytes': fileSizeBytes,
      'mimeType': mimeType,
      'description': description,
      'documentDate': documentDate?.toIso8601String(),
      'tags': tags,
      'isEncrypted': isEncrypted,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  Document copyWith({
    String? id,
    String? userId,
    String? name,
    DocumentType? type,
    String? fileUrl,
    String? thumbnailUrl,
    int? fileSizeBytes,
    String? mimeType,
    String? description,
    DateTime? documentDate,
    List<String>? tags,
    bool? isEncrypted,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Document(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      type: type ?? this.type,
      fileUrl: fileUrl ?? this.fileUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      mimeType: mimeType ?? this.mimeType,
      description: description ?? this.description,
      documentDate: documentDate ?? this.documentDate,
      tags: tags ?? this.tags,
      isEncrypted: isEncrypted ?? this.isEncrypted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String get formattedFileSize {
    if (fileSizeBytes < 1024) return '${fileSizeBytes}B';
    if (fileSizeBytes < 1024 * 1024)
      return '${(fileSizeBytes / 1024).toStringAsFixed(1)}KB';
    return '${(fileSizeBytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }

  bool get isPdf => mimeType == 'application/pdf';
  bool get isImage => mimeType.startsWith('image/');

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Document && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Document(id: $id, name: $name, type: ${type.displayName}, size: $formattedFileSize)';
  }
}
