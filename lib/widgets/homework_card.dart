import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:intl/intl.dart';
import 'package:loggy/loggy.dart';
import '../models/homework.dart';
import '../services/settings_service.dart';
import '../services/storage/json_storage_service.dart';

class HomeworkCard extends StatefulWidget {
  final Homework homework;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final double scaleFactor;

  const HomeworkCard({
    super.key,
    required this.homework,
    required this.isSelected,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    this.scaleFactor = 100.0,
  });

  @override
  State<HomeworkCard> createState() => _HomeworkCardState();
}

class _HomeworkCardState extends State<HomeworkCard> {
  late QuillController _contentController;
  double _backgroundOpacity = 0.95;

  @override
  void initState() {
    super.initState();
    _contentController = QuillController.basic();
    _loadSettings();
    if (widget.homework.content.isNotEmpty) {
      try {
        // 尝试解析JSON格式的富文本内容
        final deltaJson = jsonDecode(widget.homework.content);
        _contentController.document = Document.fromJson(deltaJson);
        logDebug('作业卡片: 成功解析富文本内容');
      } catch (e) {
        // 如果解析失败，说明是旧的纯文本格式，直接插入
        logWarning('作业卡片: 富文本解析失败，使用纯文本格式: $e');
        _contentController.document = Document()
          ..insert(0, widget.homework.content);
      }
    }
  }

  void _loadSettings() {
    final settingsService = SettingsService.instance;
    setState(() {
      _backgroundOpacity = settingsService.getBackgroundOpacity();
    });
  }

  Color _getCardBackgroundColor(ColorScheme colorScheme) {
    Color baseColor;

    if (widget.isSelected) {
      baseColor = colorScheme.primaryContainer;
    } else {
      baseColor = colorScheme.surface;
    }

    // 卡片始终跟随背景半透明度，但略高一些
    double cardOpacity = (_backgroundOpacity + 0.15).clamp(0.0, 1.0);
    return baseColor.withValues(alpha: cardOpacity);
  }

  @override
  void didUpdateWidget(HomeworkCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.homework.content != widget.homework.content) {
      if (widget.homework.content.isNotEmpty) {
        try {
          // 尝试解析JSON格式的富文本内容
          final deltaJson = jsonDecode(widget.homework.content);
          _contentController.document = Document.fromJson(deltaJson);
          logDebug('作业卡片更新: 成功解析富文本内容');
        } catch (e) {
          // 如果解析失败，直接插入
          logWarning('作业卡片更新: 富文本解析失败，使用纯文本格式: $e');
          _contentController.document = Document()
            ..insert(0, widget.homework.content);
        }
      } else {
        _contentController.document = Document();
      }
    }
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  // 判断作业是否已过期
  bool _isOverdue() {
    return DateTime.now().isAfter(widget.homework.dueDate);
  }

  // 获取格式化的截止时间
  String _getFormattedDate() {
    final dueDate = widget.homework.dueDate;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final dayAfterTomorrow = today.add(const Duration(days: 2));
    final dueDay = DateTime(dueDate.year, dueDate.month, dueDate.day);

    final timeFormat = DateFormat('HH:mm');
    final timeStr = timeFormat.format(dueDate);

    if (dueDay == today) {
      return '今天 $timeStr';
    } else if (dueDay == tomorrow) {
      return '明天 $timeStr';
    } else if (dueDay == dayAfterTomorrow) {
      return '后天 $timeStr';
    } else {
      final dateFormat = DateFormat('MM月dd日');
      return '${dateFormat.format(dueDate)} $timeStr';
    }
  }

  // 获取状态标签
  Widget? _getStatusTag() {
    // 移除上交时间相关标签
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textColor = colorScheme.onSurface;
    final s = widget.scaleFactor / 100.0;

    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        margin: EdgeInsets.symmetric(vertical: 8.0 * s),
        padding: EdgeInsets.all(16 * s), // MD3 间距
        decoration: BoxDecoration(
          color: _getCardBackgroundColor(colorScheme),
          borderRadius: BorderRadius.circular(12 * s), // 与快捷菜单保持一致的圆角
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 富文本作业内容
            widget.homework.content.isNotEmpty
                ? GestureDetector(
                    onTap: widget.onTap,
                    child: IgnorePointer(
                      child: QuillEditor.basic(
                        controller: _contentController,
                        config: QuillEditorConfig(
                          padding: EdgeInsets.zero,
                          scrollable: false,
                          customStyles: DefaultStyles(
                            paragraph: DefaultTextBlockStyle(
                              TextStyle(
                                fontSize: 20,
                                color: textColor,
                                fontFamily: 'HarmonyOS Sans SC',
                              ),
                              const HorizontalSpacing(0, 0),
                              const VerticalSpacing(0, 0),
                              const VerticalSpacing(0, 0),
                              null,
                            ),
                          ),
                        ),
                      ),
                    ),
                  )
                : GestureDetector(
                    onTap: widget.onTap,
                    child: Text(
                      '暂无内容',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
            SizedBox(height: 8 * s),

            // 截止日期和标签
            Wrap(
              spacing: 8 * s,
              runSpacing: 6 * s,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                // 截止日期
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 16 * s,
                      color: _isOverdue()
                          ? colorScheme.error
                          : colorScheme.onSurfaceVariant,
                    ),
                    SizedBox(width: 6 * s),
                    Text(
                      _getFormattedDate(),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: _isOverdue()
                            ? colorScheme.error
                            : colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),

                // 状态标签
                if (_getStatusTag() != null) _getStatusTag()!,

                // 作业标签
                ...JsonStorageService.instance
                    .getTagNamesByUuids(widget.homework.tagUuids)
                    .map(
                      (tagName) => Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8 * s,
                          vertical: 4 * s,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.secondaryContainer,
                          borderRadius: BorderRadius.circular(8 * s),
                        ),
                        child: Text(
                          tagName,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSecondaryContainer,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
              ],
            ),

            // 编辑和删除按钮
            if (widget.isSelected) ...[
              SizedBox(height: 12 * s),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    // 改为填充样式的按钮
                    icon: Icon(Icons.edit, size: 18 * s),
                    onPressed: widget.onEdit,
                    tooltip: '编辑',
                    style: IconButton.styleFrom(
                      foregroundColor: colorScheme.primary,
                      backgroundColor: colorScheme.primaryContainer.withAlpha(
                        77,
                      ),
                      padding: EdgeInsets.all(8 * s),
                      minimumSize: Size(36 * s, 36 * s),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8 * s),
                      ),
                    ),
                  ),
                  SizedBox(width: 8 * s),
                  IconButton(
                    // 改为填充样式的按钮
                    icon: Icon(Icons.delete, size: 18 * s),
                    onPressed: widget.onDelete,
                    tooltip: '删除',
                    style: IconButton.styleFrom(
                      foregroundColor: colorScheme.error,
                      backgroundColor: colorScheme.errorContainer.withAlpha(77),
                      padding: EdgeInsets.all(8 * s),
                      minimumSize: Size(36 * s, 36 * s),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8 * s),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
