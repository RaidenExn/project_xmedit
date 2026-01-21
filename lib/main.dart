import 'package:flutter/material.dart';
import 'package:project_xmedit/home_page.dart';
import 'package:project_xmedit/notifiers.dart';
import 'package:project_xmedit/providers/bulk_claim_data_provider.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:window_manager/window_manager.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:flutter/foundation.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Get app version
  final packageInfo = await PackageInfo.fromPlatform();
  final appTitle = 'project_xmedit ${packageInfo.version}';

  if (kIsWeb) {
    databaseFactory = databaseFactoryFfiWeb;
  } else {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    await windowManager.ensureInitialized();

    final windowOptions = WindowOptions(
      size: const Size(1200, 800),
      minimumSize: const Size(1150, 700),
      center: true,
      title: appTitle,
      titleBarStyle: TitleBarStyle.normal,
    );

    await windowManager.setPreventClose(true);
    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  runApp(MyApp(title: appTitle));
}

class MyApp extends StatelessWidget {
  final String title;

  const MyApp({super.key, required this.title});

  @override
  Widget build(BuildContext context) => MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (context) => ClaimDataNotifier()),
          ChangeNotifierProvider(create: (context) => BulkClaimDataNotifier()),
          ChangeNotifierProvider(create: (context) => ThemeNotifier()),
        ],
        child: AppContent(title: title),
      );
}

class AppContent extends StatelessWidget {
  final String title;

  const AppContent({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    final themeNotifier = context.watch<ThemeNotifier>();
    return MaterialApp(
      title: title,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: themeNotifier.seedColor,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF5F7FA),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: themeNotifier.seedColor, width: 2),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        tooltipTheme: TooltipThemeData(
          waitDuration: const Duration(milliseconds: 500),
          decoration: BoxDecoration(
            color: const Color(0xFF313033),
            borderRadius: BorderRadius.circular(4),
          ),
          textStyle: const TextStyle(color: Color(0xFFF4EFF4), fontSize: 12),
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: themeNotifier.seedColor,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF1A1C1E),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: themeNotifier.seedColor, width: 2),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        tooltipTheme: TooltipThemeData(
          waitDuration: const Duration(milliseconds: 500),
          decoration: BoxDecoration(
            color: const Color(0xFFE6E1E5),
            borderRadius: BorderRadius.circular(4),
          ),
          textStyle: const TextStyle(color: Color(0xFF313033), fontSize: 12),
        ),
      ),
      themeMode: themeNotifier.themeMode,
      debugShowCheckedModeBanner: false,
      home: const HomePage(),
    );
  }
}
