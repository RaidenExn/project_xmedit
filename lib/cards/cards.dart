import 'dart:convert';
import 'package:collection/collection.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:project_xmedit/database_helper.dart';
import 'package:project_xmedit/helpers/platform_helper.dart';
import 'package:project_xmedit/notifiers.dart';
import 'package:project_xmedit/xml_handler.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';

void _showInfoSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(message),
    behavior: SnackBarBehavior.floating,
    width: 200,
    duration: const Duration(seconds: 1),
  ));
}

void _copyToClipboard(BuildContext context, String text) {
  Clipboard.setData(ClipboardData(text: text.isEmpty ? 'N/A' : text));
  _showInfoSnackBar(context, 'Copied to clipboard');
}

class ClaimDataSection extends StatelessWidget {
  final String title;
  final Widget child;
  final bool canStretch;
  final IconData? titleIcon;
  final Widget? titleSuffix;
  final List<Widget>? actions;

  const ClaimDataSection({
    super.key,
    required this.title,
    required this.child,
    this.canStretch = false,
    this.titleIcon,
    this.titleSuffix,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textStyles = Theme.of(context).textTheme;

    return Card(
      elevation: 1,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
        side: BorderSide(color: colors.outlineVariant.withAlpha(128)),
      ),
      child: Column(
        mainAxisSize: canStretch ? MainAxisSize.max : MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 3.0),
            color: colors.surfaceContainer,
            child: Row(
              children: [
                if (titleIcon != null) ...[
                  Icon(titleIcon, size: 16, color: textStyles.titleSmall?.color),
                  const SizedBox(width: 8),
                ],
                Text(title, style: textStyles.titleSmall),
                if (titleSuffix != null) ...[
                  const SizedBox(width: 8),
                  titleSuffix!,
                ],
                const Spacer(),
                if (actions != null) Row(mainAxisSize: MainAxisSize.min, children: actions!),
              ],
            ),
          ),
          Padding(padding: const EdgeInsets.all(12.0), child: child),
        ],
      ),
    );
  }
}

class _InfoField extends StatelessWidget {
  final String label;
  final String value;
  final bool showCopyButton;

  const _InfoField({required this.label, required this.value, this.showCopyButton = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label, style: theme.textTheme.bodySmall),
              const SizedBox(height: 2.0),
              Text(value.isEmpty ? 'N/A' : value, style: theme.textTheme.bodyLarge),
            ],
          ),
          if (showCopyButton) ...[
            const SizedBox(width: 8.0),
            IconButton(
              icon: const Icon(Icons.copy, size: 18),
              onPressed: () => _copyToClipboard(context, value),
              splashRadius: 20,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ],
      ),
    );
  }
}

class WindowButtons extends StatelessWidget {
  const WindowButtons({super.key});

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 138,
        height: 50,
        child: WindowCaption(
          brightness: Theme.of(context).brightness,
          backgroundColor: Colors.transparent,
        ),
      );
}

// --- Table/Row Helper Widgets ---

const Map<String, int> _activityColumnFlex = {'code': 3, 'qty': 2, 'desc': 10, 'obs': 2, 'net': 2, 'copay': 2, 'actions': 1};

Color? _getRowColor(BuildContext context, {required bool isZebra, bool isDeleted = false, bool isHighlighted = false}) {
  final theme = Theme.of(context);
  if (isDeleted) return theme.colorScheme.error.withAlpha(15);
  if (isHighlighted) return theme.colorScheme.primaryContainer.withAlpha(75);
  if (isZebra) return theme.colorScheme.surfaceContainerHighest.withAlpha(128);
  return null;
}

class _CustomTableHeader extends StatelessWidget {
  final List<Widget> children;
  const _CustomTableHeader({required this.children});

  @override
  Widget build(BuildContext context) => Container(
        height: 28,
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: Row(children: children),
      );
}

class _CustomDataRow extends StatelessWidget {
  final List<Widget> children;
  final bool isZebra;
  final bool isDeleted;
  final bool isHighlighted;

  const _CustomDataRow({required this.children, this.isZebra = false, this.isDeleted = false, this.isHighlighted = false});

  @override
  Widget build(BuildContext context) => Container(
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        color: _getRowColor(context, isZebra: isZebra, isDeleted: isDeleted, isHighlighted: isHighlighted),
        child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: children),
      );
}

