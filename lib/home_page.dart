import 'package:flutter/material.dart';
import 'package:project_xmedit/cards/cards.dart';
import 'package:project_xmedit/notifiers.dart';
import 'package:project_xmedit/widgets.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:window_manager/window_manager.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WindowListener {
  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
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
        scaffoldMessenger.showSnackBar(SnackBar(
          content: Text(message),
          backgroundColor: isError
              ? Theme.of(context).colorScheme.error
              : Theme.of(context).colorScheme.secondary,
        ));
      }
    };
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<ClaimDataNotifier>();
    final bool isDataLoaded = notifier.claimData != null;

    return Scaffold(
      appBar: AppBar(
        title: const DragToMoveArea(
          child: SizedBox(width: double.infinity, child: Text('Project XMEdit')),
        ),
        actions: [
          Tooltip(
            message: "Open XML File",
            child: TextButton.icon(
              icon: const Icon(Icons.folder_open_outlined),
              label: const Text("Open"),
              onPressed: notifier.loadXmlFile,
            ),
          ),
          Tooltip(
            message: "Clear All Data",
            child: TextButton.icon(
              icon: const Icon(Icons.clear_all),
              label: const Text("Clear All"),
              onPressed: isDataLoaded ? notifier.clearData : null,
            ),
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
    );
  }
}

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  Future<void> _launchURL(String url, BuildContext context) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri)) {
      if (context.mounted) {
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
          const DrawerHeader(
            child: Text('Settings'),
          ),
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
                  final title =
                      entry.key[0].toUpperCase() + entry.key.substring(1);
                  return SwitchListTile(
                    title: Text(title),
                    value: entry.value,
                    onChanged: (value) => cardNotifier.toggle(entry.key),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                const ListTile(
                  leading: Icon(Icons.info_outline),
                  title: Text('About'),
                ),
                ListTile(
                  title: const Text('Author'),
                  subtitle: const Text('Abhijith SS'),
                  trailing: IconButton(
                    icon: const Icon(Icons.open_in_new),
                    tooltip: 'View on GitHub',
                    onPressed: () =>
                        _launchURL('https://github.com/RaidenExn', context),
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
    const double spacing = 5.0;

    if (claimNotifier.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (claimNotifier.claimData == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('No XML data loaded.',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: claimNotifier.loadXmlFile,
              icon: const Icon(Icons.folder_open),
              label: const Text('Open XML File'),
            )
          ],
        ),
      );
    }

    final List<Widget> children = [];

    if (cardNotifier.visibilities['details']!) {
      children.add(const ClaimDataSection(
          title: "Claim & Encounter Details", child: ClaimDetailsCard()));
    }

    if (cardNotifier.visibilities['controls & totals']!) {
      children.add(
        IntrinsicHeight( // Added this widget
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: const [
              Expanded(
                flex: 2,
                child: ClaimDataSection(
                    title: "Controls & Resubmission",
                    canStretch: true,
                    child: ControlsResubmissionCard()),
              ),
              SizedBox(width: spacing),
              Expanded(
                flex: 1,
                child: ClaimDataSection(
                    title: "Totals",
                    canStretch: true,
                    child: TotalsCard()),
              ),
            ],
          ),
        ),
      );
    }

    if (cardNotifier.visibilities['activities']!) {
      children.add(
          const ClaimDataSection(title: "Activities", child: ActivitiesCard()));
    }

    if (cardNotifier.visibilities['diagnosis']!) {
      children.add(
          const ClaimDataSection(title: "Diagnoses", child: DiagnosisCard()));
    }



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