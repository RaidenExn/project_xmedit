import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:project_xmedit/notifiers.dart';
import 'package:project_xmedit/widgets.dart';
import 'package:provider/provider.dart';

class ClaimDetailsCard extends StatelessWidget {
  const ClaimDetailsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final claimData = context.watch<ClaimDataNotifier>().claimData!;
    return Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      children: [
        DataFieldWithCopy(label: 'Claim ID', value: claimData.claimId ?? ''),
        DataFieldWithCopy(label: "Member ID", value: claimData.memberID ?? ''),
        SimpleDataField(label: "Sender ID", value: claimData.senderID ?? ''),
        SimpleDataField(label: "Payer ID", value: claimData.payerID ?? ''),
        SimpleDataField(
            label: "Receiver ID", value: claimData.receiverID ?? ''),
        SimpleDataField(
            label: "Transaction Date",
            value: claimData.transactionDate ?? ''),
        SimpleDataField(label: "Start Date", value: claimData.start ?? ''),
      ],
    );
  }
}

class ActivitiesCard extends StatelessWidget {
  const ActivitiesCard({super.key});

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<ClaimDataNotifier>();
    const Map<String, String> typeMap = {
      "3": "CPT",
      "8": "DSL",
      "5": "Drug",
      "6": "CDT",
    };

    if (notifier.claimData?.activities.isEmpty ?? true) {
      return const Center(child: Text("No activities in this claim."));
    }

    final grouped = notifier.groupedActivities;
    final types = grouped.keys.toList();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(types.length, (index) {
        final typeKey = types[index];
        final activitiesOfType = grouped[typeKey]!;
        final typeName = typeMap[typeKey] ?? 'Unknown Type';

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ActivityTableHeader(title: typeName),
            const Divider(height: 1),
            ...activitiesOfType.map((activity) {
              final originalIndex =
                  notifier.claimData!.activities.indexOf(activity);
              return _ActivityDataRow(
                key: ValueKey(activity.id),
                notifier: notifier,
                activity: activity,
                originalIndex: originalIndex,
              );
            }),
          ],
        );
      }),
    );
  }
}

class _ActivityTableHeader extends StatelessWidget {
  final String title;
  const _ActivityTableHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodySmall;
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Row(
        children: [
          SizedBox(width: 160, child: Text(title, style: style?.copyWith(fontWeight: FontWeight.bold))),
          SizedBox(width: 50, child: Center(child: Text('Qty', style: style))),
          Expanded(child: Center(child: Text('Description', style: style))),
          SizedBox(
              width: 40,
              child: Center(
                  child: Tooltip(
                      message: "Observations",
                      child: Icon(Icons.comment_outlined,
                          size: 16,
                          color: Theme.of(context).colorScheme.onSurfaceVariant)))),
          SizedBox(width: 100, child: Center(child: Text('Net', style: style))),
          SizedBox(
              width: 100, child: Center(child: Text('Copay', style: style))),
          SizedBox(
              width: 60, child: Center(child: Text('Actions', style: style))),
        ],
      ),
    );
  }
}

class _ActivityDataRow extends StatelessWidget {
  final ClaimDataNotifier notifier;
  final dynamic activity;
  final int originalIndex;

  const _ActivityDataRow({
    super.key,
    required this.notifier,
    required this.activity,
    required this.originalIndex,
  });