// --- Card Widgets ---

class ClaimDetailsCard extends StatelessWidget {
  const ClaimDetailsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final claimData = context.watch<ClaimDataNotifier>().claimData!;
    return Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      children: [
        _InfoField(label: 'Claim ID', value: claimData.claimId ?? '', showCopyButton: true),
        _InfoField(label: "Member ID", value: claimData.memberID ?? '', showCopyButton: true),
        _InfoField(label: "Sender ID", value: claimData.senderID ?? ''),
        _InfoField(label: "Payer ID", value: claimData.payerID ?? ''),
        _InfoField(label: "Receiver ID", value: claimData.receiverID ?? ''),
        _InfoField(label: "Transaction Date", value: claimData.transactionDate ?? ''),
        _InfoField(label: "Start Date", value: claimData.start ?? ''),
      ],
    );
  }
}

class ActivitiesCard extends StatelessWidget {
  const ActivitiesCard({super.key});

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<ClaimDataNotifier>();
    const typeMap = {"3": "CPT", "8": "DSL", "5": "Drug", "6": "CDT"};

    if (notifier.claimData?.activities.isEmpty ?? true) {
      return const Center(child: Padding(padding: EdgeInsets.all(16.0), child: Text("No activities found in this claim.")));
    }

    final grouped = notifier.groupedActivities;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < grouped.keys.length; i++)
          Padding(
            padding: EdgeInsets.only(top: i == 0 ? 0 : 12.0),
            child: _ActivityGroup(
              typeKey: grouped.keys.elementAt(i),
              activities: grouped.values.elementAt(i),
              typeName: typeMap[grouped.keys.elementAt(i)] ?? 'Unknown Type',
            ),
          ),
      ],
    );
  }
}

class _ActivityGroup extends StatelessWidget {
  final String typeKey;
  final List<ActivityData> activities;
  final String typeName;
  const _ActivityGroup({required this.typeKey, required this.activities, required this.typeName});

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withAlpha(128)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ActivityTableHeader(title: typeName),
          const Divider(height: 1),
          for (var MapEntry(key: idx, value: activity) in activities.asMap().entries)
            _ActivityDataRow(
              key: ValueKey(activity.stateId),
              activity: activity,
              isZebra: idx.isEven,
            ),
        ],
      ),
    );
  }
}

class _ActivityTableHeader extends StatelessWidget {
  final String title;
  const _ActivityTableHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodySmall;
    Widget cell(String label, String key, {bool isTitle = false, bool isIcon = false}) => Expanded(
        flex: _activityColumnFlex[key]!,
        child: Center(
            child: isIcon
                ? Icon(Icons.comment_outlined, size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant)
                : Text(label, style: isTitle ? style?.copyWith(fontWeight: FontWeight.bold) : style)));

    return _CustomTableHeader(children: [
      Expanded(flex: _activityColumnFlex['code']!, child: Text(title, style: style?.copyWith(fontWeight: FontWeight.bold))),
      cell('Qty', 'qty'),
      cell('Description', 'desc'),
      cell('', 'obs', isIcon: true),
      cell('Net', 'net'),
      cell('Copay', 'copay'),
      cell('Actions', 'actions'),
    ]);
  }
}

class _ActivityDataRow extends StatelessWidget {
  final ActivityData activity;
  final bool isZebra;

  const _ActivityDataRow({super.key, required this.activity, required this.isZebra});

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<ClaimDataNotifier>();
    final originalIndex = notifier.claimData!.activities.indexOf(activity);

    if (originalIndex < 0 || originalIndex >= notifier.originalActivities.length) return const SizedBox.shrink();

    final isDeleted = activity.isDeleted;
    final textStyle = TextStyle(fontSize: 14, decoration: isDeleted ? TextDecoration.lineThrough : null, color: isDeleted ? Theme.of(context).disabledColor : null);
    final description = notifier.cptDescriptions[activity.code] ?? 'N/A';
    final observationCount = activity.observations.length;
    final isQtyEdited = activity.quantity != (notifier.originalActivities[originalIndex].quantity ?? '1');
    final isDslType = activity.type == '8';

