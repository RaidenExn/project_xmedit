import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:project_xmedit/providers/bulk_claim_data_provider.dart';
import 'package:project_xmedit/widgets.dart';
import 'package:project_xmedit/widgets/bulk/cards/bulk_claim_details_card.dart';
import 'package:project_xmedit/widgets/bulk/cards/bulk_totals_card.dart';
import 'package:project_xmedit/widgets/bulk/cards/bulk_resubmission_card.dart';
import 'package:project_xmedit/widgets/bulk/cards/bulk_activities_card.dart';
import 'package:project_xmedit/widgets/bulk/cards/bulk_diagnosis_card.dart';

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
        // Header with claim ID (Floating Rounded Card Style)
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          sliver: SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color:
                    theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color:
                      theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onPrimaryContainer
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.receipt_long,
                      color: theme.colorScheme.onPrimaryContainer,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          selectedClaim.claimId ?? "UNKNOWN",
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                        Text(
                          'Claim ${bulkNotifier.selectedClaimIndex + 1} of ${bulkNotifier.totalClaims}',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.onPrimaryContainer
                                .withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
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
                child: BulkClaimDetailsCard(claim: selectedClaim),
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
                        child: BulkResubmissionCard(claim: selectedClaim),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 1,
                      child: ClaimDataSection(
                        title: "Totals",
                        titleIcon: Icons.calculate_rounded,
                        canStretch: true,
                        child: BulkTotalsCard(claim: selectedClaim),
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
                child: BulkActivitiesCard(claim: selectedClaim),
              ),
              const SizedBox(height: 8),

              // Diagnosis Section
              ClaimDataSection(
                title: "Diagnoses",
                titleIcon: Icons.medical_information_rounded,
                child: BulkDiagnosisCard(claim: selectedClaim),
              ),
            ]),
          ),
        ),
      ],
    );
  }
}
