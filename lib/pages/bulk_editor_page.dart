import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:project_xmedit/providers/bulk_claim_data_provider.dart';
import 'package:project_xmedit/widgets/bulk/bulk_claim_list_item_widget.dart';
import 'package:project_xmedit/widgets/bulk/bulk_claim_detail_editor.dart';
import 'package:project_xmedit/widgets/bulk/stat_chip.dart';
import 'package:project_xmedit/providers/claim_data_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:window_manager/window_manager.dart';
import 'package:project_xmedit/widgets.dart';

/// Main page for editing bulk XML files containing multiple claims
class BulkEditorPage extends StatefulWidget {
  const BulkEditorPage({super.key});

  @override
  State<BulkEditorPage> createState() => _BulkEditorPageState();
}

class _BulkEditorPageState extends State<BulkEditorPage> with WindowListener {
  bool _isFullScreen = false;

  @override
  void initState() {
    super.initState();

    if (!kIsWeb) {
      windowManager.addListener(this);
      _checkFullScreen();
    }

    // Set up single XML detection handler
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final bulkNotifier = context.read<BulkClaimDataNotifier>();
      bulkNotifier.onSingleXmlDetected = (xmlString, filePath) {
        if (!mounted) return;

        // Close bulk editor (pop back to home)
        Navigator.of(context).pop();

        // Load the single claim in the main notifier
        final claimNotifier = context.read<ClaimDataNotifier>();
        claimNotifier.loadFromXmlString(xmlString, filePath);
      };
    });
  }

  Future<void> _checkFullScreen() async {
    bool isFullScreen = await windowManager.isFullScreen();
    if (mounted) {
      setState(() {
        _isFullScreen = isFullScreen;
      });
    }
  }

  @override
  void onWindowEnterFullScreen() {
    if (mounted) {
      setState(() {
        _isFullScreen = true;
      });
    }
  }

  @override
  void onWindowLeaveFullScreen() {
    if (mounted) {
      setState(() {
        _isFullScreen = false;
      });
    }
  }

  @override
  void dispose() {
    if (!kIsWeb) {
      windowManager.removeListener(this);
    }
    // context.read<BulkClaimDataNotifier>().onSingleXmlDetected = null; // Careful with context use in dispose
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bulkNotifier = context.watch<BulkClaimDataNotifier>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: kIsWeb ? null : Theme.of(context).colorScheme.surface,
        elevation: kIsWeb ? null : 0,
        automaticallyImplyLeading: false, // Handle back button manually
        titleSpacing: 0,
        // On macOS, no title text (it's in OS menu bar), but layout needed for buttons
        // On web, show title.
        title: kIsWeb
            ? const Text('Bulk Claim Editor')
            : Row(
                children: [
                  if (defaultTargetPlatform == TargetPlatform.macOS &&
                      !_isFullScreen)
                    const SizedBox(width: 80), // Traffic lights spacer

                  // Back Button
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: 'Back',
                  ),
                  const SizedBox(width: 8),
                  const Text('Bulk Claim Editor',
                      style: TextStyle(fontSize: 16)),

                  // Drag area
                  Expanded(
                    child: DragToMoveArea(
                      child: Container(
                        color: Colors.transparent,
                        height: 56,
                        alignment: Alignment.centerLeft,
                        child: const SizedBox.shrink(),
                      ),
                    ),
                  ),
                ],
              ),

        actions: [
          // Total claims badge
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Chip(
              avatar: const Icon(Icons.description, size: 18),
              label: Text('${bulkNotifier.totalClaims} Claims'),
              visualDensity: VisualDensity.compact,
            ),
          ),

          // Estimated file size badge
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Chip(
              avatar: const Icon(Icons.storage, size: 18),
              label: Text(bulkNotifier.getEstimatedFileSize()),
              visualDensity: VisualDensity.compact,
            ),
          ),

          const VerticalDivider(indent: 12, endIndent: 12),

          // Open button
          FilledButton.icon(
            icon: const Icon(Icons.folder_open_outlined),
            label: const Text("Open"),
            onPressed: bulkNotifier.loadBulkXmlFile,
            style: FilledButton.styleFrom(
              visualDensity: VisualDensity.compact,
              backgroundColor: theme.colorScheme.secondaryContainer,
              foregroundColor: theme.colorScheme.onSecondaryContainer,
            ),
          ),
          const SizedBox(width: 8),

          // Undo button with badge
          Stack(
            children: [
              TextButton.icon(
                icon: const Icon(Icons.undo),
                label: const Text("Undo"),
                onPressed: bulkNotifier.canUndo ? bulkNotifier.undo : null,
              ),
              if (bulkNotifier.canUndo)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '${bulkNotifier.undoStack.length}',
                      style: TextStyle(
                        color: theme.colorScheme.onPrimary,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 8),

          // Reset button
          TextButton.icon(
            icon: const Icon(Icons.refresh),
            label: const Text("Reset"),
            onPressed: bulkNotifier.canReset ? bulkNotifier.reset : null,
          ),

          const VerticalDivider(indent: 12, endIndent: 12),

          if (bulkNotifier.bulkData != null) ...[
            Row(
              children: [
                ChoiceChip(
                  label: const Text('PROD'),
                  labelStyle: TextStyle(
                    fontSize: 12,
                    color: bulkNotifier.dispositionFlag == 'PRODUCTION'
                        ? Theme.of(context).colorScheme.onPrimaryContainer
                        : null,
                    fontWeight: FontWeight.bold,
                  ),
                  selected: bulkNotifier.dispositionFlag == 'PRODUCTION',
                  onSelected: (bool selected) {
                    if (selected) bulkNotifier.setDispositionFlag('PRODUCTION');
                  },
                  showCheckmark: false,
                  visualDensity: VisualDensity.compact,
                  selectedColor: Theme.of(context).colorScheme.primaryContainer,
                ),
                const SizedBox(width: 4),
                ChoiceChip(
                  label: const Text('TEST'),
                  labelStyle: TextStyle(
                    fontSize: 12,
                    color: bulkNotifier.dispositionFlag == 'TEST'
                        ? Colors.white
                        : null,
                    fontWeight: FontWeight.bold,
                  ),
                  selected: bulkNotifier.dispositionFlag == 'TEST',
                  onSelected: (bool selected) {
                    if (selected) bulkNotifier.setDispositionFlag('TEST');
                  },
                  showCheckmark: false,
                  visualDensity: VisualDensity.compact,
                  selectedColor: Colors.orange,
                ),
                const SizedBox(width: 8),
              ],
            ),
            const VerticalDivider(indent: 12, endIndent: 12),
          ],

          // Save button
          FilledButton.icon(
            icon: const Icon(Icons.save_outlined),
            label: const Text("Save"),
            onPressed: bulkNotifier.bulkData != null
                ? () => bulkNotifier.saveBulkXmlFile(saveAs: false)
                : null,
            style: FilledButton.styleFrom(
              visualDensity: VisualDensity.compact,
            ),
          ),
          const SizedBox(width: 8),

          // Save As button
          TextButton(
            onPressed: bulkNotifier.bulkData != null
                ? () => bulkNotifier.saveBulkXmlFile(saveAs: true)
                : null,
            child: const Text("Save As..."),
          ),
          const SizedBox(width: 8),

          // Split button
          TextButton(
            onPressed: bulkNotifier.bulkData != null
                ? bulkNotifier.splitAndSaveBulkXml
                : null,
            child: const Text("Split Max 2.95MB"),
          ),
          const SizedBox(width: 8),

          // Window buttons (close, minimize, maximize)
          if (!kIsWeb && defaultTargetPlatform != TargetPlatform.macOS)
            const WindowButtons(),
          const SizedBox(width: 4.0),
        ],
      ),
      body: bulkNotifier.isLoading
          ? const Center(child: CircularProgressIndicator())
          : bulkNotifier.bulkData == null
              ? Center(
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: InkWell(
                      onTap: bulkNotifier.loadBulkXmlFile,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(40),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainer,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.description_outlined,
                              size: 64,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'No Bulk XML File Loaded',
                              style: theme.textTheme.headlineSmall,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Click to open bulk XML file',
                              style: theme.textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                )
              : const _BulkEditorBody(),
    );
  }
}

