import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:project_xmedit/models/claim_models.dart';
import 'package:project_xmedit/providers/bulk_claim_data_provider.dart';
import 'package:project_xmedit/widgets.dart';

/// Detail editor for the selected claim in bulk editor
/// Reuses existing single-claim editor widgets
class BulkClaimDetailEditor extends StatefulWidget {
  const BulkClaimDetailEditor({super.key});

  @override
  State<BulkClaimDetailEditor> createState() => _BulkClaimDetailEditorState();
}

class _BulkClaimDetailEditorState extends State<BulkClaimDetailEditor> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bulkNotifier = context.watch<BulkClaimDataNotifier>();
    final selectedClaim = bulkNotifier.selectedClaim;
    final theme = Theme.of(context);

    if (selectedClaim == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.touch_app_outlined,
              size: 64,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'Select a claim to view details',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ],
        ),
      );
    }

    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        // Header with claim ID
        SliverToBoxAdapter(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
              border: Border(
                bottom: BorderSide(
                  color: theme.colorScheme.outlineVariant,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.receipt_long,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Claim: ${selectedClaim.claimId ?? "UNKNOWN"}',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                const Spacer(),
                Text(
                  'Claim ${bulkNotifier.selectedClaimIndex + 1} of ${bulkNotifier.totalClaims}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Content
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // Claim Details Card
              ClaimDataSection(
                title: "Claim & Encounter Details",
                titleIcon: Icons.receipt_long_rounded,
                child: _BulkClaimDetailsCard(claim: selectedClaim),
              ),
              const SizedBox(height: 8),

              // Resubmission & Totals Row
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      flex: 2,
                      child: ClaimDataSection(
                        title: "Resubmission",
                        titleIcon: Icons.tune_rounded,
                        canStretch: true,
                        child:
                            _BulkControlsResubmissionCard(claim: selectedClaim),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 1,
                      child: ClaimDataSection(
                        title: "Totals",
                        titleIcon: Icons.calculate_rounded,
                        canStretch: true,
                        child: _BulkTotalsCard(claim: selectedClaim),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Activities Section
              ClaimDataSection(
                title: "Activities",
                titleIcon: Icons.list_alt_rounded,
                child: _BulkActivitiesCard(claim: selectedClaim),
              ),
              const SizedBox(height: 8),

              // Diagnosis Section
              ClaimDataSection(
                title: "Diagnoses",
                titleIcon: Icons.medical_information_rounded,
                child: _BulkDiagnosisCard(claim: selectedClaim),
              ),
            ]),
          ),
        ),
      ],
    );
  }
}

/// Simplified claim details card for bulk editor (read-only for now)
class _BulkClaimDetailsCard extends StatelessWidget {
  final ClaimData claim;

  const _BulkClaimDetailsCard({required this.claim});

  @override
  Widget build(BuildContext context) {
    // Reuse existing ClaimDetailsCard logic but in read-only mode
    // For simplicity, we'll display key fields in a simple grid
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow('Claim ID', claim.claimId, theme),
          _buildInfoRow('Payer ID', claim.payerID, theme),
          _buildInfoRow('Provider ID', claim.providerID, theme),
          _buildInfoRow('Member ID', claim.memberID, theme),
          _buildInfoRow('Emirates ID', claim.emiratesIDNumber, theme),
          _buildInfoRow('Patient ID', claim.patientId, theme),
          _buildInfoRow('Facility ID', claim.facilityID, theme),
          _buildInfoRow('Encounter Type', claim.encounterType, theme),
          _buildInfoRow('Start', claim.start, theme),
          _buildInfoRow('End', claim.end, theme),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String? value, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          SizedBox(
            width: 140,
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
            ),
          ),
        ],
      ),
    );
  }
}

/// Simplified totals card
class _BulkTotalsCard extends StatelessWidget {
  final ClaimData claim;

  const _BulkTotalsCard({required this.claim});

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

/// Simplified resubmission card
class _BulkControlsResubmissionCard extends StatelessWidget {
  final ClaimData claim;

  const _BulkControlsResubmissionCard({required this.claim});

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

/// Simplified activities card
class _BulkActivitiesCard extends StatelessWidget {
  final ClaimData claim;

  const _BulkActivitiesCard({required this.claim});

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

/// Simplified diagnosis card
class _BulkDiagnosisCard extends StatelessWidget {
  final ClaimData claim;

  const _BulkDiagnosisCard({required this.claim});

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
