import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:project_xmedit/cards/cards.dart';
import 'package:project_xmedit/notifiers.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
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
  PackageInfo _packageInfo = PackageInfo(appName: '', packageName: '', version: '', buildNumber: '');

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) windowManager.addListener(this);
    _initPackageInfo();
  }

  Future<void> _initPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) setState(() => _packageInfo = info);
  }

  @override
  void dispose() {
    if (!kIsWeb) windowManager.removeListener(this);
    super.dispose();
  }
  
  void _showStatusSnackBar(String message, bool isError) {
    if (!mounted || message.isEmpty) return;
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    scaffoldMessenger
      ..removeCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(color: isError ? colorScheme.onErrorContainer : colorScheme.onSecondaryContainer),
        ),
        backgroundColor: isError ? colorScheme.errorContainer : colorScheme.secondaryContainer,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        width: 450,
      ));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    context.read<ClaimDataNotifier>().onMessage = _showStatusSnackBar;
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<ClaimDataNotifier>();
    final isDataLoaded = notifier.claimData != null;
    final appBarTitle = Text('Project XMEdit - v${_packageInfo.version}');

    return Actions(
      actions: <Type, Action<Intent>>{
        OpenIntent: CallbackAction<OpenIntent>(onInvoke: (intent) => notifier.loadXmlFile()),
        SaveIntent: CallbackAction<SaveIntent>(onInvoke: (intent) => isDataLoaded ? notifier.saveXmlFile(saveAs: false) : null),
        SaveAsIntent: CallbackAction<SaveAsIntent>(onInvoke: (intent) => isDataLoaded ? notifier.saveXmlFile(saveAs: true) : null),
      },
      child: Shortcuts(
        shortcuts: <ShortcutActivator, Intent>{
          const SingleActivator(LogicalKeyboardKey.keyO, control: true): OpenIntent(),
          const SingleActivator(LogicalKeyboardKey.keyS, control: true): SaveIntent(),
          const SingleActivator(LogicalKeyboardKey.keyS, control: true, shift: true): SaveAsIntent(),
        },
        child: Scaffold(
          appBar: AppBar(
            title: kIsWeb ? appBarTitle : DragToMoveArea(child: SizedBox(width: double.infinity, child: appBarTitle)),
            actions: [
              TextButton.icon(icon: const Icon(Icons.folder_open_outlined), label: const Text("Open"), onPressed: notifier.isLoading ? null : notifier.loadXmlFile),
              TextButton.icon(icon: const Icon(Icons.clear_all), label: const Text("Clear All"), onPressed: isDataLoaded ? notifier.clearData : null),
              const VerticalDivider(indent: 12, endIndent: 12),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: FilterChip(label: const Text('Rename on Apply'), selected: notifier.shouldRenameFile, onSelected: isDataLoaded ? notifier.toggleRenameFile : null),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                icon: const Icon(Icons.save_outlined),
                label: const Text("Apply"),
                onPressed: isDataLoaded && !notifier.isLoading ? () => notifier.saveXmlFile(saveAs: false) : null,
                style: FilledButton.styleFrom(visualDensity: VisualDensity.compact),
              ),
              const SizedBox(width: 8),
              if (!kIsWeb) ...[
                TextButton(onPressed: isDataLoaded ? () => notifier.saveXmlFile(saveAs: true) : null, child: const Text("Save As...")),
                const SizedBox(width: 8),
                const WindowButtons(),
                const SizedBox(width: 4.0)
              ],
            ],
          ),
          drawer: AppDrawer(appName: _packageInfo.appName, version: _packageInfo.version),
          body: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 1400), child: const BodyContent())),
        ),
      ),
    );
  }
}

Future<void> _launchURL(BuildContext context, String url) async {
  if (!await launchUrl(Uri.parse(url))) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not launch $url')));
    }
  }
}

