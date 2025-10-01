class Homework {
  final String id;
  final String content; // 富文本正文
  final DateTime dueDate; // 截止日期
  final String subject; // 学科
  final List<String> tags; // 标签列表
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

  // 判断是否已过期
  bool get isOverdue => DateTime.now().isAfter(dueDate);

  // 获取剩余天数
  int get daysRemaining {
    final difference = dueDate.difference(DateTime.now()).inDays;
    return difference < 0 ? 0 : difference;
  }

  // 格式化截止日期显示
  String get formattedDueDate {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueDay = DateTime(dueDate.year, dueDate.month, dueDate.day);
    
    final difference = dueDay.difference(today).inDays;
    
    if (difference == 0) {
      return '今天截止';
    } else if (difference == 1) {
      return '明天截止';
    } else if (difference > 1) {
      return '$difference天后截止';
    } else {
      return '已过期';
    }
  }
}