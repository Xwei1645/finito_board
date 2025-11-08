class AppConfig {
  final String theme; // 主题设置
  final String language; // 语言设置
  final bool autoStartup; // 开机自启动
  final bool enableNotifications; // 通知设置
  final List<String> availableSubjects; // 可用科目列表
  final List<String> availableTags; // 可用标签列表
  final double scaleFactor; // 界面缩放因子
  final int columnCount; // 作业列数
  final bool alwaysOnBottom; // 始终置底设置
  final double backgroundOpacity; // 背景不透明度
  final bool firstLaunch; // 是否首次启动
  final bool showInTaskbar; // 是否在任务栏显示

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
    this.showInTaskbar = false,
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
    bool? showInTaskbar,
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
      showInTaskbar: showInTaskbar ?? this.showInTaskbar,
    );
  }

  // JSON序列化
  Map<String, dynamic> toJson() {
    return {
      'theme': theme,
      'language': language,
      'autoStartup': autoStartup,
      'enableNotifications': enableNotifications,
      'availableSubjects': availableSubjects,
      'availableTags': availableTags,
      'scaleFactor': scaleFactor,
      'columnCount': columnCount,
      'alwaysOnBottom': alwaysOnBottom,
      'backgroundOpacity': backgroundOpacity,
      'firstLaunch': firstLaunch,
      'showInTaskbar': showInTaskbar,
    };
  }

  // JSON反序列化
  factory AppConfig.fromJson(Map<String, dynamic> json) {
    return AppConfig(
      theme: json['theme'] as String? ?? 'system',
      language: json['language'] as String? ?? 'zh_CN',
      autoStartup: json['autoStartup'] as bool? ?? false,
      enableNotifications: json['enableNotifications'] as bool? ?? true,
      availableSubjects: List<String>.from(json['availableSubjects'] as List? ?? []),
      availableTags: List<String>.from(json['availableTags'] as List? ?? []),
      scaleFactor: (json['scaleFactor'] as num?)?.toDouble() ?? 100.0,
      columnCount: json['columnCount'] as int? ?? 3,
      alwaysOnBottom: json['alwaysOnBottom'] as bool? ?? false,
      backgroundOpacity: (json['backgroundOpacity'] as num?)?.toDouble() ?? 0.95,
      firstLaunch: json['firstLaunch'] as bool? ?? true,
      showInTaskbar: json['showInTaskbar'] as bool? ?? false,
    );
  }
}