import 'package:flutter/material.dart';
import 'package:project_xmedit/models/validation_result.dart';

/// Visual indicator for validation errors/warnings
class ValidationIndicator extends StatelessWidget {
  final ValidationError? error;
  final double size;

  const ValidationIndicator({
    super.key,
    this.error,
    this.size = 20,
  });

  @override
  Widget build(BuildContext context) {
    if (error == null) return const SizedBox.shrink();

    final color = _getColor(context);
    final icon = _getIcon();

    return Tooltip(
      message: _getTooltipMessage(),
      child: Icon(
        icon,
        color: color,
        size: size,
      ),
    );
  }

  Color _getColor(BuildContext context) {
    switch (error!.severity) {
      case ValidationSeverity.error:
        return Theme.of(context).colorScheme.error;
      case ValidationSeverity.warning:
        return Colors.orange;
      case ValidationSeverity.info:
        return Colors.blue;
    }
  }

  IconData _getIcon() {
    switch (error!.severity) {
      case ValidationSeverity.error:
        return Icons.error;
      case ValidationSeverity.warning:
        return Icons.warning;
      case ValidationSeverity.info:
        return Icons.info;
    }
  }

  String _getTooltipMessage() {
    final buffer = StringBuffer(error!.message);
    if (error!.suggestion != null) {
      buffer.write('\n💡 ${error!.suggestion}');
    }
    return buffer.toString();
  }
}

/// Text field with validation support
class ValidatedTextField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final ValidationError? validationError;
  final ValueChanged<String>? onChanged;
  final bool enabled;
  final int? maxLines;
  final TextInputType? keyboardType;

  const ValidatedTextField({
    required this.label,
    required this.controller,
    this.validationError,
    this.onChanged,
    this.enabled = true,
    this.maxLines = 1,
    this.keyboardType,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasError = validationError != null;

    return TextField(
      controller: controller,
      onChanged: onChanged,
      enabled: enabled,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderSide: BorderSide(
            color:
                hasError ? _getBorderColor(theme) : theme.colorScheme.outline,
            width: hasError ? 2 : 1,
          ),
        ),
        enabledBorder: hasError
            ? OutlineInputBorder(
                borderSide: BorderSide(
                  color: _getBorderColor(theme),
                  width: 2,
                ),
              )
            : null,
        focusedBorder: hasError
            ? OutlineInputBorder(
                borderSide: BorderSide(
                  color: _getBorderColor(theme),
                  width: 2,
                ),
              )
            : null,
        suffixIcon:
            hasError ? ValidationIndicator(error: validationError) : null,
      ),
    );
  }

  Color _getBorderColor(ThemeData theme) {
    if (validationError == null) return theme.colorScheme.outline;

    switch (validationError!.severity) {
      case ValidationSeverity.error:
        return theme.colorScheme.error;
      case ValidationSeverity.warning:
        return Colors.orange;
      case ValidationSeverity.info:
        return Colors.blue;
    }
  }
}

/// Summary panel showing all validation errors
class ValidationSummaryPanel extends StatelessWidget {
  final ValidationResult? validationResult;
  final VoidCallback? onDismiss;

  const ValidationSummaryPanel({
    super.key,
    required this.validationResult,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    if (validationResult == null || validationResult!.errors.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final hasErrors = validationResult!.criticalErrors.isNotEmpty;

    return Card(
      color: hasErrors
          ? theme.colorScheme.errorContainer
          : theme.colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(
                  hasErrors ? Icons.error : Icons.warning,
                  color: hasErrors
                      ? theme.colorScheme.error
                      : theme.colorScheme.onSecondaryContainer,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _getSummaryText(),
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: hasErrors
                          ? theme.colorScheme.error
                          : theme.colorScheme.onSecondaryContainer,
                    ),
                  ),
                ),
                if (onDismiss != null)
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: onDismiss,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            ...validationResult!.errors.map((error) => Padding(
                  padding: const EdgeInsets.only(left: 28, top: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.circle,
                        size: 6,
                        color: theme.colorScheme.onSecondaryContainer,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${error.field}: ${error.message}',
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  String _getSummaryText() {
    final errorCount = validationResult!.criticalErrors.length;
    final warningCount = validationResult!.warnings.length;

    if (errorCount > 0 && warningCount > 0) {
      return '$errorCount ${errorCount == 1 ? 'error' : 'errors'}, $warningCount ${warningCount == 1 ? 'warning' : 'warnings'}';
    } else if (errorCount > 0) {
      return '$errorCount ${errorCount == 1 ? 'error' : 'errors'} found';
    } else {
      return '$warningCount ${warningCount == 1 ? 'warning' : 'warnings'} found';
    }
  }
}
