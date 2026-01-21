import 'package:flutter/material.dart';
import 'package:project_xmedit/models/claim_models.dart';

/// Simplified resubmission card
class BulkResubmissionCard extends StatelessWidget {
  final ClaimData claim;

  const BulkResubmissionCard({super.key, required this.claim});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final resubmission = claim.resubmission;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Type: ${resubmission?.type ?? 'N/A'}',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Comment:',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            resubmission?.comment ?? 'No comment',
            style: theme.textTheme.bodySmall,
            maxLines: 5,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
