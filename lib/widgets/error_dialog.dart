import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Enhanced error dialog with user-friendly messages and technical details
class ErrorDialog extends StatelessWidget {
  final String title;
  final String message;
  final String? technicalDetails;
  final String? suggestion;
  final IconData? icon;

  const ErrorDialog({
    required this.title,
    required this.message,
    this.technicalDetails,
    this.suggestion,
    this.icon,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Row(
        children: [
          Icon(
            icon ?? Icons.error,
            color: theme.colorScheme.error,
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(title)),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message),
            if (suggestion != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.lightbulb,
                      size: 20,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        suggestion!,
                        style: TextStyle(
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (technicalDetails != null) ...[
              const SizedBox(height: 16),
              ExpansionTile(
                title: const Text('Technical Details'),
                tilePadding: EdgeInsets.zero,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: SelectableText(
                      technicalDetails!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
      actions: [
        if (technicalDetails != null)
          TextButton.icon(
            icon: const Icon(Icons.copy, size: 18),
            label: const Text('Copy Details'),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: technicalDetails!));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Technical details copied to clipboard'),
                  behavior: SnackBarBehavior.floating,
                  width: 300,
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }

  /// Show error dialog
  static Future<void> show(
    BuildContext context, {
    required String title,
    required String message,
    String? technicalDetails,
    String? suggestion,
    IconData? icon,
  }) {
    return showDialog(
      context: context,
      builder: (context) => ErrorDialog(
        title: title,
        message: message,
        technicalDetails: technicalDetails,
        suggestion: suggestion,
        icon: icon,
      ),
    );
  }
}

/// Service for centralized error handling
class ErrorHandler {
  /// Handle an error with user-friendly dialog
  static void handleError(
    BuildContext context,
    dynamic error,
    StackTrace? stackTrace, {
    String? userMessage,
    String? suggestion,
  }) {
    final errorInfo = _parseError(error);

    ErrorDialog.show(
      context,
      title: errorInfo.title,
      message: userMessage ?? errorInfo.message,
      technicalDetails: '${error.toString()}\n\n${stackTrace ?? ''}',
      suggestion: suggestion ?? errorInfo.suggestion,
      icon: errorInfo.icon,
    );
  }

  /// Parse error into user-friendly information
  static _ErrorInfo _parseError(dynamic error) {
    final errorStr = error.toString().toLowerCase();

    if (errorStr.contains('xml') || errorStr.contains('parse')) {
      return _ErrorInfo(
        title: 'XML Parsing Error',
        message: 'The XML file appears to be invalid or corrupted.',
        suggestion:
            'Try opening a different file or check if the file is properly formatted.',
        icon: Icons.code,
      );
    }

    if (errorStr.contains('file') || errorStr.contains('path')) {
      return _ErrorInfo(
        title: 'File Error',
        message: 'Unable to access the file.',
        suggestion:
            'Ensure the file exists and you have permission to access it.',
        icon: Icons.folder_open,
      );
    }

    if (errorStr.contains('permission') || errorStr.contains('denied')) {
      return _ErrorInfo(
        title: 'Permission Denied',
        message: 'You don\'t have permission to perform this action.',
        suggestion:
            'Check file permissions or try running with administrator privileges.',
        icon: Icons.lock,
      );
    }

    if (errorStr.contains('network') || errorStr.contains('connection')) {
      return _ErrorInfo(
        title: 'Network Error',
        message: 'A network connection error occurred.',
        suggestion: 'Check your internet connection and try again.',
        icon: Icons.wifi_off,
      );
    }

    // Default error
    return _ErrorInfo(
      title: 'Error',
      message: 'An unexpected error occurred.',
      suggestion:
          'Try restarting the application. If the problem persists, contact support.',
      icon: Icons.error,
    );
  }
}

class _ErrorInfo {
  final String title;
  final String message;
  final String? suggestion;
  final IconData icon;

  _ErrorInfo({
    required this.title,
    required this.message,
    this.suggestion,
    required this.icon,
  });
}
