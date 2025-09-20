import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:project_xmedit/cards/cards.dart';
import 'package:project_xmedit/notifiers.dart';
import 'package:project_xmedit/widgets.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:window_manager/window_manager.dart';

// Intents for Keyboard Shortcuts
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
                  child: Text('Project XMEdit - v$_version')),
            ),
            actions: [
              TextButton.icon(
                icon: const Icon(Icons.folder_open_outlined),
                label: const Text("Open"),
                onPressed: notifier.loadXmlFile,
              ),
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

class AppDrawer extends StatefulWidget {
  const AppDrawer({super.key});

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  String _appName = '...';
  String _version = '...';

  @override
  void initState() {
    super.initState();
    _initPackageInfo();
  }

  Future<void> _initPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {
        _appName = info.appName;
        _version = info.version;
      });
    }
  }

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not launch $url')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cardNotifier = context.watch<CardVisibilityNotifier>();
    final themeNotifier = context.watch<ThemeNotifier>();

    return Drawer(
      child: ListView(
        padding: const EdgeInsets.all(8.0),
        children: [
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ListTile(
                  title: Text('Appearance'),
                  leading: Icon(Icons.palette_outlined),
                ),
                SwitchListTile(
                  title: const Text('Dark Mode'),
                  value: themeNotifier.isDarkMode,
                  onChanged: (value) => themeNotifier.toggleTheme(),
                ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Text('Theme Color'),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: themeNotifier.availableColors.map((color) {
                      final bool isSelected = themeNotifier.seedColor == color;
                      return InkWell(
                        onTap: () => themeNotifier.changeSeedColor(color),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          width: 35,
                          height: 35,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: isSelected
                                ? Border.all(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface,
                                    width: 3,
                                  )
                                : null,
                          ),
                          child: isSelected
                              ? const Icon(Icons.check,
                                  color: Colors.white, size: 20)
                              : null,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                const ListTile(
                  title: Text('Visible Cards'),
                  leading: Icon(Icons.view_quilt_outlined),
                ),
                ...cardNotifier.visibilities.entries.map((entry) {
                  final key = entry.key;
                  String title = key[0].toUpperCase() + key.substring(1);
                  if (key == 'resubmission & totals') {
                    title = 'Resubmission';
                  }
                  return SwitchListTile(
                    title: Text(title),
                    value: entry.value,
                    onChanged: (value) => cardNotifier.toggle(key),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AboutListTile(
                  icon: const Icon(Icons.info_outline),
                  applicationIcon: const Icon(Icons.edit_document),
                  applicationName: _appName,
                  applicationVersion: _version,
                  applicationLegalese: '© 2025 Abhijith SS',
                  aboutBoxChildren: [
                    const SizedBox(height: 16),
                    Text(
                      'This application is designed for editing specific XML claim files.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      icon: const Icon(Icons.bug_report_outlined),
                      label: const Text('Report an Issue'),
                      onPressed: () => _launchURL(
                          'https://github.com/RaidenExn/project_xmedit/issues'),
                    ),
                  ],
                  child: const Text('About this app'),
                ),
                ListTile(
                  leading: const Icon(Icons.code),
                  title: const Text('Developed by'),
                  subtitle: const Text('Abhijith SS'),
                  trailing: IconButton(
                    icon: const Icon(Icons.open_in_new),
                    onPressed: () => _launchURL('https://github.com/RaidenExn'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class BodyContent extends StatelessWidget {
  const BodyContent({super.key});

  @override
  Widget build(BuildContext context) {
    final claimNotifier = context.watch<ClaimDataNotifier>();
    final cardNotifier = context.watch<CardVisibilityNotifier>();
    final theme = Theme.of(context);
    const double spacing = 5.0;

    if (claimNotifier.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (claimNotifier.claimData == null) {
      return Center(
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: InkWell(
            onTap: claimNotifier.loadXmlFile,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.data_object,
                    size: 64,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'No XML File Loaded',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Click to open',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final resubmission = claimNotifier.claimData?.resubmission;
    final bool hasAttachment = resubmission?.attachment?.isNotEmpty ?? false;
    String attachmentText = 'No Attachment';
    bool isAttachmentInvalid = false;

    if (hasAttachment) {
      try {
        final decodedBytes = base64Decode(resubmission!.attachment!);
        final sizeInKb = (decodedBytes.lengthInBytes / 1024).toStringAsFixed(2);
        attachmentText = '$sizeInKb KB';
      } on FormatException {
        attachmentText = 'Corrupt';
        isAttachmentInvalid = true;
      }
    }

    final cardConfigs = [
      {
        'key': 'details',
        'widget': const ClaimDataSection(
            title: "Claim & Encounter Details",
            titleIcon: Icons.receipt_long_rounded,
            child: ClaimDetailsCard()),
      },
      {
        'key': 'resubmission & totals',
        'widget': IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 2,
                child: ClaimDataSection(
                    title: "Resubmission",
                    titleIcon: Icons.tune_rounded,
                    titleSuffix: claimNotifier.originalResubmissionType != null
                        ? Text(
                            'OG: ${claimNotifier.originalResubmissionType}',
                            style: theme.textTheme.bodySmall)
                        : null,
                    canStretch: true,
                    actions: [
                      ActionChip(
                        avatar: Icon(
                            hasAttachment
                                ? Icons.picture_as_pdf_rounded
                                : Icons.insert_drive_file_outlined,
                            size: 16,
                            color: isAttachmentInvalid
                                ? theme.colorScheme.error
                                : null),
                        label: Text(attachmentText),
                        onPressed: hasAttachment && !isAttachmentInvalid
                            ? () => claimNotifier
                                .viewResubmissionAttachment(context)
                            : null,
                        labelStyle: TextStyle(
                            color: isAttachmentInvalid
                                ? theme.colorScheme.error
                                : null),
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                      ),
                      _HeaderActionButton(
                        icon: hasAttachment
                            ? Icons.change_circle_outlined
                            : Icons.attach_file,
                        label: hasAttachment ? 'Replace' : 'Add',
                        onPressed:
                            claimNotifier.addOrEditResubmissionAttachment,
                      ),
                      _HeaderActionButton(
                        icon: Icons.delete_outline,
                        label: "Delete",
                        color: theme.colorScheme.error,
                        onPressed: hasAttachment
                            ? claimNotifier.deleteResubmissionAttachment
                            : null,
                      ),
                    ],
                    child: const ControlsResubmissionCard()),
              ),
              const SizedBox(width: spacing),
              Expanded(
                flex: 1,
                child: ClaimDataSection(
                  title: "Totals",
                  titleIcon: Icons.calculate_rounded,
                  canStretch: true,
                  actions: [
                    _HeaderActionButton(
                      icon: Icons.auto_fix_high_rounded,
                      label: "Auto Match",
                      onPressed:
                          claimNotifier.claimData!.activities.isNotEmpty
                              ? claimNotifier.autoMatchTotals
                              : null,
                    ),
                  ],
                  child: const TotalsCard(),
                ),
              ),
            ],
          ),
        ),
      },
      {
        'key': 'activities',
        'widget': ClaimDataSection(
          title: "Activities",
          titleIcon: Icons.list_alt_rounded,
          actions: [
            _HeaderActionButton(
              icon: Icons.merge_type,
              label: "Merge All Texts",
              onPressed: claimNotifier.mergeAllTextObservations,
            ),
            FilterChip(
              label: const Text("Transfer on Delete"),
              selected: claimNotifier.transferOnDelete,
              onSelected: claimNotifier.toggleTransferOnDelete,
              visualDensity: VisualDensity.compact,
            ),
            const VerticalDivider(width: 16, indent: 8, endIndent: 8),
            _HeaderActionButton(
              icon: Icons.refresh,
              label: "Reset",
              onPressed: claimNotifier.resetActivities,
            ),
            _HeaderActionButton(
              icon: Icons.clear_all_rounded,
              label: "Delete All",
              color: Theme.of(context).colorScheme.error,
              onPressed: claimNotifier.claimData!.activities.isNotEmpty
                  ? claimNotifier.deleteAllActivities
                  : null,
            ),
            _HeaderActionButton(
              icon: Icons.playlist_add_check_rounded,
              label: "Add All",
              onPressed: claimNotifier.claimData!.activities.isNotEmpty
                  ? claimNotifier.addAllActivities
                  : null,
            ),
          ],
          child: const ActivitiesCard(),
        ),
      },
      {
        'key': 'diagnosis',
        'widget': ClaimDataSection(
          title: "Diagnoses",
          titleIcon: Icons.medical_information_rounded,
          actions: [
            FilterChip(
              label: const Text("Edit"),
              selected: claimNotifier.isDiagnosisEditingEnabled,
              onSelected: claimNotifier.toggleDiagnosisEditing,
              visualDensity: VisualDensity.compact,
              labelStyle: Theme.of(context).textTheme.bodySmall,
              padding: const EdgeInsets.symmetric(horizontal: 2),
            ),
            _HeaderActionButton(
              icon: Icons.refresh,
              label: "Reset",
              onPressed: claimNotifier.isDiagnosisEditingEnabled
                  ? () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Confirm Reset'),
                          content: const Text(
                              'Are you sure you want to reset all diagnoses to their original state?'),
                          actions: [
                            TextButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(false),
                                child: const Text('Cancel')),
                            TextButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(true),
                                child: const Text('Reset')),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        claimNotifier.resetDiagnoses();
                      }
                    }
                  : null,
            ),
            _HeaderActionButton(
              icon: Icons.add,
              label: "Add",
              onPressed: claimNotifier.isDiagnosisEditingEnabled
                  ? () => showDiagnosisSearchDialog(context, claimNotifier)
                  : null,
            ),
          ],
          child: const DiagnosisCard(),
        ),
      },
    ];

    final List<Widget> children = cardConfigs
        .where((config) => cardNotifier.visibilities[config['key']]!)
        .map((config) => config['widget'] as Widget)
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(spacing),
      child: Column(
        children: [
          for (int i = 0; i < children.length; i++) ...[
            children[i],
            if (i < children.length - 1) const SizedBox(height: spacing),
          ],
        ],
      ),
    );
  }
}

class _HeaderActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final Color? color;

  const _HeaderActionButton({
    required this.icon,
    required this.label,
    this.onPressed,
    this.color,
  });

  @override
  Widget build(BuildContext context) => TextButton.icon(
        style: TextButton.styleFrom(
          visualDensity: VisualDensity.compact,
          foregroundColor: color,
        ),
        icon: Icon(icon, size: 16),
        label: Text(label),
        onPressed: onPressed,
      );
}