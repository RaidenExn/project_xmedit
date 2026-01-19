import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:project_xmedit/notifiers.dart';
import 'package:project_xmedit/models/claim_models.dart';
import 'package:project_xmedit/widgets/cards/claim_details_card.dart';
import 'package:project_xmedit/widgets/cards/controls_card.dart';
import 'package:project_xmedit/widgets/cards/diagnosis_card.dart';
import 'package:project_xmedit/widgets/cards/totals_card.dart';
import 'package:project_xmedit/widgets.dart';
import 'package:project_xmedit/widgets/cards/activities_card.dart';
import 'package:project_xmedit/dialogs/add_activity_dialog.dart';
import 'package:project_xmedit/dialogs/diagnosis_search_dialog.dart';
import 'package:project_xmedit/widgets/common/measure_size.dart';

class BodyContent extends StatefulWidget {
  const BodyContent({super.key});

  @override
  State<BodyContent> createState() => _BodyContentState();
}

class _BodyContentState extends State<BodyContent> {
  double? _contentWidth;

  @override
  Widget build(BuildContext context) {
    final claimNotifier = context.watch<ClaimDataNotifier>();
    final cardNotifier = context.watch<CardVisibilityNotifier>();
    final theme = Theme.of(context);
    const double spacing = 5.0;

    if (claimNotifier.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (claimNotifier.claimData == null) {
      return Center(
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: InkWell(
            onTap: claimNotifier.loadXmlFile,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.data_object,
                    size: 64,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'No XML File Loaded',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Click to open',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final resubmission = claimNotifier.claimData?.resubmission;
    final bool hasAttachment = resubmission?.attachment?.isNotEmpty ?? false;
    String attachmentText = 'No Attachment';
    bool isAttachmentInvalid = false;

    if (hasAttachment) {
      try {
        final decodedBytes = base64Decode(resubmission!.attachment!);
        final sizeInKb = (decodedBytes.lengthInBytes / 1024).toStringAsFixed(2);
        attachmentText = '$sizeInKb KB';
      } on FormatException {
        attachmentText = 'Corrupt';
        isAttachmentInvalid = true;
      }
    }

    // Helper to constrain content to the measured width
    Widget constrainContent(Widget child) {
      // If width not measured yet, use IntrinsicWidth to avoid taking full width?
      // No, better to center and let it be its size or hide it?
      // Layout might "jump" once measured.
      // We can use opacity 0 until measured? No, better to show it.
      if (_contentWidth == null) {
        return Center(child: child);
      }
      return Center(
        child: SizedBox(
          width: _contentWidth,
          child: child,
        ),
      );
    }

    final childrenSlivers = <Widget>[];

    // --- 1. Claim Details (The Driver of Width) ---
    // We render this inside an IntrinsicWidth -> MeasureSize block to capture its natural Row width.
    if (cardNotifier.visibilities['details']!) {
      childrenSlivers.add(SliverToBoxAdapter(
        child: Center(
          child: IntrinsicWidth(
            // This forces the child Row to have its content width
            child: MeasureSize(
              onChange: (size) {
                // Only update if difference is significant to avoid loops (though check already inside MeasureSize)
                if (_contentWidth != size.width) {
                  setState(() {
                    _contentWidth = size.width;
                  });
                }
              },
              child: const Padding(
                padding: EdgeInsets.only(bottom: spacing),
                child: ClaimDataSection(
                    title: "Claim & Encounter Details",
                    titleIcon: Icons.receipt_long_rounded,
                    child: ClaimDetailsCard()),
              ),
            ),
          ),
        ),
      ));
    }

    // --- 2. Resubmission & Totals (Followers) ---
    if (cardNotifier.visibilities['resubmission & totals']!) {
      childrenSlivers.add(SliverToBoxAdapter(
        child: constrainContent(
          Padding(
            padding: const EdgeInsets.only(bottom: spacing),
            child: LayoutBuilder(
              builder: (context, constraints) {
                // If we are constrained by _contentWidth, constraints.maxWidth should be that width.
                // We check if we have enough width for Row or fallback to Column.
                final isWide = constraints.maxWidth > 900;

                if (isWide) {
                  return IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          flex: 2,
                          child: ClaimDataSection(
                              title: "Resubmission",
                              titleIcon: Icons.tune_rounded,
                              titleSuffix: claimNotifier
                                          .originalResubmissionType !=
                                      null
                                  ? Text(
                                      'OG: ${claimNotifier.originalResubmissionType}',
                                      style: theme.textTheme.bodySmall)
                                  : null,
                              canStretch: true,
                              actions: [
                                ActionChip(
                                  avatar: Icon(
                                      hasAttachment
                                          ? Icons.picture_as_pdf_rounded
                                          : Icons.insert_drive_file_outlined,
                                      size: 16,
                                      color: isAttachmentInvalid
                                          ? theme.colorScheme.error
                                          : null),
                                  label: Text(attachmentText),
                                  onPressed: hasAttachment &&
                                          !isAttachmentInvalid
                                      ? () => claimNotifier
                                          .viewResubmissionAttachment(context)
                                      : null,
                                  labelStyle: TextStyle(
                                      color: isAttachmentInvalid
                                          ? theme.colorScheme.error
                                          : null),
                                  visualDensity: VisualDensity.compact,
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 4),
                                ),
                                HeaderActionButton(
                                  icon: hasAttachment
                                      ? Icons.change_circle_outlined
                                      : Icons.attach_file,
                                  label: hasAttachment ? 'Replace' : 'Add',
                                  onPressed: claimNotifier
                                      .addOrEditResubmissionAttachment,
                                ),
                                HeaderActionButton(
                                  icon: Icons.delete_outline,
                                  label: "Delete",
                                  color: theme.colorScheme.error,
                                  onPressed: hasAttachment
                                      ? claimNotifier
                                          .deleteResubmissionAttachment
                                      : null,
                                ),
                              ],
                              child: const ControlsResubmissionCard()),
                        ),
                        const SizedBox(width: spacing),
                        Expanded(
                          flex: 1,
                          child: ClaimDataSection(
                            title: "Totals",
                            titleIcon: Icons.calculate_rounded,
                            canStretch: true,
                            actions: [
                              HeaderActionButton(
                                icon: Icons.auto_fix_high_rounded,
                                label: "Auto Match",
                                onPressed: claimNotifier
                                        .claimData!.activities.isNotEmpty
                                    ? claimNotifier.autoMatchTotals
                                    : null,
                              ),
                            ],
                            child: const TotalsCard(),
                          ),
                        ),
                      ],
                    ),
                  );
                } else {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ClaimDataSection(
                          title: "Resubmission",
                          titleIcon: Icons.tune_rounded,
                          titleSuffix: claimNotifier.originalResubmissionType !=
                                  null
                              ? Text(
                                  'OG: ${claimNotifier.originalResubmissionType}',
                                  style: theme.textTheme.bodySmall)
                              : null,
                          canStretch: false,
                          actions: [
                            ActionChip(
                              avatar: Icon(
                                  hasAttachment
                                      ? Icons.picture_as_pdf_rounded
                                      : Icons.insert_drive_file_outlined,
                                  size: 16,
                                  color: isAttachmentInvalid
                                      ? theme.colorScheme.error
                                      : null),
                              label: Text(attachmentText),
                              onPressed: hasAttachment && !isAttachmentInvalid
                                  ? () => claimNotifier
                                      .viewResubmissionAttachment(context)
                                  : null,
                              labelStyle: TextStyle(
                                  color: isAttachmentInvalid
                                      ? theme.colorScheme.error
                                      : null),
                              visualDensity: VisualDensity.compact,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 4),
                            ),
                            HeaderActionButton(
                              icon: hasAttachment
                                  ? Icons.change_circle_outlined
                                  : Icons.attach_file,
                              label: hasAttachment ? 'Replace' : 'Add',
                              onPressed:
                                  claimNotifier.addOrEditResubmissionAttachment,
                            ),
                            HeaderActionButton(
                              icon: Icons.delete_outline,
                              label: "Delete",
                              color: theme.colorScheme.error,
                              onPressed: hasAttachment
                                  ? claimNotifier.deleteResubmissionAttachment
                                  : null,
                            ),
                          ],
                          child: const ControlsResubmissionCard()),
                      const SizedBox(height: spacing),
                      ClaimDataSection(
                        title: "Totals",
                        titleIcon: Icons.calculate_rounded,
                        canStretch: false,
                        actions: [
                          HeaderActionButton(
                            icon: Icons.auto_fix_high_rounded,
                            label: "Auto Match",
                            onPressed:
                                claimNotifier.claimData!.activities.isNotEmpty
                                    ? claimNotifier.autoMatchTotals
                                    : null,
                          ),
                        ],
                        child: const TotalsCard(),
                      ),
                    ],
                  );
                }
              },
            ),
          ),
        ),
      ));
    }

    // --- 3. Activities Section (Follower) ---
    if (cardNotifier.visibilities['activities']!) {
      childrenSlivers.add(SliverToBoxAdapter(
        child: constrainContent(
          ClaimDataSection(
            title: "Activities",
            titleIcon: Icons.list_alt_rounded,
            actions: [
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
                label: "Merge All Texts",
                onPressed: claimNotifier.mergeAllTextObservations,
              ),
              FilterChip(
                label: const Text("Transfer on Delete"),
                selected: claimNotifier.transferOnDelete,
                onSelected: claimNotifier.toggleTransferOnDelete,
                visualDensity: VisualDensity.compact,
              ),
              const VerticalDivider(width: 16, indent: 8, endIndent: 8),
              HeaderActionButton(
                icon: Icons.refresh,
                label: "Reset",
                onPressed: claimNotifier.resetActivities,
              ),
              HeaderActionButton(
                icon: Icons.clear_all_rounded,
                label: "Delete All",
                color: Theme.of(context).colorScheme.error,
                onPressed: claimNotifier.claimData!.activities.isNotEmpty
                    ? claimNotifier.deleteAllActivities
                    : null,
              ),
              HeaderActionButton(
                icon: Icons.playlist_add_check_rounded,
                label: "Add All",
                onPressed: claimNotifier.claimData!.activities.isNotEmpty
                    ? claimNotifier.addAllActivities
                    : null,
              ),
            ],
            child: Builder(builder: (context) {
              final activities = claimNotifier.claimData?.activities ?? [];

              if (activities.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text("No activities found."),
                  ),
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 0.0),
                    child: Container(
                      decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainer,
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(8)),
                          border: Border.all(
                              color: theme.colorScheme.outlineVariant
                                  .withAlpha(128))),
                      padding: const EdgeInsets.all(0),
                      child: const ActivityTableHeader(title: 'CPT'),
                    ),
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
                      itemCount: activities.length,
                      separatorBuilder: (ctx, i) => const Divider(height: 1),
                      itemBuilder: (ctx, idx) {
                        final activity = activities[idx];
                        // index in the full list is just idx
                        return ActivityDataRow(
                          key: ValueKey(activity.stateId),
                          notifier: claimNotifier,
                          activity: activity,
                          originalIndex: idx,
                          isZebra: idx.isEven,
                        );
                      },
                    ),
                  ),
                ],
              );
            }),
          ),
        ),
      ));
    }

    // --- 4. Diagnosis Section (Follower) ---
    if (cardNotifier.visibilities['diagnosis']!) {
      childrenSlivers.add(SliverToBoxAdapter(
          child: constrainContent(ClaimDataSection(
        title: "Diagnoses",
        titleIcon: Icons.medical_information_rounded,
        actions: [
          FilterChip(
            label: const Text("Edit"),
            selected: claimNotifier.isDiagnosisEditingEnabled,
            onSelected: claimNotifier.toggleDiagnosisEditing,
            visualDensity: VisualDensity.compact,
            labelStyle: Theme.of(context).textTheme.bodySmall,
            padding: const EdgeInsets.symmetric(horizontal: 2),
          ),
          HeaderActionButton(
            icon: Icons.refresh,
            label: "Reset",
            onPressed: claimNotifier.isDiagnosisEditingEnabled
                ? () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Confirm Reset'),
                        content: const Text(
                            'Are you sure you want to reset all diagnoses to their original state?'),
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
                  }
                : null,
          ),
          HeaderActionButton(
            icon: Icons.add,
            label: "Add",
            onPressed: claimNotifier.isDiagnosisEditingEnabled
                ? () => showDiagnosisSearchDialog(context, claimNotifier)
                : null,
          ),
        ],
        child: const DiagnosisCard(),
      ))));
    }

    return Padding(
      padding: const EdgeInsets.all(spacing),
      child: CustomScrollView(
        slivers: childrenSlivers,
      ),
    );
  }
}
