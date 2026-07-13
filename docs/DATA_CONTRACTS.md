# Data Contracts (The Handshake)

## 1. Core Domain Model
Both agents must use this exact structure. Do not add, remove, or rename fields without mutual agreement.

```dart
// lib/domain/models/screenshot_model.dart
class Screenshot {
  final String id;
  final String filePath;
  final String extractedText;
  final String category; // Allowed: 'receipt', 'code', 'meme', 'document', 'other'
  final DateTime timestamp;

  const Screenshot({
    required this.id,
    required this.filePath,
    required this.extractedText,
    required this.category,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'filePath': filePath,
      'extractedText': extractedText,
      'category': category,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }

  factory Screenshot.fromMap(Map<String, dynamic> map) {
    return Screenshot(
      id: map['id'] as String,
      filePath: map['filePath'] as String,
      extractedText: map['extractedText'] as String,
      category: map['category'] as String,
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
    );
  }
}