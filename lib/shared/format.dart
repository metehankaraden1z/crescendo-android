import 'dart:math' as math;

import 'package:flutter/painting.dart';

/// Scores are stored 1–10 and shown as 0.5–5 stars ("4.5").
String fmtScore(num? value) => value == null ? '–' : (value / 2).toStringAsFixed(1);

String fmtLength(int? ms) {
  if (ms == null || ms <= 0) return '';
  final seconds = (ms / 1000).round();
  return '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';
}

String plural(int n, String one, [String? many]) => '$n ${n == 1 ? one : (many ?? '${one}s')}';

/// Up to two initials for placeholder covers and avatars.
String initials(String text) {
  final words = text
      .replaceAll(RegExp(r'[^\p{L}\p{N} ]', unicode: true), ' ')
      .trim()
      .split(RegExp(r'\s+'))
      .where((w) => w.isNotEmpty)
      .toList();
  if (words.isEmpty) return '?';
  if (words.length == 1) return words.first.substring(0, math.min(2, words.first.length)).toUpperCase();
  return (words[0][0] + words[1][0]).toUpperCase();
}

/// A stable colour derived from a string, for placeholders that need to look distinct.
Color hueColor(String seed, {double saturation = 0.55, double lightness = 0.45}) {
  var hash = 0;
  for (final unit in seed.codeUnits) {
    hash = (hash * 31 + unit) & 0x7fffffff;
  }
  return HSLColor.fromAHSL(1, (hash % 360).toDouble(), saturation, lightness).toColor();
}

const _months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September',
  'October', 'November', 'December'];

String monthYear(int? epochSeconds) {
  if (epochSeconds == null) return '';
  final date = DateTime.fromMillisecondsSinceEpoch(epochSeconds * 1000);
  return '${_months[date.month - 1]} ${date.year}';
}
