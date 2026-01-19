import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:project_xmedit/notifiers.dart';
import 'package:project_xmedit/widgets.dart';
import 'package:project_xmedit/widgets/common/selection_card.dart';

class ControlsResubmissionCard extends StatelessWidget {
  const ControlsResubmissionCard({super.key});

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<ClaimDataNotifier>();
    final selectedType =
        notifier.claimData?.resubmission?.type ?? 'internal complaint';

    const List<String> resubmissionOptions = [
      "correction",
      "internal complaint",
      "reconciliation"
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: resubmissionOptions.map((option) {
            final bool isSelected = option == selectedType;
            return Expanded(
              child: SelectionCard(
                label: option,
                isSelected: isSelected,
                onTap: () => notifier.updateResubmissionType(option),
                padding: EdgeInsets.only(
                    right: option == resubmissionOptions.last ? 0 : 8.0),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
        ScrollableOnHover(
          child: TextFormField(
            controller: notifier.resubmissionCommentController,
            decoration: const InputDecoration(
              labelText: 'Resubmission Comment',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              isDense: true,
            ),
            maxLines: 3,
            minLines: 3,
          ),
        ),
      ],
    );
  }
}
