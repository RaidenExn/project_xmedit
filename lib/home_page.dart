import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:project_xmedit/notifiers.dart';
import 'package:project_xmedit/providers/bulk_claim_data_provider.dart';
import 'package:project_xmedit/pages/bulk_editor_page.dart';
import 'package:project_xmedit/widgets.dart';
import 'package:project_xmedit/widgets/app_drawer.dart';
import 'package:project_xmedit/widgets/body_content.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';

class OpenIntent extends Intent {}

class SaveIntent extends Intent {}

class SaveAsIntent extends Intent {}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WindowListener {
  String _version = '';

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isFullScreen = false;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      windowManager.addListener(this);
      _checkFullScreen();
    }
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

  Future<void> _initPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {
        _version = info.version;
      });
    }
  }

  @override
  void dispose() {
    if (!kIsWeb) {
      windowManager.removeListener(this);
    }
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
        // Navigate to bulk editor page
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const BulkEditorPage(),
          ),
        );

        // Load the bulk XML in the bulk notifier
        await bulkNotifier.loadFromXmlString(xmlString, filePath);
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
    final bool isDataLoaded = notifier.claimData != null;

    return Actions(
      actions: <Type, Action<Intent>>{
        OpenIntent: CallbackAction<OpenIntent>(
          onInvoke: (intent) => notifier.loadXmlFile(),
        ),
        SaveIntent: CallbackAction<SaveIntent>(
          onInvoke: (intent) =>
              isDataLoaded ? notifier.saveXmlFile(saveAs: false) : null,
        ),
        SaveAsIntent: CallbackAction<SaveAsIntent>(
          onInvoke: (intent) => isDataLoaded ? _handleSaveAs(notifier) : null,
        ),
      },
      child: Shortcuts(
        shortcuts: <ShortcutActivator, Intent>{
          // ... (shortcuts)
          SingleActivator(LogicalKeyboardKey.keyO,
                  meta: defaultTargetPlatform == TargetPlatform.macOS,
                  control: defaultTargetPlatform != TargetPlatform.macOS):
              OpenIntent(),
          SingleActivator(LogicalKeyboardKey.keyS,
                  meta: defaultTargetPlatform == TargetPlatform.macOS,
                  control: defaultTargetPlatform != TargetPlatform.macOS):
              SaveIntent(),
          SingleActivator(LogicalKeyboardKey.keyS,
              meta: defaultTargetPlatform == TargetPlatform.macOS,
              control: defaultTargetPlatform != TargetPlatform.macOS,
              shift: true): SaveAsIntent(),
        },
        child: Scaffold(
          key: _scaffoldKey, // Assigned key
          appBar: AppBar(
            backgroundColor:
                kIsWeb ? null : Theme.of(context).colorScheme.surface,
            elevation: kIsWeb ? null : 0,
            automaticallyImplyLeading:
                kIsWeb, // Hide native hamburger on desktop
            titleSpacing:
                0, // Remove default spacing to control padding manually
            title: kIsWeb
                ? Row(
                    children: [
                      Expanded(
                        child: Text('project_xmedit - v$_version'),
                      ),
                    ],
                  )
                : Row(
                    children: [
                      if (defaultTargetPlatform == TargetPlatform.macOS &&
                          !_isFullScreen)
                        const SizedBox(width: 80), // Traffic lights spacer

                      // Custom Hamburger Menu
                      IconButton(
                        icon: const Icon(Icons.menu),
                        onPressed: () =>
                            _scaffoldKey.currentState?.openDrawer(),
                        tooltip: 'Open Menu',
                      ),

                      // Drag area fills the rest
                      Expanded(
                        child: DragToMoveArea(
                          child: Container(
                            color: Colors.transparent,
                            height: 56,
                            alignment: Alignment.centerLeft,
                            child: const SizedBox.shrink(), // Or title text
                          ),
                        ),
                      ),
                    ],
                  ),
            actions: [
              // ... (actions)
              FilledButton.icon(
                icon: const Icon(Icons.folder_open_outlined),
                label: const Text("Open"),
                onPressed: notifier.loadXmlFile,
                style: FilledButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  backgroundColor:
                      Theme.of(context).colorScheme.secondaryContainer,
                  foregroundColor:
                      Theme.of(context).colorScheme.onSecondaryContainer,
                ),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                icon: const Icon(Icons.clear_all),
                label: const Text("Clear All"),
                onPressed: isDataLoaded ? notifier.clearData : null,
              ),
              const VerticalDivider(indent: 12, endIndent: 12),
              if (isDataLoaded) ...[
                Row(
                  children: [
                    const Text('PROD',
                        style: TextStyle(
                            fontSize: 10, fontWeight: FontWeight.bold)),
                    Transform.scale(
                      scale: 0.8,
                      child: Switch(
                        value: notifier.dispositionFlag == 'TEST',
                        onChanged: (val) => notifier
                            .setDispositionFlag(val ? 'TEST' : 'PRODUCTION'),
                        activeTrackColor: Colors.orange.withValues(alpha: 0.5),
                        activeThumbColor: Colors.orange,
                      ),
                    ),
                    const Text('TEST',
                        style: TextStyle(
                            fontSize: 10, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                  ],
                ),
                const VerticalDivider(indent: 12, endIndent: 12),
              ],
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: FilterChip(
                  label: const Text('Rename on Apply'),
                  selected: notifier.shouldRenameFile,
                  onSelected: isDataLoaded ? notifier.toggleRenameFile : null,
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                icon: const Icon(Icons.save_outlined),
                label: const Text("Apply"),
                onPressed: isDataLoaded
                    ? () => notifier.saveXmlFile(saveAs: false)
                    : null,
                style: FilledButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: isDataLoaded ? () => _handleSaveAs(notifier) : null,
                child: const Text("Save As..."),
              ),
              const SizedBox(width: 8),
              // We can keep WindowButtons or hide them since we have native ones (min/max/close)
              // The request implies "MacOS menu bar into apps menu bar" which usually means unified title bar.
              // Native macOS buttons (traffic lights) are sufficient. Non-macOS might need them.
              if (!kIsWeb && defaultTargetPlatform != TargetPlatform.macOS)
                const WindowButtons(),
              const SizedBox(width: 4.0),
            ],
          ),
          drawer: const AppDrawer(),
          body: const BodyContent(),
        ),
      ),
    );
  }
}
