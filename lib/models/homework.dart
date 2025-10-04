import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'homework.g.dart';

@HiveType(typeId: 0)
class Homework {
  @HiveField(0)
  final String uuid;
  
  @HiveField(1)
  final String content; // 富文本正文
  
  @HiveField(2)
  final DateTime dueDate; // 截止日期
  
  @HiveField(3)
  final String subjectUuid; // 学科UUID
  
  @HiveField(4)
  final List<String> tagUuids; // 标签UUID列表
  
  @HiveField(5)
  final DateTime createdAt;

  const Homework({
    required this.uuid,
    required this.content,
    required this.dueDate,
    required this.subjectUuid,
    this.tagUuids = const [],
    required this.createdAt,
  });

  // 工厂构造函数，自动生成UUID
  factory Homework.create({
    required String content,
    required DateTime dueDate,
    required String subjectUuid,
    List<String>? tagUuids,
    DateTime? createdAt,
  }) {
    return Homework(
      uuid: const Uuid().v4(),
      content: content,
      dueDate: dueDate,
      subjectUuid: subjectUuid,
      tagUuids: tagUuids ?? [],
      createdAt: createdAt ?? DateTime.now(),
    );
  }

  // 复制方法，用于编辑时创建新实例
  Homework copyWith({
    String? uuid,
    String? content,
    DateTime? dueDate,
    String? subjectUuid,
    List<String>? tagUuids,
    DateTime? createdAt,
  }) {
    return Homework(
      uuid: uuid ?? this.uuid,
      content: content ?? this.content,
      dueDate: dueDate ?? this.dueDate,
      subjectUuid: subjectUuid ?? this.subjectUuid,
      tagUuids: tagUuids ?? this.tagUuids,
      createdAt: createdAt ?? this.createdAt,
    );
  }


}