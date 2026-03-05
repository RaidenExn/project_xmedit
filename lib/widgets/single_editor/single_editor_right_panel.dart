import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:project_xmedit/notifiers.dart';
import 'package:project_xmedit/models/claim_models.dart';
import 'package:project_xmedit/widgets.dart';
import 'package:project_xmedit/widgets/cards/controls_card.dart';
import 'package:project_xmedit/widgets/cards/diagnosis_card.dart';
import 'package:project_xmedit/widgets/cards/activities_widgets.dart';
import 'package:project_xmedit/widgets/common/claim_hero_header.dart';
// Wait, BodyContent had inline logic. I should probably move that inline logic to this file or use the ActivitiesCard if it serves the purpose.
// Checking previous view_file of BodyContent, it imported activities_card.dart but used inline Builder.
// I will replicate the inline logic here to ensure exact behavior, as ActivitiesCard might be old.
// ACTUALLY, I should check activities_card.dart content to see if I can use it.
// For safety and "Optimization" (cleanup), I will assume the inline logic is the "Correct" one and put it here.
// I'll call it _ActivitiesSection locally or just put it in the list.

import 'package:project_xmedit/dialogs/add_activity_dialog.dart';
import 'package:project_xmedit/dialogs/diagnosis_search_dialog.dart';

class SingleEditorRightPanel extends StatelessWidget {
  const SingleEditorRightPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final claimNotifier = context.watch<ClaimDataNotifier>();
    final theme = Theme.of(context);
    final claim = claimNotifier.claimData;
    const double spacing = 10.0;

    if (claim == null) return const SizedBox.shrink();

    // Resubmission Helpers
    final resubmission = claimNotifier.claimData?.resubmission;
    final bool hasAttachment = resubmission?.attachment?.isNotEmpty ?? false;

    // Use the cached size from notifier
    final attachmentText = claimNotifier.attachmentSizeInKb ??
        (hasAttachment ? 'Calculating...' : 'No Attachment');
    final isAttachmentInvalid = claimNotifier.isAttachmentInvalid;

    return Container(
      color: theme.colorScheme.surface,
      child: ListView(
        padding: const EdgeInsets.all(spacing),
        children: [
          ClaimHeroHeader(
            claimId: claim.claimId ?? 'UNKNOWN',
            subtitle: 'Single Claim Mode',
            memberId: claim.memberID ?? 'N/A',
            encounterDate: claim.start ?? 'N/A',
          ),
          const SizedBox(height: spacing),

          // 1. Resubmission
          ClaimDataSection(
            title: "Resubmission",
            titleIcon: Icons.tune_rounded,
            actions: [
              if (hasAttachment) ...[
                ActionChip(
                  avatar: Icon(
                    Icons.picture_as_pdf_rounded,
                    size: 16,
                    color: isAttachmentInvalid ? theme.colorScheme.error : null,
                  ),
                  label: Text(attachmentText),
                  onPressed: !isAttachmentInvalid
                      ? () => claimNotifier.viewResubmissionAttachment(context)
                      : null,
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  labelStyle: TextStyle(
                      color:
                          isAttachmentInvalid ? theme.colorScheme.error : null),
                ),
                const SizedBox(width: 8),
                HeaderActionButton(
                  icon: Icons.edit_rounded,
                  label: "Replace",
                  onPressed: claimNotifier.addOrEditResubmissionAttachment,
                  tooltip: "Replace PDF",
                ),
                HeaderActionButton(
                  icon: Icons.delete_rounded,
                  label: "Delete",
                  onPressed: claimNotifier.deleteResubmissionAttachment,
                  color: theme.colorScheme.error,
                  tooltip: "Delete PDF",
                ),
              ] else
                HeaderActionButton(
                  icon: Icons.upload_file_rounded,
                  label: "Add PDF",
                  onPressed: claimNotifier.addOrEditResubmissionAttachment,
                  tooltip: "Upload Resubmission PDF",
                ),
            ],
            child: const ControlsResubmissionCard(),
          ),
          const SizedBox(height: spacing),

          // 2. Activities (Refactored to separate component if possible, but keeping inline for now as in original)
          _ActivitiesSection(claimNotifier: claimNotifier, theme: theme),
          const SizedBox(height: spacing),

          // 3. Diagnoses
          ClaimDataSection(
            title: "Diagnoses",
            titleIcon: Icons.medical_information_rounded,
            actions: [
              FilterChip(
                label: const Text("Edit Mode"),
                selected: claimNotifier.isDiagnosisEditingEnabled,
                onSelected: claimNotifier.toggleDiagnosisEditing,
                visualDensity: VisualDensity.compact,
              ),
              const SizedBox(width: 8),
              if (claimNotifier.isDiagnosisEditingEnabled) ...[
                HeaderActionButton(
                  icon: Icons.add,
                  label: "Add",
                  onPressed: () =>
                      showDiagnosisSearchDialog(context, claimNotifier),
                ),
                HeaderActionButton(
                  icon: Icons.refresh,
                  label: "Reset",
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Confirm Reset'),
                        content: const Text(
                            'Are you sure you want to reset all diagnoses?'),
                        actions: [
                          TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: const Text('Cancel')),
                          TextButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              child: const Text('Reset')),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      claimNotifier.resetDiagnoses();
                    }
                  },
                ),
              ],
            ],
            child: const DiagnosisCard(),
          ),
        ],
      ),
    );
  }
}

class _ActivitiesSection extends StatelessWidget {
  final ClaimDataNotifier claimNotifier;
  final ThemeData theme;

