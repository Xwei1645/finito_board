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
}