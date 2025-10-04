import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../services/storage/hive_storage_service.dart';

part 'tag.g.dart';

@HiveType(typeId: 4)
class Tag {
  @HiveField(0)
  final String uuid;
  
  @HiveField(1)
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

  // 获取可用标签列表（从存储服务中获取所有标签的名称）
  static List<String> getAvailableTags() {
    try {
      return HiveStorageService.instance.getAllTags()
          .map((tag) => tag.name)
          .toList();
    } catch (e) {
      // 如果获取标签失败，返回空列表
      return [];
    }
  }
}