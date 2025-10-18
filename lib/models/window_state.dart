class WindowState {
  final double x; // 窗口X坐标
  final double y; // 窗口Y坐标
  final double width; // 窗口宽度
  final double height; // 窗口高度
  final bool isMaximized; // 是否最大化
  final bool isMinimized; // 是否最小化
  final bool isFullScreen; // 是否全屏

  const WindowState({
    this.x = 100,
    this.y = 100,
    this.width = 1200,
    this.height = 800,
    this.isMaximized = false,
    this.isMinimized = false,
    this.isFullScreen = false,
  });

  WindowState copyWith({
    double? x,
    double? y,
    double? width,
    double? height,
    bool? isMaximized,
    bool? isMinimized,
    bool? isFullScreen,
  }) {
    return WindowState(
      x: x ?? this.x,
      y: y ?? this.y,
      width: width ?? this.width,
      height: height ?? this.height,
      isMaximized: isMaximized ?? this.isMaximized,
      isMinimized: isMinimized ?? this.isMinimized,
      isFullScreen: isFullScreen ?? this.isFullScreen,
    );
  }

  // JSON序列化
  Map<String, dynamic> toJson() {
    return {
      'x': x,
      'y': y,
      'width': width,
      'height': height,
      'isMaximized': isMaximized,
      'isMinimized': isMinimized,
      'isFullScreen': isFullScreen,
    };
  }

  // JSON反序列化
  factory WindowState.fromJson(Map<String, dynamic> json) {
    return WindowState(
      x: (json['x'] as num?)?.toDouble() ?? 100,
      y: (json['y'] as num?)?.toDouble() ?? 100,
      width: (json['width'] as num?)?.toDouble() ?? 1200,
      height: (json['height'] as num?)?.toDouble() ?? 800,
      isMaximized: json['isMaximized'] as bool? ?? false,
      isMinimized: json['isMinimized'] as bool? ?? false,
      isFullScreen: json['isFullScreen'] as bool? ?? false,
    );
  }
}