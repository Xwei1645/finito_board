import 'package:uuid/uuid.dart';

class Homework {
  final String uuid;
  final String content; // 富文本正文
  final DateTime dueDate; // 截止日期
  final String subjectUuid; // 学科UUID
  final List<String> tagUuids; // 标签UUID列表
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

  // JSON序列化
  Map<String, dynamic> toJson() {
    return {
      'uuid': uuid,
      'content': content,
      'dueDate': dueDate.toIso8601String(),
      'subjectUuid': subjectUuid,
      'tagUuids': tagUuids,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // JSON反序列化
  factory Homework.fromJson(Map<String, dynamic> json) {
    return Homework(
      uuid: json['uuid'] as String,
      content: json['content'] as String,
      dueDate: DateTime.parse(json['dueDate'] as String),
      subjectUuid: json['subjectUuid'] as String,
      tagUuids: List<String>.from(json['tagUuids'] as List),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}