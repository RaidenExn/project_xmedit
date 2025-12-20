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

class CustomDataRow extends StatelessWidget {
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
  Widget build(BuildContext context) => Container(
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        color: getRowColor(
          context: context,
          isZebra: isZebra,
          isDeleted: isDeleted,
          isHighlighted: isHighlighted,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: children,
        ),
      );
}
