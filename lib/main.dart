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

    final time =
        '${record.time.year}-${record.time.month.toString().padLeft(2, '0')}-${record.time.day.toString().padLeft(2, '0')} ${record.time.hour.toString().padLeft(2, '0')}:${record.time.minute.toString().padLeft(2, '0')}:${record.time.second.toString().padLeft(2, '0')}.${(record.time.millisecond ~/ 10).toString().padLeft(2, '0')}';
    final level = record.level
        .toString()
        .split('.')
        .last
        .toUpperCase()
        .padRight(7);

    // 写入文件
    final message = '$time | $level | ${record.message}\n';
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
      debugPrint('$color$time | $level | ${record.message}$reset');

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

      // 根据保存的窗口锁定状态初始化窗口
      final isWindowLocked = SettingsService.instance.getWindowLocked();
      if (isWindowLocked) {
        // 锁定状态：无边框，不可调整大小
        await windowManager.setAsFrameless();
        await windowManager.setResizable(false);
      } else {
        // 解锁状态：隐藏标题栏，可调整大小
        if (Platform.isLinux) {
          await windowManager.setTitleBarStyle(TitleBarStyle.normal);
        } else {
          await windowManager.setTitleBarStyle(TitleBarStyle.hidden);
        }
        await windowManager.setResizable(true);
      }
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
  double _windowCornerRadius = 12.0;
  double _savedCornerRadius = 12.0; // 保存设置的圆角值

  @override
  void initState() {
    super.initState();
    _loadThemeSettings();
  }

  Future<void> _loadThemeSettings() async {
    final settingsService = SettingsService.instance;
    final isDarkMode = settingsService.getDarkMode();
    final themeColor = settingsService.getThemeColor();
    final windowCornerRadius = settingsService.getWindowCornerRadius();
    final isWindowLocked = settingsService.getWindowLocked();

    setState(() {
      _isDarkMode = isDarkMode;
      _themeColor = themeColor;
      _savedCornerRadius = windowCornerRadius; // 保存设置值
      // 根据窗口锁定状态决定初始圆角值
      _windowCornerRadius = isWindowLocked ? windowCornerRadius : 0.0;
    });
  }

  void _onWindowLockChanged(bool isLocked) {
    setState(() {
      // 解锁时圆角为0，锁定时使用保存的圆角值
      _windowCornerRadius = isLocked ? _savedCornerRadius : 0.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final seedColor = _themeColor != null ? Color(_themeColor!) : Colors.blue;

    return ClipRRect(
      borderRadius: BorderRadius.circular(_windowCornerRadius),
      child: MaterialApp(
        title: 'Zooni',
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
        home: MainWindow(
          onThemeChanged: _loadThemeSettings,
          onWindowLockChanged: _onWindowLockChanged,
        ),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

class MainWindow extends StatelessWidget {
  final VoidCallback? onThemeChanged;
  final ValueChanged<bool>? onWindowLockChanged;

  const MainWindow({super.key, this.onThemeChanged, this.onWindowLockChanged});

  @override
  Widget build(BuildContext context) {
    return HomeworkBoard(
      onThemeChanged: onThemeChanged,
      onWindowLockChanged: onWindowLockChanged,
    );
  }
}
