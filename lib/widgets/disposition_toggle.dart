import 'package:flutter/material.dart';

class DispositionToggle extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const DispositionToggle({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final normalizedValue = _normalizeDisposition(value);
    final selected = <String>{normalizedValue};
    final colorScheme = Theme.of(context).colorScheme;

    return SegmentedButton<String>(
      showSelectedIcon: false,
      style: ButtonStyle(
        visualDensity: VisualDensity.compact,
        padding: WidgetStateProperty.all(
          const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        ),
        textStyle: WidgetStateProperty.all(
          const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        ),
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.onSecondaryContainer;
          }
          return colorScheme.onSurfaceVariant;
        }),
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.secondaryContainer;
          }
          return colorScheme.surfaceContainerHighest;
        }),
      ),
      segments: const [
        ButtonSegment<String>(
          value: 'PRODUCTION',
          icon: Icon(Icons.cloud_done_outlined, size: 16),
          label: Text('Production'),
        ),
        ButtonSegment<String>(
          value: 'TEST',
          icon: Icon(Icons.science_outlined, size: 16),
          label: Text('Test'),
        ),
      ],
      selected: selected,
      onSelectionChanged: (selection) {
        if (selection.isNotEmpty) {
          onChanged(selection.first);
        }
      },
      emptySelectionAllowed: false,
      multiSelectionEnabled: false,
    );
  }

  String _normalizeDisposition(String input) {
    final raw = input.trim().toUpperCase();
    if (raw == 'TEST') return 'TEST';
    if (raw == 'PROD' || raw == 'PRODUCTION') return 'PRODUCTION';
    return 'PRODUCTION';
  }
}
