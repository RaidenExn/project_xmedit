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
    final theme = Theme.of(context);
    final borderColor = validationError != null
        ? theme.colorScheme.error
        : theme.colorScheme.outlineVariant.withAlpha(150);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 34,
          child: TextFormField(
            controller: controller,
            enabled: enabled,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              isDense: true,
              hintText: '1',
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              filled: true,
              fillColor: enabled
                  ? theme.colorScheme.surfaceContainerLow
                  : theme.colorScheme.surfaceContainerLowest,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: theme.colorScheme.primary),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: theme.colorScheme.error),
              ),
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
            ],
          ),
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
        SizedBox(
          height: 34,
          child: TextFormField(
            controller: controller,
            enabled: isEnabled,
            textAlign: TextAlign.right,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color:
                  isEnabled ? theme.colorScheme.onSurface : theme.disabledColor,
            ),
            decoration: InputDecoration(
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              filled: true,
              fillColor: isEnabled
                  ? theme.colorScheme.surfaceContainerLow
                  : theme.colorScheme.surfaceContainerLowest,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: hasError
                      ? theme.colorScheme.error
                      : theme.colorScheme.outlineVariant.withAlpha(150),
                  width: hasError ? 1.2 : 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: theme.colorScheme.primary),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: theme.colorScheme.error),
              ),
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
        SizedBox(
          height: 34,
          child: TextFormField(
            controller: controller,
            enabled: isEnabled,
            textAlign: TextAlign.left,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
              color:
                  isEnabled ? theme.colorScheme.onSurface : theme.disabledColor,
            ),
            decoration: InputDecoration(
              isDense: true,
              hintText: hintText,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              filled: true,
              fillColor: isEnabled
                  ? theme.colorScheme.surfaceContainerLow
                  : theme.colorScheme.surfaceContainerLowest,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: hasError
                      ? theme.colorScheme.error
                      : theme.colorScheme.outlineVariant.withAlpha(150),
                  width: hasError ? 1.2 : 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: theme.colorScheme.primary),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: theme.colorScheme.error),
              ),
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
