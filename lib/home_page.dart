import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:project_xmedit/notifiers.dart';
import 'package:project_xmedit/providers/bulk_claim_data_provider.dart';
import 'package:project_xmedit/widgets/app_drawer.dart';
import 'package:project_xmedit/widgets/body_content.dart';
import 'package:provider/provider.dart';
import 'package:project_xmedit/widgets/bulk_editor_view.dart';
import 'package:project_xmedit/widgets/disposition_toggle.dart';
import 'package:window_manager/window_manager.dart';

class OpenIntent extends Intent {}

class SaveIntent extends Intent {}

class SaveAsIntent extends Intent {}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _initPackageInfo();

    // Set up message handler for bulk notifier
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final bulkNotifier = context.read<BulkClaimDataNotifier>();
      bulkNotifier.onMessage = (message, isError) {
        if (mounted && message.isNotEmpty) {
          final scaffoldMessenger = ScaffoldMessenger.of(context);
          scaffoldMessenger.removeCurrentSnackBar();
          final theme = Theme.of(context);
          scaffoldMessenger.showSnackBar(SnackBar(
            content: Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: isError
                      ? theme.colorScheme.onErrorContainer
                      : theme.colorScheme.onSecondaryContainer),
            ),
            backgroundColor: isError
                ? theme.colorScheme.errorContainer
                : theme.colorScheme.secondaryContainer,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            width: 450,
          ));
        }
      };
    });
  }

  Future<void> _initPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted && !kIsWeb) {
      await windowManager.setTitle('project_xmedit ${info.version}');
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final notifier = context.read<ClaimDataNotifier>();
    final bulkNotifier = context.read<BulkClaimDataNotifier>();

    notifier.onMessage = (message, isError) {
      if (mounted && message.isNotEmpty) {
        final scaffoldMessenger = ScaffoldMessenger.of(context);
        scaffoldMessenger.removeCurrentSnackBar();
        final theme = Theme.of(context);
        scaffoldMessenger.showSnackBar(SnackBar(
          content: Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
                color: isError
                    ? theme.colorScheme.onErrorContainer
                    : theme.colorScheme.onSecondaryContainer),
          ),
          backgroundColor: isError
              ? theme.colorScheme.errorContainer
              : theme.colorScheme.secondaryContainer,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          width: 450,
        ));
      }
    };

    // Handle bulk XML detection
    notifier.onBulkXmlDetected = (xmlString, filePath) async {
      if (mounted) {
        // Load the bulk XML directly into the bulk notifier
        // This will update the state and the UI will rebuild to show BulkEditorView
        await bulkNotifier.loadFromXmlString(xmlString, filePath);
        // Clear single claim data to switch view
        notifier.clearData();
      }
    };

    // Handle single XML detection in bulk loader
    bulkNotifier.onSingleXmlDetected = (xmlString, filePath) async {
      if (mounted) {
        // Load into single notifier
        await notifier.loadFromXmlString(xmlString, filePath);
        // Clear bulk data to switch view
        bulkNotifier.clearData();
      }
    };
  }

  Future<void> _promptForFileName(ClaimDataNotifier notifier) async {
    String? fileName = await showDialog<String>(
      context: context,
      builder: (context) {
        String input = '';
        return AlertDialog(
          title: const Text('Save As'),
          content: TextField(
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'File Name',
              hintText: 'example.xml',
            ),
            onChanged: (value) => input = value,
            onSubmitted: (value) => Navigator.pop(context, value),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, input),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (fileName != null && fileName.isNotEmpty) {
      if (!fileName.toLowerCase().endsWith('.xml')) {
        fileName = '$fileName.xml';
      }
      notifier.saveXmlFile(saveAs: true, customFileName: fileName);
    }
  }

  void _handleSaveAs(ClaimDataNotifier notifier) {
    if (kIsWeb) {
      _promptForFileName(notifier);
    } else {
      notifier.saveXmlFile(saveAs: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<ClaimDataNotifier>();
    final bulkNotifier = context.watch<BulkClaimDataNotifier>();
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isCompactToolbar = screenWidth < 1280;

    final bool isSingleDataLoaded = notifier.claimData != null;
    final bool isBulkDataLoaded = bulkNotifier.bulkData != null;
    final bool isAnyDataLoaded = isSingleDataLoaded || isBulkDataLoaded;
    final activeClaim =
        isBulkDataLoaded ? bulkNotifier.selectedClaim : notifier.claimData;
    final claimId = (activeClaim?.claimId?.trim().isNotEmpty ?? false)
        ? activeClaim!.claimId!
        : null;
    final claimMember = (activeClaim?.memberID?.trim().isNotEmpty ?? false)
        ? activeClaim!.memberID!
        : 'N/A';
    final claimEncounter = (activeClaim?.start?.trim().isNotEmpty ?? false)
        ? activeClaim!.start!
        : 'N/A';

    final bool isMac = defaultTargetPlatform == TargetPlatform.macOS;

    return Actions(
      actions: <Type, Action<Intent>>{
        OpenIntent: CallbackAction<OpenIntent>(
          onInvoke: (intent) => notifier.loadXmlFile(),
        ),
        SaveIntent: CallbackAction<SaveIntent>(
          onInvoke: (intent) {
            if (isBulkDataLoaded) {
              bulkNotifier.saveBulkXmlFile(saveAs: false);
            } else if (isSingleDataLoaded) {
              notifier.saveXmlFile(saveAs: false);
            }
            return null;
          },
        ),
        SaveAsIntent: CallbackAction<SaveAsIntent>(onInvoke: (intent) {
          if (isBulkDataLoaded) {
            bulkNotifier.saveBulkXmlFile(saveAs: true);
          } else if (isSingleDataLoaded) {
            _handleSaveAs(notifier);
          }
          return null;
        }),
      },
      child: Shortcuts(
        shortcuts: <ShortcutActivator, Intent>{
          // ... (shortcuts)
          SingleActivator(LogicalKeyboardKey.keyO,
              meta: isMac, control: !isMac): OpenIntent(),
          SingleActivator(LogicalKeyboardKey.keyS,
              meta: isMac, control: !isMac): SaveIntent(),
          SingleActivator(LogicalKeyboardKey.keyS,
              meta: isMac, control: !isMac, shift: true): SaveAsIntent(),
        },
        child: PlatformMenuBar(
          menus: [
            if (isMac)
              PlatformMenu(
                label: 'project_xmedit',
                menus: [
                  const PlatformMenuItemGroup(members: [
                    PlatformProvidedMenuItem(
                        type: PlatformProvidedMenuItemType.quit),
                  ]),
                ],
              ),
            PlatformMenu(
              label: 'File',
              menus: [
                PlatformMenuItemGroup(
                  members: [
                    PlatformMenuItem(
                      label: 'Open...',
                      shortcut: const SingleActivator(LogicalKeyboardKey.keyO,
                          meta: true),
                      onSelected: () {
                        // Always use the single notifier's load, which detects bulk
                        notifier.loadXmlFile();
                      },
                    ),
                  ],
                ),
                PlatformMenuItemGroup(
                  members: [
                    PlatformMenuItem(
                      label: 'Save',
                      shortcut: const SingleActivator(LogicalKeyboardKey.keyS,
                          meta: true),
                      onSelected: isAnyDataLoaded
                          ? () {
                              if (isBulkDataLoaded) {
                                bulkNotifier.saveBulkXmlFile(saveAs: false);
                              } else {
                                notifier.saveXmlFile(saveAs: false);
                              }
                            }
                          : null,
                    ),
                    PlatformMenuItem(
                      label: 'Save As...',
                      shortcut: const SingleActivator(LogicalKeyboardKey.keyS,
                          meta: true, shift: true),
                      onSelected: isAnyDataLoaded
                          ? () {
                              if (isBulkDataLoaded) {
                                bulkNotifier.saveBulkXmlFile(saveAs: true);
                              } else {
                                _handleSaveAs(notifier);
                              }
                            }
                          : null,
                    ),
                  ],
                ),
              ],
            ),
            PlatformMenu(
              label: 'Edit',
              menus: [
                PlatformMenuItemGroup(
                  members: [
                    PlatformMenuItem(
                      label: 'Undo',
                      shortcut: const SingleActivator(LogicalKeyboardKey.keyZ,
                          meta: true),
                      onSelected: () {
                        if (isBulkDataLoaded && bulkNotifier.canUndo) {
                          bulkNotifier.undo();
                        }
                        // Implement single undo if available
                      },
                    ),
                    PlatformMenuItem(
                      label: 'Redo',
                      shortcut: const SingleActivator(LogicalKeyboardKey.keyZ,
                          meta: true, shift: true),
                      onSelected: () {
                        // Implement redo
                      },
                    ),
                  ],
                ),
                if (isAnyDataLoaded)
                  PlatformMenuItemGroup(
                    members: [
                      PlatformMenuItem(
                        label: 'Clear All',
                        onSelected: () {
                          notifier.clearData();
                          bulkNotifier.clearData();
                        },
                      ),
                    ],
                  ),
              ],
            ),
            PlatformMenu(
              label: 'View',
              menus: [
                PlatformMenuItemGroup(
                  members: [
                    PlatformMenuItem(
                      label: 'Toggle Theme',
                      onSelected: () {
                        context.read<ThemeNotifier>().toggleTheme();
                      },
                    ),
                    if (isMac)
                      PlatformMenuItem(
                        label: 'Toggle Full Screen',
                        onSelected: () async {
                          bool isFullScreen =
                              await windowManager.isFullScreen();
                          await windowManager.setFullScreen(!isFullScreen);
                        },
                      ),
                  ],
                ),
              ],
            ),
            if (isMac)
              const PlatformMenu(
                label: 'Window',
                menus: [
                  PlatformProvidedMenuItem(
                      type: PlatformProvidedMenuItemType.minimizeWindow),
                  PlatformProvidedMenuItem(
                      type: PlatformProvidedMenuItemType.zoomWindow),
                ],
              ),
          ],
          child: Scaffold(
            key: _scaffoldKey, // Assigned key
            appBar: AppBar(
              backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              scrolledUnderElevation: 0,
              automaticallyImplyLeading: true,
              titleSpacing: NavigationToolbar.kMiddleSpacing,
              title: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    claimId != null
                        ? 'Claim: $claimId'
                        : (isBulkDataLoaded
                            ? 'Bulk Claim Workspace'
                            : 'Single Claim Workspace'),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    claimId != null
                        ? 'Member: $claimMember    Encounter: $claimEncounter'
                        : (isBulkDataLoaded
                            ? '${bulkNotifier.filteredClaimCount}/${bulkNotifier.totalClaims} claims loaded'
                            : (isSingleDataLoaded
                                ? '1 claim loaded'
                                : 'No file loaded')),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
              actions: [
                if (isAnyDataLoaded)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: DispositionToggle(
                      value: isBulkDataLoaded
                          ? bulkNotifier.dispositionFlag
                          : notifier.dispositionFlag,
                      onChanged: isBulkDataLoaded
                          ? bulkNotifier.setDispositionFlag
                          : notifier.setDispositionFlag,
                    ),
                  ),
                if (isAnyDataLoaded) ...[
                  if (isCompactToolbar)
                    IconButton.filledTonal(
                      onPressed: () {
                        if (isBulkDataLoaded) {
                          bulkNotifier.saveBulkXmlFile(saveAs: true);
                        } else {
                          _handleSaveAs(notifier);
                        }
                      },
                      icon: const Icon(Icons.save_as_rounded),
                      tooltip: 'Save As',
                    )
                  else
                    FilledButton.tonalIcon(
                      onPressed: () {
                        if (isBulkDataLoaded) {
                          bulkNotifier.saveBulkXmlFile(saveAs: true);
                        } else {
                          _handleSaveAs(notifier);
                        }
                      },
                      icon: const Icon(Icons.save_as_rounded),
                      label: const Text('Save As'),
                    ),
                  const SizedBox(width: 6),
                  if (isCompactToolbar)
                    IconButton.filled(
                      onPressed: () {
                        if (isBulkDataLoaded) {
                          bulkNotifier.saveBulkXmlFile(saveAs: false);
                        } else {
                          notifier.saveXmlFile(saveAs: false);
                        }
                      },
                      icon: const Icon(Icons.playlist_add_check_rounded),
                      tooltip: 'Apply',
                    )
                  else
                    FilledButton.icon(
                      icon: const Icon(Icons.playlist_add_check_rounded),
                      label: const Text('Apply'),
                      onPressed: () {
                        if (isBulkDataLoaded) {
                          bulkNotifier.saveBulkXmlFile(saveAs: false);
                        } else {
                          notifier.saveXmlFile(saveAs: false);
                        }
                      },
                    ),
                  if (isBulkDataLoaded) ...[
                    const SizedBox(width: 6),
                    if (isCompactToolbar)
                      IconButton.filledTonal(
                        onPressed: bulkNotifier.splitAndSaveBulkXml,
                        icon: const Icon(Icons.call_split_rounded),
                        tooltip: 'Split Bulk File',
                      )
                    else
                      FilledButton.tonalIcon(
                        onPressed: bulkNotifier.splitAndSaveBulkXml,
                        icon: const Icon(Icons.call_split_rounded),
                        label: const Text('Split'),
                      ),
                  ],
                  const SizedBox(width: 6),
                  PopupMenuButton<String>(
                    tooltip: 'More Actions',
                    icon: const Icon(Icons.more_horiz_rounded),
                    onSelected: (value) {
                      if (value == 'clear') {
                        notifier.clearData();
                        bulkNotifier.clearData();
                      } else if (value == 'undo' &&
                          isBulkDataLoaded &&
                          bulkNotifier.canUndo) {
                        bulkNotifier.undo();
                      } else if (value == 'reset') {
                        if (isBulkDataLoaded) {
                          if (bulkNotifier.canReset) bulkNotifier.reset();
                        } else if (notifier.canReset) {
                          notifier.reset();
                        }
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'clear',
                        child: ListTile(
                          leading: Icon(Icons.clear_all_rounded),
                          title: Text('Clear All'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      PopupMenuItem(
                        value: 'undo',
                        enabled: isBulkDataLoaded && bulkNotifier.canUndo,
                        child: ListTile(
                          leading: const Icon(Icons.undo_rounded),
                          title: Text(
                              'Undo${isBulkDataLoaded ? ' (${bulkNotifier.undoStack.length})' : ''}'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      PopupMenuItem(
                        value: 'reset',
                        enabled: isBulkDataLoaded
                            ? bulkNotifier.canReset
                            : notifier.canReset,
                        child: const ListTile(
                          leading: Icon(Icons.refresh_rounded),
                          title: Text('Reset'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(width: 6),
                if (isCompactToolbar)
                  IconButton.filledTonal(
                    onPressed: () {
                      if (isBulkDataLoaded) {
                        bulkNotifier.loadBulkXmlFile();
                      } else {
                        notifier.loadXmlFile();
                      }
                    },
                    icon: const Icon(Icons.folder_open_rounded),
                    tooltip: 'Open XML',
                  )
                else
                  FilledButton.tonalIcon(
                    onPressed: () {
                      if (isBulkDataLoaded) {
                        bulkNotifier.loadBulkXmlFile();
                      } else {
                        notifier.loadXmlFile();
                      }
                    },
                    icon: const Icon(Icons.folder_open_rounded),
                    label: const Text('Open XML'),
                  ),
                const SizedBox(width: 8),
              ],
            ),
            drawer: const AppDrawer(),
            // SWITCH BODY BASED ON MODE
            body: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: child,
                );
              },
              child: isBulkDataLoaded
                  ? (bulkNotifier.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : const BulkEditorView())
                  : const BodyContent(),
            ),
          ),
        ),
      ),
    );
  }
}
