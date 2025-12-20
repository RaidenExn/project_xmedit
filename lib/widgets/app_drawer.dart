import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:project_xmedit/notifiers.dart';

import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

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
                  dense: true,
                ),
                SwitchListTile(
                  title: const Text('Dark Mode'),
                  value: themeNotifier.isDarkMode,
                  onChanged: (value) => themeNotifier.toggleTheme(),
                  visualDensity: VisualDensity.compact,
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                  child: Text(
                    'Theme Color',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: themeNotifier.availableColors.map((color) {
                      final bool isSelected = themeNotifier.seedColor == color;
                      final brightness =
                          ThemeData.estimateBrightnessForColor(color);
                      final iconColor = brightness == Brightness.dark
                          ? Colors.white
                          : Colors.black;
                      const double size = 32;

                      return InkWell(
                        onTap: () => themeNotifier.changeSeedColor(color),
                        borderRadius: BorderRadius.circular(size / 2),
                        child: Container(
                          width: size,
                          height: size,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: isSelected
                                ? Border.all(
                                    color:
                                        Theme.of(context).colorScheme.onSurface,
                                    width: 3,
                                  )
                                : null,
                          ),
                          child: isSelected
                              ? Icon(Icons.check, color: iconColor, size: 18)
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
                  dense: true,
                ),
                ...cardNotifier.visibilities.entries.map((entry) {
                  final key = entry.key;
                  String title = key[0].toUpperCase() + key.substring(1);
                  if (key == 'resubmission & totals') {
                    title = 'Resubmission & Totals';
                  } else if (key == 'activities') {
                    title = 'Activities List';
                  } else if (key == 'details') {
                    title = 'Claim Details';
                  }
                  return SwitchListTile(
                    title: Text(title),
                    value: entry.value,
                    onChanged: (value) => cardNotifier.toggle(key),
                    visualDensity: VisualDensity.compact,
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
                  dense: true,
                  child: const Text('About this app'),
                ),
                ListTile(
                  leading: const Icon(Icons.code),
                  title: const Text('Developed by'),
                  subtitle: const Text('Abhijith SS'),
                  trailing: IconButton(
                    icon: const Icon(Icons.open_in_new),
                    onPressed: () => _launchURL(
                        'https://raidenexn.github.io/project_xmedit/'),
                  ),
                  dense: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