    Widget codeWidget;
    if (isDslType && notifier.activityDslCodeControllers[activity.stateId] != null) {
      codeWidget = TextFormField(
        controller: notifier.activityDslCodeControllers[activity.stateId]!,
        style: textStyle,
        decoration: const InputDecoration(border: UnderlineInputBorder(), isDense: true, contentPadding: EdgeInsets.only(bottom: 4)),
      );
    } else {
      codeWidget = Text(activity.code ?? 'N/A', style: textStyle);
    }

    return _CustomDataRow(isZebra: isZebra, isDeleted: isDeleted, children: [
      Expanded(flex: _activityColumnFlex['code']!, child: codeWidget),
      Expanded(
          flex: _activityColumnFlex['qty']!,
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            SizedBox(width: 50, child: _EditableQuantityCell(controller: notifier.activityQuantityControllers[originalIndex], enabled: !isDeleted)),
            if (isQtyEdited && !isDeleted)
              const Padding(padding: EdgeInsets.only(left: 4.0), child: Tooltip(message: 'Quantity has been modified', child: Icon(Icons.edit_note, size: 16))),
          ])),
      Expanded(flex: _activityColumnFlex['desc']!, child: Center(child: Text(description, style: textStyle, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center))),
      Expanded(
        flex: _activityColumnFlex['obs']!,
        child: Center(
          child: Tooltip(
            message: "Manage Observations",
            child: TextButton(
              style: TextButton.styleFrom(
                  shape: const CircleBorder(), backgroundColor: observationCount > 0 ? Theme.of(context).colorScheme.secondaryContainer : null),
              onPressed: kIsWeb ? null : () => showDialog(context: context, builder: (_) => ObservationDialog(activity: activity, notifier: notifier)),
              child: Text('$observationCount',
                  style: TextStyle(
                      color: observationCount > 0 ? Theme.of(context).colorScheme.onSecondaryContainer : Theme.of(context).disabledColor,
                      fontWeight: FontWeight.bold)),
            ),
          ),
        ),
      ),
      Expanded(
          flex: _activityColumnFlex['net']!,
          child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: _EditableNumberCell(controller: notifier.activityNetControllers[originalIndex], enabled: !isDeleted))),
      Expanded(
          flex: _activityColumnFlex['copay']!,
          child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: _EditableNumberCell(controller: notifier.activityCopayControllers[originalIndex], enabled: !isDeleted))),
      Expanded(
          flex: _activityColumnFlex['actions']!,
          child: Center(
              child: IconButton(
            icon: Icon(isDeleted ? Icons.undo : Icons.delete_outline, size: 18),
            color: isDeleted ? null : Theme.of(context).colorScheme.error,
            onPressed: () => notifier.toggleActivityDeleted(originalIndex),
          ))),
    ]);
  }
}

class _EditableQuantityCell extends StatelessWidget {
  final TextEditingController controller;
  final bool enabled;

  const _EditableQuantityCell({required this.controller, required this.enabled});

  @override
  Widget build(BuildContext context) => TextFormField(
        controller: controller,
        enabled: enabled,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 14),
        decoration: const InputDecoration(border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero),
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      );
}

class _EditableNumberCell extends StatelessWidget {
  final TextEditingController controller;
  final bool enabled;

  const _EditableNumberCell({required this.controller, required this.enabled});

  @override
  Widget build(BuildContext context) => TextFormField(
        controller: controller,
        enabled: enabled,
        textAlign: TextAlign.right,
        style: const TextStyle(fontSize: 14),
        decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 6)),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
      );
}

class ControlsResubmissionCard extends StatelessWidget {
  const ControlsResubmissionCard({super.key});

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<ClaimDataNotifier>();
    final selectedType = notifier.claimData?.resubmission?.type ?? 'internal complaint';
    const options = ["correction", "internal complaint", "reconciliation"];

    return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(children: [
        for (final option in options)
          Expanded(
            child: RadioListTile<String>(
              title: Text(option, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: option == selectedType ? FontWeight.bold : FontWeight.normal)),
              value: option,
              dense: true,
              contentPadding: EdgeInsets.zero,
              groupValue: selectedType,
              onChanged: notifier.updateResubmissionType,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
            ),
          )
      ]),
      const SizedBox(height: 10),
      TextFormField(
        controller: notifier.resubmissionCommentController,
        decoration: const InputDecoration(labelText: 'Resubmission Comment', border: OutlineInputBorder()),
        maxLines: 2,
        minLines: 2,
      ),
    ]);
  }
}

