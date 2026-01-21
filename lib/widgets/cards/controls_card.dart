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
            _buildSelectionButton(
                context, 'correction', selectedType, notifier),
            const SizedBox(height: 8),
            _buildSelectionButton(
                context, 'internal complaint', selectedType, notifier),
            const SizedBox(height: 8),
            _buildSelectionButton(
                context, 'reconciliation', selectedType, notifier),
            const SizedBox(height: 12),
            _buildCommentField(theme, notifier),
          ],
        );
      }

      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                _buildSelectionButton(
                    context, 'correction', selectedType, notifier),
                const SizedBox(height: 8),
                _buildSelectionButton(
                    context, 'internal complaint', selectedType, notifier),
                const SizedBox(height: 8),
                _buildSelectionButton(
                    context, 'reconciliation', selectedType, notifier),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 6,
            child: _buildCommentField(theme, notifier),
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
            borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
          ),
          filled: false,
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
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.secondaryContainer
              : theme.colorScheme.surfaceContainerHighest
                  .withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.secondaryContainer
                : theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
            width: isSelected ? 2 : 1,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: isSelected
                ? theme.colorScheme.onSecondaryContainer
                : theme.colorScheme.onSurfaceVariant,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}
