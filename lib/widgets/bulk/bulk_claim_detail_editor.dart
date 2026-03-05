import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:project_xmedit/models/claim_models.dart';
import 'package:project_xmedit/providers/bulk_claim_data_provider.dart';
import 'package:project_xmedit/widgets.dart';
import 'package:project_xmedit/widgets/bulk/cards/bulk_claim_details_card.dart';
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

    return Padding(
      padding: const EdgeInsets.all(10),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return ListView(
            children: [
              _buildClaimDetailsSection(selectedClaim),
              const SizedBox(height: 10),
              _buildActivitiesSection(selectedClaim),
              const SizedBox(height: 10),
              _buildDiagnosisSection(selectedClaim),
            ],
          );
        },
      ),
    );
  }

  Widget _buildClaimDetailsSection(ClaimData claim) => ClaimDataSection(
        title: "Claim Details",
        titleIcon: Icons.receipt_long_rounded,
        child: BulkClaimDetailsCard(claim: claim),
      );

  Widget _buildActivitiesSection(ClaimData claim) => ClaimDataSection(
        title: "Activities",
        titleIcon: Icons.list_alt_rounded,
        child: BulkActivitiesCard(claim: claim),
      );

  Widget _buildDiagnosisSection(ClaimData claim) => ClaimDataSection(
        title: "Diagnoses",
        titleIcon: Icons.medical_information_rounded,
        child: BulkDiagnosisCard(claim: claim),
      );
}
