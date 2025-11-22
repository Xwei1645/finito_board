import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'package:path/path.dart' as p;
import '../../models/homework.dart';
import '../../models/subject.dart';
import '../../models/app_config.dart';
import '../../models/window_state.dart';
import '../../models/tag.dart';
import '../../models/storage_config.dart';

class JsonStorageService {
  static const String _homeworkFileName = 'homework.json';
  static const String _subjectFileName = 'subject.json';
  static const String _configFileName = 'config.json';
  static const String _windowStateFileName = 'window_state.json';
  static const String _tagFileName = 'tag.json';

  late String _dataDir;
  
  // 内存缓存
  final Map<String, Homework> _homeworkCache = {};
  final Map<String, Subject> _subjectCache = {};
  AppConfig? _configCache;
  WindowState? _windowStateCache;
  final Map<String, Tag> _tagCache = {};
  
  // 防抖定时器
  Timer? _windowStateDebounceTimer;
  
  // 脏标记
  bool _homeworkDirty = false;
  bool _subjectDirty = false;
  bool _configDirty = false;
  bool _windowStateDirty = false;
  bool _tagDirty = false;
  
  // 写入队列定时器
  Timer? _flushTimer;
  static const Duration _flushInterval = Duration(seconds: 2);
  
  // 窗口状态防抖延迟
  static const Duration _windowStateDebounceDelay = Duration(milliseconds: 500);

  static JsonStorageService? _instance;
  static JsonStorageService get instance => _instance ??= JsonStorageService._();

  JsonStorageService._();

  /// 初始化JSON存储服务
  Future<void> init() async {
    try {
      final appDir = p.dirname(Platform.resolvedExecutable);
      _dataDir = p.join(appDir, 'data');
      
      // 确保data目录存在
      final dataDirEntity = Directory(_dataDir);
      if (!await dataDirEntity.exists()) {
        await dataDirEntity.create(recursive: true);
      }
      
      // 加载所有数据到缓存
      await _loadAllData();
    } catch (e) {
      rethrow;
    }
  }

  /// 加载所有数据到内存缓存
  Future<void> _loadAllData() async {
    await _loadHomeworkData();
    await _loadSubjectData();
    await _loadConfigData();
    await _loadWindowStateData();
    await _loadTagData();
  }

  /// 通用的JSON文件读取方法
  Future<Map<String, dynamic>?> _readJsonFile(String fileName) async {
    try {
      final file = File(p.join(_dataDir, fileName));
      
      // 检查文件是否存在
      if (!await file.exists()) {
        return null;
      }
      
      // 读取文件内容
      final content = await file.readAsString();
      
      // 检查内容是否为空
      if (content.trim().isEmpty) {
        return null;
      }
      
      // 尝试解析JSON
      try {
        final decoded = json.decode(content);
        if (decoded is! Map<String, dynamic>) {
          return null;
        }
        return decoded;
      } on FormatException {
        // 尝试备份损坏的文件
        try {
          final bakFile = File(p.join(_dataDir, '$fileName.corrupted'));
          await file.copy(bakFile.path);
        } catch (_) {
          // 备份失败不影响主流程
        }
        return null;
      }
    } catch (e) {
      // 处理其他读取错误（如权限问题）
      return null;
    }
  }

  /// 通用的JSON文件写入方法
  Future<void> _writeJsonFile(String fileName, Map<String, dynamic> data, {int retries = 3}) async {
    for (int i = 0; i < retries; i++) {
      try {
        final file = File(p.join(_dataDir, fileName));
        final bakFile = File(p.join(_dataDir, '$fileName.bak'));
        
        // 如果目标文件存在，先创建.bak备份
        if (await file.exists()) {
          try {
            await file.copy(bakFile.path);
          } catch (e) {
            // 备份失败不影响主流程
          }
        }
        
        // 尝试编码为JSON字符串
        String jsonString;
        try {
          jsonString = json.encode(data);
        } catch (e) {
          rethrow;
        }
        
        // 写入文件
        await file.writeAsString(jsonString);
        return; // 写入成功
      } catch (e) {
        if (i == retries - 1) {
          // 最后一次重试失败，尝试恢复备份
          try {
            final file = File(p.join(_dataDir, fileName));
            final bakFile = File(p.join(_dataDir, '$fileName.bak'));
            if (await bakFile.exists()) {
              await bakFile.copy(file.path);
            }
          } catch (restoreError) {
            // 恢复失败
          }
          rethrow;
        }
        // 等待后重试
        await Future.delayed(Duration(milliseconds: 100 * (i + 1)));
      }
    }
  }

