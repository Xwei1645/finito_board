import 'dart:io';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path/path.dart' as p;
import '../../models/homework.dart';
import '../../models/subject.dart';
import '../../models/app_config.dart';
import '../../models/window_state.dart';
import '../../models/tag.dart';

class HiveStorageService {
  static const String _homeworkBoxName = 'homework_box';
  static const String _subjectBoxName = 'subject_box';
  static const String _configBoxName = 'config_box';
  static const String _windowStateBoxName = 'window_state_box';
  static const String _tagBoxName = 'tag_box';

  // Box实例
  late Box<Homework> _homeworkBox;
  late Box<Subject> _subjectBox;
  late Box<AppConfig> _configBox;
  late Box<WindowState> _windowStateBox;
  late Box<Tag> _tagBox;

  static HiveStorageService? _instance;
  static HiveStorageService get instance => _instance ??= HiveStorageService._();

  HiveStorageService._();

  /// 初始化Hive存储服务
  Future<void> init() async {
    // 获取exe文件所在目录
    final exeDir = p.dirname(Platform.resolvedExecutable);
    final dataDir = p.join(exeDir, 'data');
    
    // 确保data目录存在
    final dataDirEntity = Directory(dataDir);
    if (!await dataDirEntity.exists()) {
      await dataDirEntity.create(recursive: true);
    }
    
    // 初始化Hive并指定存储路径
    Hive.init(dataDir);
    
    // 注册适配器
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(HomeworkAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(SubjectAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(AppConfigAdapter());
    }
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(WindowStateAdapter());
    }
    if (!Hive.isAdapterRegistered(4)) {
      Hive.registerAdapter(TagAdapter());
    }

    // 打开Box
    _homeworkBox = await Hive.openBox<Homework>(_homeworkBoxName);
    _subjectBox = await Hive.openBox<Subject>(_subjectBoxName);
    _configBox = await Hive.openBox<AppConfig>(_configBoxName);
    _windowStateBox = await Hive.openBox<WindowState>(_windowStateBoxName);
    _tagBox = await Hive.openBox<Tag>(_tagBoxName);
  }

  /// 关闭所有Box
  Future<void> close() async {
    await _homeworkBox.close();
    await _subjectBox.close();
    await _configBox.close();
    await _windowStateBox.close();
    await _tagBox.close();
  }

  // ==================== 作业数据管理 ====================
  
  /// 获取所有作业
  List<Homework> getAllHomework() {
    return _cleanHomeworkList(_homeworkBox.values.toList());
  }

  /// 根据UUID获取作业
  Homework? getHomeworkByUuid(String uuid) {
    try {
      final homework = _homeworkBox.values.firstWhere(
        (homework) => homework.uuid == uuid,
      );
      final cleanedTagUuids = cleanInvalidTagUuids(homework.tagUuids);
      if (cleanedTagUuids.length != homework.tagUuids.length) {
        // 如果有无效的UUID被清理，更新作业
        final updatedHomework = homework.copyWith(tagUuids: cleanedTagUuids);
        _homeworkBox.put(homework.uuid, updatedHomework);
        return updatedHomework;
      }
      return homework;
    } catch (e) {
      return null;
    }
  }

  /// 保存作业
  Future<void> saveHomework(Homework homework) async {
    await _homeworkBox.put(homework.uuid, homework);
  }

  /// 删除作业
  Future<void> deleteHomework(String uuid) async {
    await _homeworkBox.delete(uuid);
  }

  /// 更新作业
  Future<void> updateHomework(Homework homework) async {
    await _homeworkBox.put(homework.uuid, homework);
  }

  /// 根据科目UUID获取作业
  List<Homework> getHomeworkBySubjectUuid(String subjectUuid) {
    return _cleanHomeworkList(_homeworkBox.values
        .where((homework) => homework.subjectUuid == subjectUuid)
        .toList());
  }

  /// 获取过期作业
  List<Homework> getOverdueHomework() {
    final now = DateTime.now();
    return _cleanHomeworkList(_homeworkBox.values
        .where((homework) => homework.dueDate.isBefore(now))
        .toList());
  }

  /// 检查作业是否存在（根据UUID）
  bool homeworkExistsByUuid(String uuid) {
    return _homeworkBox.containsKey(uuid);
  }

  /// 根据标签UUID获取作业
  List<Homework> getHomeworkByTagUuid(String tagUuid) {
    return _cleanHomeworkList(_homeworkBox.values
        .where((homework) => homework.tagUuids.contains(tagUuid))
        .toList());
  }

  /// 获取今日到期的作业
  List<Homework> getTodayDueHomework() {
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    final todayEnd = todayStart.add(const Duration(days: 1));
    
    return _cleanHomeworkList(_homeworkBox.values
        .where((homework) => 
            homework.dueDate.isAfter(todayStart) && 
            homework.dueDate.isBefore(todayEnd))
        .toList());
  }

  // ==================== 科目数据管理 ====================
  
  /// 获取所有科目
  List<Subject> getAllSubjects() {
    return _subjectBox.values.toList();
  }

  /// 保存科目
  Future<void> saveSubject(Subject subject) async {
    await _subjectBox.put(subject.uuid, subject);
  }

  /// 删除科目
  Future<void> deleteSubject(String uuid) async {
    await _subjectBox.delete(uuid);
  }

