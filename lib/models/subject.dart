import 'package:uuid/uuid.dart';

class Subject {
  final String uuid;
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

  // JSON序列化
  Map<String, dynamic> toJson() {
    return {
      'uuid': uuid,
      'name': name,
    };
  }

  // JSON反序列化
  factory Subject.fromJson(Map<String, dynamic> json) {
    return Subject(
      uuid: json['uuid'] as String,
      name: json['name'] as String,
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
      // 延迟导入以避免循环依赖
      final storageService = _getStorageService();
      if (storageService != null) {
        final config = storageService.getAppConfig();
        if (config.availableSubjects.isNotEmpty) {
          return config.availableSubjects;
        }
      }
    } catch (e) {
      // 如果获取配置失败，返回空列表
    }
    
    // 返回空列表
    return [];
  }

  // 延迟获取存储服务实例以避免循环依赖
  static dynamic _getStorageService() {
    try {
      // 使用反射或动态导入来避免循环依赖
      return null; // 暂时返回null，后续在替换存储服务时会修复
    } catch (e) {
      return null;
    }
  }
}