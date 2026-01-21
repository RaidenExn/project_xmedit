import 'package:flutter/material.dart';
import 'package:project_xmedit/widgets/bulk/bulk_claim_list_panel.dart';
import 'package:project_xmedit/widgets/bulk/bulk_claim_detail_editor.dart';
import 'package:project_xmedit/widgets/common/responsive_layout.dart';

/// Body of bulk editor with two-panel layout
class BulkEditorView extends StatelessWidget {
  const BulkEditorView({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsiveTwoPanel(
      leftPanel: Container(
        decoration: BoxDecoration(
          border: Border(
            right: BorderSide(
              color: Theme.of(context).colorScheme.outlineVariant,
              width: 1,
            ),
          ),
        ),
        child: const BulkClaimListPanel(),
      ),
      rightPanel: const BulkClaimDetailEditor(),
    );
  }
}
