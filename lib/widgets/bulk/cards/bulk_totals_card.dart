import 'package:flutter/material.dart';
import 'package:project_xmedit/models/claim_models.dart';

/// Simplified totals card
class BulkTotalsCard extends StatelessWidget {
  final ClaimData claim;

  const BulkTotalsCard({super.key, required this.claim});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTotalRow('Gross', claim.gross, theme),
          const SizedBox(height: 8),
          _buildTotalRow('Patient Share', claim.patientShare, theme),
          const SizedBox(height: 8),
          _buildTotalRow('Net', claim.net, theme),
        ],
      ),
    );
  }

  Widget _buildTotalRow(String label, String? value, ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value ?? '0.00',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
