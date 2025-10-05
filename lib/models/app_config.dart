import 'package:hive/hive.dart';

part 'app_config.g.dart';

@HiveType(typeId: 2)
class AppConfig {
  @HiveField(0)
  final String theme; // 主题设置
  
  @HiveField(1)
  final String language; // 语言设置
  
  @HiveField(2)
  final bool autoStartup; // 开机自启动
  
  @HiveField(3)
  final bool enableNotifications; // 通知设置
  
  @HiveField(4)
  final List<String> availableSubjects; // 可用科目列表
  
  @HiveField(5)
  final List<String> availableTags; // 可用标签列表
  
  @HiveField(6)
  final double scaleFactor; // 界面缩放因子
  
  @HiveField(7)
  final int columnCount; // 作业列数
  
  @HiveField(8)
  final bool alwaysOnBottom; // 始终置底设置
  
  @HiveField(9)
  final double backgroundOpacity; // 背景不透明度
  
  @HiveField(10)
  final bool firstLaunch; // 是否首次启动

  const AppConfig({
    this.theme = 'system',
    this.language = 'zh_CN',
    this.autoStartup = false,
    this.enableNotifications = true,
    this.availableSubjects = const [],
    this.availableTags = const [],
    this.scaleFactor = 100.0,
    this.columnCount = 3,
    this.alwaysOnBottom = false,
    this.backgroundOpacity = 0.95,
    this.firstLaunch = true,
  });

  AppConfig copyWith({
    String? theme,
    String? language,
    bool? autoStartup,
    bool? enableNotifications,
    List<String>? availableSubjects,
    List<String>? availableTags,
    double? scaleFactor,
    int? columnCount,
    bool? alwaysOnBottom,
    double? backgroundOpacity,
    bool? firstLaunch,
  }) {
    return AppConfig(
      theme: theme ?? this.theme,
      language: language ?? this.language,
      autoStartup: autoStartup ?? this.autoStartup,
      enableNotifications: enableNotifications ?? this.enableNotifications,
      availableSubjects: availableSubjects ?? this.availableSubjects,
      availableTags: availableTags ?? this.availableTags,
      scaleFactor: scaleFactor ?? this.scaleFactor,
      columnCount: columnCount ?? this.columnCount,
      alwaysOnBottom: alwaysOnBottom ?? this.alwaysOnBottom,
      backgroundOpacity: backgroundOpacity ?? this.backgroundOpacity,
      firstLaunch: firstLaunch ?? this.firstLaunch,
    );
  }
}