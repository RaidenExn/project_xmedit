import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:project_xmedit/notifiers.dart';
import 'package:project_xmedit/widgets.dart';
import 'package:project_xmedit/widgets/common/selection_card.dart';

class ControlsResubmissionCard extends StatefulWidget {
  const ControlsResubmissionCard({super.key});

  @override
  State<ControlsResubmissionCard> createState() =>
      _ControlsResubmissionCardState();
}

class _ControlsResubmissionCardState extends State<ControlsResubmissionCard> {
  late TextEditingController _commentController;

  @override
  void initState() {
    super.initState();
    _commentController = TextEditingController();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<ClaimDataNotifier>();
    final selectedType =
        notifier.claimData?.resubmission?.type ?? 'internal complaint';

    // Sync from provider if external change
    if (notifier.claimData?.resubmission?.comment != null) {
      if (_commentController.text !=
              notifier.claimData!.resubmission!.comment &&
          !_commentController.selection.isValid) {
        _commentController.text =
            notifier.claimData!.resubmission!.comment ?? '';
      }
    }

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
            controller: _commentController,
            decoration: const InputDecoration(
              labelText: 'Resubmission Comment',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              isDense: true,
            ),
            maxLines: 3,
            minLines: 3,
            onChanged: (value) {
              if (notifier.claimData?.resubmission != null) {
                notifier.claimData!.resubmission!.comment = value;
                // No need to notify listeners for comment change unless we validate it?
                // Save operation reads from claimData now (in my planned refactor).
              }
            },
          ),
        ),
      ],
    );
  }
}