class DiagnosisCard extends StatelessWidget {
  const DiagnosisCard({super.key});

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<ClaimDataNotifier>();
    final diagnoses = notifier.claimData!.diagnoses;

    if (diagnoses.isEmpty) {
      return const Center(child: Text("No diagnoses found. Use the 'Add' button in the title bar."));
    }

    return Column(children: [
      const _DiagnosisTableHeader(),
      const Divider(height: 1),
      for (var MapEntry(key: idx, value: diag) in diagnoses.asMap().entries)
        _DiagnosisDataRow(key: ValueKey(diag.id), diag: diag, isZebra: idx.isEven),
    ]);
  }
}

class _DiagnosisTableHeader extends StatelessWidget {
  const _DiagnosisTableHeader();

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodySmall;
    return _CustomTableHeader(children: [
      SizedBox(width: 100, child: Text('Code', style: style)),
      Expanded(child: Center(child: Text('Description', style: style))),
      SizedBox(width: 80, child: Center(child: Text('Principal', style: style))),
      SizedBox(width: 60, child: Center(child: Text('Actions', style: style))),
    ]);
  }
}

class _DiagnosisDataRow extends StatefulWidget {
  final DiagnosisData diag;
  final bool isZebra;
  const _DiagnosisDataRow({super.key, required this.diag, required this.isZebra});

  @override
  State<_DiagnosisDataRow> createState() => _DiagnosisDataRowState();
}

class _DiagnosisDataRowState extends State<_DiagnosisDataRow> {
  late Future<String?> _descriptionFuture;

  @override
  void initState() {
    super.initState();
    _descriptionFuture = kIsWeb ? Future.value("N/A") : DatabaseHelper().getIcd10Description(widget.diag.code ?? '');
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<ClaimDataNotifier>();
    final isEditing = notifier.isDiagnosisEditingEnabled;
    final textStyle = TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurface);
    final principalId = notifier.claimData!.diagnoses.firstWhere((d) => d.type == 'Principal', orElse: () => notifier.claimData!.diagnoses.first).id;
    final isPrincipal = widget.diag.type == 'Principal';

    return FutureBuilder<String?>(
        future: _descriptionFuture,
        builder: (context, snapshot) {
          final description = snapshot.connectionState == ConnectionState.done ? (snapshot.data ?? 'N/A') : 'Loading...';
          return _CustomDataRow(isZebra: widget.isZebra, isHighlighted: isPrincipal, children: [
            SizedBox(width: 100, child: Text(widget.diag.code ?? '', style: textStyle)),
            Expanded(child: Center(child: Text(description, style: textStyle, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center))),
            SizedBox(
                width: 80,
                child: Center(
                    child: Radio<String>(
                        value: widget.diag.id,
                        groupValue: principalId,
                        onChanged: isEditing ? (value) => value != null ? notifier.setPrincipalDiagnosis(value) : null : null))),
            SizedBox(
                width: 60,
                child: Center(
                    child: IconButton(
                        icon: const Icon(Icons.delete_outline, size: 18),
                        color: Theme.of(context).colorScheme.error,
                        onPressed: isEditing ? () => notifier.deleteDiagnosis(widget.diag.id) : null))),
          ]);
        });
  }
}

void showDiagnosisSearchDialog(BuildContext context, ClaimDataNotifier notifier) async {
  final selectedCode = await showDialog<String>(context: context, builder: (context) => const DiagnosisSearchDialog());
  if (selectedCode != null && context.mounted) {
    notifier.addDiagnosis(selectedCode);
  }
}

class DiagnosisSearchDialog extends StatefulWidget {
  const DiagnosisSearchDialog({super.key});
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