  @override
  Widget build(BuildContext context) {
    final isDeleted = activity.isDeleted;
    final textStyle = TextStyle(
      fontSize: 14,
      decoration: isDeleted ? TextDecoration.lineThrough : null,
      color: isDeleted ? Theme.of(context).disabledColor : null,
    );
    final description = notifier.cptDescriptions[activity.code] ?? 'N/A';
    final bool hasComplaint =
        activity.observations.any((obs) => obs['Code'] == 'Presenting-Complaint');

    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      color: isDeleted
          ? Theme.of(context).colorScheme.error.withAlpha((255 * 0.05).round())
          : null,
      child: Row(
        children: [
          // Left Fixed Columns
          SizedBox(
              width: 160, child: Text(activity.code ?? 'N/A', style: textStyle)),
          SizedBox(
              width: 50,
              child:
                  Center(child: Text(activity.quantity ?? '1', style: textStyle))),
          // Center Expanding Column
          Expanded(
            child: Center(
              child: Tooltip(
                message: description,
                child: Text(
                  description,
                  style: textStyle,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
          // Right Fixed Columns
          SizedBox(
            width: 40,
            child: Center(
              child: hasComplaint
                  ? Tooltip(
                      message: 'Has Presenting-Complaint',
                      child: Icon(Icons.flag_circle,
                          size: 16,
                          color: Theme.of(context).colorScheme.primary),
                    )
                  : const SizedBox(),
            ),
          ),
          SizedBox(
            width: 100,
            child: _EditableNumberCell(
              controller: notifier.activityNetControllers[originalIndex],
              enabled: !isDeleted,
            ),
          ),
          SizedBox(
            width: 100,
            child: _EditableNumberCell(
              controller: notifier.activityCopayControllers[originalIndex],
              enabled: !isDeleted,
            ),
          ),
          SizedBox(
            width: 60,
            child: Center(
              child: IconButton(
                icon: Icon(isDeleted ? Icons.undo : Icons.delete_outline, size: 18),
                color: isDeleted ? null : Theme.of(context).colorScheme.error,
                tooltip: isDeleted ? 'Restore Activity' : 'Delete Activity',
                onPressed: () => notifier.toggleActivityDeleted(originalIndex),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EditableNumberCell extends StatelessWidget {
  final TextEditingController controller;
  final bool enabled;

  const _EditableNumberCell({required this.controller, required this.enabled});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      textAlign: TextAlign.right,
      style: const TextStyle(fontSize: 14),
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        isDense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
      ],
    );
  }
}

class ControlsResubmissionCard extends StatelessWidget {
  const ControlsResubmissionCard({super.key});

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<ClaimDataNotifier>();
    final theme = Theme.of(context);
    const List<String> resubmissionOptions = [
      "correction",
      "internal complaint",
      "reconciliation"
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text("Change Resub Tag", style: theme.textTheme.titleSmall),
            const SizedBox(width: 8),
            if (notifier.originalResubmissionType != null)
              Text(
                '(Current Type: ${notifier.originalResubmissionType})',
                style: theme.textTheme.bodySmall,
              ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: resubmissionOptions.map((option) {
            return Expanded(
              child: RadioListTile<String>(
                title: Text(option, overflow: TextOverflow.ellipsis),
                value: option,
                dense: true,
                contentPadding: EdgeInsets.zero,
                groupValue: notifier.claimData?.resubmission?.type ?? 'internal complaint',
                onChanged: (value) {
                  notifier.updateResubmissionType(value);
                },
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: notifier.resubmissionCommentController,
          decoration: const InputDecoration(
            labelText: 'Resubmission Comment',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
      ],
    );
  }
}

class DiagnosisCard extends StatelessWidget {
  const DiagnosisCard({super.key});

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<ClaimDataNotifier>();
    final diagnoses = notifier.claimData!.diagnoses;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text("Reset"),
              onPressed: diagnoses.isEmpty ? null : notifier.resetDiagnoses,
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text("Add Diagnosis"),
              onPressed: () => _showSearchDialog(context, notifier),
            ),
          ],
        ),
        if (diagnoses.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(
              child: Text("No diagnoses found."),
            ),
          )
        else
          Column(
            children: [
              _DiagnosisTableHeader(),
              const Divider(height: 1),
              ...diagnoses.map((diag) => _DiagnosisDataRow(
                    key: ValueKey(diag.id),
                    notifier: notifier,
                    diag: diag,
                  ))
            ],
          )
      ],
    );
  }

  void _showSearchDialog(
      BuildContext context, ClaimDataNotifier notifier) async {
    final selectedCode = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return DiagnosisSearchDialog(
          allDiagnoses: notifier.icd10Descriptions,
        );
      },
    );
    if (selectedCode != null && context.mounted) {
      notifier.addDiagnosis(selectedCode);
    }
  }
}

class _DiagnosisTableHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodySmall;
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Row(
        children: [
          SizedBox(width: 100, child: Text('Code', style: style)),
          Expanded(child: Center(child: Text('Description', style: style))),
          SizedBox(width: 80, child: Center(child: Text('Principal', style: style))),
          SizedBox(width: 60, child: Center(child: Text('Actions', style: style))),
        ],
      ),
    );
  }
}

class _DiagnosisDataRow extends StatelessWidget {
  final ClaimDataNotifier notifier;
  final dynamic diag;

  const _DiagnosisDataRow({super.key, required this.notifier, required this.diag});

