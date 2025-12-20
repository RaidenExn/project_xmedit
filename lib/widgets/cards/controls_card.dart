import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:project_xmedit/notifiers.dart';
import 'package:project_xmedit/widgets.dart';

class ControlsResubmissionCard extends StatelessWidget {
  const ControlsResubmissionCard({super.key});

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<ClaimDataNotifier>();
    final selectedType =
        notifier.claimData?.resubmission?.type ?? 'internal complaint';
    final theme = Theme.of(context);

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
            final Color cardColor = isSelected
                ? theme.colorScheme.secondaryContainer
                : theme.colorScheme.surfaceContainer;
            final Color textColor = isSelected
                ? theme.colorScheme.onSecondaryContainer
                : theme.colorScheme.onSurface;

            final Color borderColor = isSelected
                ? theme.colorScheme.secondaryContainer
                : theme.colorScheme.outlineVariant.withAlpha(128);

            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                    right: option == resubmissionOptions.last ? 0 : 8.0),
                child: Card(
                  color: cardColor,
                  elevation: 0,
                  clipBehavior: Clip.antiAlias,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                    side: BorderSide(
                      color: borderColor,
                      width: 1.0,
                    ),
                  ),
                  child: InkWell(
                    onTap: () => notifier.updateResubmissionType(option),
                    child: ListTile(
                      dense: true,
                      title: Text(
                        option,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: textColor,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 0),
                    ),
                  ),
                ),
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
