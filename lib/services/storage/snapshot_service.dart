import 'dart:io';
import 'dart:async';
import 'package:path/path.dart' as p;
import 'package:intl/intl.dart';
import 'package:loggy/loggy.dart';
import '../settings_service.dart';

/// 快照管理服务
/// 用于保存作业内容的历史版本
class SnapshotService {
  static SnapshotService? _instance;
  static SnapshotService get instance => _instance ??= SnapshotService._();

  SnapshotService._();

  late String _dataDir;
  late String _snapshotDir;

  /// 初始化快照服务
  Future<void> init(String dataDir) async {
    logInfo('Initializing snapshot service with data dir: $dataDir');
    _dataDir = dataDir;
    _snapshotDir = p.join(p.dirname(dataDir), 'snapshots');

    // 确保快照目录存在
    final snapshotDirEntity = Directory(_snapshotDir);
    if (!await snapshotDirEntity.exists()) {
      logDebug('Creating snapshot directory: $_snapshotDir');
      await snapshotDirEntity.create(recursive: true);
    }
    logInfo('Snapshot service initialized successfully');
  }

  /// 创建快照
  /// [isAuto] 是否为自动快照（用于区分手动快照和自动快照）
  /// [trigger] 触发方式：'edit', 'startup', 'exit', 'manual'
  Future<bool> createSnapshot({
    bool isAuto = false,
    String trigger = 'manual',
  }) async {
    try {
      logInfo(
        'Creating snapshot: type=${isAuto ? 'auto' : 'manual'}, trigger=$trigger',
      );
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final snapshotType = isAuto ? 'auto' : 'manual';
      final snapshotName = '${snapshotType}_${trigger}_$timestamp';
      final snapshotPath = p.join(_snapshotDir, snapshotName);

      // 创建快照目录
      final snapshotDirEntity = Directory(snapshotPath);
      await snapshotDirEntity.create(recursive: true);
      logDebug('Snapshot directory created: $snapshotPath');

      // 只备份作业数据文件
      final homeworkFile = File(p.join(_dataDir, 'homework.json'));
      if (await homeworkFile.exists()) {
        final targetPath = p.join(snapshotPath, 'homework.json');
        await homeworkFile.copy(targetPath);
        logDebug('Homework file copied to snapshot');
      } else {
        // 如果没有作业文件，删除刚创建的空目录
        logDebug('No homework file found, deleting empty snapshot directory');
        await snapshotDirEntity.delete();
        return false;
      }

      // 如果是自动快照，清理旧的快照
      if (isAuto) {
        logDebug('Cleaning old snapshots');
        await _cleanOldSnapshots();
      }

      logInfo('Snapshot created successfully: $snapshotName');
      return true;
    } catch (e) {
      logError('Failed to create snapshot', e);
      return false;
    }
  }

  /// 清理旧的快照
  Future<void> _cleanOldSnapshots() async {
    try {
      final config = SettingsService.instance.getStorageConfig();

      // 如果未启用限制，则不清理快照
      if (!config.limitSnapshotCount) {
        logDebug('Snapshot count limit not enabled, skipping cleanup');
        return;
      }

      final maxCount = config.maxSnapshotCount;
      logDebug('Cleaning old snapshots with max count: $maxCount');

      // 获取所有快照
      final snapshotDir = Directory(_snapshotDir);
      if (!await snapshotDir.exists()) return;

      final snapshots = <FileSystemEntity>[];
      await for (final entity in snapshotDir.list()) {
        if (entity is Directory) {
          snapshots.add(entity);
        }
      }

      // 按修改时间排序（最新的在前）
      snapshots.sort((a, b) {
        final aStat = a.statSync();
        final bStat = b.statSync();
        return bStat.modified.compareTo(aStat.modified);
      });

      // 删除超出数量限制的快照
      if (snapshots.length > maxCount) {
        logDebug('Deleting ${snapshots.length - maxCount} old snapshots');
        for (int i = maxCount; i < snapshots.length; i++) {
          await snapshots[i].delete(recursive: true);
        }
        logDebug('Old snapshots cleaned successfully');
      } else {
        logDebug('No snapshots to clean (${snapshots.length} <= $maxCount)');
      }
    } catch (e) {
      // 清理失败，静默处理
      logError('Failed to clean old snapshots', e);
    }
  }

