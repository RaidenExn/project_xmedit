import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:project_xmedit/notifiers.dart';
import 'package:project_xmedit/widgets.dart';

class ControlsResubmissionCard extends StatefulWidget {
  const ControlsResubmissionCard({super.key});

  @override
  State<ControlsResubmissionCard> createState() =>
      _ControlsResubmissionCardState();
}

class _ControlsResubmissionCardState extends State<ControlsResubmissionCard> {
  static const List<String> _resubmissionTypes = [
    'correction',
    'internal complaint',
    'reconciliation',
  ];

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
    final theme = Theme.of(context);
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

    return LayoutBuilder(builder: (context, constraints) {
      // If very narrow (e.g. mobile), fallback to column (optional, but good practice)
      final bool isNarrow = constraints.maxWidth < 400;

      if (isNarrow) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildCommentField(theme, notifier),
            const SizedBox(height: 12),
            ..._resubmissionTypes.map((type) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _buildSelectionButton(
                    context,
                    type,
                    selectedType,
                    notifier,
                  ),
                )),
          ],
        );
      }

      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 6,
            child: _buildCommentField(theme, notifier),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                ..._resubmissionTypes.map((type) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _buildSelectionButton(
                        context,
                        type,
                        selectedType,
                        notifier,
                      ),
                    )),
              ],
            ),
          ),
        ],
      );
    });
  }

  Widget _buildCommentField(ThemeData theme, ClaimDataNotifier notifier) {
    return ScrollableOnHover(
      child: TextFormField(
        controller: _commentController,
        decoration: InputDecoration(
          labelText: 'Resubmission Comment',
          alignLabelWithHint: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
                color: theme.colorScheme.outlineVariant.withAlpha(170)),
          ),
          fillColor: theme.colorScheme.surfaceContainerLowest.withAlpha(220),
          filled: true,
          contentPadding: const EdgeInsets.all(12),
          isDense: true,
        ),
        maxLines: 7, // Taller to match the height of 3 buttons
        minLines: 7,
        style: theme.textTheme.bodyMedium,
        onChanged: (value) {
          if (notifier.claimData?.resubmission != null) {
            notifier.claimData!.resubmission!.comment = value;
          }
        },
      ),
    );
  }

  Widget _buildSelectionButton(BuildContext context, String value,
      String selected, ClaimDataNotifier notifier) {
    final isSelected = value == selected;
    final theme = Theme.of(context);
    // Capitalize label
    final label = value
        .split(' ')
        .map((w) => w.isNotEmpty ? w[0].toUpperCase() + w.substring(1) : '')
        .join(' ');

    return InkWell(
      onTap: () => notifier.updateResubmissionType(value),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isSelected
                ? [
                    theme.colorScheme.secondaryContainer,
                    theme.colorScheme.primaryContainer.withAlpha(190),
                  ]
                : [
                    theme.colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.5),
                    theme.colorScheme.surfaceContainer.withValues(alpha: 0.2),
                  ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          color: isSelected
              ? null
              : theme.colorScheme.surfaceContainerHighest
                  .withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary.withAlpha(170)
                : theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
            width: isSelected ? 2 : 1,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: isSelected
                ? theme.colorScheme.onPrimaryContainer
                : theme.colorScheme.onSurfaceVariant,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}
