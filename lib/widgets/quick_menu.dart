import 'package:flutter/material.dart';

/// 快捷菜单组件
/// 
/// 显示在工具栏上方，提供各种快捷操作选项
class QuickMenu extends StatelessWidget {
  /// 背景透明度（用于计算菜单背景色）
  final double backgroundOpacity;
  
  /// 是否全屏状态
  final bool isFullScreen;
  
  /// 窗口是否锁定
  final bool isWindowLocked;
  
  /// 全屏前的窗口锁定状态
  final bool windowLockedBeforeFullScreen;
  
  /// 界面缩放倍数（百分比）
  final double scaleFactor;
  
  /// 作业列数
  final int columnCount;
  
  /// 打开更多选项回调
  final VoidCallback onOpenMoreOptions;
  
  /// 切换窗口锁定回调
  final VoidCallback onToggleWindowLock;
  
  /// 显示科目管理器回调
  final VoidCallback onShowSubjectManager;
  
  /// 显示标签管理器回调
  final VoidCallback onShowTagManager;
  
  /// 调整界面缩放回调
  final void Function(double delta) onAdjustScale;
  
  /// 调整作业列数回调
  final void Function(int delta) onAdjustColumnCount;
  
  /// 退出应用回调
  final VoidCallback onExitApplication;
  
  /// 重置快捷菜单定时器回调
  final VoidCallback onResetMenuTimer;

  const QuickMenu({
    super.key,
    required this.backgroundOpacity,
    required this.isFullScreen,
    required this.isWindowLocked,
    required this.windowLockedBeforeFullScreen,
    required this.scaleFactor,
    required this.columnCount,
    required this.onOpenMoreOptions,
    required this.onToggleWindowLock,
    required this.onShowSubjectManager,
    required this.onShowTagManager,
    required this.onAdjustScale,
    required this.onAdjustColumnCount,
    required this.onExitApplication,
    required this.onResetMenuTimer,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      width: 220,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: (backgroundOpacity + 0.2).clamp(0.0, 1.0)),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.15),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 更多选项
          _buildMenuButton(
            context: context,
            icon: Icons.more_horiz,
            text: '更多选项...',
            onPressed: onOpenMoreOptions,
          ),
          const SizedBox(height: 12),
          // 窗口控制
          _buildMenuSection(
            context: context,
            title: '窗口控制',
            child: Row(
              children: [
                Expanded(
                  child: _buildMenuButton(
                    context: context,
                    icon: (isFullScreen ? windowLockedBeforeFullScreen : isWindowLocked) ? Icons.lock_open : Icons.lock,
                    text: (isFullScreen ? windowLockedBeforeFullScreen : isWindowLocked) ? '解锁' : '锁定',
                    onPressed: isFullScreen ? null : () {
                      onResetMenuTimer();
                      onToggleWindowLock();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMenuButton(
                    context: context,
                    icon: Icons.picture_in_picture_alt,
                    text: '收起',
                    onPressed: () {
                      onResetMenuTimer();
                      // TODO: 实现收起功能
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // 编辑选项
          _buildMenuSection(
            context: context,
            title: '编辑...',
            child: Row(
              children: [
                Expanded(
                  child: _buildMenuButton(
                    context: context,
                    icon: Icons.subject,
                    text: '科目',
                    onPressed: onShowSubjectManager,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMenuButton(
                    context: context,
                    icon: Icons.label,
                    text: '标签',
                    onPressed: onShowTagManager,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // 界面设置
          _buildMenuSection(
            context: context,
            title: '界面设置',
            child: Column(
              children: [
                // 界面缩放
                Row(
                  children: [
                    Text(
                      '界面缩放',
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                    const Spacer(),
                    _buildScaleButton(
                      context: context,
                      icon: Icons.remove,
                      onPressed: () {
                        onResetMenuTimer();
                        onAdjustScale(-10);
                      },
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 50,
                      child: Text(
                        '${scaleFactor.toInt()}%',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildScaleButton(
                      context: context,
                      icon: Icons.add,
                      onPressed: () {
                        onResetMenuTimer();
                        onAdjustScale(10);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // 作业列数
                Row(
                  children: [
                    Text(
                      '作业列数',
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                    const Spacer(),
                    _buildScaleButton(
                      context: context,
                      icon: Icons.remove,
                      onPressed: () {
                        onResetMenuTimer();
                        onAdjustColumnCount(-1);
                      },
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 50,
                      child: Text(
                        '$columnCount 列',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildScaleButton(
                      context: context,
                      icon: Icons.add,
                      onPressed: () {
                        onResetMenuTimer();
                        onAdjustColumnCount(1);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // 退出选项
          _buildMenuButton(
            context: context,
            icon: Icons.exit_to_app,
            text: '退出...',
            onPressed: onExitApplication,
            isDestructive: true,
          ),
        ],
      ),
    );
  }

  /// 构建菜单区块
  Widget _buildMenuSection({
    required BuildContext context,
    required String title,
    required Widget child,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            color: colorScheme.onSurface.withValues(alpha: 0.7),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }

  /// 构建菜单按钮
  Widget _buildMenuButton({
    required BuildContext context,
    required IconData icon,
    required String text,
    required VoidCallback? onPressed,
    bool isDestructive = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final bool isEnabled = onPressed != null;

    Color backgroundColor;
    Color foregroundColor;

    if (isEnabled) {
      if (isDestructive) {
        backgroundColor = colorScheme.errorContainer.withValues(alpha: 0.3);
        foregroundColor = colorScheme.error;
      } else {
        backgroundColor = colorScheme.surfaceContainerHighest.withValues(alpha: 0.5);
        foregroundColor = colorScheme.onSurface;
      }
    } else {
      backgroundColor = colorScheme.surfaceContainer.withValues(alpha: 0.5);
      foregroundColor = colorScheme.onSurface.withValues(alpha: 0.38);
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 18,
                color: foregroundColor,
              ),
              const SizedBox(width: 8),
              Text(
                text,
                style: TextStyle(
                  fontSize: 14,
                  color: foregroundColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建缩放按钮
  Widget _buildScaleButton({
    required BuildContext context,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            icon,
            size: 16,
            color: colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
      ),
    );
  }
}
