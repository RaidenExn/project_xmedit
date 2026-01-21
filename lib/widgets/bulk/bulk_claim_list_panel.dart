import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:project_xmedit/providers/bulk_claim_data_provider.dart';
import 'package:project_xmedit/widgets/bulk/bulk_claim_list_item_widget.dart';
import 'package:project_xmedit/widgets/common/empty_state_view.dart';
import 'package:project_xmedit/widgets/bulk/bulk_claim_list_header.dart';

class BulkClaimListPanel extends StatelessWidget {
  const BulkClaimListPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final bulkNotifier = context.watch<BulkClaimDataNotifier>();
    final claimListItems = bulkNotifier.claimListItems;

    if (claimListItems.isEmpty) {
      // If list is empty, it could be no file loaded (unlikely here as view wouldn't be shown)
      // or search result empty.
      return EmptyStateView(
        icon: Icons.inbox_outlined,
        title: 'No claims found',
        // Show clear search action if searching
        actionLabel:
            bulkNotifier.searchQuery.isNotEmpty ? 'Clear Search' : null,
        onAction: bulkNotifier.searchQuery.isNotEmpty
            ? bulkNotifier.clearSearch
            : null,
      );
    }

    return Column(
      children: [
        // Header
        const BulkClaimListHeader(),

        // Scrollable list
        Expanded(
          child: ListView.builder(
            itemCount: claimListItems.length,
            itemBuilder: (context, index) {
              final item = claimListItems[index];
              // Use indices logic
              final isSelected =
                  bulkNotifier.selectedClaimIndices.contains(item.index);
              final isFocused = bulkNotifier.selectedClaimIndex == item.index;

              return BulkClaimListItemWidget(
                claimListItem: item,
                isSelected: isSelected,
                isFocused: isFocused,
                onFocus: () => bulkNotifier.focusClaim(item.index),
                onSelect: () => bulkNotifier.toggleClaimSelection(item.index),
                onDelete: () => bulkNotifier.deleteClaim(item.index),
              );
            },
          ),
        ),
      ],
    );
  }
}
