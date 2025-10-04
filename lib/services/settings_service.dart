import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:launch_at_startup/launch_at_startup.dart';
import 'package:window_manager/window_manager.dart';
import 'package:package_info_plus/package_info_plus.dart';


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
  
  static SettingsService? _instance;
  static SettingsService get instance => _instance ??= SettingsService._();
  
  SettingsService._();
  
  SharedPreferences? _prefs;
  
  /// 初始化设置服务
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    
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
    // 应用始终置底设置
    final alwaysOnBottom = getAlwaysOnBottom();
    if (alwaysOnBottom) {
      await setAlwaysOnBottom(true);
    }
  }
  
  /// 获取开机自启状态
  bool getAutoStart() {
    return _prefs?.getBool(_autoStartKey) ?? false;
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
}