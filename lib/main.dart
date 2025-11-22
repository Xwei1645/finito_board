import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:window_manager/window_manager.dart';
import 'package:path/path.dart' as p;
import 'screens/homework_board.dart';
import 'services/settings_service.dart';
import 'services/storage/json_storage_service.dart';
import 'services/storage/backup_service.dart';
import 'services/storage/snapshot_service.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 初始化JSON存储服务
  await JsonStorageService.instance.init();
  
  // 初始化备份服务
  final appDir = p.dirname(Platform.resolvedExecutable);
  final dataDir = p.join(appDir, 'data');
  await BackupService.instance.init(dataDir);
  
  // 初始化快照服务
  await SnapshotService.instance.init(dataDir);
  
  // 初始化设置服务
  await SettingsService.instance.initialize();
  
  // 应用启动时执行自动备份
  await BackupService.instance.backupOnStartup();
  
  // 应用启动时执行自动快照
  await SnapshotService.instance.snapshotOnStartup();
  
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    await windowManager.ensureInitialized();
    
    // 尝试恢复窗口状态
    final savedWindowState = SettingsService.instance.getWindowState();
    final windowSize = savedWindowState != null 
        ? Size(savedWindowState.width, savedWindowState.height)
        : const Size(1200, 800);
    
    WindowOptions windowOptions = WindowOptions(
      size: windowSize,
      center: savedWindowState == null,
      backgroundColor: Colors.transparent,
      skipTaskbar: !SettingsService.instance.getShowInTaskbar(),
      titleBarStyle: TitleBarStyle.hidden,
      windowButtonVisibility: false,
    );
    
    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
      
      // 恢复窗口状态
      if (savedWindowState != null) {
        await SettingsService.instance.restoreWindowState();
      }
      
      // 初始状态设置为锁定（无边框，不可调整大小）
      // 初始化时先设置为无边框，再禁用调整大小
      await windowManager.setAsFrameless();
      // await windowManager.setHasShadow(false);
      await windowManager.setResizable(false);
    });
  }
  
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isDarkMode = false;
  int? _themeColor;

  @override
  void initState() {
    super.initState();
    _loadThemeSettings();
  }

  Future<void> _loadThemeSettings() async {
    final settingsService = SettingsService.instance;
    final isDarkMode = settingsService.getDarkMode();
    final themeColor = settingsService.getThemeColor();
    
    setState(() {
      _isDarkMode = isDarkMode;
      _themeColor = themeColor;
    });
  }

  @override
  Widget build(BuildContext context) {
    final seedColor = _themeColor != null ? Color(_themeColor!) : Colors.blue;
    
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: MaterialApp(
        title: 'FinitoBoard',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: seedColor,
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          fontFamily: 'HarmonyOS Sans SC',
        ),
        darkTheme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: seedColor,
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
          fontFamily: 'HarmonyOS Sans SC',
        ),
        themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          FlutterQuillLocalizations.delegate,
        ],
        locale: const Locale('zh', 'CN'),
        home: MainWindow(onThemeChanged: _loadThemeSettings),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

class MainWindow extends StatelessWidget {
  final VoidCallback? onThemeChanged;
  
  const MainWindow({super.key, this.onThemeChanged});

  @override
  Widget build(BuildContext context) {
    return HomeworkBoard(onThemeChanged: onThemeChanged);
  }
}
