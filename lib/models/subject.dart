import 'package:hive/hive.dart';
import 'homework.dart';
import '../services/storage/hive_storage_service.dart';

part 'subject.g.dart';

@HiveType(typeId: 1)
class Subject {
  @HiveField(0)
  final String name;
  
  @HiveField(1)
  final List<Homework> homeworks;

  const Subject({
    required this.name,
    required this.homeworks,
  });
}

class SampleData {
  static List<Subject> getSubjects() {
    return [];
  }
  
  // 获取可用科目列表（从配置中获取，如果为空则返回默认列表）
  static List<String> getAvailableSubjects() {
    try {
      final config = HiveStorageService.instance.getAppConfig();
      if (config.availableSubjects.isNotEmpty) {
        return config.availableSubjects;
      }
    } catch (e) {
      // 如果获取配置失败，返回默认列表
    }
    
    // 默认科目列表
    return [
      '数学',
      '语文',
      '英语',
      '物理',
      '化学',
      '生物',
      '历史',
      '地理',
      '政治',
    ];
  }
  
  // 获取可用标签列表（从配置中获取，如果为空则返回默认列表）
  static List<String> getAvailableTags() {
    try {
      final config = HiveStorageService.instance.getAppConfig();
      if (config.availableTags.isNotEmpty) {
        return config.availableTags;
      }
    } catch (e) {
      // 如果获取配置失败，返回默认列表
    }
    
    // 默认标签列表
    return [
      '重要',
      '紧急',
      '复习',
      '预习',
      '作业',
      '考试',
      '项目',
      '课外',
    ];
  }
}