  /// 加载作业数据
  Future<void> _loadHomeworkData() async {
    try {
      final data = await _readJsonFile(_homeworkFileName);
      _homeworkCache.clear();
      if (data != null && data['homework'] is List) {
        final homeworkList = data['homework'] as List;
        for (final item in homeworkList) {
          try {
            if (item is Map<String, dynamic>) {
              final homework = Homework.fromJson(item);
              _homeworkCache[homework.uuid] = homework;
            }
          } catch (e) {
            // 跳过无效项
          }
        }
      }
    } catch (e) {
      _homeworkCache.clear();
    }
  }

  /// 保存作业数据
  Future<void> _saveHomeworkData({bool immediate = false}) async {
    _homeworkDirty = true;
    if (immediate) {
      await _flushHomeworkData();
    } else {
      _scheduleFlush();
    }
  }
  
  /// 立即写入作业数据
  Future<void> _flushHomeworkData() async {
    if (!_homeworkDirty) return;
    final data = {
      'homework': _homeworkCache.values.map((h) => h.toJson()).toList(),
    };
    await _writeJsonFile(_homeworkFileName, data);
    _homeworkDirty = false;
  }

  /// 加载科目数据
  Future<void> _loadSubjectData() async {
    try {
      final data = await _readJsonFile(_subjectFileName);
      _subjectCache.clear();
      if (data != null && data['subjects'] is List) {
        final subjectList = data['subjects'] as List;
        for (final item in subjectList) {
          try {
            if (item is Map<String, dynamic>) {
              final subject = Subject.fromJson(item);
              _subjectCache[subject.uuid] = subject;
            }
          } catch (e) {
            // 跳过无效项
          }
        }
      }
    } catch (e) {
      _subjectCache.clear();
    }
  }

  /// 保存科目数据
  Future<void> _saveSubjectData({bool immediate = false}) async {
    _subjectDirty = true;
    if (immediate) {
      await _flushSubjectData();
    } else {
      _scheduleFlush();
    }
  }
  
  /// 立即写入科目数据
  Future<void> _flushSubjectData() async {
    if (!_subjectDirty) return;
    final data = {
      'subjects': _subjectCache.values.map((s) => s.toJson()).toList(),
    };
    await _writeJsonFile(_subjectFileName, data);
    _subjectDirty = false;
  }

  /// 加载配置数据
  Future<void> _loadConfigData() async {
    try {
      final data = await _readJsonFile(_configFileName);
      if (data != null && data['config'] != null) {
        try {
          if (data['config'] is Map<String, dynamic>) {
            _configCache = AppConfig.fromJson(data['config']);
          } else {
            _configCache = const AppConfig();
          }
        } catch (e) {
          _configCache = const AppConfig();
        }
      } else {
        _configCache = const AppConfig();
      }
    } catch (e) {
      _configCache = const AppConfig();
    }
  }

  /// 保存配置数据
  Future<void> _saveConfigData({bool immediate = false}) async {
    _configDirty = true;
    if (immediate) {
      await _flushConfigData();
    } else {
      _scheduleFlush();
    }
  }
  
  /// 立即写入配置数据
  Future<void> _flushConfigData() async {
    if (!_configDirty) return;
    final data = {
      'config': _configCache?.toJson() ?? const AppConfig().toJson(),
    };
    await _writeJsonFile(_configFileName, data);
    _configDirty = false;
  }

  /// 加载窗口状态数据
  Future<void> _loadWindowStateData() async {
    try {
      final data = await _readJsonFile(_windowStateFileName);
      if (data != null && data['windowState'] != null) {
        try {
          if (data['windowState'] is Map<String, dynamic>) {
            _windowStateCache = WindowState.fromJson(data['windowState']);
          } else {
            _windowStateCache = const WindowState();
          }
        } catch (e) {
          _windowStateCache = const WindowState();
        }
      } else {
        _windowStateCache = const WindowState();
      }
    } catch (e) {
      _windowStateCache = const WindowState();
    }
  }

  /// 保存窗口状态数据（带防抖）
  Future<void> _saveWindowStateData({bool immediate = false}) async {
    _windowStateDirty = true;
    
    if (immediate) {
      _windowStateDebounceTimer?.cancel();
      await _flushWindowStateData();
    } else {
      // 使用防抖，避免频繁写入
      _windowStateDebounceTimer?.cancel();
      _windowStateDebounceTimer = Timer(_windowStateDebounceDelay, () {
        _flushWindowStateData();
      });
    }
  }
  