  /// 根据UUID获取科目
  Subject? getSubjectByUuid(String uuid) {
    return _subjectBox.get(uuid);
  }

  /// 根据名称获取科目
  Subject? getSubjectByName(String name) {
    try {
      return _subjectBox.values.firstWhere(
        (subject) => subject.name == name,
      );
    } catch (e) {
      return null;
    }
  }

  /// 更新科目
  Future<void> updateSubject(Subject subject) async {
    await _subjectBox.put(subject.uuid, subject);
  }

  /// 检查科目是否存在（根据UUID）
  bool subjectExistsByUuid(String uuid) {
    return _subjectBox.containsKey(uuid);
  }

  /// 检查科目是否存在（根据名称）
  bool subjectExistsByName(String name) {
    return _subjectBox.values.any((subject) => subject.name == name);
  }

  // ==================== 配置数据管理 ====================
  
  /// 获取应用配置
  AppConfig getAppConfig() {
    return _configBox.get('app_config') ?? const AppConfig();
  }

  /// 保存应用配置
  Future<void> saveAppConfig(AppConfig config) async {
    await _configBox.put('app_config', config);
  }

  /// 更新应用配置
  Future<void> updateAppConfig(AppConfig config) async {
    await _configBox.put('app_config', config);
  }

  /// 保存界面缩放因子
  Future<void> saveScaleFactor(double scaleFactor) async {
    final currentConfig = getAppConfig();
    final updatedConfig = currentConfig.copyWith(scaleFactor: scaleFactor);
    await updateAppConfig(updatedConfig);
  }

  /// 保存作业列数
  Future<void> saveColumnCount(int columnCount) async {
    final currentConfig = getAppConfig();
    final updatedConfig = currentConfig.copyWith(columnCount: columnCount);
    await updateAppConfig(updatedConfig);
  }

  // ==================== 窗口状态管理 ====================
  
  /// 获取窗口状态
  WindowState getWindowState() {
    return _windowStateBox.get('window_state') ?? const WindowState();
  }

  /// 保存窗口状态
  Future<void> saveWindowState(WindowState state) async {
    await _windowStateBox.put('window_state', state);
  }

  /// 更新窗口状态
  Future<void> updateWindowState(WindowState state) async {
    await _windowStateBox.put('window_state', state);
  }

  // ==================== 数据清理 ====================
  
  /// 清空所有作业数据
  Future<void> clearAllHomework() async {
    await _homeworkBox.clear();
  }

  /// 清空所有科目数据
  Future<void> clearAllSubjects() async {
    await _subjectBox.clear();
  }

  /// 重置应用配置
  Future<void> resetAppConfig() async {
    await _configBox.clear();
  }

  /// 重置窗口状态
  Future<void> resetWindowState() async {
    await _windowStateBox.clear();
  }

  /// 清空所有数据
  Future<void> clearAllData() async {
    await clearAllHomework();
    await clearAllSubjects();
    await resetAppConfig();
    await resetWindowState();
  }

  // ==================== 数据统计 ====================
  
  /// 获取作业总数
  int getHomeworkCount() {
    return _homeworkBox.length;
  }

  /// 获取科目总数
  int getSubjectCount() {
    return _subjectBox.length;
  }

  /// 获取今日到期作业数量
  int getTodayDueHomeworkCount() {
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    final todayEnd = todayStart.add(const Duration(days: 1));
    
    return _homeworkBox.values
        .where((homework) => 
            homework.dueDate.isAfter(todayStart) && 
            homework.dueDate.isBefore(todayEnd))
        .length;
  }

  /// 获取过期作业数量
  int getOverdueHomeworkCount() {
    final now = DateTime.now();
    return _homeworkBox.values
        .where((homework) => homework.dueDate.isBefore(now))
        .length;
  }

  // ==================== 标签数据管理 ====================
  
  /// 获取所有标签
  List<Tag> getAllTags() {
    return _tagBox.values.toList();
  }

  /// 根据UUID获取标签
  Tag? getTagByUuid(String uuid) {
    try {
      return _tagBox.values.firstWhere(
        (tag) => tag.uuid == uuid,
      );
    } catch (e) {
      return null;
    }
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
    await _tagBox.put(tag.uuid, tag);
  }

  /// 删除标签
  Future<void> deleteTag(String uuid) async {
    await _tagBox.delete(uuid);
  }

  /// 根据名称查找标签
  Tag? getTagByName(String name) {
    try {
      return _tagBox.values.firstWhere(
        (tag) => tag.name == name,
      );
    } catch (e) {
      return null;
    }
  }

  /// 清理无效的标签UUID，返回有效的UUID列表
  List<String> cleanInvalidTagUuids(List<String> tagUuids) {
    return tagUuids.where((uuid) => getTagByUuid(uuid) != null).toList();
  }

  /// 清理作业列表中的无效标签UUID
  List<Homework> _cleanHomeworkList(List<Homework> homeworkList) {
    return homeworkList.map((homework) {
      final cleanedTagUuids = cleanInvalidTagUuids(homework.tagUuids);
      if (cleanedTagUuids.length != homework.tagUuids.length) {
        // 如果有无效的UUID被清理，更新作业
        final updatedHomework = homework.copyWith(tagUuids: cleanedTagUuids);
        _homeworkBox.put(homework.uuid, updatedHomework);
        return updatedHomework;
      }
      return homework;
    }).toList();
  }
}