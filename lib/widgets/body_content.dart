import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:project_xmedit/notifiers.dart';
import 'package:project_xmedit/widgets/common/empty_state_view.dart';
import 'package:project_xmedit/widgets/single_editor/single_editor_left_panel.dart';
import 'package:project_xmedit/widgets/single_editor/single_editor_right_panel.dart';
import 'package:project_xmedit/widgets/common/responsive_layout.dart';

class BodyContent extends StatelessWidget {
  const BodyContent({super.key});

  @override
  Widget build(BuildContext context) {
    final claimNotifier = context.watch<ClaimDataNotifier>();

    if (claimNotifier.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (claimNotifier.claimData == null) {
      return EmptyStateView(
        icon: Icons.data_object,
        title: 'No XML File Loaded',
        message: 'Click below to open a file',
        actionLabel: 'Open File',
        onAction: claimNotifier.loadXmlFile,
      );
    }

    return const ResponsiveTwoPanel(
      leftPanel: SingleEditorLeftPanel(),
      rightPanel: SingleEditorRightPanel(),
    );
  }
}
