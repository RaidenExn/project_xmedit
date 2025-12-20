import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:project_xmedit/notifiers.dart';
import 'package:project_xmedit/widgets.dart';
import 'package:project_xmedit/widgets/cards/activities_card.dart';
import 'package:project_xmedit/widgets/cards/claim_details_card.dart';
import 'package:project_xmedit/widgets/cards/controls_card.dart';
import 'package:project_xmedit/widgets/cards/diagnosis_card.dart';
import 'package:project_xmedit/widgets/cards/totals_card.dart';
import 'package:project_xmedit/dialogs/add_activity_dialog.dart';
import 'package:project_xmedit/dialogs/diagnosis_search_dialog.dart';
import 'package:project_xmedit/xml_handler.dart';

class BodyContent extends StatelessWidget {
  const BodyContent({super.key});

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

    final cardConfigs = [
      {
        'key': 'details',
        'widget': const ClaimDataSection(
            title: "Claim & Encounter Details",
            titleIcon: Icons.receipt_long_rounded,
            child: ClaimDetailsCard()),
      },
      {
        'key': 'resubmission & totals',
        'widget': LayoutBuilder(
          builder: (context, constraints) {
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
                          titleSuffix: claimNotifier.originalResubmissionType !=
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
                            onPressed:
                                claimNotifier.claimData!.activities.isNotEmpty
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
                          padding: const EdgeInsets.symmetric(horizontal: 4),
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
      },
      {
        'key': 'activities',
        'widget': ClaimDataSection(
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
          child: const ActivitiesCard(),
        ),
      },
      {
        'key': 'diagnosis',
        'widget': ClaimDataSection(
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
                                onPressed: () =>
                                    Navigator.of(context).pop(false),
                                child: const Text('Cancel')),
                            TextButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(true),
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
        ),
      },
    ];

    final List<Widget> children = cardConfigs
        .where((config) => cardNotifier.visibilities[config['key']]!)
        .map((config) => config['widget'] as Widget)
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(spacing),
      child: Column(
        children: [
          for (int i = 0; i < children.length; i++) ...[
            children[i],
            if (i < children.length - 1) const SizedBox(height: spacing),
          ],
        ],
      ),
    );
  }
}
