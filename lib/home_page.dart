import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:project_xmedit/notifiers.dart';
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

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    _initPackageInfo();
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
    windowManager.removeListener(this);
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final notifier = context.read<ClaimDataNotifier>();
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
          onInvoke: (intent) =>
              isDataLoaded ? notifier.saveXmlFile(saveAs: true) : null,
        ),
      },
      child: Shortcuts(
        shortcuts: <ShortcutActivator, Intent>{
          const SingleActivator(LogicalKeyboardKey.keyO, control: true):
              OpenIntent(),
          const SingleActivator(LogicalKeyboardKey.keyS, control: true):
              SaveIntent(),
          const SingleActivator(LogicalKeyboardKey.keyS,
              control: true, shift: true): SaveAsIntent(),
        },
        child: Scaffold(
          appBar: AppBar(
            title: DragToMoveArea(
              child: SizedBox(
                  width: double.infinity,
                  child: Text('project_xmedit - v$_version')),
            ),
            actions: [
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
                onPressed: isDataLoaded
                    ? () => notifier.saveXmlFile(saveAs: true)
                    : null,
                child: const Text("Save As..."),
              ),
              const SizedBox(width: 8),
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
