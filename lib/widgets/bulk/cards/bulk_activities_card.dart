import 'package:flutter/material.dart';
import 'package:project_xmedit/models/claim_models.dart';

/// Simplified activities card
class BulkActivitiesCard extends StatelessWidget {
  final ClaimData claim;

  const BulkActivitiesCard({super.key, required this.claim});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activities = claim.activities.where((a) => !a.isDeleted).toList();

    if (activities.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(child: Text('No activities')),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: activities.map((activity) {
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Code: ${activity.code ?? 'N/A'}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Qty: ${activity.quantity ?? '0'} | Net: ${activity.net ?? '0.00'}',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
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