class AppDrawer extends StatelessWidget {
  final String appName;
  final String version;
  const AppDrawer({super.key, required this.appName, required this.version});
  
  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: const EdgeInsets.all(8.0),
        children: [
          _buildAppearanceCard(context),
          const SizedBox(height: 8),
          _buildVisibilityCard(context),
          const SizedBox(height: 8),
          _buildAboutCard(context),
        ],
      ),
    );
  }

  Widget _buildAppearanceCard(BuildContext context) {
    final themeNotifier = context.watch<ThemeNotifier>();
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ListTile(title: Text('Appearance'), leading: Icon(Icons.palette_outlined)),
          SwitchListTile(title: const Text('Dark Mode'), value: themeNotifier.isDarkMode, onChanged: (value) => themeNotifier.toggleTheme()),
          const Padding(padding: EdgeInsets.fromLTRB(16, 8, 16, 8), child: Text('Theme Color')),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Wrap(spacing: 8, runSpacing: 8, children: [
              for (final color in themeNotifier.availableColors)
                _ThemeColorChip(
                  color: color,
                  isSelected: themeNotifier.seedColor == color,
                  onTap: () => themeNotifier.changeSeedColor(color),
                ),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildVisibilityCard(BuildContext context) {
    final cardNotifier = context.watch<CardVisibilityNotifier>();
    String formatTitle(String key) => (key == 'resubmission & totals' ? 'Resubmission' : key[0].toUpperCase() + key.substring(1));
    
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(children: [
        const ListTile(title: Text('Visible Cards'), leading: Icon(Icons.view_quilt_outlined)),
        for (final entry in cardNotifier.visibilities.entries)
          SwitchListTile(title: Text(formatTitle(entry.key)), value: entry.value, onChanged: (value) => cardNotifier.toggle(entry.key)),
      ]),
    );
  }

  Widget _buildAboutCard(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AboutListTile(
            icon: const Icon(Icons.info_outline),
            applicationIcon: const Icon(Icons.edit_document),
            applicationName: appName,
            applicationVersion: version,
            applicationLegalese: '© 2025 Abhijith SS',
            aboutBoxChildren: [
              const SizedBox(height: 16),
              Text('This application is designed for editing specific XML claim files.', style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 8),
              TextButton.icon(
                icon: const Icon(Icons.bug_report_outlined),
                label: const Text('Report an Issue'),
                onPressed: () => _launchURL(context, 'https://github.com/RaidenExn/project_xmedit/issues'),
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
              onPressed: () => _launchURL(context, 'https://github.com/RaidenExn/project_xmedit'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ThemeColorChip extends StatelessWidget {
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;
  const _ThemeColorChip({required this.color, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final brightness = ThemeData.estimateBrightnessForColor(color);
    final iconColor = brightness == Brightness.dark ? Colors.white : Colors.black;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 35,
        height: 35,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: isSelected ? Border.all(color: Theme.of(context).colorScheme.onSurface, width: 3) : null,
        ),
        child: isSelected ? Icon(Icons.check, color: iconColor, size: 20) : null,
      ),
    );
  }
}

class BodyContent extends StatelessWidget {
  const BodyContent({super.key});

  Future<bool?> _showConfirmDialog(BuildContext context, String title, String content) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Confirm')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final claimNotifier = context.watch<ClaimDataNotifier>();
    
    if (claimNotifier.isLoading) return const Center(child: CircularProgressIndicator());
    if (claimNotifier.claimData == null) return _EmptyState(onTap: claimNotifier.loadXmlFile);

    final cardNotifier = context.watch<CardVisibilityNotifier>();
    final List<Widget> visibleCards = [
      if (cardNotifier.visibilities['details']!)
        const ClaimDataSection(title: "Claim & Encounter Details", titleIcon: Icons.receipt_long_rounded, child: ClaimDetailsCard()),
      if (cardNotifier.visibilities['resubmission & totals']!)
        _buildResubmissionAndTotalsSection(context, claimNotifier),
      if (cardNotifier.visibilities['activities']!)
        _buildActivitiesSection(context, claimNotifier),
      if (cardNotifier.visibilities['diagnosis']!)
        _buildDiagnosisSection(context, claimNotifier),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(5.0),
      child: Column(children: [
        for (int i = 0; i < visibleCards.length; i++) ...[
          visibleCards[i],
          if (i < visibleCards.length - 1) const SizedBox(height: 5.0),
        ],
      ]),
    );
  }
  
  Widget _buildResubmissionAndTotalsSection(BuildContext context, ClaimDataNotifier claimNotifier) {
    final theme = Theme.of(context);
    final resubmission = claimNotifier.claimData?.resubmission;
    final hasAttachment = resubmission?.attachment?.isNotEmpty ?? false;
    String attachmentText = 'No Attachment';
    bool isAttachmentInvalid = false;

    if (hasAttachment) {
      try {
        final sizeInKb = (base64Decode(resubmission!.attachment!).lengthInBytes / 1024).toStringAsFixed(2);
        attachmentText = '$sizeInKb KB';
      } on FormatException {
        attachmentText = 'Corrupt';
        isAttachmentInvalid = true;
      }
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 2,
            child: ClaimDataSection(
              title: "Resubmission",
              titleIcon: Icons.tune_rounded,
              titleSuffix: claimNotifier.originalResubmissionType != null ? Text('OG: ${claimNotifier.originalResubmissionType}', style: theme.textTheme.bodySmall) : null,
              canStretch: true,
              actions: [
                ActionChip(
                  avatar: Icon(hasAttachment ? Icons.picture_as_pdf_rounded : Icons.insert_drive_file_outlined, size: 16, color: isAttachmentInvalid ? theme.colorScheme.error : null),
                  label: Text(attachmentText),
                  onPressed: hasAttachment && !isAttachmentInvalid ? () => claimNotifier.viewResubmissionAttachment(context) : null,
                  labelStyle: TextStyle(color: isAttachmentInvalid ? theme.colorScheme.error : null),
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                ),
                _HeaderActionButton(icon: hasAttachment ? Icons.change_circle_outlined : Icons.attach_file, label: hasAttachment ? 'Replace' : 'Add', onPressed: claimNotifier.addOrEditResubmissionAttachment),
                _HeaderActionButton(icon: Icons.delete_outline, label: "Delete", color: theme.colorScheme.error, onPressed: hasAttachment ? claimNotifier.deleteResubmissionAttachment : null),
              ],
              child: const ControlsResubmissionCard(),
            ),
          ),
          const SizedBox(width: 5.0),
          Expanded(
            flex: 1,
            child: ClaimDataSection(
              title: "Totals",
              titleIcon: Icons.calculate_rounded,
              canStretch: true,
              actions: [
                _HeaderActionButton(icon: Icons.auto_fix_high_rounded, label: "Auto Match", onPressed: claimNotifier.claimData!.activities.isNotEmpty ? claimNotifier.autoMatchTotals : null),
              ],
              child: const TotalsCard(),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildActivitiesSection(BuildContext context, ClaimDataNotifier claimNotifier) => ClaimDataSection(
        title: "Activities",
        titleIcon: Icons.list_alt_rounded,
        actions: [
          if (!kIsWeb) _HeaderActionButton(icon: Icons.merge_type, label: "Merge All Texts", onPressed: claimNotifier.mergeAllTextObservations),
          FilterChip(label: const Text("Transfer on Delete"), selected: claimNotifier.transferOnDelete, onSelected: claimNotifier.toggleTransferOnDelete, visualDensity: VisualDensity.compact),
          const VerticalDivider(width: 16, indent: 8, endIndent: 8),
          _HeaderActionButton(icon: Icons.refresh, label: "Reset", onPressed: claimNotifier.resetActivities),
          _HeaderActionButton(icon: Icons.clear_all_rounded, label: "Delete All", color: Theme.of(context).colorScheme.error, onPressed: claimNotifier.claimData!.activities.isNotEmpty ? claimNotifier.deleteAllActivities : null),
          _HeaderActionButton(icon: Icons.playlist_add_check_rounded, label: "Add All", onPressed: claimNotifier.claimData!.activities.isNotEmpty ? claimNotifier.addAllActivities : null),
        ],
        child: const ActivitiesCard(),
      );

  Widget _buildDiagnosisSection(BuildContext context, ClaimDataNotifier claimNotifier) => ClaimDataSection(
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
              onPressed: claimNotifier.isDiagnosisEditingEnabled ? () async {
                  final confirm = await _showConfirmDialog(context, 'Confirm Reset', 'Are you sure you want to reset all diagnoses to their original state?');
                  if (confirm == true) claimNotifier.resetDiagnoses();
                } : null),
          if (!kIsWeb)
            _HeaderActionButton(icon: Icons.add, label: "Add", onPressed: claimNotifier.isDiagnosisEditingEnabled ? () => showDiagnosisSearchDialog(context, claimNotifier) : null),
        ],
        child: const DiagnosisCard(),
      );
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onTap;
  const _EmptyState({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainer, borderRadius: BorderRadius.circular(16)),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.data_object, size: 64, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 20),
              Text('No XML File Loaded', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text('Click to open', style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final Color? color;
  const _HeaderActionButton({required this.icon, required this.label, this.onPressed, this.color});

  @override
  Widget build(BuildContext context) => TextButton.icon(
        style: TextButton.styleFrom(visualDensity: VisualDensity.compact, foregroundColor: color),
        icon: Icon(icon, size: 16),
        label: Text(label),
        onPressed: onPressed,
      );
}