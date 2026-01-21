import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:project_xmedit/providers/bulk_claim_data_provider.dart';
import 'package:project_xmedit/widgets/bulk/stat_chip.dart';

class BulkClaimListHeader extends StatelessWidget {
  const BulkClaimListHeader({super.key});

  @override
  @override
  Widget build(BuildContext context) {
    final bulkNotifier = context.watch<BulkClaimDataNotifier>();
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outlineVariant,
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search bar
          TextField(
            decoration: InputDecoration(
              hintText: 'Search...',
              prefixIcon: const Icon(Icons.search, size: 20),
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              suffixIcon: bulkNotifier.searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      hoverColor: Colors.transparent,
                      onPressed: bulkNotifier.clearSearch,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                      padding: EdgeInsets.zero,
                    )
                  : null,
            ),
            style: theme.textTheme.bodyMedium,
            onChanged: bulkNotifier.updateSearchQuery,
          ),
          const SizedBox(height: 8),
          // Statistics (Horizontal Scroll)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                StatChip(
                  icon: Icons.monetization_on,
                  label: 'Gross',
                  value: bulkNotifier.getTotalGross().toStringAsFixed(2),
                ),
                const SizedBox(width: 8),
                StatChip(
                  icon: Icons.account_balance_wallet,
                  label: 'Net',
                  value: bulkNotifier.getTotalNet().toStringAsFixed(2),
                ),
                const SizedBox(width: 8),
                StatChip(
                  icon: Icons.description,
                  label: 'Claims',
                  value: '${bulkNotifier.totalClaims}',
                ),
                if (bulkNotifier.searchQuery.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  StatChip(
                    icon: Icons.filter_list,
                    label: 'Show',
                    value: '${bulkNotifier.filteredClaimCount}',
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Batch Actions
          Row(
            children: [
              TextButton.icon(
                icon: Icon(
                  bulkNotifier.selectedClaimIndices.length ==
                          bulkNotifier.totalClaims
                      ? Icons.deselect
                      : Icons.select_all,
                  size: 16,
                ),
                label: Text(
                  bulkNotifier.selectedClaimIndices.length ==
                          bulkNotifier.totalClaims
                      ? 'Deselect All'
                      : 'Select All',
                  style: const TextStyle(fontSize: 12),
                ),
                onPressed: bulkNotifier.selectedClaimIndices.length ==
                        bulkNotifier.totalClaims
                    ? bulkNotifier.deselectAll
                    : bulkNotifier.selectAll,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                ),
              ),
              const SizedBox(width: 16),
              // Total Size Monitor
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.storage,
                        size: 12, color: theme.colorScheme.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Text(
                      bulkNotifier.getEstimatedFileSize(),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              if (bulkNotifier.selectedClaimIndices.isNotEmpty)
                TextButton.icon(
                  icon: Icon(Icons.delete_outline,
                      size: 16, color: theme.colorScheme.error),
                  label: Text(
                    'Delete (${bulkNotifier.selectedClaimIndices.length})',
                    style:
                        TextStyle(fontSize: 12, color: theme.colorScheme.error),
                  ),
                  onPressed: () =>
                      _confirmDeleteSelected(context, bulkNotifier),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteSelected(
      BuildContext context, BulkClaimDataNotifier notifier) async {
    final count = notifier.selectedClaimIndices.length;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content:
            Text('Are you sure you want to delete $count selected claim(s)?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await notifier.deleteSelectedClaims();
    }
  }
}
