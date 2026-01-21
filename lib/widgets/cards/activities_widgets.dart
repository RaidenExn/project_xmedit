import 'package:flutter/material.dart';
import 'package:project_xmedit/notifiers.dart';
import 'package:project_xmedit/providers/claim_data_provider.dart'; // Moved here
import 'package:project_xmedit/models/claim_models.dart';
import 'package:project_xmedit/widgets/common/custom_table.dart';
import 'package:project_xmedit/widgets/common/editable_cells.dart';
import 'package:project_xmedit/dialogs/observation_dialog.dart'; // Moved here

import 'package:project_xmedit/widgets/validation_widgets.dart';

const Map<String, int> _activityColumnFlex = {
  'code': 3,
  'qty': 2,
  'desc': 8,
  'priorAuth': 3,
  'obs': 2,
  'net': 2,
  'copay': 2,
  'actions': 1,
};

class ActivityTableHeader extends StatelessWidget {
  final String title;
  const ActivityTableHeader({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.titleSmall;
    return CustomTableHeader(
      children: [
        Expanded(
          flex: _activityColumnFlex['code']!,
          child:
              Text(title, style: style?.copyWith(fontWeight: FontWeight.bold)),
        ),
        Expanded(
          flex: _activityColumnFlex['qty']!,
          child: Center(child: Text('Qty', style: style)),
        ),
        Expanded(
          flex: _activityColumnFlex['desc']!,
          child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Description', style: style)),
        ),
        Expanded(
          flex: _activityColumnFlex['priorAuth']!,
          child: Align(
              alignment: Alignment.centerLeft, // Matches EditableStringCell
              child: Padding(
                padding: const EdgeInsets.only(left: 4.0),
                child: Text('Prior Auth', style: style),
              )),
        ),
        Expanded(
          flex: _activityColumnFlex['obs']!,
          child: Center(
            child: Icon(Icons.comment_outlined,
                size: 16,
                color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        ),
        Expanded(
          flex: _activityColumnFlex['net']!,
          child: Align(
              alignment: Alignment.centerRight, // Matches EditableNumberCell
              child: Padding(
                padding: const EdgeInsets.only(right: 6.0),
                child: Text('Net', style: style),
              )),
        ),
        Expanded(
          flex: _activityColumnFlex['copay']!,
          child: Align(
              alignment: Alignment.centerRight, // Matches EditableNumberCell
              child: Padding(
                padding: const EdgeInsets.only(right: 6.0),
                child: Text('Copay', style: style),
              )),
        ),
        Expanded(
          flex: _activityColumnFlex['actions']!,
          child: Center(child: Text('Actions', style: style)),
        ),
      ],
    );
  }
}

class ActivityDataRow extends StatefulWidget {
  final ClaimDataNotifier notifier;
  final ActivityData activity;
  final int originalIndex;
  final bool isZebra;

  const ActivityDataRow({
    super.key,
    required this.notifier,
    required this.activity,
    required this.originalIndex,
    required this.isZebra,
  });

  @override
  State<ActivityDataRow> createState() => _ActivityDataRowState();
}

class _ActivityDataRowState extends State<ActivityDataRow> {
  late TextEditingController _dslCodeController;
  late TextEditingController _quantityController;
  late TextEditingController _netController;
  late TextEditingController _copayController;
  late TextEditingController _priorAuthController;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    _dslCodeController =
        TextEditingController(text: widget.activity.code ?? '');
    _quantityController =
        TextEditingController(text: widget.activity.quantity ?? '1');
    _netController = TextEditingController(text: widget.activity.net ?? '0.00');
    _copayController =
        TextEditingController(text: widget.activity.copay ?? '0.00');
    _priorAuthController =
        TextEditingController(text: widget.activity.priorAuthorizationID ?? '');

    _dslCodeController.addListener(_onDslCodeChanged);
    _quantityController.addListener(_onQuantityChanged);
    _netController.addListener(_onNetChanged);
    _copayController.addListener(_onCopayChanged);
    _priorAuthController.addListener(_onPriorAuthChanged);
  }

  @override
  void didUpdateWidget(covariant ActivityDataRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.activity != widget.activity) {
      // If the activity instance changes (e.g. reload), re-init controllers
      // Note: Ideally, Key should handle this, but for safety:
      _disposeControllers();
      _initializeControllers();
    }
  }

  void _disposeControllers() {
    _dslCodeController.removeListener(_onDslCodeChanged);
    _quantityController.removeListener(_onQuantityChanged);
    _netController.removeListener(_onNetChanged);
    _copayController.removeListener(_onCopayChanged);
    _priorAuthController.removeListener(_onPriorAuthChanged);

    _dslCodeController.dispose();
    _quantityController.dispose();
    _netController.dispose();
    _copayController.dispose();
    _priorAuthController.dispose();
  }

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }

  void _onDslCodeChanged() {
    if (widget.activity.code != _dslCodeController.text) {
      // We might want to add a method on notifier to handle logic related to DSL code change
      // For now, updating the model directly and notifying listener if needed
      // But the notifier has specific logic for DSL code changes (checking against original)
      // so we should probably expose a method or keep using a callback.
      // Let's call a method on notifier to handle side effects.
      widget.notifier
          .updateActivityCode(widget.originalIndex, _dslCodeController.text);
    }
  }

