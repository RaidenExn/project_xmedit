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

    final bool isSingleDataLoaded = notifier.claimData != null;
    final bool isBulkDataLoaded = bulkNotifier.bulkData != null;
    final bool isAnyDataLoaded = isSingleDataLoaded || isBulkDataLoaded;

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
              backgroundColor: Theme.of(context).colorScheme.surface,
              elevation: 0,
              automaticallyImplyLeading:
                  true, // Use standard leading widget (Hamburger)
              titleSpacing: NavigationToolbar.kMiddleSpacing,
              title: isBulkDataLoaded
                  ? Text('Bulk Claim Editor',
                      style: Theme.of(context).textTheme.titleMedium)
                  : null,
              actions: [
                // ... (actions)

                // Group: Edit Actions (Clear All, Undo, Reset)
                if (isAnyDataLoaded) ...[
                  IconButton(
                    icon: const Icon(Icons.clear_all),
                    tooltip: "Clear All",
                    onPressed: () {
                      notifier.clearData();
                      bulkNotifier.clearData();
                    },
                  ),
                  const SizedBox(width: 4),

                  // Undo (Bulk and Single)
                  Stack(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.undo),
                        tooltip: "Undo",
                        onPressed: isBulkDataLoaded
                            ? (bulkNotifier.canUndo ? bulkNotifier.undo : null)
                            : null, // Single undo not implemented yet
                      ),
                      if (isBulkDataLoaded && bulkNotifier.canUndo)
                        Positioned(
                          right: 4,
                          top: 4,
                          child: IgnorePointer(
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary,
                                shape: BoxShape.circle,
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 16,
                                minHeight: 16,
                              ),
                              child: Text(
                                '${bulkNotifier.undoStack.length}',
                                style: TextStyle(
                                  color:
                                      Theme.of(context).colorScheme.onPrimary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 4),

                  IconButton(
                    icon: const Icon(Icons.refresh),
                    tooltip: "Reset",
                    onPressed: isBulkDataLoaded
                        ? (bulkNotifier.canReset ? bulkNotifier.reset : null)
                        : (notifier.canReset ? notifier.reset : null),
                  ),
                  const VerticalDivider(indent: 12, endIndent: 12),

                  // Group: Disposition
                  DispositionToggle(
                    value: isBulkDataLoaded
                        ? bulkNotifier.dispositionFlag
                        : notifier.dispositionFlag,
                    onChanged: isBulkDataLoaded
                        ? bulkNotifier.setDispositionFlag
                        : notifier.setDispositionFlag,
                  ),
                  const VerticalDivider(indent: 12, endIndent: 12),

                  // Group: File Ops (Split, Save As, Apply)
                  if (isBulkDataLoaded) ...[
                    FilledButton.tonal(
                      onPressed: bulkNotifier.splitAndSaveBulkXml,
                      style: FilledButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                      ),
                      child: const Text("Split"),
                    ),
                    const SizedBox(width: 8),
                  ],

                  FilledButton.tonal(
                    onPressed: () {
                      if (isBulkDataLoaded) {
                        bulkNotifier.saveBulkXmlFile(saveAs: true);
                      } else {
                        _handleSaveAs(notifier);
                      }
                    },
                    style: FilledButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                    ),
                    child: const Text("Save As"),
                  ),
                  const SizedBox(width: 8),

                  FilledButton.icon(
                    icon: const Icon(Icons.save_outlined),
                    label: Text(isBulkDataLoaded
                        ? "Apply"
                        : "Apply"), // Using Apply for both as per user request flow, or keep consistent with Save icon
                    onPressed: () {
                      if (isBulkDataLoaded) {
                        bulkNotifier.saveBulkXmlFile(saveAs: false);
                      } else {
                        notifier.saveXmlFile(saveAs: false);
                      }
                    },
                    style: FilledButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                  const VerticalDivider(indent: 12, endIndent: 12),
                ],

                // Open Button (Always Last)
                FilledButton.icon(
                  icon: const Icon(Icons.folder_open_outlined),
                  label: const Text("Open"),
                  onPressed: () {
                    if (isBulkDataLoaded) {
                      bulkNotifier.loadBulkXmlFile();
                    } else {
                      notifier.loadXmlFile();
                    }
                  },
                  style: FilledButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    backgroundColor:
                        Theme.of(context).colorScheme.secondaryContainer,
                    foregroundColor:
                        Theme.of(context).colorScheme.onSecondaryContainer,
                  ),
                ),

                const SizedBox(width: 4.0),
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
