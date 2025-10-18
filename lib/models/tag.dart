import 'package:uuid/uuid.dart';

class Tag {
  final String uuid;
  final String name;

  const Tag({
    required this.uuid,
    required this.name,
  });

  // 工厂构造函数，自动生成UUID
  factory Tag.create({
    required String name,
  }) {
    return Tag(
      uuid: const Uuid().v4(),
      name: name,
    );
  }

  // 复制方法
  Tag copyWith({
    String? uuid,
    String? name,
  }) {
    return Tag(
      uuid: uuid ?? this.uuid,
      name: name ?? this.name,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Tag && other.uuid == uuid;
  }

  @override
  int get hashCode => uuid.hashCode;

  @override
  String toString() => 'Tag(uuid: $uuid, name: $name)';

  // JSON序列化
  Map<String, dynamic> toJson() {
    return {
      'uuid': uuid,
      'name': name,
    };
  }

  // JSON反序列化
  factory Tag.fromJson(Map<String, dynamic> json) {
    return Tag(
      uuid: json['uuid'] as String,
      name: json['name'] as String,
    );
  }

  // 获取可用标签列表（从存储服务中获取所有标签的名称）
  static List<String> getAvailableTags() {
    try {
      // 延迟获取存储服务实例以避免循环依赖
      final storageService = _getStorageService();
      if (storageService != null) {
        return storageService.getAllTags()
            .map((tag) => tag.name)
            .toList();
      }
      return [];
    } catch (e) {
      // 如果获取标签失败，返回空列表
      return [];
    }
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