  Future<void> _filterDiagnoses() async {
    final query = _searchController.text;
    if (query.length < 2) {
      if (mounted) setState(() => _filteredDiagnoses = []);
      return;
    }
    final results = await DatabaseHelper().searchIcd10(query);
    if (mounted) setState(() => _filteredDiagnoses = results);
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
      title: const Text('Search Diagnosis'),
      content: SizedBox(
          width: 600,
          height: 400,
          child: Column(children: [
            TextField(
              controller: _searchController,
              autofocus: true,
              decoration: const InputDecoration(
                  labelText: 'Search by code or description...', border: OutlineInputBorder(), prefixIcon: Icon(Icons.search)),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _filteredDiagnoses.isEmpty
                  ? Center(child: Text(_searchController.text.length < 2 ? 'Type at least 2 characters to search.' : 'No results found.'))
                  : ListView.builder(
                      itemCount: _filteredDiagnoses.length,
                      itemBuilder: (context, index) {
                        final entry = _filteredDiagnoses[index];
                        return ListTile(
                            title: Text(entry.value), subtitle: Text(entry.key), onTap: () => Navigator.of(context).pop(entry.key));
                      },
                    ),
            ),
          ])),
      actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel'))]);
}

class TotalsCard extends StatelessWidget {
  const TotalsCard({super.key});
  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<ClaimDataNotifier>();
    return Column(mainAxisSize: MainAxisSize.min, children: [
      _FinancialInputRow(
          label: 'Gross:',
          controller: notifier.grossController,
          difference: notifier.grossDifference,
          onChanged: () => notifier.onTotalsEdited('gross')),
      const SizedBox(height: 8),
      _FinancialInputRow(
          label: 'PatientShare:', controller: notifier.patientShareController, onChanged: () => notifier.onTotalsEdited('pshare')),
      const SizedBox(height: 8),
      _FinancialInputRow(
          label: 'Net:',
          controller: notifier.netController,
          difference: notifier.netDifference,
          onChanged: () => notifier.onTotalsEdited('net')),
    ]);
  }
}

class _FinancialInputRow extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String? difference;
  final VoidCallback onChanged;
  const _FinancialInputRow({required this.label, required this.controller, required this.onChanged, this.difference});

  @override
  Widget build(BuildContext context) {
    final hasDiff = difference?.isNotEmpty ?? false;
    final theme = Theme.of(context);
    return Row(children: [
      SizedBox(width: 90, child: Text(label, style: theme.textTheme.titleSmall)),
      Expanded(
        child: TextFormField(
          controller: controller,
          onChanged: (_) => onChanged(),
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            contentPadding: const EdgeInsets.symmetric(horizontal: 8),
            isDense: true,
            enabledBorder: hasDiff ? OutlineInputBorder(borderSide: BorderSide(color: theme.colorScheme.error)) : null,
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
        ),
      ),
      if (hasDiff)
        Padding(padding: const EdgeInsets.symmetric(horizontal: 4.0), child: Text(difference!, style: TextStyle(color: theme.colorScheme.error))),
      IconButton(
        icon: const Icon(Icons.copy, size: 16),
        onPressed: () => _copyToClipboard(context, controller.text),
        splashRadius: 18,
      ),
    ]);
  }
}

// --- Observation Manager Widgets & Dialogs ---

class ObservationDialog extends StatefulWidget {
  final ActivityData activity;
  final ClaimDataNotifier notifier;

  const ObservationDialog({super.key, required this.activity, required this.notifier});
  @override
  State<ObservationDialog> createState() => _ObservationDialogState();
}

class _ObservationDialogState extends State<ObservationDialog> {
  Future<void> _addOrEditObservation({ObservationData? existing}) async {
    final result = await showDialog<ObservationData>(
        context: context,
        barrierDismissible: false,
        builder: (_) => AddEditObservationDialog(observation: existing, activity: widget.activity));
    if (result != null) {
      setState(() => existing != null
          ? widget.notifier.updateObservation(widget.activity.stateId, result)
          : widget.notifier.addObservation(widget.activity.stateId, result));
    }
  }