  /// 立即写入窗口状态数据
  Future<void> _flushWindowStateData() async {
    if (!_windowStateDirty) return;
    final data = {
      'windowState': _windowStateCache?.toJson() ?? const WindowState().toJson(),
    };
    await _writeJsonFile(_windowStateFileName, data);
    _windowStateDirty = false;
  }

  /// 加载标签数据
  Future<void> _loadTagData() async {
    try {
      final data = await _readJsonFile(_tagFileName);
      _tagCache.clear();
      if (data != null && data['tags'] is List) {
        final tagList = data['tags'] as List;
        for (final item in tagList) {
          try {
            if (item is Map<String, dynamic>) {
              final tag = Tag.fromJson(item);
              _tagCache[tag.uuid] = tag;
            }
          } catch (e) {
            // 跳过无效项
          }
        }
      }
    } catch (e) {
      _tagCache.clear();
    }
  }

  /// 保存标签数据
  Future<void> _saveTagData({bool immediate = false}) async {
    _tagDirty = true;
    if (immediate) {
      await _flushTagData();
    } else {
      _scheduleFlush();
    }
  }
  
  /// 立即写入标签数据
  Future<void> _flushTagData() async {
    if (!_tagDirty) return;
    final data = {
      'tags': _tagCache.values.map((t) => t.toJson()).toList(),
    };
    await _writeJsonFile(_tagFileName, data);
    _tagDirty = false;
  }

  /// 调度批量写入
  void _scheduleFlush() {
    _flushTimer?.cancel();
    _flushTimer = Timer(_flushInterval, () {
      _flushAll();
    });
  }
  
  /// 批量写入所有脏数据
  Future<void> _flushAll() async {
    final futures = <Future>[];
    
    if (_homeworkDirty) {
      futures.add(_flushHomeworkData());
    }
    if (_subjectDirty) {
      futures.add(_flushSubjectData());
    }
    if (_configDirty) {
      futures.add(_flushConfigData());
    }
    if (_windowStateDirty) {
      futures.add(_flushWindowStateData());
    }
    if (_tagDirty) {
      futures.add(_flushTagData());
    }
    
    if (futures.isNotEmpty) {
      await Future.wait(futures);
    }
  }
  
  /// 手动触发所有待写入数据的立即写入
  Future<void> flush() async {
    _flushTimer?.cancel();
    _windowStateDebounceTimer?.cancel();
    await _flushAll();
  }
  
  /// 清理资源
  void dispose() {
    _flushTimer?.cancel();
    _windowStateDebounceTimer?.cancel();
  }

  // ==================== 作业数据管理 ====================
  
  /// 获取所有作业
  List<Homework> getAllHomework() {
    return _homeworkCache.values.toList();
  }

  /// 根据UUID获取作业
  Homework? getHomeworkByUuid(String uuid) {
    return _homeworkCache[uuid];
  }

  /// 保存作业
  Future<void> saveHomework(Homework homework) async {
    _homeworkCache[homework.uuid] = homework;
    await _saveHomeworkData(immediate: true);
  }

  /// 删除作业
  Future<void> deleteHomework(String uuid) async {
    _homeworkCache.remove(uuid);
    await _saveHomeworkData(immediate: true);
  }



  /// 根据科目UUID获取作业
  List<Homework> getHomeworkBySubjectUuid(String subjectUuid) {
    return _homeworkCache.values
        .where((homework) => homework.subjectUuid == subjectUuid)
        .toList();
  }

  /// 获取过期作业
  List<Homework> getOverdueHomework() {
    final now = DateTime.now();
    return _homeworkCache.values
        .where((homework) => homework.dueDate.isBefore(now))
        .toList();
  }



  /// 根据标签UUID获取作业
  List<Homework> getHomeworkByTagUuid(String tagUuid) {
    return _homeworkCache.values
        .where((homework) => homework.tagUuids.contains(tagUuid))
        .toList();
  }

  /// 获取今日到期的作业
  List<Homework> getTodayDueHomework() {
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    final todayEnd = todayStart.add(const Duration(days: 1));
    
    return _homeworkCache.values
        .where((homework) => 
            homework.dueDate.isAfter(todayStart) && 
            homework.dueDate.isBefore(todayEnd))
        .toList();
  }

  // ==================== 科目数据管理 ====================
  
  /// 获取所有科目
  List<Subject> getAllSubjects() {
    return _subjectCache.values.toList();
  }

  /// 保存科目
  Future<void> saveSubject(Subject subject) async {
    _subjectCache[subject.uuid] = subject;
    await _saveSubjectData(immediate: true);
  }

  /// 删除科目
  Future<void> deleteSubject(String uuid) async {
    _subjectCache.remove(uuid);
    await _saveSubjectData(immediate: true);
  }

