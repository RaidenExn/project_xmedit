import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

/// Keyboard shortcuts help dialog
class ShortcutsHelpDialog extends StatelessWidget {
  const ShortcutsHelpDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final isMacOS = defaultTargetPlatform == TargetPlatform.macOS;
    final modifier = isMacOS ? 'Cmd' : 'Ctrl';
    final theme = Theme.of(context);

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.keyboard, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          const Text('Keyboard Shortcuts'),
        ],
      ),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _SectionHeader('File Operations'),
              _ShortcutRow('$modifier + O', 'Open file'),
              _ShortcutRow('$modifier + S', 'Save'),
              _ShortcutRow('$modifier + Shift + S', 'Save As'),
              _ShortcutRow('$modifier + W', 'Clear All / Close'),
              const SizedBox(height: 16),
              _SectionHeader('Edit Operations'),
              _ShortcutRow('$modifier + Z', 'Undo (Bulk Editor)'),
              _ShortcutRow('$modifier + Shift + Z', 'Redo (Bulk Editor)'),
              _ShortcutRow('$modifier + D', 'Delete Activity'),
              _ShortcutRow('$modifier + N', 'Add New Activity'),
              _ShortcutRow('$modifier + F', 'Search Diagnoses'),
              _ShortcutRow('$modifier + R', 'Reset to Original'),
              const SizedBox(height: 16),
              _SectionHeader('View Operations'),
              _ShortcutRow('$modifier + Shift + D', 'Toggle Dark Mode'),
              _ShortcutRow('F1', 'Show This Help'),
              const SizedBox(height: 16),
              _SectionHeader('Bulk Editor'),
              _ShortcutRow('$modifier + A', 'Select All Claims'),
              _ShortcutRow('$modifier + Shift + A', 'Deselect All'),
              _ShortcutRow('Delete', 'Delete Selected Claims'),
              const SizedBox(height: 16),
              _SectionHeader('Navigation'),
              _ShortcutRow('Tab', 'Next Field'),
              _ShortcutRow('Shift + Tab', 'Previous Field'),
              _ShortcutRow('Esc', 'Close Dialog'),
            ],
          ),
        ),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }

  /// Show shortcuts help dialog
  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (context) => const ShortcutsHelpDialog(),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }
}

class _ShortcutRow extends StatelessWidget {
  final String shortcut;
  final String description;

  const _ShortcutRow(this.shortcut, this.description);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: theme.colorScheme.outline),
            ),
            child: Text(
              shortcut,
              style: theme.textTheme.bodySmall?.copyWith(
                fontFamily: 'monospace',
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              description,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

/// Keyboard shortcut intents
class OpenFileIntent extends Intent {
  const OpenFileIntent();
}

class SaveFileIntent extends Intent {
  const SaveFileIntent();
}

class SaveAsIntent extends Intent {
  const SaveAsIntent();
}

class ClearAllIntent extends Intent {
  const ClearAllIntent();
}

class DeleteActivityIntent extends Intent {
  const DeleteActivityIntent();
}

class AddActivityIntent extends Intent {
  const AddActivityIntent();
}

class SearchDiagnosisIntent extends Intent {
  const SearchDiagnosisIntent();
}

class ResetIntent extends Intent {
  const ResetIntent();
}

class ToggleThemeIntent extends Intent {
  const ToggleThemeIntent();
}

class ShowShortcutsHelpIntent extends Intent {
  const ShowShortcutsHelpIntent();
}

class SelectAllIntent extends Intent {
  const SelectAllIntent();
}

class DeselectAllIntent extends Intent {
  const DeselectAllIntent();
}

class DeleteSelectedIntent extends Intent {
  const DeleteSelectedIntent();
}
