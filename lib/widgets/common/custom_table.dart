import 'package:flutter/material.dart';
import 'package:project_xmedit/widgets/common/ui_helpers.dart';

class CustomTableHeader extends StatelessWidget {
  final List<Widget> children;
  const CustomTableHeader({super.key, required this.children});

  @override
  Widget build(BuildContext context) => Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 14.0),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHigh,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
        ),
        child: Row(
          children: children,
        ),
      );
}

class CustomDataRow extends StatefulWidget {
  final List<Widget> children;
  final bool isZebra;
  final bool isDeleted;
  final bool isHighlighted;

  const CustomDataRow({
    super.key,
    required this.children,
    this.isZebra = false,
    this.isDeleted = false,
    this.isHighlighted = false,
  });

  @override
  State<CustomDataRow> createState() => _CustomDataRowState();
}

class _CustomDataRowState extends State<CustomDataRow> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final baseColor = getRowColor(
      context: context,
      isZebra: widget.isZebra,
      isDeleted: widget.isDeleted,
      isHighlighted: widget.isHighlighted,
    );

    // If hovered, overlay a subtle primary tint or darken/lighten slightly
    final hoverColor = Theme.of(context)
        .colorScheme
        .primary
        .withValues(alpha: 0.07); // Subtle hover overlay

    final effectiveColor = _isHovered
        ? Color.alphaBlend(hoverColor, baseColor ?? Colors.transparent)
        : baseColor;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutCubic,
        constraints: const BoxConstraints(minHeight: 42),
        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 4.0),
        decoration: BoxDecoration(
          color: effectiveColor,
          border: Border(
            bottom: BorderSide(
              color: Theme.of(context).colorScheme.outlineVariant.withAlpha(55),
            ),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: widget.children,
        ),
      ),
    );
  }
}
