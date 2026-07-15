// lib/core/utils/smart_tagger.dart

class SmartTagger {
  const SmartTagger._();

  static const Map<String, List<String>> _tagRules =
      <String, List<String>>{
    'receipt': <String>[
      '₹', '\$', '€', 'total', 'amount', 'invoice',
      'order', 'subtotal', 'tax', 'grand total',
      'bill', 'payment',
    ],
    'credentials': <String>[
      'password', 'wifi', 'username', 'login', 'otp',
      'pin', 'passcode', 'ssid', 'network key',
    ],
    'travel': <String>[
      'pnr', 'flight', 'boarding', 'hotel', 'booking',
      'check-in', 'departure', 'arrival', 'terminal',
      'gate',
    ],
    'code': <String>[
      'function', 'import', 'class', 'def ', '=>',
      'const', 'var', 'let', 'return', 'async',
      'await', 'flutter', 'widget',
    ],
    'recipe': <String>[
      'ingredients', 'recipe', 'cook', 'bake', 'serves',
      'prep time', 'cook time', 'cups', 'tbsp', 'tsp',
    ],
    'meme': <String>[
      'lol', 'lmao', 'rofl', 'meme', 'funny',
      'haha', 'xd', '💀', '😂', '🤣',
    ],
    'temporary': <String>[
      'otp', 'code', 'valid for', 'expires',
      'expires in', 'one-time', 'verification code',
      'temporary',
    ],
    'document': <String>[
      'pdf', 'document', 'agreement', 'contract',
      'terms', 'policy', 'certificate', 'report',
    ],
  };

  static List<String> tag(String text) {
    if (text.trim().isEmpty) return <String>['other'];

    final String lower = text.toLowerCase();
    final List<String> tags = <String>[];

    for (final MapEntry<String, List<String>> entry
        in _tagRules.entries) {
      int count = 0;
      for (final String keyword in entry.value) {
        if (lower.contains(keyword)) {
          count++;
        }
      }
      if (count >= 4) {
        tags.add('⭐${entry.key}');
      } else if (count >= 2) {
        tags.add(entry.key);
      }
    }

    if (tags.isEmpty) return <String>['other'];
    return tags;
  }
}