  /// 根据UUID获取科目
  Subject? getSubjectByUuid(String uuid) {
    return _subjectCache[uuid];
  }

  /// 根据名称获取科目
  Subject? getSubjectByName(String name) {
    try {
      return _subjectCache.values.firstWhere(
        (subject) => subject.name == name,
      );
    } catch (e) {
      return null;
    }
  }





  // ==================== 配置数据管理 ====================
  
  /// 获取应用配置
  AppConfig getAppConfig() {
    return _configCache ?? const AppConfig();
  }

  /// 保存应用配置
  Future<void> saveAppConfig(AppConfig config) async {
    _configCache = config;
    await _saveConfigData(immediate: false);
  }



  /// 保存界面缩放因子
  Future<void> saveScaleFactor(double scaleFactor) async {
    final currentConfig = getAppConfig();
    final updatedConfig = currentConfig.copyWith(scaleFactor: scaleFactor);
    await saveAppConfig(updatedConfig);
  }

  /// 保存作业列数
  Future<void> saveColumnCount(int columnCount) async {
    final currentConfig = getAppConfig();
    final updatedConfig = currentConfig.copyWith(columnCount: columnCount);
    await saveAppConfig(updatedConfig);
  }

  // ==================== 窗口状态管理 ====================
  
  /// 获取窗口状态
  WindowState getWindowState() {
    return _windowStateCache ?? const WindowState();
  }

  /// 保存窗口状态
  Future<void> saveWindowState(WindowState state) async {
    _windowStateCache = state;
    await _saveWindowStateData(immediate: false);
  }







  // ==================== 标签数据管理 ====================
  
  /// 获取所有标签
  List<Tag> getAllTags() {
    return _tagCache.values.toList();
  }

  /// 根据UUID获取标签
  Tag? getTagByUuid(String uuid) {
    return _tagCache[uuid];
  }

  /// 根据UUID列表获取标签名称列表
  List<String> getTagNamesByUuids(List<String> tagUuids) {
    return tagUuids
        .map((uuid) => getTagByUuid(uuid)?.name)
        .where((name) => name != null)
        .cast<String>()
        .toList();
  }

  /// 保存标签
  Future<void> saveTag(Tag tag) async {
    _tagCache[tag.uuid] = tag;
    await _saveTagData(immediate: true);
  }

  /// 删除标签
  Future<void> deleteTag(String uuid) async {
    _tagCache.remove(uuid);
    await _saveTagData(immediate: true);
  }

  /// 根据名称查找标签
  Tag? getTagByName(String name) {
    try {
      return _tagCache.values.firstWhere(
        (tag) => tag.name == name,
      );
    } catch (e) {
      return null;
    }
  }

  // ==================== 存储配置管理 ====================
  
  /// 获取存储配置（从 AppConfig 中提取）
  StorageConfig getStorageConfig() {
    final config = _configCache ?? const AppConfig();
    return StorageConfig(
      snapshotEnabled: config.snapshotEnabled,
      snapshotOnEdit: config.snapshotOnEdit,
      snapshotOnStartup: config.snapshotOnStartup,
      snapshotOnExit: config.snapshotOnExit,
      limitSnapshotCount: config.limitSnapshotCount,
      maxSnapshotCount: config.maxSnapshotCount,
      autoBackupEnabled: config.autoBackupEnabled,
      backupOnStartup: config.backupOnStartup,
      backupOnConfigChange: config.backupOnConfigChange,
      backupOnExit: config.backupOnExit,
      limitBackupCount: config.limitBackupCount,
      maxAutoBackupCount: config.maxAutoBackupCount,
    );
  }

  /// 保存存储配置（更新到 AppConfig 中）
  Future<void> saveStorageConfig(StorageConfig config) async {
    final currentConfig = _configCache ?? const AppConfig();
    _configCache = currentConfig.copyWith(
      snapshotEnabled: config.snapshotEnabled,
      snapshotOnEdit: config.snapshotOnEdit,
      snapshotOnStartup: config.snapshotOnStartup,
      snapshotOnExit: config.snapshotOnExit,
      limitSnapshotCount: config.limitSnapshotCount,
      maxSnapshotCount: config.maxSnapshotCount,
      autoBackupEnabled: config.autoBackupEnabled,
      backupOnStartup: config.backupOnStartup,
      backupOnConfigChange: config.backupOnConfigChange,
      backupOnExit: config.backupOnExit,
      limitBackupCount: config.limitBackupCount,
      maxAutoBackupCount: config.maxAutoBackupCount,
    );
    await _saveConfigData(immediate: true);
  }

}