import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:project_xmedit/notifiers.dart';
import 'package:project_xmedit/xml_handler.dart';
import 'package:project_xmedit/widgets/common/custom_table.dart';
import 'package:project_xmedit/widgets/common/editable_cells.dart';
import 'package:project_xmedit/dialogs/observation_dialog.dart'; // Moved here

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
      return const Center(child: Text("No activities found."));
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

        final bool isFirstGroup = index == 0;

        return Padding(
          padding: EdgeInsets.only(top: isFirstGroup ? 0 : 12.0),
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(
                color:
                    Theme.of(context).colorScheme.outlineVariant.withAlpha(128),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ActivityTableHeader(title: typeName),
                const Divider(height: 1),
                ...activitiesOfType.asMap().entries.map((entry) {
                  final int idx = entry.key;
                  final activity = entry.value;
                  final originalIndex =
                      notifier.claimData!.activities.indexOf(activity);

                  return _ActivityDataRow(
                    key: ValueKey(activity.stateId),
                    notifier: notifier,
                    activity: activity,
                    originalIndex: originalIndex,
                    isZebra: idx.isEven,
                  );
                }),
              ],
            ),
          ),
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
          child: Center(child: Text('Description', style: style)),
        ),
        Expanded(
          flex: _activityColumnFlex['priorAuth']!,
          child: Center(child: Text('Prior Auth', style: style)),
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
          child: Center(child: Text('Net', style: style)),
        ),
        Expanded(
          flex: _activityColumnFlex['copay']!,
          child: Center(child: Text('Copay', style: style)),
        ),
        Expanded(
          flex: _activityColumnFlex['actions']!,
          child: Center(child: Text('Actions', style: style)),
        ),
      ],
    );
  }
}

class _ActivityDataRow extends StatelessWidget {
  final ClaimDataNotifier notifier;
  final ActivityData activity;
  final int originalIndex;
  final bool isZebra;

  const _ActivityDataRow({
    super.key,
    required this.notifier,
    required this.activity,
    required this.originalIndex,
    required this.isZebra,
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
    final int observationCount = activity.observations.length;

    Widget codeWidget;
    if (activity.type == '8') {
      final controller = notifier.activityDslCodeControllers[activity.stateId];
      codeWidget = controller != null
          ? TextFormField(
              controller: controller,
              style: textStyle,
              decoration: const InputDecoration(
                border: UnderlineInputBorder(),
                isDense: true,
                contentPadding: EdgeInsets.only(bottom: 4),
              ),
            )
          : Text(activity.code ?? 'N/A', style: textStyle);
    } else {
      codeWidget = Text(activity.code ?? 'N/A', style: textStyle);
    }

    final originalActivity = notifier.originalActivities[originalIndex];
    final isQtyEdited = activity.quantity != (originalActivity.quantity ?? '1');

    return CustomDataRow(
      isZebra: isZebra,
      isDeleted: isDeleted,
      children: [
        Expanded(
          flex: _activityColumnFlex['code']!,
          child: codeWidget,
        ),
        Expanded(
          flex: _activityColumnFlex['qty']!,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 50,
                child: EditableQuantityCell(
                  controller:
                      notifier.activityQuantityControllers[originalIndex],
                  enabled: !isDeleted,
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
              controller: notifier.activityPriorAuthControllers[originalIndex],
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
                      activity: activity,
                      notifier: notifier,
                    ),
                  );
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
              controller: notifier.activityNetControllers[originalIndex],
              enabled: !isDeleted,
            ),
          ),
        ),
        Expanded(
          flex: _activityColumnFlex['copay']!,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: EditableNumberCell(
              controller: notifier.activityCopayControllers[originalIndex],
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
              onPressed: () => notifier.toggleActivityDeleted(originalIndex),
            ),
          ),
        ),
      ],
    );
  }
}
