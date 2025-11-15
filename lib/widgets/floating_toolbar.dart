import 'package:flutter/material.dart';

class FloatingToolbar extends StatelessWidget {
  final double opacity;
  final double backgroundOpacity;
  final bool isFullScreen;
  final VoidCallback onMouseEnter;
  final VoidCallback onMouseExit;
  final VoidCallback onNewHomework;
  final VoidCallback onToggleFullScreen;
  final VoidCallback onToggleMenu;

  const FloatingToolbar({
    super.key,
    required this.opacity,
    required this.backgroundOpacity,
    required this.isFullScreen,
    required this.onMouseEnter,
    required this.onMouseExit,
    required this.onNewHomework,
    required this.onToggleFullScreen,
    required this.onToggleMenu,
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
              _ToolbarButton(
                icon: Icons.add,
                onPressed: onNewHomework,
                tooltip: '新建',
              ),
              const SizedBox(width: 4),
              _ToolbarButton(
                icon: isFullScreen ? Icons.fullscreen_exit : Icons.fullscreen,
                onPressed: onToggleFullScreen,
                tooltip: isFullScreen ? '退出全屏' : '全屏',
              ),
              const SizedBox(width: 4),
              _ToolbarButton(
                icon: Icons.menu,
                onPressed: onToggleMenu,
                tooltip: '快捷菜单',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ToolbarButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final String tooltip;

  const _ToolbarButton({
    required this.icon,
    required this.onPressed,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
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
