// lib/core/utils/redaction_engine.dart

enum PiiType { creditCard, aadhaar, phone, email, password }

class PiiMatch {
  final PiiType type;
  final String value;
  final String label;

  const PiiMatch({
    required this.type,
    required this.value,
    required this.label,
  });
}

class RedactionEngine {
  const RedactionEngine._();

  static final RegExp _emailRegex = RegExp(
    r'[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}',
  );
  static final RegExp _phoneRegex = RegExp(
    r'(?:\+91\s?)?[6-9]\d{9}',
  );
  static final RegExp _aadhaarRegex = RegExp(
    r'\b[2-9]\d{11}\b',
  );
  static final RegExp _digitSeqRegex = RegExp(
    r'\b\d{13,19}\b',
  );
  static final RegExp _passwordRegex = RegExp(
    r'(?:password|pass|pwd)\s*:\s*.+',
    caseSensitive: false,
  );

  static List<PiiMatch> detect(String text) {
    final List<PiiMatch> matches = <PiiMatch>[];

    // Credit cards (Luhn check)
    for (final RegExpMatch m
        in _digitSeqRegex.allMatches(text)) {
      final String digits = m.group(0)!;
      if (_passesLuhn(digits)) {
        matches.add(PiiMatch(
          type: PiiType.creditCard,
          value: digits,
          label: 'Credit Card',
        ));
      }
    }

    // Aadhaar numbers
    for (final RegExpMatch m
        in _aadhaarRegex.allMatches(text)) {
      matches.add(PiiMatch(
        type: PiiType.aadhaar,
        value: m.group(0)!,
        label: 'Aadhaar',
      ));
    }

    // Phone numbers
    for (final RegExpMatch m
        in _phoneRegex.allMatches(text)) {
      matches.add(PiiMatch(
        type: PiiType.phone,
        value: m.group(0)!,
        label: 'Phone',
      ));
    }

    // Emails
    for (final RegExpMatch m
        in _emailRegex.allMatches(text)) {
      matches.add(PiiMatch(
        type: PiiType.email,
        value: m.group(0)!,
        label: 'Email',
      ));
    }

    // Password lines
    for (final RegExpMatch m
        in _passwordRegex.allMatches(text)) {
      matches.add(PiiMatch(
        type: PiiType.password,
        value: m.group(0)!,
        label: 'Password',
      ));
    }

    return matches;
  }

  static bool _passesLuhn(String digits) {
    int sum = 0;
    bool alternate = false;
    for (int i = digits.length - 1; i >= 0; i--) {
      int n = int.parse(digits[i]);
      if (alternate) {
        n *= 2;
        if (n > 9) n -= 9;
      }
      sum += n;
      alternate = !alternate;
    }
    return sum % 10 == 0;
  }

  static String redactText(String text) {
    String redacted = text;
    final List<PiiMatch> pii = detect(text);
    for (final PiiMatch match in pii) {
      redacted = redacted.replaceAll(
        match.value,
        '█' * match.value.length,
      );
    }
    return redacted;
  }
}
