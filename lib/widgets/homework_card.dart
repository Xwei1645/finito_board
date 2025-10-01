import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
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

  // 获取格式化的月/日
  String _getFormattedDate() {
    final date = widget.homework.dueDate;
    return '${date.month}/${date.day}';
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
    final textScaleFactor = MediaQuery.textScalerOf(context).scale(1.0);
    
    return GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(16), // MD3 间距
          decoration: BoxDecoration(
            color: widget.isSelected 
                ? colorScheme.primaryContainer.withValues(alpha: 0.3)
                : colorScheme.surface,
            borderRadius: BorderRadius.circular(16), // MD3 圆角
            border: widget.isSelected 
                ? Border.all(color: colorScheme.primary, width: 2)
                : Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
            boxShadow: [
              BoxShadow(
                color: widget.isSelected 
                    ? colorScheme.primary.withValues(alpha: 0.1) 
                    : colorScheme.shadow.withValues(alpha: 0.05),
                spreadRadius: widget.isSelected ? 1 : 0,
                blurRadius: widget.isSelected ? 8 : 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 富文本作业内容
              Container(
                constraints: const BoxConstraints(
                  maxHeight: 120, // 限制最大高度，避免卡片过高
                ),
                child: widget.homework.content.isNotEmpty
                    ? Theme(
                        data: theme.copyWith(
                          textTheme: theme.textTheme.apply(
                            fontSizeFactor: textScaleFactor,
                          ),
                        ),
                        child: QuillEditor.basic(
                          controller: _contentController,
                          config: const QuillEditorConfig(
                            showCursor: false,
                            padding: EdgeInsets.zero,
                          ),
                          focusNode: _editorFocusNode,
                        ),
                      )
                    : Text(
                        '暂无内容',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontStyle: FontStyle.italic,
                          fontSize: (theme.textTheme.bodyMedium?.fontSize ?? 14) * textScaleFactor,
                        ),
                      ),
              ),
              const SizedBox(height: 12),
              
              // 截止日期
              Row(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 16 * textScaleFactor,
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
                      fontSize: (theme.textTheme.bodySmall?.fontSize ?? 12) * textScaleFactor,
                    ),
                  ),
                ],
              ),
              
              // 状态标签
              if (_getStatusTag() != null) ...[
                const SizedBox(height: 8),
                _getStatusTag()!,
              ],
              
              // 作业标签
              if (widget.homework.tags.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: widget.homework.tags.map((tag) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: colorScheme.outline.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Text(
                      tag,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSecondaryContainer,
                        fontWeight: FontWeight.w500,
                        fontSize: (theme.textTheme.labelSmall?.fontSize ?? 11) * textScaleFactor,
                      ),
                    ),
                  )).toList(),
                ),
              ],
              
              // 编辑和删除按钮
              if (widget.isSelected) ...[
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton.outlined( // MD3 outlined icon button
                      icon: Icon(Icons.edit_outlined, size: 18 * textScaleFactor),
                      onPressed: widget.onEdit,
                      tooltip: '编辑',
                      style: IconButton.styleFrom(
                        foregroundColor: colorScheme.primary,
                        side: BorderSide(color: colorScheme.outline),
                        padding: const EdgeInsets.all(8),
                        minimumSize: Size(36 * textScaleFactor, 36 * textScaleFactor),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.outlined( // MD3 outlined icon button
                      icon: Icon(Icons.delete_outline, size: 18 * textScaleFactor),
                      onPressed: widget.onDelete,
                      tooltip: '删除',
                      style: IconButton.styleFrom(
                        foregroundColor: colorScheme.error,
                        side: BorderSide(color: colorScheme.outline),
                        padding: const EdgeInsets.all(8),
                        minimumSize: Size(36 * textScaleFactor, 36 * textScaleFactor),
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