  void _onQuantityChanged() {
    // Update quantity and get the new calculated net value
    final newNetText = widget.notifier
        .updateActivityQuantity(widget.originalIndex, _quantityController.text);

    // Update the net controller with the new value if one was returned
    if (newNetText != null && _netController.text != newNetText) {
      _netController.text = newNetText;
    }
  }

  void _onNetChanged() {
    // Just update model and check balances
    widget.activity.net = _netController.text;
    widget.notifier.checkBalances();
  }

  void _onCopayChanged() {
    widget.activity.copay = _copayController.text;
    widget.notifier.checkBalances();
  }

  void _onPriorAuthChanged() {
    widget.activity.priorAuthorizationID = _priorAuthController.text;
  }

  @override
  Widget build(BuildContext context) {
    // We need to listen to notifier somewhat? Actually, if we update via notifier, it calls notifyListeners.
    // The parent ActivitiesCard rebuilds, so this widget might receive new props.
    // But since we are stateful and use controllers, we are the source of truth for the text while editing.

    final isDeleted = widget.activity.isDeleted;
    final textStyle = TextStyle(
      fontSize: 14,
      fontStyle: isDeleted ? FontStyle.italic : null,
      color: isDeleted ? Theme.of(context).colorScheme.error : null,
    );
    final description =
        widget.notifier.cptDescriptions[widget.activity.code] ?? 'N/A';
    final int observationCount = widget.activity.observations.length;

    final validationResult = widget.notifier.validationResult;
    // XmlValidator uses 1-based index for activities
    final validationIndex = widget.originalIndex + 1;

    Widget codeWidget;
    if (widget.activity.type == '8') {
      codeWidget = TextFormField(
        controller: _dslCodeController,
        style: textStyle,
        decoration: const InputDecoration(
          border: UnderlineInputBorder(),
          isDense: true,
          contentPadding: EdgeInsets.only(bottom: 4),
        ),
      );
    } else {
      codeWidget = Text(widget.activity.code ?? 'N/A', style: textStyle);
    }

    // Checking for specific field errors
    final codeError = validationResult
        ?.getFirstErrorForField('activity_${validationIndex}_code');
    final quantityError = validationResult
        ?.getFirstErrorForField('activity_${validationIndex}_quantity');
    final netError = validationResult
        ?.getFirstErrorForField('activity_${validationIndex}_net');
    // Note: copay and priorAuth might not have specific validations yet, but we can add placeholders

    final originalActivity =
        widget.notifier.originalActivities[widget.originalIndex];
    final isQtyEdited =
        widget.activity.quantity != (originalActivity.quantity ?? '1');

    return CustomDataRow(
      isZebra: widget.isZebra,
      isDeleted: isDeleted,
      children: [
        Expanded(
          flex: _activityColumnFlex['code']!,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              codeWidget,
              if (codeError != null && !isDeleted)
                ValidationIndicator(error: codeError, size: 12),
            ],
          ),
        ),
        Expanded(
          flex: _activityColumnFlex['qty']!,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 50,
                child: EditableQuantityCell(
                  controller: _quantityController,
                  enabled: !isDeleted,
                  validationError: quantityError,
                ),
              ),
              if (isQtyEdited && !isDeleted)
                const Padding(
                  padding: EdgeInsets.only(left: 4.0),
                  child: Tooltip(
                    message: 'Quantity has been modified',
                    child: Icon(Icons.edit_note, size: 16),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          flex: _activityColumnFlex['desc']!,
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              description,
              style: textStyle,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.left,
            ),
          ),
        ),
        Expanded(
          flex: _activityColumnFlex['priorAuth']!,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: EditableStringCell(
              controller: _priorAuthController,
              enabled: !isDeleted,
              hintText: 'Auth ID',
            ),
          ),
        ),
        Expanded(
          flex: _activityColumnFlex['obs']!,
          child: Center(
            child: Tooltip(
              message: "Manage Observations",
              child: TextButton(
                style: TextButton.styleFrom(
                  shape: const CircleBorder(),
                  backgroundColor: observationCount > 0
                      ? Theme.of(context).colorScheme.secondaryContainer
                      : null,
                ),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => ObservationDialog(
                      activity: widget.activity,
                      notifier: widget.notifier,
                    ),
                  ).then((_) {
                    // Force rebuild to show updated observation count if changed
                    setState(() {});
                  });
                },
                child: Text(
                  '$observationCount',
                  style: TextStyle(
                    color: observationCount > 0
                        ? Theme.of(context).colorScheme.onSecondaryContainer
                        : Theme.of(context).disabledColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ),
        Expanded(
          flex: _activityColumnFlex['net']!,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: EditableNumberCell(
              controller: _netController,
              enabled: !isDeleted,
              validationError: netError,
            ),
          ),
        ),
        Expanded(
          flex: _activityColumnFlex['copay']!,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: EditableNumberCell(
              controller: _copayController,
              enabled: !isDeleted,
            ),
          ),
        ),
        Expanded(
          flex: _activityColumnFlex['actions']!,
          child: Center(
            child: IconButton(
              icon:
                  Icon(isDeleted ? Icons.undo : Icons.delete_outline, size: 18),
              color: isDeleted ? null : Theme.of(context).colorScheme.error,
              onPressed: () =>
                  widget.notifier.toggleActivityDeleted(widget.originalIndex),
            ),
          ),
        ),
      ],
    );
  }
}