/// Body of bulk editor with two-panel layout
class _BulkEditorBody extends StatelessWidget {
  const _BulkEditorBody();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Left panel: Claim list
        SizedBox(
          width: 350,
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(
                  color: Theme.of(context).colorScheme.outlineVariant,
                  width: 1,
                ),
              ),
            ),
            child: const _ClaimListPanel(),
          ),
        ),

        // Right panel: Claim detail editor
        const Expanded(
          child: BulkClaimDetailEditor(),
        ),
      ],
    );
  }
}

/// Left panel showing list of claims
class _ClaimListPanel extends StatelessWidget {
  const _ClaimListPanel();

  @override
  Widget build(BuildContext context) {
    final bulkNotifier = context.watch<BulkClaimDataNotifier>();
    final claimListItems = bulkNotifier.claimListItems;
    final theme = Theme.of(context);

    if (claimListItems.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.inbox_outlined,
                size: 48,
                color: theme.colorScheme.outline,
              ),
              const SizedBox(height: 16),
              Text(
                'No claims found',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(16),
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
              Row(
                children: [
                  Icon(
                    Icons.list_alt,
                    size: 20,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Claims List',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Search bar
              TextField(
                decoration: InputDecoration(
                  hintText: 'Search by ID, patient, or amount...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: bulkNotifier.searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: bulkNotifier.clearSearch,
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  isDense: true,
                ),
                onChanged: bulkNotifier.updateSearchQuery,
              ),
              const SizedBox(height: 12),
              // Statistics
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  StatChip(
                    icon: Icons.monetization_on,
                    label: 'Total Gross',
                    value: bulkNotifier.getTotalGross().toStringAsFixed(2),
                  ),
                  StatChip(
                    icon: Icons.account_balance_wallet,
                    label: 'Total Net',
                    value: bulkNotifier.getTotalNet().toStringAsFixed(2),
                  ),
                  if (bulkNotifier.searchQuery.isNotEmpty)
                    StatChip(
                      icon: Icons.filter_list,
                      label: 'Showing',
                      value:
                          '${bulkNotifier.filteredClaimCount} of ${bulkNotifier.totalClaims}',
                    ),
                ],
              ),
              const SizedBox(height: 12),
              // Batch Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                    ),
                  ),
                  if (bulkNotifier.selectedClaimIndices.isNotEmpty)
                    TextButton.icon(
                      icon: Icon(Icons.delete_outline,
                          size: 16, color: theme.colorScheme.error),
                      label: Text(
                        'Delete (${bulkNotifier.selectedClaimIndices.length})',
                        style: TextStyle(
                            fontSize: 12, color: theme.colorScheme.error),
                      ),
                      onPressed: () =>
                          _confirmDeleteSelected(context, bulkNotifier),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),

        // Scrollable list
        Expanded(
          child: ListView.builder(
            itemCount: claimListItems.length,
            itemBuilder: (context, index) {
              final item = claimListItems[index];
              // Use indices logic
              final isSelected =
                  bulkNotifier.selectedClaimIndices.contains(item.index);

              return BulkClaimListItemWidget(
                claimListItem: item,
                isSelected: isSelected,
                onTap: () => bulkNotifier.toggleClaimSelection(item.index),
                onDelete: () => bulkNotifier.deleteClaim(index),
              );
            },
          ),
        ),
      ],
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
