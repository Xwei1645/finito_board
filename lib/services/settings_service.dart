import 'dart:io';
import 'package:flutter/material.dart';
import 'package:launch_at_startup/launch_at_startup.dart';
import 'package:window_manager/window_manager.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:loggy/loggy.dart';
import '../models/app_config.dart';
import '../models/window_state.dart';
import '../models/storage_config.dart';
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
      logDebug('开机自启配置初始化成功');
    } catch (e) {
      logWarning('开机自启配置初始化失败', e);
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
      final enabled = await launchAtStartup.isEnabled();
      logDebug('开机自启状态: $enabled');
      return enabled;
    } catch (e) {
      logError('检查开机自启状态失败', e);
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
      logInfo('开机自启已${enabled ? "启用" : "禁用"}');
      return const SettingsResult.success();
    } catch (e) {
      final errorMessage = e.toString();
      logError('设置开机自启失败', e);
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
      logDebug('窗口层级已设置为: $level');
      return true;
    } catch (e) {
      logError('设置窗口层级失败', e);
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
      logDebug('任务栏显示已${enabled ? "启用" : "禁用"}');
      return true;
    } catch (e) {
      logError('设置任务栏显示失败', e);
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
        themeColor: currentConfig.themeColor,
      );
      await storageService.saveAppConfig(updatedConfig);
      logDebug('主题模式已设置为: ${enabled ? "深色" : "浅色"}');
      return true;
    } catch (e) {
      logError('设置主题模式失败', e);
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
      logDebug('背景不透明度已设置为: ${(clampedOpacity * 100).toStringAsFixed(0)}%');
      return true;
    } catch (e) {
      logError('设置背景不透明度失败', e);
      return false;
    }
  }

  /// 获取主题色
  int? getThemeColor() {
    final config = JsonStorageService.instance.getAppConfig();
    return config.themeColor;
  }

  /// 设置主题色
  Future<bool> setThemeColor(int? colorValue) async {
    try {
      // 更新JSON配置
      final storageService = JsonStorageService.instance;
      final currentConfig = storageService.getAppConfig();
      final updatedConfig = currentConfig.copyWith(
        themeColor: colorValue,
      );
      await storageService.saveAppConfig(updatedConfig);
      logDebug('主题色已设置: ${colorValue != null ? "#${colorValue.toRadixString(16)}" : "默认"}');
      return true;
    } catch (e) {
      logError('设置主题色失败', e);
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
      logDebug('窗口状态已保存: $width x $height at ($x, $y)');
      return true;
    } catch (e) {
      logError('保存窗口状态失败', e);
      return false;
    }
  }

  /// 获取窗口状态
  WindowState? getWindowState() {
    try {
      return JsonStorageService.instance.getWindowState();
    } catch (e) {
      logError('获取窗口状态失败', e);
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
        
        logInfo('窗口状态已恢复');
        return true;
      }
      return false;
    } catch (e) {
      logError('恢复窗口状态失败', e);
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
      logInfo('OOBE已完成标记');
      return true;
    } catch (e) {
      logError('标记OOBE完成失败', e);
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
        logInfo('桌面快捷方式创建成功');
        return const SettingsResult.success();
      } else {
        logError('创建桌面快捷方式失败', createResult.stderr);
        return SettingsResult.failure('创建快捷方式失败: ${createResult.stderr}');
      }
    } catch (e) {
      logError('创建桌面快捷方式异常', e);
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
        logInfo('开始菜单快捷方式创建成功');
        return const SettingsResult.success();
      } else {
        logError('创建开始菜单快捷方式失败', createResult.stderr);
        return SettingsResult.failure('创建快捷方式失败: ${createResult.stderr}');
      }
    } catch (e) {
      logError('创建开始菜单快捷方式异常', e);
      return SettingsResult.failure('创建开始菜单快捷方式时发生错误: $e');
    }
  }

  /// 获取背景图片路径
  String? getBackgroundImagePath() {
    final config = JsonStorageService.instance.getAppConfig();
    return config.backgroundImagePath;
  }

  /// 设置背景图片路径
  Future<bool> setBackgroundImagePath(String? path) async {
    try {
      // 更新JSON配置
      final storageService = JsonStorageService.instance;
      final currentConfig = storageService.getAppConfig();
      final updatedConfig = currentConfig.copyWith(
        backgroundImagePath: path,
      );
      await storageService.saveAppConfig(updatedConfig);
      logDebug('背景图片路径已设置: ${path ?? "无"}');
      return true;
    } catch (e) {
      logError('设置背景图片路径失败', e);
      return false;
    }
  }

  /// 获取背景图片显示模式
  int getBackgroundImageMode() {
    final config = JsonStorageService.instance.getAppConfig();
    return config.backgroundImageMode;
  }

  /// 设置背景图片显示模式: 0=适应, 1=填充, 2=拉伸
  Future<bool> setBackgroundImageMode(int mode) async {
    try {
      // 更新JSON配置
      final storageService = JsonStorageService.instance;
      final currentConfig = storageService.getAppConfig();
      final updatedConfig = currentConfig.copyWith(
        backgroundImageMode: mode,
      );
      await storageService.saveAppConfig(updatedConfig);
      logDebug('背景图片显示模式已设置为: $mode');
      return true;
    } catch (e) {
      logError('设置背景图片显示模式失败', e);
      return false;
    }
  }

  /// 获取背景图片混合比例
  double getBackgroundImageOpacity() {
    final config = JsonStorageService.instance.getAppConfig();
    return config.backgroundImageOpacity;
  }

  /// 设置背景图片混合比例: 0.0-1.0
  Future<bool> setBackgroundImageOpacity(double opacity) async {
    try {
      // 更新JSON配置
      final storageService = JsonStorageService.instance;
      final currentConfig = storageService.getAppConfig();
      final updatedConfig = currentConfig.copyWith(
        backgroundImageOpacity: opacity,
      );
      await storageService.saveAppConfig(updatedConfig);
      logDebug('背景图片不透明度已设置为: ${(opacity * 100).toStringAsFixed(0)}%');
      return true;
    } catch (e) {
      logError('设置背景图片不透明度失败', e);
      return false;
    }
  }

  // ==================== 存储配置管理 ====================

  /// 获取存储配置
  StorageConfig getStorageConfig() {
    return JsonStorageService.instance.getStorageConfig();
  }

  /// 保存存储配置
  Future<bool> saveStorageConfig(StorageConfig config) async {
    try {
      await JsonStorageService.instance.saveStorageConfig(config);
      logDebug('存储配置已保存');
      return true;
    } catch (e) {
      logError('保存存储配置失败', e);
      return false;
    }
  }

}