class AppConfig {
  final String theme; // 主题设置
  final bool autoStartup; // 开机自启动
  final List<String> availableSubjects; // 可用科目列表
  final List<String> availableTags; // 可用标签列表
  final double scaleFactor; // 界面缩放因子
  final int columnCount; // 作业列数
  final int windowLevel; // 窗口层级: 0=常规, 1=置顶, 2=置底
  final double backgroundOpacity; // 背景不透明度
  final bool firstLaunch; // 是否首次启动
  final bool showInTaskbar; // 是否在任务栏显示
  final int? themeColor; // 自定义主题色，null表示使用默认色
  final String? backgroundImagePath; // 背景图片路径
  final int backgroundImageMode; // 背景图片显示模式: 0=适应, 1=填充, 2=拉伸

  const AppConfig({
    this.theme = 'light',
    this.autoStartup = false,
    this.availableSubjects = const [],
    this.availableTags = const [],
    this.scaleFactor = 100.0,
    this.columnCount = 3,
    this.windowLevel = 0,
    this.backgroundOpacity = 0.95,
    this.firstLaunch = true,
    this.showInTaskbar = false,
    this.themeColor,
    this.backgroundImagePath,
    this.backgroundImageMode = 0,
  });

  AppConfig copyWith({
    String? theme,
    bool? autoStartup,
    List<String>? availableSubjects,
    List<String>? availableTags,
    double? scaleFactor,
    int? columnCount,
    int? windowLevel,
    double? backgroundOpacity,
    bool? firstLaunch,
    bool? showInTaskbar,
    int? themeColor,
    String? backgroundImagePath,
    int? backgroundImageMode,
  }) {
    return AppConfig(
      theme: theme ?? this.theme,
      autoStartup: autoStartup ?? this.autoStartup,
      availableSubjects: availableSubjects ?? this.availableSubjects,
      availableTags: availableTags ?? this.availableTags,
      scaleFactor: scaleFactor ?? this.scaleFactor,
      columnCount: columnCount ?? this.columnCount,
      windowLevel: windowLevel ?? this.windowLevel,
      backgroundOpacity: backgroundOpacity ?? this.backgroundOpacity,
      firstLaunch: firstLaunch ?? this.firstLaunch,
      showInTaskbar: showInTaskbar ?? this.showInTaskbar,
      themeColor: themeColor ?? this.themeColor,
      backgroundImagePath: backgroundImagePath ?? this.backgroundImagePath,
      backgroundImageMode: backgroundImageMode ?? this.backgroundImageMode,
    );
  }

  // JSON序列化
  Map<String, dynamic> toJson() {
    return {
      'theme': theme,
      'autoStartup': autoStartup,
      'availableSubjects': availableSubjects,
      'availableTags': availableTags,
      'scaleFactor': scaleFactor,
      'columnCount': columnCount,
      'windowLevel': windowLevel,
      'backgroundOpacity': backgroundOpacity,
      'firstLaunch': firstLaunch,
      'showInTaskbar': showInTaskbar,
      'themeColor': themeColor,
      'backgroundImagePath': backgroundImagePath,
      'backgroundImageMode': backgroundImageMode,
    };
  }

  // JSON反序列化
  factory AppConfig.fromJson(Map<String, dynamic> json) {
    return AppConfig(
      theme: json['theme'] as String? ?? 'light',
      autoStartup: json['autoStartup'] as bool? ?? false,
      availableSubjects: List<String>.from(json['availableSubjects'] as List? ?? []),
      availableTags: List<String>.from(json['availableTags'] as List? ?? []),
      scaleFactor: (json['scaleFactor'] as num?)?.toDouble() ?? 100.0,
      columnCount: json['columnCount'] as int? ?? 3,
      windowLevel: json['windowLevel'] as int? ?? 0,
      backgroundOpacity: (json['backgroundOpacity'] as num?)?.toDouble() ?? 0.95,
      firstLaunch: json['firstLaunch'] as bool? ?? true,
      showInTaskbar: json['showInTaskbar'] as bool? ?? false,
      themeColor: json['themeColor'] as int?,
      backgroundImagePath: json['backgroundImagePath'] as String?,
      backgroundImageMode: json['backgroundImageMode'] as int? ?? 0,
    );
  }
}