  const _ActivitiesSection({required this.claimNotifier, required this.theme});

  @override
  Widget build(BuildContext context) {
    return ClaimDataSection(
      title: "Activities",
      titleIcon: Icons.list_alt_rounded,
      actions: [
        FilterChip(
          label: const Text("Transfer on Delete"),
          selected: claimNotifier.transferOnDelete,
          onSelected: claimNotifier.toggleTransferOnDelete,
          visualDensity: VisualDensity.compact,
        ),
        const SizedBox(width: 8),
        HeaderActionButton(
          icon: Icons.add,
          label: "Add",
          onPressed: () async {
            final activities = claimNotifier.claimData?.activities;
            final existingClinician =
                (activities != null && activities.isNotEmpty)
                    ? (activities.first.clinician ?? 'GD')
                    : 'GD';
            final existingCodes =
                activities?.map((a) => a.code ?? '').toList() ?? [];

            final newActivity = await showDialog<ActivityData>(
              context: context,
              builder: (context) => AddActivityDialog(
                clinicianId: existingClinician,
                existingCodes: existingCodes,
              ),
            );
            if (newActivity != null) {
              claimNotifier.addActivity(newActivity);
            }
          },
        ),
        HeaderActionButton(
          icon: Icons.merge_type,
          label: "Merge Texts",
          onPressed: claimNotifier.mergeAllTextObservations,
          tooltip: "Merge All Text Observations",
        ),
        HeaderActionButton(
          icon: Icons.refresh,
          label: "Reset",
          onPressed: claimNotifier.resetActivities,
          tooltip: "Reset Activities",
        ),
        HeaderActionButton(
          icon: Icons.delete_outline,
          label: "Delete All",
          onPressed: (claimNotifier.claimData?.activities.isNotEmpty ?? false)
              ? claimNotifier.deleteAllActivities
              : null,
          color: theme.colorScheme.error,
          tooltip: "Delete All Activities",
        ),
        HeaderActionButton(
          icon: Icons.select_all,
          label: "Add All",
          onPressed: (claimNotifier.claimData?.activities.isNotEmpty ?? false)
              ? claimNotifier.addAllActivities
              : null,
          tooltip: "Add All Activities",
        ),
      ],
      child: Builder(builder: (context) {
        final activities = claimNotifier.claimData?.activities ?? [];

        if (activities.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: Text("No activities found."),
            ),
          );
        }

        // Group activities by type and define category order
        final groupedActivities = claimNotifier.groupedActivities;
        final categoryOrder = [
          ('3', 'CPT'),
          ('8', 'DSL'),
          ('5', 'Drug'),
          ('6', 'CDT'),
        ];

        // Check if there are any unknown/other activities
        final knownTypes = {'3', '8', '5', '6'};
        final hasUnknownActivities =
            groupedActivities.keys.any((type) => !knownTypes.contains(type));

        // Add unknown category if it exists
        final displayCategories = List<(String, String)>.from(categoryOrder);
        if (hasUnknownActivities) {
          displayCategories.add(('_unknown', 'Other/Unknown'));
        }

        return LayoutBuilder(builder: (context, constraints) {
          const double minTableWidth = 800.0;
          final shouldScroll = constraints.maxWidth < minTableWidth;

          // Build sections for each category
          final categorySections = <Widget>[];

          for (final (typeId, categoryName) in displayCategories) {
            List<ActivityData> categoryActivities;

            // Handle special '_unknown' category
            if (typeId == '_unknown') {
              // Collect all activities that don't match known types
              categoryActivities = [];
              for (final entry in groupedActivities.entries) {
                if (!knownTypes.contains(entry.key)) {
                  categoryActivities.addAll(entry.value);
                }
              }
            } else {
              categoryActivities = groupedActivities[typeId] ?? [];
            }

            if (categoryActivities.isEmpty) {
              continue; // Skip empty categories
            }

            // Add spacing between categories
            if (categorySections.isNotEmpty) {
              categorySections.add(const SizedBox(height: 16));
            }

            categorySections.add(
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainer,
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(8)),
                        border: Border.all(
                            color: theme.colorScheme.outlineVariant
                                .withAlpha(128))),
                    child: ActivityTableHeader(title: categoryName),
                  ),
                  Container(
                    decoration: BoxDecoration(
                        border: Border(
                          left: BorderSide(
                              color: theme.colorScheme.outlineVariant
                                  .withAlpha(128)),
                          right: BorderSide(
                              color: theme.colorScheme.outlineVariant
                                  .withAlpha(128)),
                          bottom: BorderSide(
                              color: theme.colorScheme.outlineVariant
                                  .withAlpha(128)),
                        ),
                        borderRadius: const BorderRadius.vertical(
                            bottom: Radius.circular(8))),
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: categoryActivities.length,
                      separatorBuilder: (ctx, i) => const Divider(height: 1),
                      itemBuilder: (ctx, categoryIdx) {
                        final activity = categoryActivities[categoryIdx];
                        // Find original index in the full activities list
                        final originalIndex = activities.indexOf(activity);
                        return ActivityDataRow(
                          key: ValueKey(activity.stateId),
                          notifier: claimNotifier,
                          activity: activity,
                          originalIndex: originalIndex,
                          isZebra: categoryIdx.isEven,
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          }

          Widget tableContent = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: categorySections,
          );

          if (shouldScroll) {
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: minTableWidth,
                child: tableContent,
              ),
            );
          }

          return tableContent;
        });
      }),
    );
  }
}
