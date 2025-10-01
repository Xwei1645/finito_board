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
    // 初始化QuillController来显示富文本内容
    _contentController = QuillController.basic();
    _contentController.readOnly = true; // 设置为只读模式
    _editorFocusNode = FocusNode(); // 初始化 FocusNode
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
    // 如果作业内容发生变化，更新QuillController
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
    _editorFocusNode.dispose(); // 释放 FocusNode
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
                    ? QuillEditor.basic(
                        controller: _contentController,
                        config: const QuillEditorConfig(
                          showCursor: false, // 不显示光标
                          padding: EdgeInsets.zero, // 移除内边距
                        ),
                        focusNode: _editorFocusNode, // 添加 FocusNode
                      )
                    : Text(
                        '暂无内容',
                        style: TextStyle(
                          fontSize: 15,
                          color: colorScheme.onSurfaceVariant,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
              ),
              const SizedBox(height: 12),
              
              // 截止日期
              Row(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 16,
                    color: widget.homework.isOverdue 
                        ? colorScheme.error 
                        : colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _getFormattedDate(),
                    style: TextStyle(
                      fontSize: 14,
                      color: widget.homework.isOverdue 
                          ? colorScheme.error 
                          : colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
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
                      style: TextStyle(
                        fontSize: 11,
                        color: colorScheme.onSecondaryContainer,
                        fontWeight: FontWeight.w500,
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
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      onPressed: widget.onEdit,
                      tooltip: '编辑',
                      style: IconButton.styleFrom(
                        foregroundColor: colorScheme.primary,
                        side: BorderSide(color: colorScheme.outline),
                        padding: const EdgeInsets.all(8),
                        minimumSize: const Size(36, 36),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.outlined( // MD3 outlined icon button
                      icon: const Icon(Icons.delete_outline, size: 18),
                      onPressed: widget.onDelete,
                      tooltip: '删除',
                      style: IconButton.styleFrom(
                        foregroundColor: colorScheme.error,
                        side: BorderSide(color: colorScheme.outline),
                        padding: const EdgeInsets.all(8),
                        minimumSize: const Size(36, 36),
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