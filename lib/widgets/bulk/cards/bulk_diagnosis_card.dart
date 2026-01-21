import 'package:flutter/material.dart';
import 'package:project_xmedit/models/claim_models.dart';

/// Simplified diagnosis card
class BulkDiagnosisCard extends StatelessWidget {
  final ClaimData claim;

  const BulkDiagnosisCard({super.key, required this.claim});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final diagnoses = claim.diagnoses;

    if (diagnoses.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(child: Text('No diagnoses')),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: diagnoses.map((diagnosis) {
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest
                  .withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: diagnosis.type == 'Principal'
                        ? theme.colorScheme.primaryContainer
                        : theme.colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    diagnosis.type ?? 'Unknown',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: diagnosis.type == 'Principal'
                          ? theme.colorScheme.onPrimaryContainer
                          : theme.colorScheme.onSecondaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  diagnosis.code ?? 'N/A',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
