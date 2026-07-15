// lib/domain/models/screenshot_model.dart

class Screenshot {
  final String id;
  final String filePath;
  final String extractedText;
  final String category;
  final DateTime timestamp;
  final bool isCompressed;

  const Screenshot({
    required this.id,
    required this.filePath,
    required this.extractedText,
    required this.category,
    required this.timestamp,
    this.isCompressed = false,
  });

  Map<String, Object> toMap() {
    return <String, Object>{
      'id': id,
      'filePath': filePath,
      'extractedText': extractedText,
      'category': category,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'isCompressed': isCompressed ? 1 : 0,
    };
  }

  factory Screenshot.fromMap(Map<String, Object?> map) {
    return Screenshot(
      id: map['id'] as String,
      filePath: map['filePath'] as String,
      extractedText: map['extractedText'] as String,
      category: map['category'] as String,
      timestamp: DateTime.fromMillisecondsSinceEpoch(
        map['timestamp'] as int,
      ),
      isCompressed: (map['isCompressed'] as int?) == 1,
    );
  }

  Screenshot copyWith({
    String? id,
    String? filePath,
    String? extractedText,
    String? category,
    DateTime? timestamp,
    bool? isCompressed,
  }) {
    return Screenshot(
      id: id ?? this.id,
      filePath: filePath ?? this.filePath,
      extractedText: extractedText ?? this.extractedText,
      category: category ?? this.category,
      timestamp: timestamp ?? this.timestamp,
      isCompressed: isCompressed ?? this.isCompressed,
    );
  }
}
