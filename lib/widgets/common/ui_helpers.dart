import 'package:flutter/material.dart';

Color? getRowColor({
  required BuildContext context,
  required bool isZebra,
  bool isDeleted = false,
  bool isHighlighted = false,
}) {
  if (isDeleted) {
    return Theme.of(context).colorScheme.error.withAlpha((255 * 0.05).round());
  }
  if (isHighlighted) {
    return Theme.of(context)
        .colorScheme
        .primaryContainer
        .withAlpha((255 * 0.3).round());
  }
  if (isZebra) {
    return Theme.of(context)
        .colorScheme
        .surfaceContainerHighest
        .withAlpha((255 * 0.5).round());
  }
  return null;
}
