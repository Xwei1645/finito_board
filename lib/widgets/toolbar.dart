import 'package:flutter/material.dart';
import 'package:split_button_m3e/split_button_m3e.dart';
import 'custom_split_button.dart';

/// 工具栏组件
/// 
/// 显示在窗口右下角，使用 SplitButton 样式
/// 左侧是加号图标，右侧可以打开 PopupMenu
class Toolbar extends StatefulWidget {
  /// 工具栏透明度（0.0-1.0）
  final double opacity;
  
  /// 背景透明度（用于计算工具栏背景色）
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
  
  /// 新建作业回调
  final VoidCallback onNewHomework;
  
  /// 全屏切换回调
  final VoidCallback onToggleFullScreen;
  
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
  
  /// 鼠标进入工具栏回调
  final VoidCallback onMouseEnter;
  
  /// 鼠标离开工具栏回调
  final VoidCallback onMouseExit;
  
  /// 工具栏按钮点击回调（用于重置透明度定时器）
  final VoidCallback onButtonPressed;

  const Toolbar({
    super.key,
    required this.opacity,
    required this.backgroundOpacity,
    required this.isFullScreen,
    required this.isWindowLocked,
    required this.windowLockedBeforeFullScreen,
    required this.scaleFactor,
    required this.columnCount,
    required this.onNewHomework,
    required this.onToggleFullScreen,
    required this.onOpenMoreOptions,
    required this.onToggleWindowLock,
    required this.onShowSubjectManager,
    required this.onShowTagManager,
    required this.onAdjustScale,
    required this.onAdjustColumnCount,
    required this.onExitApplication,
    required this.onMouseEnter,
    required this.onMouseExit,
    required this.onButtonPressed,
  });

  @override
  State<Toolbar> createState() => _ToolbarState();
}

class _ToolbarState extends State<Toolbar> {
  // 用于菜单内部即时更新的本地状态
  late double _localScaleFactor;
  late int _localColumnCount;

  @override
  void initState() {
    super.initState();
    _localScaleFactor = widget.scaleFactor;
    _localColumnCount = widget.columnCount;
  }

  @override
  void didUpdateWidget(Toolbar oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 当外部状态变化时同步本地状态
    if (oldWidget.scaleFactor != widget.scaleFactor) {
      _localScaleFactor = widget.scaleFactor;
    }
    if (oldWidget.columnCount != widget.columnCount) {
      _localColumnCount = widget.columnCount;
    }
  }

  void _handleScaleAdjust(double delta) {
    setState(() {
      _localScaleFactor = (_localScaleFactor + delta).clamp(50.0, 200.0);
    });
    widget.onButtonPressed();
    widget.onAdjustScale(delta);
  }