  Future<void> _deleteObservation(ObservationData obs) async {
    final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
                title: const Text('Confirm Deletion'),
                content: Text('Delete observation: ${obs.code}?'),
                actions: [
                  TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
                  TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
                      child: const Text('Delete'))
                ]));
    if (confirm == true) {
      setState(() => widget.notifier.deleteObservation(widget.activity.stateId, obs.id));
    }
  }

  IconData _getIconForType(String type) => switch (type) {
        'File' => Icons.attach_file,
        'Result' => Icons.science_outlined,
        'Text' => Icons.notes,
        'Presenting-Complaint' => Icons.emergency_outlined,
        'Universal Dental' => Icons.medical_services_outlined,
        _ => Icons.comment_outlined
      };

  @override
  Widget build(BuildContext context) {
    final groupedObservations = groupBy(widget.activity.observations, (ObservationData obs) => obs.type);

    return AlertDialog(
      title: Text('Observations for Activity ${widget.activity.code}'),
      content: SizedBox(
        width: 700,
        height: 500,
        child: widget.activity.observations.isEmpty
            ? _buildEmptyState()
            : ListView(children: [
                for (var entry in groupedObservations.entries) _buildObservationGroup(entry.key, entry.value),
              ]),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close')),
        FilledButton.icon(icon: const Icon(Icons.add), label: const Text('Add Observation'), onPressed: _addOrEditObservation),
      ],
    );
  }

  Widget _buildEmptyState() => Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.find_in_page_outlined, size: 64, color: Theme.of(context).disabledColor),
        const SizedBox(height: 16),
        Text('No Observations Added', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        const Text('Click "Add Observation" to get started.'),
      ]));

  Widget _buildObservationGroup(String type, List<ObservationData> observations) {
    final isMergeable = (type == 'Text' || type == 'Presenting-Complaint') && observations.length > 1;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
          padding: const EdgeInsets.fromLTRB(8, 12, 8, 0),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(type, style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Theme.of(context).colorScheme.primary)),
            if (isMergeable)
              TextButton.icon(
                icon: const Icon(Icons.merge_type, size: 16),
                label: const Text('Merge'),
                onPressed: () => setState(() => widget.notifier.mergeObservations(widget.activity.stateId, type)),
                style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
              ),
          ])),
      for (var obs in observations) _buildObservationTile(obs),
      const Divider(),
    ]);
  }

  Widget _buildObservationTile(ObservationData obs) {
    String subtitleText = 'Value: ${obs.value}';
    Widget? customTrailing;

    if (obs.type == 'File') {
      try {
        final sizeInKb = (base64Decode(obs.value).lengthInBytes / 1024).toStringAsFixed(2);
        subtitleText = 'File Attachment: $sizeInKb KB';
      } catch (_) {
        subtitleText = 'Corrupt or invalid attachment data';
      }
      customTrailing = TextButton.icon(
        icon: const Icon(Icons.visibility_outlined, size: 18),
        label: const Text('View'),
        onPressed: () => AttachmentHelper.viewDecodedFile(obs.value, context),
      );
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: ListTile(
        leading: Icon(_getIconForType(obs.type)),
        title: Text(obs.code),
        subtitle: obs.value.isNotEmpty ? Text(subtitleText, maxLines: 2, overflow: TextOverflow.ellipsis) : null,
        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
          if (customTrailing != null) customTrailing,
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 20),
            onPressed: () => _addOrEditObservation(existing: obs),
            tooltip: 'Edit',
          ),
          IconButton(
            icon: Icon(Icons.delete_outline, size: 20, color: Theme.of(context).colorScheme.error),
            onPressed: () => _deleteObservation(obs),
            tooltip: 'Delete',
          ),
        ]),
      ),
    );
  }
}

class AddEditObservationDialog extends StatefulWidget {
  final ObservationData? observation;
  final ActivityData activity;
  const AddEditObservationDialog({super.key, this.observation, required this.activity});
  @override
  State<AddEditObservationDialog> createState() => _AddEditObservationDialogState();
}

class _AddEditObservationDialogState extends State<AddEditObservationDialog> {
  final _formKey = GlobalKey<FormState>();
  late String _selectedType;
  late TextEditingController _codeController, _valueController, _valueTypeController;
  String? _fileName, _fileBase64;
  bool _isDragging = false;

  final List<String> _observationTypes = ['Text', 'File', 'Result', 'Presenting-Complaint', 'Universal Dental'];

