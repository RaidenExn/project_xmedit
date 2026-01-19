import 'package:flutter/material.dart';

class SelectionCard extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final EdgeInsetsGeometry? padding;

  const SelectionCard({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Color cardColor = isSelected
        ? theme.colorScheme.secondaryContainer
        : theme.colorScheme.surfaceContainer;
    final Color textColor = isSelected
        ? theme.colorScheme.onSecondaryContainer
        : theme.colorScheme.onSurface;

    final Color borderColor = isSelected
        ? theme.colorScheme.secondaryContainer
        : theme.colorScheme.outlineVariant.withAlpha(128);

    return Padding(
      padding: padding ?? EdgeInsets.zero,
      child: Card(
        color: cardColor,
        elevation: 0,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
          side: BorderSide(
            color: borderColor,
            width: 1.0,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          child: ListTile(
            dense: true,
            title: Text(
              label,
              textAlign: TextAlign.center,
              style: theme.textTheme.labelLarge?.copyWith(
                color: textColor,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
          ),
        ),
      ),
    );
  }
}
