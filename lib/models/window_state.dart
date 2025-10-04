import 'package:hive/hive.dart';

part 'window_state.g.dart';

@HiveType(typeId: 3)
class WindowState {
  @HiveField(0)
  final double x; // 窗口X坐标
  
  @HiveField(1)
  final double y; // 窗口Y坐标
  
  @HiveField(2)
  final double width; // 窗口宽度
  
  @HiveField(3)
  final double height; // 窗口高度
  
  @HiveField(4)
  final bool isMaximized; // 是否最大化
  
  @HiveField(5)
  final bool isMinimized; // 是否最小化
  
  @HiveField(6)
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
}