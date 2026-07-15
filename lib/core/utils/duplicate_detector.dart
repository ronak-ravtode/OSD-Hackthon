// lib/core/utils/duplicate_detector.dart

class DuplicateDetector {
  const DuplicateDetector._();

  static bool isDuplicate(
    String text1,
    String text2, {
    double threshold = 0.85,
  }) {
    final Set<String> set1 = _tokenize(text1);
    final Set<String> set2 = _tokenize(text2);
    if (set1.isEmpty || set2.isEmpty) return false;

    final int intersection =
        set1.intersection(set2).length;
    final int union = set1.union(set2).length;
    if (union == 0) return false;

    return (intersection / union) >= threshold;
  }

  static double similarity(String text1, String text2) {
    final Set<String> set1 = _tokenize(text1);
    final Set<String> set2 = _tokenize(text2);
    if (set1.isEmpty || set2.isEmpty) return 0.0;

    final int intersection =
        set1.intersection(set2).length;
    final int union = set1.union(set2).length;
    if (union == 0) return 0.0;

    return intersection / union;
  }

  static Set<String> _tokenize(String text) {
    final String normalized = text
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .trim();
    if (normalized.isEmpty) return <String>{};
    return normalized
        .split(RegExp(r'\s+'))
        .where((String w) => w.isNotEmpty)
        .toSet();
  }
}
