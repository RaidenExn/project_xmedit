import 'package:flutter/material.dart';

class CodeDescriptionText extends StatelessWidget {
  final String shortDescription;
  final String fullDescription;
  final TextStyle? style;
  final bool isLoading;
  final String loadingText;
  final String emptyText;
  final int maxLines;
  final TextAlign textAlign;
  final bool enableTooltip;

  const CodeDescriptionText({
    super.key,
    required this.shortDescription,
    required this.fullDescription,
    this.style,
    this.isLoading = false,
    this.loadingText = 'Loading...',
    this.emptyText = 'N/A',
    this.maxLines = 1,
    this.textAlign = TextAlign.left,
    this.enableTooltip = true,
  });

  @override
  Widget build(BuildContext context) {
    final safeShort = shortDescription.trim();
    final safeFull = fullDescription.trim();
    final text =
        isLoading ? loadingText : (safeShort.isEmpty ? emptyText : safeShort);
    final tooltip = safeFull.isEmpty ? text : safeFull;

    final textWidget = Text(
      text,
      style: style,
      overflow: TextOverflow.ellipsis,
      maxLines: maxLines,
      textAlign: textAlign,
    );
    if (!enableTooltip) return textWidget;
    return Tooltip(
      message: tooltip,
      child: textWidget,
    );
  }
}
