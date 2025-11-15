import 'package:flutter/material.dart';

class QuickMenu extends StatelessWidget {
  final double backgroundOpacity;
  final bool isFullScreen;
  final bool isWindowLocked;
  final bool windowLockedBeforeFullScreen;
  final double scaleFactor;
  final int columnCount;
  final VoidCallback onMoreOptions;
  final VoidCallback onToggleWindowLock;
  final VoidCallback onMinimize;
  final VoidCallback onManageSubjects;
  final VoidCallback onManageTags;
  final VoidCallback onScaleIncrease;
  final VoidCallback onScaleDecrease;
  final VoidCallback onColumnIncrease;
  final VoidCallback onColumnDecrease;
  final VoidCallback onExit;
  final VoidCallback onInteraction;

  const QuickMenu({
    super.key,
    required this.backgroundOpacity,
    required this.isFullScreen,
    required this.isWindowLocked,
    required this.windowLockedBeforeFullScreen,
    required this.scaleFactor,
    required this.columnCount,
    required this.onMoreOptions,
    required this.onToggleWindowLock,
    required this.onMinimize,
    required this.onManageSubjects,
    required this.onManageTags,
    required this.onScaleIncrease,
    required this.onScaleDecrease,
    required this.onColumnIncrease,
    required this.onColumnDecrease,
    required this.onExit,
    required this.onInteraction,
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
          _MenuButton(
            icon: Icons.more_horiz,
            text: '更多选项...',
            onPressed: onMoreOptions,
          ),
          const SizedBox(height: 12),
          // 窗口控制
          _MenuSection(
            title: '窗口控制',
            child: Row(
              children: [
                Expanded(
                  child: _MenuButton(
                    icon: (isFullScreen ? windowLockedBeforeFullScreen : isWindowLocked) ? Icons.lock_open : Icons.lock,
                    text: (isFullScreen ? windowLockedBeforeFullScreen : isWindowLocked) ? '解锁' : '锁定',
                    onPressed: isFullScreen ? null : () {
                      onInteraction();
                      onToggleWindowLock();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _MenuButton(
                    icon: Icons.picture_in_picture_alt,
                    text: '收起',
                    onPressed: () {
                      onInteraction();
                      onMinimize();
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // 编辑选项
          _MenuSection(
            title: '编辑...',
            child: Row(
              children: [
                Expanded(
                  child: _MenuButton(
                    icon: Icons.subject,
                    text: '科目',
                    onPressed: onManageSubjects,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _MenuButton(
                    icon: Icons.label,
                    text: '标签',
                    onPressed: onManageTags,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // 界面设置
          _MenuSection(
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
                    _ScaleButton(
                      icon: Icons.remove,
                      onPressed: () {
                        onInteraction();
                        onScaleDecrease();
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
                    _ScaleButton(
                      icon: Icons.add,
                      onPressed: () {
                        onInteraction();
                        onScaleIncrease();
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
                    _ScaleButton(
                      icon: Icons.remove,
                      onPressed: () {
                        onInteraction();
                        onColumnDecrease();
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
                    _ScaleButton(
                      icon: Icons.add,
                      onPressed: () {
                        onInteraction();
                        onColumnIncrease();
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // 退出选项
          _MenuButton(
            icon: Icons.exit_to_app,
            text: '退出...',
            onPressed: onExit,
            isDestructive: true,
          ),
        ],
      ),
    );
  }
}

class _MenuSection extends StatelessWidget {
  final String title;
  final Widget child;

  const _MenuSection({
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
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
}

class _MenuButton extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback? onPressed;
  final bool isDestructive;

  const _MenuButton({
    required this.icon,
    required this.text,
    required this.onPressed,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
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
}

class _ScaleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _ScaleButton({
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
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
