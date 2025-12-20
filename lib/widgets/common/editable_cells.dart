import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class EditableQuantityCell extends StatelessWidget {
  final TextEditingController controller;
  final bool enabled;

  const EditableQuantityCell(
      {super.key, required this.controller, required this.enabled});

  @override
  Widget build(BuildContext context) => TextFormField(
        controller: controller,
        enabled: enabled,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 14),
        decoration: const InputDecoration(
          border: InputBorder.none,
          isDense: true,
          hintText: '1',
          contentPadding: EdgeInsets.zero,
        ),
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
        ],
      );
}

class EditableNumberCell extends StatelessWidget {
  final TextEditingController controller;
  final bool enabled;

  const EditableNumberCell(
      {super.key, required this.controller, required this.enabled});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEnabled = enabled;

    return Container(
      decoration: BoxDecoration(
        color: isEnabled
            ? theme.colorScheme.surfaceContainerHighest
                .withAlpha((255 * 0.8).round())
            : theme.colorScheme.surfaceContainerHighest
                .withAlpha((255 * 0.4).round()),
        borderRadius: BorderRadius.circular(6.0),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: TextFormField(
        controller: controller,
        enabled: isEnabled,
        textAlign: TextAlign.right,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontSize: 14,
          color: isEnabled ? theme.colorScheme.onSurface : theme.disabledColor,
        ),
        decoration: const InputDecoration(
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.symmetric(vertical: 6),
        ),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
        ],
      ),
    );
  }
}

class EditableStringCell extends StatelessWidget {
  final TextEditingController controller;
  final bool enabled;
  final String? hintText;

  const EditableStringCell({
    super.key,
    required this.controller,
    required this.enabled,
    this.hintText,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEnabled = enabled;

    return Container(
      decoration: BoxDecoration(
        color: isEnabled
            ? theme.colorScheme.surfaceContainerHighest
                .withAlpha((255 * 0.8).round())
            : theme.colorScheme.surfaceContainerHighest
                .withAlpha((255 * 0.4).round()),
        borderRadius: BorderRadius.circular(6.0),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: TextFormField(
        controller: controller,
        enabled: isEnabled,
        textAlign: TextAlign.left,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontSize: 12, // Slightly smaller font for ID
          color: isEnabled ? theme.colorScheme.onSurface : theme.disabledColor,
        ),
        decoration: InputDecoration(
          border: InputBorder.none,
          isDense: true,
          hintText: hintText,
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
        ),
      ),
    );
  }
}
