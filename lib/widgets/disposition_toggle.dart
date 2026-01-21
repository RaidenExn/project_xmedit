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
    return Container(
      height: 32,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildOption(context, 'PRODUCTION', 'PROD', Colors.green),
          _buildOption(context, 'TEST', 'TEST', Colors.orange),
        ],
      ),
    );
  }

  Widget _buildOption(
      BuildContext context, String optionValue, String label, Color color) {
    final isSelected = value == optionValue;
    return InkWell(
      onTap: () => onChanged(optionValue),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.2) : null,
          borderRadius: BorderRadius.circular(6),
          border: isSelected
              ? Border.all(color: color.withValues(alpha: 0.5))
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isSelected
                ? color
                : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
