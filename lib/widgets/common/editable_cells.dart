import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:project_xmedit/models/validation_result.dart';
import 'package:project_xmedit/widgets/validation_widgets.dart';

class EditableQuantityCell extends StatelessWidget {
  final TextEditingController controller;
  final bool enabled;
  final ValidationError? validationError;

  const EditableQuantityCell({
    super.key,
    required this.controller,
    required this.enabled,
    this.validationError,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextFormField(
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
        ),
        if (validationError != null)
          ValidationIndicator(error: validationError!, size: 12),
      ],
    );
  }
}

class EditableNumberCell extends StatelessWidget {
  final TextEditingController controller;
  final bool enabled;
  final ValidationError? validationError;

  const EditableNumberCell({
    super.key,
    required this.controller,
    required this.enabled,
    this.validationError,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEnabled = enabled;
    final hasError = validationError != null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          decoration: BoxDecoration(
            color: isEnabled
                ? theme.colorScheme.surfaceContainerHighest
                    .withAlpha((255 * 0.8).round())
                : theme.colorScheme.surfaceContainerHighest
                    .withAlpha((255 * 0.4).round()),
            borderRadius: BorderRadius.circular(6.0),
            border: hasError
                ? Border.all(color: theme.colorScheme.error, width: 1)
                : null,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: TextFormField(
            controller: controller,
            enabled: isEnabled,
            textAlign: TextAlign.right,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: 14,
              color:
                  isEnabled ? theme.colorScheme.onSurface : theme.disabledColor,
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
        ),
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: ValidationIndicator(error: validationError!, size: 12),
          ),
      ],
    );
  }
}

class EditableStringCell extends StatelessWidget {
  final TextEditingController controller;
  final bool enabled;
  final String? hintText;
  final ValidationError? validationError;

  const EditableStringCell({
    super.key,
    required this.controller,
    required this.enabled,
    this.hintText,
    this.validationError,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEnabled = enabled;
    final hasError = validationError != null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: isEnabled
                ? theme.colorScheme.surfaceContainerHighest
                    .withAlpha((255 * 0.8).round())
                : theme.colorScheme.surfaceContainerHighest
                    .withAlpha((255 * 0.4).round()),
            borderRadius: BorderRadius.circular(6.0),
            border: hasError
                ? Border.all(color: theme.colorScheme.error, width: 1)
                : null,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: TextFormField(
            controller: controller,
            enabled: isEnabled,
            textAlign: TextAlign.left,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: 12, // Slightly smaller font for ID
              color:
                  isEnabled ? theme.colorScheme.onSurface : theme.disabledColor,
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              isDense: true,
              hintText: hintText,
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
            ),
          ),
        ),
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(top: 2, left: 2),
            child: ValidationIndicator(error: validationError!, size: 12),
          ),
      ],
    );
  }
}