  @override
  Widget build(BuildContext context) {
    final description = notifier.icd10Descriptions[diag.code] ?? 'N/A';
    final textStyle = TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurface);
    final String? principalId = notifier.claimData!.diagnoses
        .firstWhere((d) => d.type == 'Principal', orElse: () => notifier.claimData!.diagnoses.first)
        .id;
    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      child: Row(
        children: [
          SizedBox(width: 100, child: Text(diag.code ?? '', style: textStyle)),
          Expanded(
            child: Center(
              child: Tooltip(
                message: description,
                child: Text(
                  description,
                  style: textStyle,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
          SizedBox(
            width: 80,
            child: Center(
              child: Radio<String>(
                value: diag.id,
                groupValue: principalId,
                onChanged: (value) {
                  if (value != null) {
                    notifier.setPrincipalDiagnosis(value);
                  }
                },
              ),
            ),
          ),
          SizedBox(
            width: 60,
            child: Center(
              child: IconButton(
                icon: const Icon(Icons.delete_outline, size: 18),
                color: Theme.of(context).colorScheme.error,
                tooltip: "Delete Diagnosis",
                onPressed: () => notifier.deleteDiagnosis(diag.id),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


class DiagnosisSearchDialog extends StatefulWidget {
  final Map<String, String> allDiagnoses;
  const DiagnosisSearchDialog({super.key, required this.allDiagnoses});

  @override
  State<DiagnosisSearchDialog> createState() => _DiagnosisSearchDialogState();
}

class _DiagnosisSearchDialogState extends State<DiagnosisSearchDialog> {
  final _searchController = TextEditingController();
  List<MapEntry<String, String>> _filteredDiagnoses = [];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterDiagnoses);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterDiagnoses);
    _searchController.dispose();
    super.dispose();
  }

  void _filterDiagnoses() {
    final query = _searchController.text.toLowerCase();
    if (query.length < 2) {
      // Start searching after 2 characters
      setState(() {
        _filteredDiagnoses = [];
      });
      return;
    }

    final filtered = widget.allDiagnoses.entries.where((entry) {
      final code = entry.key.toLowerCase();
      final description = entry.value.toLowerCase();
      return code.contains(query) || description.contains(query);
    }).toList();

    setState(() {
      _filteredDiagnoses = filtered;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Search Diagnosis'),
      content: SizedBox(
        width: 600,
        height: 400,
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Search by code or description...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _filteredDiagnoses.isEmpty
                  ? Center(
                      child: Text(_searchController.text.length < 2
                          ? 'Type at least 2 characters to search.'
                          : 'No results found.'))
                  : ListView.builder(
                      itemCount: _filteredDiagnoses.length,
                      itemBuilder: (context, index) {
                        final entry = _filteredDiagnoses[index];
                        return ListTile(
                          title: Text(entry.value),
                          subtitle: Text(entry.key),
                          onTap: () {
                            Navigator.of(context).pop(entry.key);
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}

class TotalsCard extends StatelessWidget {
  const TotalsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<ClaimDataNotifier>();
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _FinancialInputRow(
          label: 'Gross:',
          controller: notifier.grossController,
          difference: notifier.grossDifference,
          onChanged: () => notifier.onTotalsEdited('gross'),
        ),
        const SizedBox(height: 0),
        _FinancialInputRow(
          label: 'PatientShare:',
          controller: notifier.patientShareController,
          onChanged: () => notifier.onTotalsEdited('pshare'),
        ),
        const SizedBox(height: 0),
        _FinancialInputRow(
          label: 'Net:',
          controller: notifier.netController,
          difference: notifier.netDifference,
          onChanged: () => notifier.onTotalsEdited('net'),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            ElevatedButton(
                onPressed: notifier.autoMatchTotals,
                child: const Text('Auto Match')),
            OutlinedButton(
              onPressed: notifier.deleteAllActivities,
              style: OutlinedButton.styleFrom(
                  foregroundColor: theme.colorScheme.error),
              child: const Text('Delete All'),
            ),
            OutlinedButton(
                onPressed: notifier.addAllActivities,
                child: const Text('Add All')),
          ],
        )
      ],
    );
  }
}

class _FinancialInputRow extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String? difference;
  final VoidCallback onChanged;

  const _FinancialInputRow({
    required this.label,
    required this.controller,
    required this.onChanged,
    this.difference,
  });

  @override
  Widget build(BuildContext context) {
    final hasDiff = difference != null && difference!.isNotEmpty;
    final theme = Theme.of(context);
    return Row(
      children: [
        SizedBox(
            width: 90, child: Text(label, style: theme.textTheme.titleSmall)),
        Expanded(
          child: TextFormField(
            controller: controller,
            onChanged: (_) => onChanged(),
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              contentPadding: const EdgeInsets.symmetric(horizontal: 8),
              isDense: true,
              enabledBorder: hasDiff
                  ? OutlineInputBorder(
                      borderSide: BorderSide(color: theme.colorScheme.error))
                  : null,
            ),
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
            ],
          ),
        ),
        if (hasDiff)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Text(difference!,
                style: TextStyle(color: theme.colorScheme.error)),
          ),
        IconButton(
          icon: const Icon(Icons.copy, size: 16),
          onPressed: () {
            Clipboard.setData(ClipboardData(text: controller.text));
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('Copied to clipboard'),
                width: 200,
                behavior: SnackBarBehavior.floating));
          },
          splashRadius: 18,
        ),
      ],
    );
  }
}