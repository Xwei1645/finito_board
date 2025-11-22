import 'dart:io';
import 'dart:async';
import 'package:path/path.dart' as p;
import 'package:intl/intl.dart';
import '../settings_service.dart';

/// 备份管理服务
class BackupService {
  static BackupService? _instance;
  static BackupService get instance => _instance ??= BackupService._();
  
  BackupService._();
  
  late String _dataDir;
  late String _backupDir;
  
  /// 初始化备份服务
  Future<void> init(String dataDir) async {
    _dataDir = dataDir;
    _backupDir = p.join(p.dirname(dataDir), 'backups');
    
    // 确保备份目录存在
    final backupDirEntity = Directory(_backupDir);
    if (!await backupDirEntity.exists()) {
      await backupDirEntity.create(recursive: true);
    }
  }
  
  /// 执行备份
  /// [isAuto] 是否为自动备份（用于区分手动备份和自动备份）
  Future<bool> performBackup({bool isAuto = false}) async {
    try {
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final backupType = isAuto ? 'auto' : 'manual';
      final backupName = '${backupType}_$timestamp';
      final backupPath = p.join(_backupDir, backupName);
      
      // 创建备份目录
      final backupDirEntity = Directory(backupPath);
      await backupDirEntity.create(recursive: true);
      
      // 备份所有数据文件
      final dataDir = Directory(_dataDir);
      if (await dataDir.exists()) {
        await for (final file in dataDir.list()) {
          if (file is File && file.path.endsWith('.json')) {
            final fileName = p.basename(file.path);
            final targetPath = p.join(backupPath, fileName);
            await file.copy(targetPath);
          }
        }
      }
      
      // 如果是自动备份，清理旧的自动备份
      if (isAuto) {
        await _cleanOldAutoBackups();
      }
      
      return true;
    } catch (e) {
      return false;
    }
  }
  
  /// 清理旧的自动备份
  Future<void> _cleanOldAutoBackups() async {
    try {
      final config = SettingsService.instance.getStorageConfig();
      
      // 如果未启用限制，则不清理备份
      if (!config.limitBackupCount) return;
      
      final maxCount = config.maxAutoBackupCount;
      
      // 获取所有自动备份
      final backupDir = Directory(_backupDir);
      if (!await backupDir.exists()) return;
      
      final autoBackups = <FileSystemEntity>[];
      await for (final entity in backupDir.list()) {
        if (entity is Directory) {
          final name = p.basename(entity.path);
          if (name.startsWith('auto_')) {
            autoBackups.add(entity);
          }
        }
      }
      
      // 按修改时间排序（最新的在前）
      autoBackups.sort((a, b) {
        final aStat = a.statSync();
        final bStat = b.statSync();
        return bStat.modified.compareTo(aStat.modified);
      });
      
      // 删除超出数量限制的备份
      if (autoBackups.length > maxCount) {
        for (int i = maxCount; i < autoBackups.length; i++) {
          await autoBackups[i].delete(recursive: true);
        }
      }
    } catch (e) {
      // 清理失败，静默处理
    }
  }
  
  /// 获取所有备份列表
  Future<List<BackupInfo>> getBackupList() async {
    final backups = <BackupInfo>[];
    
    try {
      final backupDir = Directory(_backupDir);
      if (!await backupDir.exists()) return backups;
      
      await for (final entity in backupDir.list()) {
        if (entity is Directory) {
          final name = p.basename(entity.path);
          final stat = await entity.stat();
          final isAuto = name.startsWith('auto_');
          
          backups.add(BackupInfo(
            name: name,
            path: entity.path,
            createdAt: stat.modified,
            isAuto: isAuto,
            size: await _getDirectorySize(entity),
          ));
        }
      }
      
      // 按创建时间倒序排序
      backups.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (e) {
      // 获取失败，返回空列表
    }
    
    return backups;
  }
  
  /// 计算目录大小
  Future<int> _getDirectorySize(Directory dir) async {
    int size = 0;
    try {
      await for (final file in dir.list(recursive: true)) {
        if (file is File) {
          size += await file.length();
        }
      }
    } catch (e) {
      // 计算失败
    }
    return size;
  }
  
  /// 删除备份
  Future<bool> deleteBackup(String backupPath) async {
    try {
      final dir = Directory(backupPath);
      if (await dir.exists()) {
        await dir.delete(recursive: true);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
  
  /// 恢复备份
  Future<bool> restoreBackup(String backupPath) async {
    try {
      final backupDir = Directory(backupPath);
      if (!await backupDir.exists()) return false;
      
      // 先备份当前数据（作为恢复前的保护）
      await performBackup(isAuto: false);
      
      // 清空当前数据目录
      final dataDir = Directory(_dataDir);
      if (await dataDir.exists()) {
        await for (final file in dataDir.list()) {
          if (file is File && file.path.endsWith('.json')) {
            await file.delete();
          }
        }
      }
      
      // 复制备份文件到数据目录
      await for (final file in backupDir.list()) {
        if (file is File && file.path.endsWith('.json')) {
          final fileName = p.basename(file.path);
          final targetPath = p.join(_dataDir, fileName);
          await file.copy(targetPath);
        }
      }
      
      return true;
    } catch (e) {
      return false;
    }
  }
  
  /// 打开备份目录
  Future<bool> openBackupDirectory() async {
    try {
      final backupDir = Directory(_backupDir);
      if (!await backupDir.exists()) {
        await backupDir.create(recursive: true);
      }
      
      if (Platform.isWindows) {
        await Process.run('explorer', [backupDir.path]);
      } else if (Platform.isMacOS) {
        await Process.run('open', [backupDir.path]);
      } else if (Platform.isLinux) {
        await Process.run('xdg-open', [backupDir.path]);
      }
      
      return true;
    } catch (e) {
      return false;
    }
  }
  
  /// 应用启动时的自动备份
  Future<void> backupOnStartup() async {
    final config = SettingsService.instance.getStorageConfig();
    if (config.autoBackupEnabled && config.backupOnStartup) {
      await performBackup(isAuto: true);
    }
  }
  
  /// 配置修改时的自动备份
  Future<void> backupOnConfigChange() async {
    final config = SettingsService.instance.getStorageConfig();
    if (config.autoBackupEnabled && config.backupOnConfigChange) {
      await performBackup(isAuto: true);
    }
  }
  
  /// 应用退出时的自动备份
  Future<void> backupOnExit() async {
    final config = SettingsService.instance.getStorageConfig();
    if (config.autoBackupEnabled && config.backupOnExit) {
      await performBackup(isAuto: true);
    }
  }
}

/// 备份信息
class BackupInfo {
  final String name;
  final String path;
  final DateTime createdAt;
  final bool isAuto;
  final int size;
  
  const BackupInfo({
    required this.name,
    required this.path,
    required this.createdAt,
    required this.isAuto,
    required this.size,
  });
  
  /// 格式化大小显示
  String get sizeFormatted {
    if (size < 1024) {
      return '$size B';
    } else if (size < 1024 * 1024) {
      return '${(size / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }
  
  /// 格式化时间显示
  String get timeFormatted {
    return DateFormat('yyyy-MM-dd HH:mm:ss').format(createdAt);
  }
}
