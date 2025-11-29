import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:window_manager/window_manager.dart';
import 'package:path/path.dart' as p;
import 'package:loggy/loggy.dart';
import 'screens/homework_board.dart';
import 'services/settings_service.dart';
import 'services/storage/json_storage_service.dart';
import 'services/storage/backup_service.dart';
import 'services/storage/snapshot_service.dart';

// 文件日志输出器（自动分文件）+ 控制台彩色输出
class RotatingFilePrinter extends LoggyPrinter {
  final String logDir;
  final int maxFileSize;
  File? _currentFile;
  int _currentFileSize = 0;

  RotatingFilePrinter({
    required this.logDir,
    this.maxFileSize = 10 * 1024 * 1024, // 默认 10MB
  }) {
    _initLogFile();
  }

  void _initLogFile() {
    final dir = Directory(logDir);
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    _rotateIfNeeded();
  }

  void _rotateIfNeeded() {
    if (_currentFile == null || _currentFileSize >= maxFileSize) {
      final timestamp = DateTime.now()
          .toIso8601String()
          .replaceAll(':', '-')
          .replaceAll('.', '-');
      _currentFile = File(p.join(logDir, 'app_$timestamp.log'));
      _currentFileSize = 0;
    }
  }

  String _getColor(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return '\x1B[36m'; // Cyan
      case LogLevel.info:
        return '\x1B[32m'; // Green
      case LogLevel.warning:
        return '\x1B[33m'; // Yellow
      case LogLevel.error:
        return '\x1B[31m'; // Red
      default:
        return '\x1B[37m'; // White
    }
  }

  @override
  void onLog(LogRecord record) {
    _rotateIfNeeded();

    final time = record.time.toIso8601String();
    final level = record.level
        .toString()
        .split('.')
        .last
        .toUpperCase()
        .padRight(7);

    // 写入文件
    final message = '[$time] $level | ${record.message}\n';
    _currentFile?.writeAsStringSync(message, mode: FileMode.append);
    _currentFileSize += message.length;

    if (record.error != null) {
      final errorMsg = '  Error: ${record.error}\n';
      _currentFile?.writeAsStringSync(errorMsg, mode: FileMode.append);
      _currentFileSize += errorMsg.length;
    }

    if (record.stackTrace != null) {
      final stackMsg = '  ${record.stackTrace}\n';
      _currentFile?.writeAsStringSync(stackMsg, mode: FileMode.append);
      _currentFileSize += stackMsg.length;
    }

    // 控制台输出（仅在 debug 模式）
    if (kDebugMode) {
      final color = _getColor(record.level);
      final reset = '\x1B[0m';
      debugPrint('$color[$time] $level | ${record.message}$reset');

      if (record.error != null) {
        debugPrint('$color  Error: ${record.error}$reset');
      }

      if (record.stackTrace != null) {
        debugPrint('$color  ${record.stackTrace}$reset');
      }
    }
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化日志系统
  final appDir = p.dirname(Platform.resolvedExecutable);
  final logsDir = p.join(appDir, 'logs');

  Loggy.initLoggy(
    logPrinter: RotatingFilePrinter(
      logDir: logsDir,
      maxFileSize: 10 * 1024 * 1024,
    ),
  );

  logInfo('应用启动');

  // 初始化JSON存储服务
  await JsonStorageService.instance.init();
  logInfo('JSON存储服务初始化完成');

  // 初始化备份服务
  final dataDir = p.join(appDir, 'data');
  await BackupService.instance.init(dataDir);
  logInfo('备份服务初始化完成');

  // 初始化快照服务
  await SnapshotService.instance.init(dataDir);
  logInfo('快照服务初始化完成');

  // 初始化设置服务
  await SettingsService.instance.initialize();
  logInfo('设置服务初始化完成');

  // 应用启动时执行自动备份
  await BackupService.instance.backupOnStartup();
  logInfo('启动备份已执行');

  // 应用启动时执行自动快照
  await SnapshotService.instance.snapshotOnStartup();
  logInfo('启动快照已执行');

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
