import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:launch_at_startup/launch_at_startup.dart';
import 'package:window_manager/window_manager.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../models/app_config.dart';
import '../models/window_state.dart';
import 'storage/hive_storage_service.dart';


/// 设置操作结果
class SettingsResult {
  final bool success;
  final String? error;
  
  const SettingsResult.success() : success = true, error = null;
  const SettingsResult.failure(this.error) : success = false;
}

class SettingsService {
  static const String _autoStartKey = 'auto_start_enabled';
  static const String _alwaysOnBottomKey = 'always_on_bottom_enabled';
  static const String _darkModeKey = 'dark_mode_enabled';
  static const String _backgroundOpacityKey = 'background_opacity';
  
  static SettingsService? _instance;
  static SettingsService get instance => _instance ??= SettingsService._();
  
  SettingsService._();
  
  SharedPreferences? _prefs;
  
  /// 初始化设置服务
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    
    // 迁移SharedPreferences数据到Hive
    await _migrateToHive();
    
    // 初始化开机自启设置
    await _initializeLaunchAtStartup();
    
    // 应用已保存的设置
    await _applySettings();
  }

  /// 迁移SharedPreferences数据到Hive
  Future<void> _migrateToHive() async {
    try {
      final storageService = HiveStorageService.instance;
      
      // 获取当前配置
      AppConfig currentConfig = storageService.getAppConfig();
      
      // 如果配置为默认值，尝试从SharedPreferences迁移
      if (currentConfig.theme == 'system' && 
          currentConfig.language == 'zh_CN' && 
          !currentConfig.autoStartup && 
          currentConfig.enableNotifications) {
        
        // 迁移设置数据
        final darkMode = _prefs?.getBool(_darkModeKey) ?? false;
        final autoStart = _prefs?.getBool(_autoStartKey) ?? false;
        
        final migratedConfig = AppConfig(
          theme: darkMode ? 'dark' : 'light',
          language: 'zh_CN',
          autoStartup: autoStart,
          enableNotifications: true,
          availableSubjects: [
            '数学', '语文', '英语', '物理', '化学', '生物', '历史', '地理', '政治'
          ],
          availableTags: [
            '重要', '紧急', '复习', '预习', '作业', '考试', '项目', '课外'
          ],
        );
        
        await storageService.saveAppConfig(migratedConfig);
      }
    } catch (e) {
      // 迁移失败，使用默认配置
    }
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
    // 应用始终置底设置
    final alwaysOnBottom = getAlwaysOnBottom();
    if (alwaysOnBottom) {
      await setAlwaysOnBottom(true);
    }
  }
  
  /// 获取开机自启状态
  bool getAutoStart() {
    try {
      final config = HiveStorageService.instance.getAppConfig();
      return config.autoStartup;
    } catch (e) {
      return _prefs?.getBool(_autoStartKey) ?? false;
    }
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
      
      // 更新Hive配置
      final storageService = HiveStorageService.instance;
      final currentConfig = storageService.getAppConfig();
      final updatedConfig = AppConfig(
        theme: currentConfig.theme,
        language: currentConfig.language,
        autoStartup: enabled,
        enableNotifications: currentConfig.enableNotifications,
        availableSubjects: currentConfig.availableSubjects,
        availableTags: currentConfig.availableTags,
      );
      await storageService.saveAppConfig(updatedConfig);
      
      // 保持SharedPreferences兼容性
      await _prefs?.setBool(_autoStartKey, enabled);
      return const SettingsResult.success();
    } catch (e) {
      final errorMessage = e.toString();
      return SettingsResult.failure(errorMessage);
    }
  }
  
  /// 获取始终置底状态
  bool getAlwaysOnBottom() {
    return _prefs?.getBool(_alwaysOnBottomKey) ?? false;
  }
  
  /// 设置始终置底
  Future<bool> setAlwaysOnBottom(bool enabled) async {
    try {
      if (enabled) {
        await windowManager.setAlwaysOnBottom(true);
      } else {
        await windowManager.setAlwaysOnBottom(false);
      }
      
      await _prefs?.setBool(_alwaysOnBottomKey, enabled);
      return true;
    } catch (e) {
      return false;
    }
  }
  
  /// 检查开机自启是否可用（仅桌面端支持）
  bool get isAutoStartSupported {
    return Platform.isWindows || Platform.isMacOS || Platform.isLinux;
  }
  
  /// 检查始终置底是否可用（仅桌面端支持）
  bool get isAlwaysOnBottomSupported {
    return Platform.isWindows || Platform.isMacOS || Platform.isLinux;
  }
  
  /// 获取明暗模式状态
  bool getDarkMode() {
    try {
      final config = HiveStorageService.instance.getAppConfig();
      return config.theme == 'dark';
    } catch (e) {
      return _prefs?.getBool(_darkModeKey) ?? false;
    }
  }
  
  /// 设置明暗模式
  Future<bool> setDarkMode(bool enabled) async {
    try {
      // 更新Hive配置
      final storageService = HiveStorageService.instance;
      final currentConfig = storageService.getAppConfig();
      final updatedConfig = AppConfig(
        theme: enabled ? 'dark' : 'light',
        language: currentConfig.language,
        autoStartup: currentConfig.autoStartup,
        enableNotifications: currentConfig.enableNotifications,
        availableSubjects: currentConfig.availableSubjects,
        availableTags: currentConfig.availableTags,
      );
      await storageService.saveAppConfig(updatedConfig);
      
      // 保持SharedPreferences兼容性
      await _prefs?.setBool(_darkModeKey, enabled);
      return true;
    } catch (e) {
      return false;
    }
  }
  
  /// 获取背景不透明度 (0.0 - 1.0)
  double getBackgroundOpacity() {
    return _prefs?.getDouble(_backgroundOpacityKey) ?? 0.95;
  }
  
  /// 设置背景不透明度
  Future<bool> setBackgroundOpacity(double opacity) async {
    try {
      // 确保值在有效范围内
      final clampedOpacity = opacity.clamp(0.0, 1.0);
      await _prefs?.setDouble(_backgroundOpacityKey, clampedOpacity);
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
      
      await HiveStorageService.instance.saveWindowState(windowState);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// 获取窗口状态
  WindowState? getWindowState() {
    try {
      return HiveStorageService.instance.getWindowState();
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

}