import 'dart:io';
import 'package:flutter/material.dart';
import 'package:launch_at_startup/launch_at_startup.dart';
import 'package:window_manager/window_manager.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../models/app_config.dart';
import '../models/window_state.dart';
import 'storage/json_storage_service.dart';


/// 设置操作结果
class SettingsResult {
  final bool success;
  final String? error;
  
  const SettingsResult.success() : success = true, error = null;
  const SettingsResult.failure(this.error) : success = false;
}

class SettingsService {
  static SettingsService? _instance;
  static SettingsService get instance => _instance ??= SettingsService._();
  
  SettingsService._();
  
  /// 初始化设置服务
  Future<void> initialize() async {
    // 初始化开机自启设置
    await _initializeLaunchAtStartup();
    
    // 应用已保存的设置
    await _applySettings();
  }


  
  /// 初始化开机自启配置
  Future<void> _initializeLaunchAtStartup() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      
      launchAtStartup.setup(
        appName: packageInfo.appName,
        appPath: Platform.resolvedExecutable,
        packageName: packageInfo.packageName,
      );
    } catch (e) {
      // 初始化失败，静默处理
    }
  }
  
  /// 应用已保存的设置
  Future<void> _applySettings() async {
    // 应用窗口层级设置
    final windowLevel = getWindowLevel();
    await setWindowLevel(windowLevel);
  }
  
  /// 获取开机自启状态
  bool getAutoStart() {
    final config = JsonStorageService.instance.getAppConfig();
    return config.autoStartup;
  }
  
  /// 检查开机自启的实际状态（从系统获取）
  Future<bool> checkAutoStartStatus() async {
    try {
      return await launchAtStartup.isEnabled();
    } catch (e) {
      return false;
    }
  }
  
  /// 设置开机自启
  Future<SettingsResult> setAutoStart(bool enabled) async {
    try {
      // 检查是否已经初始化
      final packageInfo = await PackageInfo.fromPlatform();
      
      // 重新设置launch_at_startup配置，确保路径正确
      launchAtStartup.setup(
        appName: packageInfo.appName,
        appPath: Platform.resolvedExecutable,
        packageName: packageInfo.packageName,
      );
      
      if (enabled) {
        await launchAtStartup.enable();
      } else {
        await launchAtStartup.disable();
      }
      
      // 更新JSON配置
      final storageService = JsonStorageService.instance;
      final currentConfig = storageService.getAppConfig();
      final updatedConfig = AppConfig(
        theme: currentConfig.theme,
        autoStartup: enabled,
        availableSubjects: currentConfig.availableSubjects,
        availableTags: currentConfig.availableTags,
        scaleFactor: currentConfig.scaleFactor,
        columnCount: currentConfig.columnCount,
        windowLevel: currentConfig.windowLevel,
        backgroundOpacity: currentConfig.backgroundOpacity,
        firstLaunch: currentConfig.firstLaunch,
        showInTaskbar: currentConfig.showInTaskbar,
      );
      await storageService.saveAppConfig(updatedConfig);
      return const SettingsResult.success();
    } catch (e) {
      final errorMessage = e.toString();
      return SettingsResult.failure(errorMessage);
    }
  }
  
  /// 获取窗口层级状态
  int getWindowLevel() {
    final config = JsonStorageService.instance.getAppConfig();
    return config.windowLevel;
  }
  
  /// 设置窗口层级: 0=常规, 1=置顶, 2=置底
  Future<bool> setWindowLevel(int level) async {
    try {
      if (level == 1) {
        // 置顶
        await windowManager.setAlwaysOnTop(true);
      } else if (level == 2) {
        // 置底
        await windowManager.setAlwaysOnTop(false);
        await windowManager.setAlwaysOnBottom(true);
      } else {
        // 常规
        await windowManager.setAlwaysOnTop(false);
        await windowManager.setAlwaysOnBottom(false);
      }
      
      // 更新JSON配置
      final storageService = JsonStorageService.instance;
      final currentConfig = storageService.getAppConfig();
      final updatedConfig = currentConfig.copyWith(
        windowLevel: level,
      );
      await storageService.saveAppConfig(updatedConfig);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// 获取在任务栏显示状态
  bool getShowInTaskbar() {
    final config = JsonStorageService.instance.getAppConfig();
    return config.showInTaskbar;
  }

  /// 设置在任务栏显示
  Future<bool> setShowInTaskbar(bool enabled) async {
    try {
      if (enabled) {
        await windowManager.setSkipTaskbar(false);
      } else {
        await windowManager.setSkipTaskbar(true);
      }

      // 更新JSON配置
      final storageService = JsonStorageService.instance;
      final currentConfig = storageService.getAppConfig();
      final updatedConfig = currentConfig.copyWith(
        showInTaskbar: enabled,
      );
      await storageService.saveAppConfig(updatedConfig);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// 获取明暗模式状态
  bool getDarkMode() {
    final config = JsonStorageService.instance.getAppConfig();
    return config.theme == 'dark';
  }
  
  /// 设置明暗模式
  Future<bool> setDarkMode(bool enabled) async {
    try {
      // 更新JSON配置
      final storageService = JsonStorageService.instance;
      final currentConfig = storageService.getAppConfig();
      final updatedConfig = AppConfig(
        theme: enabled ? 'dark' : 'light',
        autoStartup: currentConfig.autoStartup,
        availableSubjects: currentConfig.availableSubjects,
        availableTags: currentConfig.availableTags,
        scaleFactor: currentConfig.scaleFactor,
        columnCount: currentConfig.columnCount,
        windowLevel: currentConfig.windowLevel,
        backgroundOpacity: currentConfig.backgroundOpacity,
        firstLaunch: currentConfig.firstLaunch,
        showInTaskbar: currentConfig.showInTaskbar,
      );
      await storageService.saveAppConfig(updatedConfig);
      return true;
    } catch (e) {
      return false;
    }
  }
  
  /// 获取背景不透明度 (0.0 - 1.0)
  double getBackgroundOpacity() {
    final config = JsonStorageService.instance.getAppConfig();
    return config.backgroundOpacity;
  }
  
  /// 设置背景不透明度
  Future<bool> setBackgroundOpacity(double opacity) async {
    try {
      // 确保值在有效范围内
      final clampedOpacity = opacity.clamp(0.0, 1.0);
      
      // 更新JSON配置
      final storageService = JsonStorageService.instance;
      final currentConfig = storageService.getAppConfig();
      final updatedConfig = currentConfig.copyWith(
        backgroundOpacity: clampedOpacity,
      );
      await storageService.saveAppConfig(updatedConfig);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// 保存窗口状态
  Future<bool> saveWindowState({
    required double x,
    required double y,
    required double width,
    required double height,
    bool maximized = false,
    bool minimized = false,
    bool fullscreen = false,
  }) async {
    try {
      final windowState = WindowState(
        x: x,
        y: y,
        width: width,
        height: height,
        isMaximized: maximized,
        isMinimized: minimized,
        isFullScreen: fullscreen,
      );
      
      await JsonStorageService.instance.saveWindowState(windowState);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// 获取窗口状态
  WindowState? getWindowState() {
    try {
      return JsonStorageService.instance.getWindowState();
    } catch (e) {
      return null;
    }
  }

  /// 恢复窗口状态
  Future<bool> restoreWindowState() async {
    try {
      final windowState = getWindowState();
      if (windowState != null) {
        await windowManager.setBounds(
          null,
          position: Offset(windowState.x, windowState.y),
          size: Size(windowState.width, windowState.height),
        );
        
        if (windowState.isMaximized) {
          await windowManager.maximize();
        } else if (windowState.isMinimized) {
          await windowManager.minimize();
        } else if (windowState.isFullScreen) {
          await windowManager.setFullScreen(true);
        }
        
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// 检查是否是首次启动
  bool isFirstLaunch() {
    final config = JsonStorageService.instance.getAppConfig();
    return config.firstLaunch;
  }

  /// 标记OOBE已完成
  Future<bool> markOOBECompleted() async {
    try {
      final storageService = JsonStorageService.instance;
      final currentConfig = storageService.getAppConfig();
      final updatedConfig = currentConfig.copyWith(
        firstLaunch: false,
      );
      await storageService.saveAppConfig(updatedConfig);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// 创建桌面快捷方式
  Future<SettingsResult> createDesktopShortcut() async {
    if (!Platform.isWindows) {
      return const SettingsResult.failure('仅支持Windows平台');
    }

    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final executablePath = Platform.resolvedExecutable;
      final appName = packageInfo.appName;
      
      // 获取桌面路径
      final result = await Process.run('powershell', [
        '-Command',
        '[Environment]::GetFolderPath("Desktop")'
      ]);
      
      if (result.exitCode != 0) {
        return const SettingsResult.failure('无法获取桌面路径');
      }
      
      final desktopPath = result.stdout.toString().trim();
      final shortcutPath = '$desktopPath\\$appName.lnk';
      
      // 创建快捷方式的PowerShell脚本
      final script = '''
\$WshShell = New-Object -comObject WScript.Shell
\$Shortcut = \$WshShell.CreateShortcut("$shortcutPath")
\$Shortcut.TargetPath = "$executablePath"
\$Shortcut.WorkingDirectory = "${executablePath.substring(0, executablePath.lastIndexOf('\\'))}"
\$Shortcut.Description = "$appName"
\$Shortcut.Save()
''';
      
      final createResult = await Process.run('powershell', [
        '-Command',
        script
      ]);
      
      if (createResult.exitCode == 0) {
        return const SettingsResult.success();
      } else {
        return SettingsResult.failure('创建快捷方式失败: ${createResult.stderr}');
      }
    } catch (e) {
      return SettingsResult.failure('创建桌面快捷方式时发生错误: $e');
    }
  }

  /// 创建开始菜单快捷方式
  Future<SettingsResult> createStartMenuShortcut() async {
    if (!Platform.isWindows) {
      return const SettingsResult.failure('仅支持Windows平台');
    }

    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final executablePath = Platform.resolvedExecutable;
      final appName = packageInfo.appName;
      
      // 获取开始菜单程序文件夹路径
      final result = await Process.run('powershell', [
        '-Command',
        '[Environment]::GetFolderPath("Programs")'
      ]);
      
      if (result.exitCode != 0) {
        return const SettingsResult.failure('无法获取开始菜单路径');
      }
      
      final programsPath = result.stdout.toString().trim();
      final shortcutPath = '$programsPath\\$appName.lnk';
      
      // 创建快捷方式的PowerShell脚本
      final script = '''
\$WshShell = New-Object -comObject WScript.Shell
\$Shortcut = \$WshShell.CreateShortcut("$shortcutPath")
\$Shortcut.TargetPath = "$executablePath"
\$Shortcut.WorkingDirectory = "${executablePath.substring(0, executablePath.lastIndexOf('\\'))}"
\$Shortcut.Description = "$appName"
\$Shortcut.Save()
''';
      
      final createResult = await Process.run('powershell', [
        '-Command',
        script
      ]);
      
      if (createResult.exitCode == 0) {
        return const SettingsResult.success();
      } else {
        return SettingsResult.failure('创建快捷方式失败: ${createResult.stderr}');
      }
    } catch (e) {
      return SettingsResult.failure('创建开始菜单快捷方式时发生错误: $e');
    }
  }

}