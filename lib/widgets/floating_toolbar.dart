import 'package:flutter/material.dart';

/// 悬浮工具栏组件
/// 
/// 显示在窗口右下角，包含新建作业、全屏切换和快捷菜单按钮
class FloatingToolbar extends StatelessWidget {
  /// 工具栏透明度（0.0-1.0）
  final double opacity;
  
  /// 背景透明度（用于计算工具栏背景色）
  final double backgroundOpacity;
  
  /// 是否全屏状态
  final bool isFullScreen;
  
  /// 新建作业回调
  final VoidCallback onNewHomework;
  
  /// 全屏切换回调
  final VoidCallback onToggleFullScreen;
  
  /// 打开快捷菜单回调
  final VoidCallback onOpenQuickMenu;
  
  /// 鼠标进入工具栏回调
  final VoidCallback onMouseEnter;
  
  /// 鼠标离开工具栏回调
  final VoidCallback onMouseExit;
  
  /// 工具栏按钮点击回调（用于重置透明度定时器）
  final VoidCallback onButtonPressed;

  const FloatingToolbar({
    super.key,
    required this.opacity,
    required this.backgroundOpacity,
    required this.isFullScreen,
    required this.onNewHomework,
    required this.onToggleFullScreen,
    required this.onOpenQuickMenu,
    required this.onMouseEnter,
    required this.onMouseExit,
    required this.onButtonPressed,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    double toolbarBackgroundOpacity = (backgroundOpacity + 0.1).clamp(0.0, 1.0);
    
    return MouseRegion(
      onEnter: (_) => onMouseEnter(),
      onExit: (_) => onMouseExit(),
      child: Opacity(
        opacity: opacity,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: colorScheme.surface.withValues(alpha: toolbarBackgroundOpacity),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withValues(alpha: 0.15 * opacity),
                spreadRadius: 1,
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildToolbarButton(
                context: context,
                icon: Icons.add,
                onPressed: () {
                  onButtonPressed();
                  onNewHomework();
                },
                tooltip: '新建',
              ),
              const SizedBox(width: 4),
              _buildToolbarButton(
                context: context,
                icon: isFullScreen ? Icons.fullscreen_exit : Icons.fullscreen,
                onPressed: () {
                  onButtonPressed();
                  onToggleFullScreen();
                },
                tooltip: isFullScreen ? '退出全屏' : '全屏',
              ),
              const SizedBox(width: 4),
              _buildToolbarButton(
                context: context,
                icon: Icons.menu,
                onPressed: () {
                  onButtonPressed();
                  onOpenQuickMenu();
                },
                tooltip: '快捷菜单',
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建工具栏按钮
  Widget _buildToolbarButton({
    required BuildContext context,
    required IconData icon,
    required VoidCallback onPressed,
    required String tooltip,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: colorScheme.onSurface.withValues(alpha: 0.7),
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}
