// lib/core/utils/summarizer.dart

class TextRankSummarizer {
  const TextRankSummarizer._();

  static const Set<String> _stopWords = <String>{
    'the', 'is', 'at', 'which', 'on', 'a', 'an', 'as',
    'are', 'was', 'were', 'be', 'been', 'being', 'have',
    'has', 'had', 'do', 'does', 'did', 'will', 'would',
    'could', 'should', 'may', 'might', 'must', 'shall',
    'can', 'need', 'dare', 'ought', 'used', 'to', 'of',
    'in', 'for', 'with', 'about', 'against', 'between',
    'into', 'through', 'during', 'before', 'after',
    'above', 'below', 'from', 'up', 'down', 'out', 'off',
    'over', 'under', 'again', 'further', 'then', 'once',
    'here', 'there', 'when', 'where', 'why', 'how', 'all',
    'any', 'both', 'each', 'few', 'more', 'most', 'other',
    'some', 'such', 'no', 'nor', 'not', 'only', 'own',
    'same', 'so', 'than', 'too', 'very', 'just', 'and',
    'but', 'if', 'or', 'because', 'until', 'while',
  };

  static String summarize(String text) {
    if (text.trim().isEmpty) return text;

    final List<String> sentences = _splitSentences(text);
    if (sentences.length <= 3) return text;

    final List<Set<String>> tokenized =
        sentences.map(_tokenize).toList();

    // Build similarity matrix
    final int n = sentences.length;
    final List<List<double>> sim = List<List<double>>.generate(
      n,
      (_) => List<double>.filled(n, 0.0),
    );
    for (int i = 0; i < n; i++) {
      for (int j = i + 1; j < n; j++) {
        final double s = _jaccard(tokenized[i], tokenized[j]);
        sim[i][j] = s;
        sim[j][i] = s;
      }
    }

    // PageRank iterations
    final List<double> scores = List<double>.filled(n, 1.0);
    const double damping = 0.85;
    const int iterations = 30;

    for (int iter = 0; iter < iterations; iter++) {
      final List<double> newScores =
          List<double>.filled(n, 0.0);
      for (int i = 0; i < n; i++) {
        double sum = 0.0;
        for (int j = 0; j < n; j++) {
          if (i == j) continue;
          double denom = 0.0;
          for (int k = 0; k < n; k++) {
            if (k != j) denom += sim[j][k];
          }
          if (denom > 0) {
            sum += sim[i][j] * scores[j] / denom;
          }
        }
        newScores[i] = (1 - damping) + damping * sum;
      }
      for (int i = 0; i < n; i++) {
        scores[i] = newScores[i];
      }
    }

    // Top 3 by score, sorted by original order
    final List<int> indices =
        List<int>.generate(n, (int i) => i);
    indices.sort(
        (int a, int b) => scores[b].compareTo(scores[a]));
    final List<int> top = indices.take(3).toList()..sort();

    final StringBuffer buf = StringBuffer();
    for (final int idx in top) {
      if (buf.isNotEmpty) buf.write('\n');
      buf.write('• ${sentences[idx].trim()}');
    }
    return buf.toString();
  }

  static List<String> _splitSentences(String text) {
    return text
        .split(RegExp(r'[.!?]\s+'))
        .where((String s) => s.trim().isNotEmpty)
        .toList();
  }

  static Set<String> _tokenize(String sentence) {
    final String cleaned = sentence
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), '');
    return cleaned
        .split(RegExp(r'\s+'))
        .where((String w) =>
            w.isNotEmpty && !_stopWords.contains(w))
        .toSet();
  }

  static double _jaccard(Set<String> a, Set<String> b) {
    if (a.isEmpty || b.isEmpty) return 0.0;
    final int intersection = a.intersection(b).length;
    final int union = a.union(b).length;
    if (union == 0) return 0.0;
    return intersection / union;
  }
}