  void _handleColumnCountAdjust(int delta) {
    setState(() {
      _localColumnCount = (_localColumnCount + delta).clamp(1, 5);
    });
    widget.onButtonPressed();
    widget.onAdjustColumnCount(delta);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final onSurface = colorScheme.onSurface;
    final onSurfaceVariant = colorScheme.onSurfaceVariant;
    final errorColor = colorScheme.error;
    
    return MouseRegion(
      onEnter: (_) => widget.onMouseEnter(),
      onExit: (_) => widget.onMouseExit(),
      child: Opacity(
        opacity: widget.opacity,
        child: CustomSplitButton<String>(
          size: SplitButtonM3ESize.sm,
          shape: SplitButtonM3EShape.round,
          emphasis: SplitButtonM3EEmphasis.tonal,
          leadingIcon: Icons.add,
          onPressed: () {
            widget.onButtonPressed();
            widget.onNewHomework();
          },
          leadingTooltip: '新建作业',
          trailingTooltip: '快捷菜单',
          menuBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
            // 更多选项
            PopupMenuItem<String>(
              value: 'more_options',
              padding: const EdgeInsets.symmetric(vertical: 4),
              height: 44,
              onTap: widget.onOpenMoreOptions,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Icon(Icons.more_horiz, size: 18, color: onSurface),
                    SizedBox(width: 12),
                    Text('更多选项...', style: TextStyle(fontSize: 14, color: onSurface)),
                  ],
                ),
              ),
            ),
            PopupMenuDivider(height: 1),
            // 窗口控制标题
            PopupMenuItem<String>(
              enabled: false,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              height: 32,
              child: Text(
                '窗口控制',
                style: TextStyle(
                  fontSize: 11,
                  color: onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            // 全屏、锁定/解锁 和 收起 放在同一行
            PopupMenuItem<String>(
              enabled: false,
              padding: EdgeInsets.zero,
              height: 44,
              child: Row(
                children: [
                  // 全屏/退出全屏
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        Navigator.of(context).pop();
                        widget.onToggleFullScreen();
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            Icon(
                              widget.isFullScreen ? Icons.fullscreen_exit : Icons.fullscreen,
                              size: 18,
                              color: onSurface,
                            ),
                            SizedBox(width: 8),
                            Text(
                              widget.isFullScreen ? '退出全屏' : '全屏',
                              style: TextStyle(
                                fontSize: 14,
                                color: onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // 锁定/解锁
                  Expanded(
                    child: InkWell(
                      onTap: widget.isFullScreen ? null : () {
                        Navigator.of(context).pop();
                        widget.onToggleWindowLock();
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            Icon(
                              (widget.isFullScreen ? widget.windowLockedBeforeFullScreen : widget.isWindowLocked) ? Icons.lock_open : Icons.lock,
                              size: 18,
                              color: widget.isFullScreen 
                                  ? onSurfaceVariant.withOpacity(0.4)
                                  : onSurface,
                            ),
                            SizedBox(width: 8),
                            Text(
                              (widget.isFullScreen ? widget.windowLockedBeforeFullScreen : widget.isWindowLocked) ? '解锁' : '锁定',
                              style: TextStyle(
                                fontSize: 14,
                                color: widget.isFullScreen 
                                    ? onSurfaceVariant.withOpacity(0.4)
                                    : onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // 收起
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        Navigator.of(context).pop();
                        // TODO: 实现收起功能
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            Icon(
                              Icons.picture_in_picture_alt,
                              size: 18,
                              color: onSurface,
                            ),
                            SizedBox(width: 8),
                            Text(
                              '收起',
                              style: TextStyle(
                                fontSize: 14,
                                color: onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuDivider(height: 1),
            // 编辑选项标题
            PopupMenuItem<String>(
              enabled: false,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              height: 32,
              child: Text(
                '编辑...',
                style: TextStyle(
                  fontSize: 11,
                  color: onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            // 科目 和 标签 放在同一行
            PopupMenuItem<String>(
              enabled: false,
              padding: EdgeInsets.zero,
              height: 44,
              child: Row(
                children: [
                  // 科目
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        Navigator.of(context).pop();
                        widget.onShowSubjectManager();
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            Icon(
                              Icons.subject,
                              size: 18,
                              color: onSurface,
                            ),
                            SizedBox(width: 8),
                            Text(
                              '科目',
                              style: TextStyle(
                                fontSize: 14,
                                color: onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // 标签
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        Navigator.of(context).pop();
                        widget.onShowTagManager();
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            Icon(
                              Icons.label,
                              size: 18,
                              color: onSurface,
                            ),
                            SizedBox(width: 8),
                            Text(
                              '标签',
                              style: TextStyle(
                                fontSize: 14,
                                color: onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuDivider(height: 1),
            // 界面设置标题
            PopupMenuItem<String>(
              enabled: false,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              height: 32,
              child: Text(
                '界面设置',
                style: TextStyle(
                  fontSize: 11,
                  color: onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            // 界面缩放
            PopupMenuItem<String>(
              enabled: false,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              height: 44,
              child: StatefulBuilder(
                builder: (context, setMenuState) {
                  final canDecrease = _localScaleFactor > 50.0;
                  final canIncrease = _localScaleFactor < 200.0;
                  return Row(
                    children: [
                      Text(
                        '界面缩放',
                        style: TextStyle(
                          fontSize: 12,
                          color: onSurface,
                        ),
                      ),
                      const Spacer(),
                      InkWell(
                        onTap: canDecrease ? () {
                          setMenuState(() {
                            _localScaleFactor = (_localScaleFactor - 10).clamp(50.0, 200.0);
                          });
                          _handleScaleAdjust(-10);
                        } : null,
                        borderRadius: BorderRadius.circular(20),
                        child: Padding(
                          padding: const EdgeInsets.all(6.0),
                          child: Icon(
                            Icons.remove,
                            size: 16,
                            color: canDecrease 
                                ? onSurface
                                : onSurfaceVariant.withOpacity(0.4),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 50,
                        child: Text(
                          '${_localScaleFactor.toInt()}%',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: onSurface,
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: canIncrease ? () {
                          setMenuState(() {
                            _localScaleFactor = (_localScaleFactor + 10).clamp(50.0, 200.0);
                          });
                          _handleScaleAdjust(10);
                        } : null,
                        borderRadius: BorderRadius.circular(20),
                        child: Padding(
                          padding: const EdgeInsets.all(6.0),
                          child: Icon(
                            Icons.add,
                            size: 16,
                            color: canIncrease 
                                ? onSurface
                                : onSurfaceVariant.withOpacity(0.4),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            // 作业列数
            PopupMenuItem<String>(
              enabled: false,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              height: 44,
              child: StatefulBuilder(
                builder: (context, setMenuState) {
                  final canDecrease = _localColumnCount > 1;
                  final canIncrease = _localColumnCount < 5;
                  return Row(
                    children: [
                      Text(
                        '作业列数',
                        style: TextStyle(
                          fontSize: 12,
                          color: onSurface,
                        ),
                      ),
                      const Spacer(),
                      InkWell(
                        onTap: canDecrease ? () {
                          setMenuState(() {
                            _localColumnCount = (_localColumnCount - 1).clamp(1, 5);
                          });
                          _handleColumnCountAdjust(-1);
                        } : null,
                        borderRadius: BorderRadius.circular(20),
                        child: Padding(
                          padding: const EdgeInsets.all(6.0),
                          child: Icon(
                            Icons.remove,
                            size: 16,
                            color: canDecrease 
                                ? onSurface
                                : onSurfaceVariant.withOpacity(0.4),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 50,
                        child: Text(
                          '$_localColumnCount 列',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: onSurface,
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: canIncrease ? () {
                          setMenuState(() {
                            _localColumnCount = (_localColumnCount + 1).clamp(1, 5);
                          });
                          _handleColumnCountAdjust(1);
                        } : null,
                        borderRadius: BorderRadius.circular(20),
                        child: Padding(
                          padding: const EdgeInsets.all(6.0),
                          child: Icon(
                            Icons.add,
                            size: 16,
                            color: canIncrease 
                                ? onSurface
                                : onSurfaceVariant.withOpacity(0.4),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            PopupMenuDivider(height: 1),
            // 退出
            PopupMenuItem<String>(
              value: 'exit',
              padding: const EdgeInsets.symmetric(vertical: 4),
              height: 44,
              onTap: widget.onExitApplication,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Icon(Icons.exit_to_app, size: 18, color: errorColor),
                    SizedBox(width: 12),
                    Text('退出...', style: TextStyle(fontSize: 14, color: errorColor)),
                  ],
                ),
              ),
            ),
          ],
          onSelected: (value) {
            widget.onButtonPressed();
            // 打开菜单时同步本地状态
            setState(() {
              _localScaleFactor = widget.scaleFactor;
              _localColumnCount = widget.columnCount;
            });
          },
        ),
      ),
    );
  }
}
