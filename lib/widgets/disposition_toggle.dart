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
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant.withAlpha(170)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildSegment(
            context: context,
            segmentValue: 'PRODUCTION',
            label: 'Production',
            icon: Icons.cloud_done_rounded,
            selectedValue: normalizedValue,
            selectedBg: colorScheme.primaryContainer,
            selectedFg: colorScheme.onPrimaryContainer,
          ),
          const SizedBox(width: 4),
          _buildSegment(
            context: context,
            segmentValue: 'TEST',
            label: 'Test',
            icon: Icons.science_rounded,
            selectedValue: normalizedValue,
            selectedBg: colorScheme.tertiaryContainer,
            selectedFg: colorScheme.onTertiaryContainer,
          ),
        ],
      ),
    );
  }

  Widget _buildSegment({
    required BuildContext context,
    required String segmentValue,
    required String label,
    required IconData icon,
    required String selectedValue,
    required Color selectedBg,
    required Color selectedFg,
  }) {
    final theme = Theme.of(context);
    final isSelected = segmentValue == selectedValue;
    final colorScheme = theme.colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => onChanged(segmentValue),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: isSelected ? selectedBg : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? selectedFg.withAlpha(70)
                  : colorScheme.outlineVariant.withAlpha(60),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? selectedFg : colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isSelected ? selectedFg : colorScheme.onSurfaceVariant,
                  letterSpacing: 0.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _normalizeDisposition(String input) {
    final raw = input.trim().toUpperCase();
    if (raw == 'TEST') return 'TEST';
    if (raw == 'PROD' || raw == 'PRODUCTION') return 'PRODUCTION';
    return 'PRODUCTION';
  }
}
