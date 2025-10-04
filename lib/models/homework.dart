import 'package:hive/hive.dart';

part 'homework.g.dart';

@HiveType(typeId: 0)
class Homework {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String content; // 富文本正文
  
  @HiveField(2)
  final DateTime dueDate; // 截止日期
  
  @HiveField(3)
  final String subject; // 学科
  
  @HiveField(4)
  final List<String> tags; // 标签列表
  
  @HiveField(5)
  final DateTime createdAt;

  const Homework({
    required this.id,
    required this.content,
    required this.dueDate,
    required this.subject,
    this.tags = const [],
    required this.createdAt,
  });

  // 复制方法，用于编辑时创建新实例
  Homework copyWith({
    String? id,
    String? content,
    DateTime? dueDate,
    String? subject,
    List<String>? tags,
    DateTime? createdAt,
  }) {
    return Homework(
      id: id ?? this.id,
      content: content ?? this.content,
      dueDate: dueDate ?? this.dueDate,
      subject: subject ?? this.subject,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
    );
  }


}