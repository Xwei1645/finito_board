import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart' as p;
import '../../models/homework.dart';
import '../../models/subject.dart';
import '../../models/app_config.dart';
import '../../models/window_state.dart';
import '../../models/tag.dart';

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

  static JsonStorageService? _instance;
  static JsonStorageService get instance => _instance ??= JsonStorageService._();

  JsonStorageService._();

  /// 初始化JSON存储服务
  Future<void> init() async {
    // 获取exe文件所在目录
    final exeDir = p.dirname(Platform.resolvedExecutable);
    _dataDir = p.join(exeDir, 'data');
    
    // 确保data目录存在
    final dataDirEntity = Directory(_dataDir);
    if (!await dataDirEntity.exists()) {
      await dataDirEntity.create(recursive: true);
    }
    
    // 加载所有数据到缓存
    await _loadAllData();
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
      if (!await file.exists()) {
        return null;
      }
      final content = await file.readAsString();
      if (content.trim().isEmpty) {
        return null;
      }
      return json.decode(content) as Map<String, dynamic>;
    } catch (e) {
      // 静默处理读取错误，返回null
      return null;
    }
  }

  /// 通用的JSON文件写入方法
  Future<void> _writeJsonFile(String fileName, Map<String, dynamic> data) async {
    try {
      final file = File(p.join(_dataDir, fileName));
      final jsonString = json.encode(data);
      await file.writeAsString(jsonString);
    } catch (e) {
      // 重新抛出写入错误
      rethrow;
    }
  }

  /// 加载作业数据
  Future<void> _loadHomeworkData() async {
    final data = await _readJsonFile(_homeworkFileName);
    _homeworkCache.clear();
    if (data != null && data['homework'] is List) {
      final homeworkList = data['homework'] as List;
      for (final item in homeworkList) {
        try {
          final homework = Homework.fromJson(item);
          _homeworkCache[homework.uuid] = homework;
        } catch (e) {
          // 跳过无效的作业数据
        }
      }
    }
  }

  /// 保存作业数据
  Future<void> _saveHomeworkData() async {
    final data = {
      'homework': _homeworkCache.values.map((h) => h.toJson()).toList(),
    };
    await _writeJsonFile(_homeworkFileName, data);
  }

  /// 加载科目数据
  Future<void> _loadSubjectData() async {
    final data = await _readJsonFile(_subjectFileName);
    _subjectCache.clear();
    if (data != null && data['subjects'] is List) {
      final subjectList = data['subjects'] as List;
      for (final item in subjectList) {
        try {
          final subject = Subject.fromJson(item);
          _subjectCache[subject.uuid] = subject;
        } catch (e) {
          // 跳过无效的科目数据
        }
      }
    }
  }

  /// 保存科目数据
  Future<void> _saveSubjectData() async {
    final data = {
      'subjects': _subjectCache.values.map((s) => s.toJson()).toList(),
    };
    await _writeJsonFile(_subjectFileName, data);
  }

  /// 加载配置数据
  Future<void> _loadConfigData() async {
    final data = await _readJsonFile(_configFileName);
    if (data != null && data['config'] != null) {
      try {
        _configCache = AppConfig.fromJson(data['config']);
      } catch (e) {
        // 使用默认配置
        _configCache = const AppConfig();
      }
    } else {
      _configCache = const AppConfig();
    }
  }

  /// 保存配置数据
  Future<void> _saveConfigData() async {
    final data = {
      'config': _configCache?.toJson() ?? const AppConfig().toJson(),
    };
    await _writeJsonFile(_configFileName, data);
  }

  /// 加载窗口状态数据
  Future<void> _loadWindowStateData() async {
    final data = await _readJsonFile(_windowStateFileName);
    if (data != null && data['windowState'] != null) {
      try {
        _windowStateCache = WindowState.fromJson(data['windowState']);
      } catch (e) {
        // 使用默认窗口状态
        _windowStateCache = const WindowState();
      }
    } else {
      _windowStateCache = const WindowState();
    }
  }

  /// 保存窗口状态数据
  Future<void> _saveWindowStateData() async {
    final data = {
      'windowState': _windowStateCache?.toJson() ?? const WindowState().toJson(),
    };
    await _writeJsonFile(_windowStateFileName, data);
  }

  /// 加载标签数据
  Future<void> _loadTagData() async {
    final data = await _readJsonFile(_tagFileName);
    _tagCache.clear();
    if (data != null && data['tags'] is List) {
      final tagList = data['tags'] as List;
      for (final item in tagList) {
        try {
          final tag = Tag.fromJson(item);
          _tagCache[tag.uuid] = tag;
        } catch (e) {
          // 跳过无效的标签数据
        }
      }
    }
  }

  /// 保存标签数据
  Future<void> _saveTagData() async {
    final data = {
      'tags': _tagCache.values.map((t) => t.toJson()).toList(),
    };
    await _writeJsonFile(_tagFileName, data);
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
    await _saveHomeworkData();
  }

  /// 删除作业
  Future<void> deleteHomework(String uuid) async {
    _homeworkCache.remove(uuid);
    await _saveHomeworkData();
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
    await _saveSubjectData();
  }

  /// 删除科目
  Future<void> deleteSubject(String uuid) async {
    _subjectCache.remove(uuid);
    await _saveSubjectData();
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
    await _saveConfigData();
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
    await _saveWindowStateData();
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
    await _saveTagData();
  }

  /// 删除标签
  Future<void> deleteTag(String uuid) async {
    _tagCache.remove(uuid);
    await _saveTagData();
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



}