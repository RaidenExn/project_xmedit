import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:project_xmedit/notifiers.dart';

class TotalsCard extends StatelessWidget {
  const TotalsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<ClaimDataNotifier>();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _FinancialInputRow(
          label: 'Gross:',
          controller: notifier.grossController,
          difference: notifier.grossDifference,
          onChanged: () => notifier.onTotalsEdited('gross'),
        ),
        const SizedBox(height: 4),
        _FinancialInputRow(
          label: 'PatientShare:',
          controller: notifier.patientShareController,
          onChanged: () => notifier.onTotalsEdited('pshare'),
        ),
        const SizedBox(height: 4),
        _FinancialInputRow(
          label: 'Net:',
          controller: notifier.netController,
          difference: notifier.netDifference,
          onChanged: () => notifier.onTotalsEdited('net'),
        ),
      ],
    );
  }
}

class _FinancialInputRow extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String? difference;
  final VoidCallback onChanged;

  const _FinancialInputRow({
    required this.label,
    required this.controller,
    required this.onChanged,
    this.difference,
  });

  @override
  Widget build(BuildContext context) {
    final hasDiff = difference != null && difference!.isNotEmpty;
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
            width: 90, child: Text(label, style: theme.textTheme.titleSmall)),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest
                  .withAlpha((255 * 0.5).round()),
              borderRadius: BorderRadius.circular(8.0),
              border: hasDiff
                  ? Border.all(color: theme.colorScheme.error, width: 1.5)
                  : null,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: TextFormField(
              controller: controller,
              onChanged: (_) => onChanged(),
              textAlign: TextAlign.right,
              style: theme.textTheme.bodyLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 6),
                isDense: true,
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
            child: Text(difference!,
                style: TextStyle(color: theme.colorScheme.error, fontSize: 12)),
          ),
        IconButton(
          icon: const Icon(Icons.copy, size: 16),
          onPressed: () {
            Clipboard.setData(ClipboardData(text: controller.text));
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('Copied to clipboard'),
                width: 200,
                behavior: SnackBarBehavior.floating));
          },
          splashRadius: 18,
        ),
      ],
    );
  }
}
