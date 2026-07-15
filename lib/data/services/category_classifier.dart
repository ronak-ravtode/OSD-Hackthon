// lib/data/services/category_classifier.dart

class CategoryClassifier {
  static const Map<String, List<String>> _keywords = <String, List<String>>{
    'receipts_invoices': <String>[
      'receipt', 'invoice', 'bill', 'payment', 'amount', 'total', 'tax', 'gst', 'vat', 
      'visa', 'mastercard', 'amex', 'transaction', 'cashier', 'subtotal', 'paid', 
      'remittance', 'invoice number', 'receipt number', 'rs.', 'usd', '\$', 'eur', 'purchase',
      'order summary', 'checkout', 'billing', 'merchant'
    ],
    'screenshots': <String>[
      'screenshot', 'screen_shot', 'status bar', 'battery percent', 'wifi signal', 
      'cellular data', 'am/pm', 'notifications', 'screenshot captured', 'low battery'
    ],
    'documents': <String>[
      'contract', 'agreement', 'signature', 'date', 'form', 'application', 'hereby', 
      'pdf', 'letter', 'clause', 'terms', 'conditions', 'policy', 'witness', 'notary', 
      'memorandum', 'statute', 'charter', 'report', 'certificate', 'resume', 'cv'
    ],
    'identification': <String>[
      'passport', 'id card', 'driver license', 'driver\'s license', 'identity card', 
      'pan card', 'aadhaar', 'ssn', 'national id', 'dob', 'birth date', 'gender', 
      'licence', 'expiry date', 'issue date', 'birthplace', 'nationality', 'citizenship'
    ],
    'memes_social': <String>[
      'meme', 'twitter', 'instagram', 'facebook', 'reddit', 'like', 'retweet', 
      'follow', 'comment', 'share', 'post', 'lol', 'funny', 'subreddit', 'tweet', 
      'retweets', 'likes', '@', 'tumblr', 'tiktok'
    ],
    'travel_tickets': <String>[
      'boarding pass', 'ticket', 'flight', 'train', 'seat', 'gate', 'passenger', 
      'booking', 'pnr', 'departure', 'arrival', 'hotel', 'check-in', 'itinerary', 
      'airline', 'boarding time', 'class: ', 'coach: ', 'railway', 'reservation'
    ],
    'food_menus': <String>[
      'menu', 'appetizer', 'salad', 'pizza', 'burger', 'pasta', 'dessert', 'beverage', 
      'price', 'chicken', 'beef', 'food', 'recipe', 'ingredients', 'cuisine', 
      'beverages', 'drinks', 'starters', 'main course', 'soups', 'restaurant'
    ],
    'code_tech': <String>[
      'class ', 'void ', 'function ', 'import ', 'const ', 'var ', 'let ', 'error', 
      'exception', 'terminal', 'console', 'diagram', 'git', 'status', 'commit', 
      'public ', 'private ', 'static ', 'def ', 'return ', 'struct ', 'impl ', 
      'include', 'null', 'undefined', 'compile', 'debugging', 'database', 'schema'
    ],
    'people_portraits': <String>[
      'selfie', 'portrait', 'face', 'smile', 'group photo', 'people', 'portrait photo',
      'friend', 'family', 'person'
    ],
    'nature_scenery': <String>[
      'scenery', 'mountain', 'beach', 'lake', 'forest', 'animal', 'plant', 'garden', 
      'flower', 'tree', 'river', 'wildlife', 'ocean', 'sunset', 'sunrise', 'landscape',
      'nature', 'outdoor'
    ],
  };

  static String classify(String text, String filePath) {
    final String cleanText = text.toLowerCase();
    final String cleanPath = filePath.toLowerCase();

    String bestCategory = 'other';
    int maxScore = 0;

    for (final MapEntry<String, List<String>> entry in _keywords.entries) {
      final String category = entry.key;
      final List<String> words = entry.value;
      int score = 0;

      for (final String word in words) {
        final int matches = _countOccurrences(cleanText, word);
        score += matches;
      }

      if (category == 'screenshots' && 
          (cleanPath.contains('screenshot') || cleanPath.contains('screen_shot'))) {
        score += 3;
      }

      if (score > maxScore) {
        maxScore = score;
        bestCategory = category;
      }
    }

    if (bestCategory == 'other' && 
        (cleanPath.contains('screenshot') || cleanPath.contains('screen_shot'))) {
      return 'screenshots';
    }

    return bestCategory;
  }

  static int _countOccurrences(String source, String word) {
    if (word.isEmpty) return 0;
    int count = 0;
    int index = source.indexOf(word);
    while (index != -1) {
      count++;
      index = source.indexOf(word, index + word.length);
    }
    return count;
  }
}
