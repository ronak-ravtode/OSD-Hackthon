// lib/core/utils/action_extractor.dart

import 'package:flutter/material.dart';

enum ActionType { url, phone, email, tracking, otp, unknown }

class ActionItem {
  final ActionType type;
  final String value;
  final String label;
  final IconData icon;

  const ActionItem({
    required this.type,
    required this.value,
    required this.label,
    required this.icon,
  });
}

class ActionExtractor {
  const ActionExtractor._();

  static final RegExp _urlRegex = RegExp(
    r'https?://[^\s<>"{}|\\^\[\]`]+',
  );
  static final RegExp _phoneRegex = RegExp(
    r'(?:\+91\s?)?[6-9]\d{9}',
  );
  static final RegExp _emailRegex = RegExp(
    r'[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}',
  );
  static final RegExp _trackingRegex = RegExp(
    r'\b[A-Z]{2}\d{9}[A-Z]{2}\b',
  );
  static final RegExp _otpRegex = RegExp(
    r'\b\d{4,6}\b',
  );

  static const Set<String> _otpKeywords = <String>{
    'otp', 'code', 'verification', 'verify', 'pin',
  };

  static List<ActionItem> extract(String text) {
    final List<ActionItem> items = <ActionItem>[];

    for (final RegExpMatch m in _urlRegex.allMatches(text)) {
      items.add(ActionItem(
        type: ActionType.url,
        value: m.group(0)!,
        label: 'Open Link',
        icon: Icons.link,
      ));
    }

    for (final RegExpMatch m
        in _emailRegex.allMatches(text)) {
      items.add(ActionItem(
        type: ActionType.email,
        value: m.group(0)!,
        label: 'Copy Email',
        icon: Icons.email,
      ));
    }

    for (final RegExpMatch m
        in _phoneRegex.allMatches(text)) {
      items.add(ActionItem(
        type: ActionType.phone,
        value: m.group(0)!,
        label: 'Copy Number',
        icon: Icons.phone,
      ));
    }

    for (final RegExpMatch m
        in _trackingRegex.allMatches(text)) {
      items.add(ActionItem(
        type: ActionType.tracking,
        value: m.group(0)!,
        label: 'Copy Tracking',
        icon: Icons.local_shipping,
      ));
    }

    // OTPs: only near keywords
    final String lower = text.toLowerCase();
    final bool hasOtpKeyword =
        _otpKeywords.any((String k) => lower.contains(k));
    if (hasOtpKeyword) {
      for (final RegExpMatch m
          in _otpRegex.allMatches(text)) {
        items.add(ActionItem(
          type: ActionType.otp,
          value: m.group(0)!,
          label: 'Copy OTP',
          icon: Icons.pin,
        ));
      }
    }

    return items;
  }
}
