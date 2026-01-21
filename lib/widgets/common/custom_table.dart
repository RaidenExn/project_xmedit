import 'package:flutter/material.dart';
import 'package:project_xmedit/widgets/common/ui_helpers.dart';

class CustomTableHeader extends StatelessWidget {
  final List<Widget> children;
  const CustomTableHeader({super.key, required this.children});

  @override
  Widget build(BuildContext context) => Container(
        height: 28,
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
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
        .onSurface
        .withValues(alpha: 0.05); // Subtle hover overlay

    final effectiveColor = _isHovered
        ? Color.alphaBlend(hoverColor, baseColor ?? Colors.transparent)
        : baseColor;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Container(
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        color: effectiveColor,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: widget.children,
        ),
      ),
    );
  }
}
