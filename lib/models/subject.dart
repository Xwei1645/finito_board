import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../services/storage/hive_storage_service.dart';

part 'subject.g.dart';

@HiveType(typeId: 1)
class Subject {
  @HiveField(0)
  final String uuid;
  
  @HiveField(1)
  final String name;

  const Subject({
    required this.uuid,
    required this.name,
  });

  // 工厂构造函数，自动生成UUID
  factory Subject.create({
    required String name,
  }) {
    return Subject(
      uuid: const Uuid().v4(),
      name: name,
    );
  }

  // 复制方法
  Subject copyWith({
    String? uuid,
    String? name,
  }) {
    return Subject(
      uuid: uuid ?? this.uuid,
      name: name ?? this.name,
    );
  }
}

class SampleData {
  static List<Subject> getSubjects() {
    return [];
  }
  
  // 获取可用科目列表（从配置中获取，如果为空则返回空列表）
  static List<String> getAvailableSubjects() {
    try {
      final config = HiveStorageService.instance.getAppConfig();
      if (config.availableSubjects.isNotEmpty) {
        return config.availableSubjects;
      }
    } catch (e) {
      // 如果获取配置失败，返回空列表
    }
    
    // 返回空列表
    return [];
  }

}