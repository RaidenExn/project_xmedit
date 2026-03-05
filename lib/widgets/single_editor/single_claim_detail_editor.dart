import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:project_xmedit/dialogs/add_activity_dialog.dart';
import 'package:project_xmedit/dialogs/diagnosis_search_dialog.dart';
import 'package:project_xmedit/models/claim_models.dart';
import 'package:project_xmedit/notifiers.dart';
import 'package:project_xmedit/widgets.dart';
import 'package:project_xmedit/widgets/cards/activities_widgets.dart';
import 'package:project_xmedit/widgets/cards/claim_details_card.dart';
import 'package:project_xmedit/widgets/cards/controls_card.dart';
import 'package:project_xmedit/widgets/cards/diagnosis_card.dart';
import 'package:project_xmedit/widgets/cards/totals_card.dart';
import 'package:project_xmedit/widgets/validation_widgets.dart';

class SingleClaimDetailEditor extends StatelessWidget {
  const SingleClaimDetailEditor({super.key});

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<ClaimDataNotifier>();
    final claim = notifier.claimData;
    final theme = Theme.of(context);
    if (claim == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.all(10),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isStacked = constraints.maxWidth < 1120;
          if (isStacked) {
            return ListView(
              children: [
                _buildTotalsSection(notifier),
                const SizedBox(height: 10),
                if (_hasValidationErrors(notifier)) ...[
                  ValidationSummaryPanel(
                    validationResult: notifier.validationResult!,
                  ),
                  const SizedBox(height: 10),
                ],
                _buildClaimDetailsSection(),
                const SizedBox(height: 10),
                _buildResubmissionSection(context, notifier, theme),
                const SizedBox(height: 10),
                _SingleActivitiesSection(
                  claimNotifier: notifier,
                  theme: theme,
                ),
                const SizedBox(height: 10),
                _buildDiagnosisSection(context, notifier),
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: 360,
                child: ListView(
                  children: [
                    _buildClaimDetailsSection(),
                    if (_hasValidationErrors(notifier)) ...[
                      const SizedBox(height: 10),
                      ValidationSummaryPanel(
                        validationResult: notifier.validationResult!,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ListView(
                  children: [
                    Builder(
                      builder: (context) {
                        final scale = MediaQuery.textScalerOf(context).scale(1);
                        final topRowHeight = 248.0 + ((scale - 1.0) * 24.0);
                        return SizedBox(
                          height: topRowHeight.clamp(248.0, 286.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: _buildResubmissionSection(
                                  context,
                                  notifier,
                                  theme,
                                ),
                              ),
                              const SizedBox(width: 10),
                              SizedBox(
                                width: 320,
                                child: _buildTotalsSection(notifier),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                    _SingleActivitiesSection(
                      claimNotifier: notifier,
                      theme: theme,
                    ),
                    const SizedBox(height: 10),
                    _buildDiagnosisSection(context, notifier),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  bool _hasValidationErrors(ClaimDataNotifier notifier) =>
      notifier.validationResult != null &&
      notifier.validationResult!.errors.isNotEmpty;

  Widget _buildTotalsSection(ClaimDataNotifier notifier) => ClaimDataSection(
        title: "Totals",
        titleIcon: Icons.calculate_rounded,
        actions: [
          if (notifier.claimData?.activities.isNotEmpty == true)
            HeaderActionButton(
              icon: Icons.auto_fix_high_rounded,
              label: "Auto Match",
              onPressed: notifier.autoMatchTotals,
            ),
        ],
        child: const TotalsCard(),
      );

  Widget _buildClaimDetailsSection() => const ClaimDataSection(
        title: "Claim Details",
        titleIcon: Icons.receipt_long_rounded,
        child: ClaimDetailsCard(),
      );

  Widget _buildResubmissionSection(
    BuildContext context,
    ClaimDataNotifier notifier,
    ThemeData theme,
  ) {
    final resubmission = notifier.claimData?.resubmission;
    final hasAttachment = resubmission?.attachment?.isNotEmpty ?? false;
    final attachmentText = notifier.attachmentSizeInKb ??
        (hasAttachment ? 'Calculating...' : 'No Attachment');
    final isAttachmentInvalid = notifier.isAttachmentInvalid;

    return ClaimDataSection(
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
                ? () => notifier.viewResubmissionAttachment(context)
                : null,
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            labelStyle: TextStyle(
                color: isAttachmentInvalid ? theme.colorScheme.error : null),
          ),
          const SizedBox(width: 8),
          HeaderActionButton(
            icon: Icons.edit_rounded,
            label: "Replace",
            onPressed: notifier.addOrEditResubmissionAttachment,
            tooltip: "Replace PDF",
          ),
          HeaderActionButton(
            icon: Icons.delete_rounded,
            label: "Delete",
            onPressed: notifier.deleteResubmissionAttachment,
            color: theme.colorScheme.error,
            tooltip: "Delete PDF",
          ),
        ] else
          HeaderActionButton(
            icon: Icons.upload_file_rounded,
            label: "Add PDF",
            onPressed: notifier.addOrEditResubmissionAttachment,
            tooltip: "Upload Resubmission PDF",
          ),
      ],
      child: const ControlsResubmissionCard(),
    );
  }

  Widget _buildDiagnosisSection(
          BuildContext context, ClaimDataNotifier notifier) =>
      ClaimDataSection(
        title: "Diagnoses",
        titleIcon: Icons.medical_information_rounded,
        actions: [
          FilterChip(
            label: const Text("Edit Mode"),
            selected: notifier.isDiagnosisEditingEnabled,
            onSelected: notifier.toggleDiagnosisEditing,
            visualDensity: VisualDensity.compact,
          ),
          const SizedBox(width: 8),
          if (notifier.isDiagnosisEditingEnabled) ...[
            HeaderActionButton(
              icon: Icons.add,
              label: "Add",
              onPressed: () => showDiagnosisSearchDialog(context, notifier),
            ),
            HeaderActionButton(
              icon: Icons.refresh,
              label: "Reset",
              onPressed: notifier.resetDiagnoses,
            ),
          ],
        ],
        child: const DiagnosisCard(),
      );
}

class _SingleActivitiesSection extends StatelessWidget {
  final ClaimDataNotifier claimNotifier;
  final ThemeData theme;

  const _SingleActivitiesSection({
    required this.claimNotifier,
    required this.theme,
  });

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
      child: Builder(
        builder: (context) {
          final activities = claimNotifier.claimData?.activities ?? [];
          if (activities.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: Text("No activities found."),
              ),
            );
          }

          final groupedActivities = claimNotifier.groupedActivities;
          final categoryOrder = [
            ('3', 'CPT'),
            ('8', 'DSL'),
            ('5', 'Drug'),
            ('6', 'CDT'),
          ];
          final knownTypes = {'3', '8', '5', '6'};
          final hasUnknownActivities =
              groupedActivities.keys.any((type) => !knownTypes.contains(type));
          final displayCategories = List<(String, String)>.from(categoryOrder);
          if (hasUnknownActivities) {
            displayCategories.add(('_unknown', 'Other/Unknown'));
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              const minTableWidth = 840.0;
              final shouldScroll = constraints.maxWidth < minTableWidth;
              final sections = <Widget>[];

              for (final (typeId, categoryName) in displayCategories) {
                List<ActivityData> categoryActivities;
                if (typeId == '_unknown') {
                  categoryActivities = [];
                  for (final entry in groupedActivities.entries) {
                    if (!knownTypes.contains(entry.key)) {
                      categoryActivities.addAll(entry.value);
                    }
                  }
                } else {
                  categoryActivities = groupedActivities[typeId] ?? [];
                }
                if (categoryActivities.isEmpty) continue;

                if (sections.isNotEmpty) {
                  sections.add(const SizedBox(height: 12));
                }
                sections.add(
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainer,
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(8)),
                          border: Border.all(
                            color:
                                theme.colorScheme.outlineVariant.withAlpha(128),
                          ),
                        ),
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
                              bottom: Radius.circular(8)),
                        ),
                        child: ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: categoryActivities.length,
                          separatorBuilder: (ctx, i) =>
                              const Divider(height: 1),
                          itemBuilder: (ctx, categoryIdx) {
                            final activity = categoryActivities[categoryIdx];
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

              final table = Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: sections,
              );
              if (!shouldScroll) return table;
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(width: minTableWidth, child: table),
              );
            },
          );
        },
      ),
    );
  }
}
