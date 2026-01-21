import 'package:flutter/material.dart';
import 'package:project_xmedit/models/claim_models.dart';

/// Simplified claim details card for bulk editor (read-only for now)
class BulkClaimDetailsCard extends StatelessWidget {
  final ClaimData claim;

  const BulkClaimDetailsCard({super.key, required this.claim});

  @override
  Widget build(BuildContext context) {
    // Reuse existing ClaimDetailsCard logic but in read-only mode
    // Display fields in a dense 2-column grid
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Column: Identification (Claim, Payer, Insurance)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow('Claim ID', claim.claimId, theme),
                _buildInfoRow('Payer ID', claim.payerID, theme),
                _buildInfoRow('Provider ID', claim.providerID, theme),
                _buildInfoRow('Member ID', claim.memberID, theme),
                _buildInfoRow('Emirates ID', claim.emiratesIDNumber, theme),
              ],
            ),
          ),
          const SizedBox(width: 32),
          // Right Column: Details (Patient, Facility, Dates)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow('Patient ID', claim.patientId, theme),
                _buildInfoRow('Facility ID', claim.facilityID, theme),
                _buildInfoRow('Encounter Type', claim.encounterType, theme),
                _buildInfoRow('Start', claim.start, theme),
                _buildInfoRow('End', claim.end, theme),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String? value, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120, // Slightly reduced from 140 for better density
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value ?? 'N/A',
              style: theme.textTheme.bodyMedium,
              softWrap: true,
            ),
          ),
        ],
      ),
    );
  }
}
