import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:project_xmedit/models/validation_result.dart';
import 'package:project_xmedit/widgets/validation_widgets.dart';

class FinancialInputField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String? difference;
  final ValidationError? validationError;
  final VoidCallback onChanged;

  const FinancialInputField({
    super.key,
    required this.label,
    required this.controller,
    required this.onChanged,
    this.difference,
    this.validationError,
  });

  @override
  Widget build(BuildContext context) {
    final hasDiff = difference != null && difference!.isNotEmpty;
    final theme = Theme.of(context);
    final borderColor = hasDiff
        ? theme.colorScheme.error
        : theme.colorScheme.outlineVariant.withAlpha(150);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 94,
          child: Text(label, style: theme.textTheme.titleSmall),
        ),
        Expanded(
          child: SizedBox(
            height: 36,
            child: TextFormField(
              controller: controller,
              onChanged: (_) => onChanged(),
              textAlign: TextAlign.right,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
              decoration: InputDecoration(
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerLow,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: borderColor,
                    width: hasDiff ? 1.2 : 1,
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
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
              ],
            ),
          ),
        ),
        if (hasDiff)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6.0),
            child: Text(
              difference!,
              style: TextStyle(
                color: theme.colorScheme.error,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        if (validationError != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: ValidationIndicator(error: validationError!, size: 16),
          ),
        IconButton(
          icon: const Icon(Icons.copy_rounded, size: 16),
          tooltip: 'Copy value',
          onPressed: () {
            Clipboard.setData(ClipboardData(text: controller.text));
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('Copied to clipboard'),
                width: 200,
                behavior: SnackBarBehavior.floating));
          },
          splashRadius: 18,
          visualDensity: VisualDensity.compact,
        ),
      ],
    );
  }
}
