import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:project_xmedit/notifiers.dart';
import 'package:project_xmedit/widgets.dart';
import 'package:project_xmedit/widgets/cards/totals_card.dart';
import 'package:project_xmedit/widgets/cards/claim_details_card.dart';
import 'package:project_xmedit/widgets/validation_widgets.dart';

class SingleEditorLeftPanel extends StatelessWidget {
  const SingleEditorLeftPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final claimNotifier = context.watch<ClaimDataNotifier>();
    final theme = Theme.of(context);
    const double spacing = 16.0;

    return Container(
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(
            color: theme.colorScheme.outlineVariant,
            width: 1,
          ),
        ),
        color: theme.colorScheme.surface,
      ),
      child: ListView(
        padding: const EdgeInsets.all(spacing),
        children: [
          // 1. Totals (Top)
          ClaimDataSection(
            title: "Totals",
            titleIcon: Icons.calculate_rounded,
            actions: [
              if (claimNotifier.claimData?.activities.isNotEmpty == true)
                HeaderActionButton(
                  icon: Icons.auto_fix_high_rounded,
                  label: "Auto Match",
                  onPressed: claimNotifier.autoMatchTotals,
                ),
            ],
            child: const TotalsCard(),
          ),
          const SizedBox(height: spacing),

          // 2. Validation Summary (if any)
          if (claimNotifier.validationResult != null &&
              claimNotifier.validationResult!.errors.isNotEmpty) ...[
            ValidationSummaryPanel(
              validationResult: claimNotifier.validationResult!,
            ),
            const SizedBox(height: spacing),
          ],

          // 3. Claim Details
          const ClaimDataSection(
            title: "Claim Details",
            titleIcon: Icons.receipt_long_rounded,
            child: ClaimDetailsCard(),
          ),
        ],
      ),
    );
  }
}
