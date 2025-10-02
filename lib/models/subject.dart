import 'homework.dart';

class Subject {
  final String name;
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
  
  // 预定义的科目列表
  static List<String> getAvailableSubjects() {
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
  
  // 预定义的标签列表
  static List<String> getAvailableTags() {
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