  /// 获取所有快照列表
  Future<List<SnapshotInfo>> getSnapshotList() async {
    final snapshots = <SnapshotInfo>[];

    try {
      logDebug('Getting snapshot list from: $_snapshotDir');
      final snapshotDir = Directory(_snapshotDir);
      if (!await snapshotDir.exists()) {
        logDebug('Snapshot directory does not exist');
        return snapshots;
      }

      await for (final entity in snapshotDir.list()) {
        if (entity is Directory) {
          final name = p.basename(entity.path);
          final stat = await entity.stat();
          final isAuto = name.startsWith('auto_');

          // 解析触发方式
          String trigger = 'unknown';
          if (name.contains('_edit_')) {
            trigger = 'edit';
          } else if (name.contains('_startup_')) {
            trigger = 'startup';
          } else if (name.contains('_exit_')) {
            trigger = 'exit';
          } else if (name.contains('_manual_')) {
            trigger = 'manual';
          }

          snapshots.add(
            SnapshotInfo(
              name: name,
              path: entity.path,
              createdAt: stat.modified,
              isAuto: isAuto,
              trigger: trigger,
              size: await _getDirectorySize(entity),
            ),
          );
        }
      }

      // 按创建时间倒序排序
      snapshots.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      logDebug('Found ${snapshots.length} snapshots');
    } catch (e) {
      // 获取失败，返回空列表
      logError('Failed to get snapshot list', e);
    }

    return snapshots;
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
      logDebug('Directory size calculated: $size bytes for ${dir.path}');
    } catch (e) {
      // 计算失败
      logError('Failed to calculate directory size for ${dir.path}', e);
    }
    return size;
  }

  /// 删除快照
  Future<bool> deleteSnapshot(String snapshotPath) async {
    try {
      logInfo('Deleting snapshot: $snapshotPath');
      final dir = Directory(snapshotPath);
      if (await dir.exists()) {
        await dir.delete(recursive: true);
        logInfo('Snapshot deleted successfully');
        return true;
      }
      logDebug('Snapshot directory does not exist: $snapshotPath');
      return false;
    } catch (e) {
      logError('Failed to delete snapshot: $snapshotPath', e);
      return false;
    }
  }

  /// 恢复快照
  Future<bool> restoreSnapshot(String snapshotPath) async {
    try {
      logInfo('Restoring snapshot: $snapshotPath');
      final snapshotDir = Directory(snapshotPath);
      if (!await snapshotDir.exists()) {
        logDebug('Snapshot directory does not exist: $snapshotPath');
        return false;
      }

      // 先创建当前状态的快照（作为恢复前的保护）
      logDebug('Creating backup before restore');
      await createSnapshot(isAuto: false, trigger: 'before_restore');

      // 恢复作业文件
      final homeworkFile = File(p.join(snapshotPath, 'homework.json'));
      if (await homeworkFile.exists()) {
        final targetPath = p.join(_dataDir, 'homework.json');
        await homeworkFile.copy(targetPath);
        logInfo('Snapshot restored successfully');
        return true;
      }

      logDebug('No homework file found in snapshot');
      return false;
    } catch (e) {
      logError('Failed to restore snapshot: $snapshotPath', e);
      return false;
    }
  }

  /// 打开快照目录
  Future<bool> openSnapshotDirectory() async {
    try {
      logInfo('Opening snapshot directory: $_snapshotDir');
      final snapshotDir = Directory(_snapshotDir);
      if (!await snapshotDir.exists()) {
        logDebug('Creating snapshot directory before opening');
        await snapshotDir.create(recursive: true);
      }

      if (Platform.isWindows) {
        await Process.run('explorer', [snapshotDir.path]);
      } else if (Platform.isMacOS) {
        await Process.run('open', [snapshotDir.path]);
      } else if (Platform.isLinux) {
        await Process.run('xdg-open', [snapshotDir.path]);
      }

      logInfo('Snapshot directory opened successfully');
      return true;
    } catch (e) {
      logError('Failed to open snapshot directory', e);
      return false;
    }
  }

  /// 编辑后自动快照
  Future<void> snapshotOnEdit() async {
    final config = SettingsService.instance.getStorageConfig();
    if (config.snapshotEnabled && config.snapshotOnEdit) {
      logDebug('Triggering snapshot on edit');
      await createSnapshot(isAuto: true, trigger: 'edit');
    }
  }

  /// 应用启动时的自动快照
  Future<void> snapshotOnStartup() async {
    final config = SettingsService.instance.getStorageConfig();
    if (config.snapshotEnabled && config.snapshotOnStartup) {
      logDebug('Triggering snapshot on startup');
      await createSnapshot(isAuto: true, trigger: 'startup');
    }
  }

  /// 应用退出时的自动快照
  Future<void> snapshotOnExit() async {
    final config = SettingsService.instance.getStorageConfig();
    if (config.snapshotEnabled && config.snapshotOnExit) {
      logDebug('Triggering snapshot on exit');
      await createSnapshot(isAuto: true, trigger: 'exit');
    }
  }
}

/// 快照信息
class SnapshotInfo {
  final String name;
  final String path;
  final DateTime createdAt;
  final bool isAuto;
  final String
  trigger; // 'edit', 'startup', 'exit', 'manual', 'before_restore', 'unknown'
  final int size;

  const SnapshotInfo({
    required this.name,
    required this.path,
    required this.createdAt,
    required this.isAuto,
    required this.trigger,
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

  /// 获取触发方式的中文描述
  String get triggerDescription {
    switch (trigger) {
      case 'edit':
        return '编辑后';
      case 'startup':
        return '启动时';
      case 'exit':
        return '退出时';
      case 'manual':
        return '手动创建';
      case 'before_restore':
        return '恢复前';
      default:
        return '未知';
    }
  }

  /// 获取快照类型的中文描述
  String get typeDescription {
    return isAuto ? '自动快照' : '手动快照';
  }
}