  @override
  void initState() {
    super.initState();
    final obs = widget.observation;
    _selectedType = obs?.type ?? (widget.activity.type == '6' ? 'Universal Dental' : _observationTypes.first);
    _codeController = TextEditingController(text: obs?.code ?? '');
    _valueController = TextEditingController(text: obs?.value ?? '');
    _valueTypeController = TextEditingController(text: obs?.valueType ?? '');

    if (_selectedType == 'File') {
      _fileBase64 = obs?.value;
      if (obs == null) _valueTypeController.text = 'Base64';
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    _valueController.dispose();
    _valueTypeController.dispose();
    super.dispose();
  }

  Future<void> _handleFile({required String name, required Uint8List bytes}) async {
    try {
      final base64 = await AttachmentHelper.encodeFromBytes(bytes);
      setState(() {
        _fileBase64 = base64;
        _fileName = name;
      });
    } catch (e) {
      if (mounted) _showInfoSnackBar(context, 'Error handling file: $e');
    }
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedType == 'File' && _fileBase64 == null) {
      _showInfoSnackBar(context, 'Please select or drop a file.');
      return;
    }

    String value, valueType;
    switch (_selectedType) {
      case 'File':
        value = _fileBase64!;
        valueType = _valueTypeController.text;
        break;
      case 'Universal Dental':
        value = '';
        valueType = '';
        break;
      default:
        value = _valueController.text;
        valueType = _valueTypeController.text;
        break;
    }

    final newObservation = ObservationData(
      type: _selectedType,
      code: _codeController.text,
      value: value,
      valueType: valueType,
    );

    if (widget.observation != null) {
      newObservation.id = widget.observation!.id;
    }

    Navigator.of(context).pop(newObservation);
  }

  @override
  Widget build(BuildContext context) {
    final dropTargetChild = Container(
        decoration: _isDragging && _selectedType == 'File'
            ? BoxDecoration(border: Border.all(color: Theme.of(context).colorScheme.primary, width: 2), borderRadius: BorderRadius.circular(8.0))
            : null,
        width: 500,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
            DropdownButtonFormField<String>(
                initialValue: _selectedType,
                items: _observationTypes.map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    _selectedType = value;
                    _codeController.clear();
                    _valueController.clear();
                    _valueTypeController.clear();
                    _fileBase64 = null;
                    _fileName = null;
                    if (_selectedType == 'File') _valueTypeController.text = 'Base64';
                  });
                },
                decoration: const InputDecoration(labelText: 'Observation Type')),
            const SizedBox(height: 16),
            TextFormField(
                controller: _codeController,
                decoration: const InputDecoration(labelText: 'Code', helperText: 'e.g., "Attachment" or a LOINC code'),
                validator: (v) => v!.isEmpty ? 'Code cannot be empty' : null),
            const SizedBox(height: 16),
            _buildTypeSpecificFields(),
            const SizedBox(height: 16),
            if (_selectedType != 'Universal Dental')
              TextFormField(
                  controller: _valueTypeController,
                  decoration: const InputDecoration(labelText: 'Value Type'),
                  readOnly: _selectedType == 'File'),
          ])),
        ));

    return AlertDialog(
        title: Text(widget.observation != null ? 'Edit Observation' : 'Add Observation'),
        content: DropTarget(
          onDragDone: (details) async {
            if (details.files.isNotEmpty && _selectedType == 'File') {
              final file = details.files.first;
              await _handleFile(name: file.name, bytes: await file.readAsBytes());
            }
          },
          onDragEntered: (_) => setState(() => _isDragging = true),
          onDragExited: (_) => setState(() => _isDragging = false),
          child: dropTargetChild,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
          FilledButton(onPressed: _save, child: const Text('Save'))
        ]);
  }

  Widget _buildTypeSpecificFields() {
    switch (_selectedType) {
      case 'File':
        return _buildFilePicker();
      case 'Universal Dental':
        return const SizedBox.shrink();
      default:
        return TextFormField(
            controller: _valueController,
            decoration: const InputDecoration(labelText: 'Value'),
            maxLines: 3,
            validator: (v) => v!.isEmpty ? 'Value cannot be empty' : null,
            onChanged: (v) {
              if (_selectedType == 'Result' && double.tryParse(v) != null) {
                _valueTypeController.text = 'Decimal';
              }
            });
    }
  }

  Widget _buildFilePicker() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(kIsWeb ? 'Attachment' : 'Attachment (Select file or drop on window)',
            style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color)),
        const SizedBox(height: 8),
        Row(children: [
          ElevatedButton.icon(
              icon: const Icon(Icons.attach_file),
              label: const Text('Select File'),
              onPressed: () async {
                final result = await FilePicker.platform.pickFiles(withData: true);
                if (result?.files.single.bytes != null) {
                  await _handleFile(name: result!.files.single.name, bytes: result.files.single.bytes!);
                }
              }),
          const SizedBox(width: 16),
          Expanded(
              child: Text(
                  _fileName ?? (_fileBase64 != null ? 'Existing attachment loaded' : 'No file selected'),
                  overflow: TextOverflow.ellipsis)),
        ]),
      ]);
}