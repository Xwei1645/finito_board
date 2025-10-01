import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:intl/intl.dart';
import '../models/homework.dart';

class HomeworkCard extends StatefulWidget {
  final Homework homework;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const HomeworkCard({
    super.key,
    required this.homework,
    required this.isSelected,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<HomeworkCard> createState() => _HomeworkCardState();
}

class _HomeworkCardState extends State<HomeworkCard> {
  late QuillController _contentController;
  late FocusNode _editorFocusNode;

  @override
  void initState() {
    super.initState();
    _contentController = QuillController.basic();
    _contentController.readOnly = true;
    _editorFocusNode = FocusNode();
    if (widget.homework.content.isNotEmpty) {
      try {
        // 尝试解析JSON格式的富文本内容
        final deltaJson = jsonDecode(widget.homework.content);
        _contentController.document = Document.fromJson(deltaJson);
      } catch (e) {
        // 如果解析失败，说明是旧的纯文本格式，直接插入
        _contentController.document = Document()..insert(0, widget.homework.content);
      }
    }
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
        } catch (e) {
          // 如果解析失败，说明是旧的纯文本格式，直接插入
          _contentController.document = Document()..insert(0, widget.homework.content);
        }
      } else {
        _contentController.document = Document();
      }
    }
  }

  @override
  void dispose() {
    _contentController.dispose();
    _editorFocusNode.dispose();
    super.dispose();
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
    
    return GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(16), // MD3 间距
          decoration: BoxDecoration(
            color: widget.isSelected 
                ? Colors.grey.shade100
                : Colors.white,
            borderRadius: BorderRadius.circular(12), // 与快捷菜单保持一致的圆角
            boxShadow: [
              BoxShadow(
                color: widget.isSelected 
                    ? Colors.grey.withValues(alpha: 0.3) 
                    : Colors.black.withValues(alpha: 0.08),
                spreadRadius: widget.isSelected ? 2 : 1,
                blurRadius: widget.isSelected ? 12 : 6,
                offset: Offset(0, widget.isSelected ? 4 : 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 富文本作业内容
              widget.homework.content.isNotEmpty
                  ? GestureDetector(
                      onTap: widget.onTap,
                      child: QuillEditor.basic(
                        controller: _contentController,
                        config: const QuillEditorConfig(
                          showCursor: false,
                          padding: EdgeInsets.zero,
                        ),
                        focusNode: _editorFocusNode,
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
              const SizedBox(height: 12),
              
              // 截止日期和标签
              Wrap(
                spacing: 8,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  // 截止日期
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 16,
                        color: widget.homework.isOverdue 
                            ? colorScheme.error 
                            : colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _getFormattedDate(),
                        style: theme.textTheme.bodySmall?.copyWith(
                        color: widget.homework.isOverdue 
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
                  ...widget.homework.tags.map((tag) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      tag,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSecondaryContainer,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  )),
                ],
              ),
              
              // 编辑和删除按钮
              if (widget.isSelected) ...[
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton( // 改为填充样式的按钮
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      onPressed: widget.onEdit,
                      tooltip: '编辑',
                      style: IconButton.styleFrom(
                        foregroundColor: colorScheme.primary,
                        backgroundColor: colorScheme.primaryContainer.withValues(alpha: 0.3),
                        padding: const EdgeInsets.all(8),
                        minimumSize: const Size(36, 36),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton( // 改为填充样式的按钮
                      icon: const Icon(Icons.delete_outline, size: 18),
                      onPressed: widget.onDelete,
                      tooltip: '删除',
                      style: IconButton.styleFrom(
                        foregroundColor: colorScheme.error,
                        backgroundColor: colorScheme.errorContainer.withValues(alpha: 0.3),
                        padding: const EdgeInsets.all(8),
                        minimumSize: const Size(36, 36),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
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