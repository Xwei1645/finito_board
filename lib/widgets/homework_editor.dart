import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:intl/intl.dart';
import '../models/homework.dart';

class HomeworkEditor extends StatefulWidget {
  final Homework? homework; // null表示新建，非null表示编辑
  final String? initialSubject; // 新建时的默认学科
  final Function(Homework) onSave;
  final VoidCallback onCancel;

  const HomeworkEditor({
    super.key,
    this.homework,
    this.initialSubject,
    required this.onSave,
    required this.onCancel,
  });

  @override
  State<HomeworkEditor> createState() => _HomeworkEditorState();
}

class _HomeworkEditorState extends State<HomeworkEditor> {
  late QuillController _contentController;
  late FocusNode _editorFocusNode;
  late String _selectedSubject;
  late DateTime _selectedDate;
  late List<String> _selectedTags;
  final TextEditingController _newTagController = TextEditingController();
  final TextEditingController _fontSizeController = TextEditingController();
  double _currentFontSize = 20.0;
  
  // 格式状态
  bool _isBold = false;
  bool _isItalic = false;
  bool _isStrikethrough = false;

  // 可选学科列表
  static const List<String> _availableSubjects = [
    '数学', '英语', '物理', '化学', '计算机科学', '生物', '历史', '地理', '政治', '语文'
  ];

  // 预定义标签
  static const List<String> _predefinedTags = [
    '重要', '紧急', '简单', '困难', '小组作业', '个人作业', 
    '实验', '报告', '演示', '考试', '复习', '预习'
  ];

  @override
  void initState() {
    super.initState();
    
    _contentController = QuillController.basic();
    _editorFocusNode = FocusNode();
    _selectedSubject = widget.homework?.subject ?? widget.initialSubject ?? _availableSubjects.first;
    _fontSizeController.text = _currentFontSize.toInt().toString();
    
    _contentController.addListener(_updateFontSizeDisplay);
    
    if (widget.homework != null && widget.homework!.content.isNotEmpty) {
      try {
        // 尝试解析JSON格式的富文本内容
        final deltaJson = jsonDecode(widget.homework!.content);
        _contentController.document = Document.fromJson(deltaJson);
      } catch (e) {
        // 如果解析失败，说明是旧的纯文本格式，直接插入
        _contentController.document = Document()..insert(0, widget.homework!.content);
      }
    }
    
    _selectedDate = widget.homework?.dueDate ?? DateTime.now().add(const Duration(days: 1));
    _selectedTags = List.from(widget.homework?.tags ?? []);
  }

  @override
  void dispose() {
    _contentController.dispose();
    _editorFocusNode.dispose();
    _newTagController.dispose();
    _fontSizeController.dispose();
    super.dispose();
  }

  void _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('zh', 'CN'),
    );
    
    if (picked != null && mounted) {
      setState(() {
        _selectedDate = DateTime(
          picked.year,
          picked.month,
          picked.day,
          0, // 设置为0点
          0, // 设置为0分
        );
      });
    }
  }

  void _addTag(String tag) {
    if (tag.isNotEmpty && !_selectedTags.contains(tag)) {
      setState(() {
        _selectedTags.add(tag);
      });
    }
  }

  void _removeTag(String tag) {
    setState(() {
      _selectedTags.remove(tag);
    });
  }

  void _addNewTag() {
    final newTag = _newTagController.text.trim();
    if (newTag.isNotEmpty) {
      _addTag(newTag);
      _newTagController.clear();
    }
  }

  void _increaseFontSize() {
    setState(() {
      _currentFontSize = (_currentFontSize + 1).clamp(8.0, 72.0);
      _fontSizeController.text = _currentFontSize.toInt().toString();
    });
    _applyFontSize();
  }

  void _decreaseFontSize() {
    setState(() {
      _currentFontSize = (_currentFontSize - 1).clamp(8.0, 72.0);
      _fontSizeController.text = _currentFontSize.toInt().toString();
    });
    _applyFontSize();
  }

  void _onFontSizeChanged(String value) {
    final fontSize = double.tryParse(value);
    if (fontSize != null && fontSize >= 8 && fontSize <= 72) {
      setState(() {
        _currentFontSize = fontSize;
      });
      _applyFontSize();
    }
  }

  void _applyFontSize() {
    final selection = _contentController.selection;
    if (selection.isValid) {
      // 保存当前选择状态
      final currentSelection = _contentController.selection;
      
      _contentController.formatSelection(SizeAttribute(_currentFontSize.toString()));
      
      // 恢复选择状态和焦点
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _contentController.updateSelection(currentSelection, ChangeSource.local);
        _editorFocusNode.requestFocus();
      });
    }
  }

  void _updateFontSizeDisplay() {
    final selection = _contentController.selection;
    if (!selection.isValid) return;
    
    // 获取当前选择位置的样式
    final style = _contentController.getSelectionStyle();
    
    // 更新字号
    final sizeAttribute = style.attributes[Attribute.size.key];
    double newFontSize = _currentFontSize;
    if (sizeAttribute != null && sizeAttribute.value != null) {
      final fontSize = double.tryParse(sizeAttribute.value.toString());
      if (fontSize != null) {
        newFontSize = fontSize;
      }
    }
    
    // 简化格式状态检测逻辑
    bool newIsBold = false;
    bool newIsItalic = false;
    bool newIsStrikethrough = false;
    
    if (selection.isCollapsed) {
      // 光标位置，直接检查当前样式
      newIsBold = style.attributes.containsKey(Attribute.bold.key);
      newIsItalic = style.attributes.containsKey(Attribute.italic.key);
      newIsStrikethrough = style.attributes.containsKey(Attribute.strikeThrough.key);
    } else {
      // 有选择范围，检查选择范围的格式一致性
      final document = _contentController.document;
      bool allBold = true;
      bool allItalic = true;
      bool allStrikethrough = true;
      
      // 检查选择范围内是否所有字符都有相同的格式
      for (int i = selection.start; i < selection.end && i < document.length; i++) {
        final charStyle = document.collectStyle(i, 1);
        
        if (!charStyle.attributes.containsKey(Attribute.bold.key)) {
          allBold = false;
        }
        if (!charStyle.attributes.containsKey(Attribute.italic.key)) {
          allItalic = false;
        }
        if (!charStyle.attributes.containsKey(Attribute.strikeThrough.key)) {
          allStrikethrough = false;
        }
      }
      
      newIsBold = allBold;
      newIsItalic = allItalic;
      newIsStrikethrough = allStrikethrough;
    }
    
    // 只有状态发生变化时才更新UI
    if (newFontSize != _currentFontSize || 
        newIsBold != _isBold || 
        newIsItalic != _isItalic || 
        newIsStrikethrough != _isStrikethrough) {
      setState(() {
        _currentFontSize = newFontSize;
        _fontSizeController.text = _currentFontSize.toInt().toString();
        _isBold = newIsBold;
        _isItalic = newIsItalic;
        _isStrikethrough = newIsStrikethrough;
      });
    }
  }

  void _save() {
    // 保存富文本格式的JSON数据
    final content = jsonEncode(_contentController.document.toDelta().toJson());
    
    final homework = Homework(
      id: widget.homework?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      content: content,
      dueDate: _selectedDate,
      subject: _selectedSubject,
      tags: _selectedTags,
      createdAt: widget.homework?.createdAt ?? DateTime.now(),
    );

    widget.onSave(homework);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)), // MD3 圆角
      child: Container(
        width: 700,
        height: 750,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题栏
            Row(
              children: [
                Text(
                  widget.homework == null ? '新建作业' : '编辑作业',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurface,
                  ),
                ),
                const Spacer(),
                IconButton.outlined(
                  icon: const Icon(Icons.close),
                  onPressed: widget.onCancel,
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedSubject,
                    decoration: InputDecoration(
                      labelText: '学科',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12), // MD3 圆角
                      ),
                      filled: true,
                      fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    items: _availableSubjects.map((subject) => DropdownMenuItem(
                      value: subject,
                      child: Text(subject),
                    )).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedSubject = value;
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(width: 16),
                
                Expanded(
                  flex: 3,
                  child: OutlinedButton.icon(
                    onPressed: _selectDate,
                    icon: Icon(Icons.calendar_today_outlined, 
                      color: colorScheme.primary,
                    ),
                    label: Text(
                      DateFormat('yyyy年MM月dd日').format(_selectedDate),
                      style: TextStyle(color: colorScheme.onSurface),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: BorderSide(color: colorScheme.outline),
                      backgroundColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                      minimumSize: const Size(0, 48),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // 标签选择
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('标签', 
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                
                // 已选标签
                if (_selectedTags.isNotEmpty) ...[
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _selectedTags.map((tag) => Chip(
                      label: Text(tag, style: TextStyle(
                        fontSize: 13,
                        color: colorScheme.onSecondaryContainer,
                      )),
                      onDeleted: () => _removeTag(tag),
                      deleteIcon: Icon(Icons.close, 
                        size: 16, 
                        color: colorScheme.onSecondaryContainer,
                      ),
                      backgroundColor: colorScheme.secondaryContainer,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8), // MD3 圆角
                      ),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    )).toList(),
                  ),
                  const SizedBox(height: 12),
                ],
                
                // 预定义标签 + 新建标签按钮
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    // 预定义标签
                    ..._predefinedTags
                        .where((tag) => !_selectedTags.contains(tag))
                        .map((tag) => ActionChip(
                              label: Text(tag, style: TextStyle(
                                fontSize: 13,
                                color: colorScheme.onSurfaceVariant,
                              )),
                              onPressed: () => _addTag(tag),
                              backgroundColor: colorScheme.surfaceContainerHighest,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8), // MD3 圆角
                              ),
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            )),
                    
                    // 新建标签
                    ActionChip(
                      label: Icon(Icons.add, 
                        size: 18, 
                        color: colorScheme.primary,
                      ),
                      onPressed: () => _showAddTagDialog(),
                      backgroundColor: colorScheme.primaryContainer,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8), // MD3 圆角
                      ),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // 富文本编辑
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text('内容', 
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurface,
                  ),
                ),
                const Spacer(),
                // 富文本工具栏 - 分为两个独立的容器
                Row(
                  children: [
                    // 加粗按钮
                    Container(
                      decoration: BoxDecoration(
                        color: _isBold 
                          ? colorScheme.primaryContainer 
                          : colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: _isBold 
                            ? colorScheme.primary 
                            : colorScheme.outline.withValues(alpha: 0.2)
                        ),
                      ),
                      child: IconButton(
                        icon: Icon(
                          Icons.format_bold,
                          color: _isBold ? colorScheme.primary : null,
                        ),
                        iconSize: 18,
                        onPressed: () {
                          // 保存当前选择状态
                          final currentSelection = _contentController.selection;
                          
                          // 直接切换状态，然后应用格式
                          final newBoldState = !_isBold;
                          setState(() {
                            _isBold = newBoldState;
                          });
                          
                          // 应用或移除格式
                          if (newBoldState) {
                            _contentController.formatSelection(Attribute.bold);
                          } else {
                            _contentController.formatSelection(Attribute.clone(Attribute.bold, null));
                          }
                          
                          // 恢复选择状态和焦点
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            _contentController.updateSelection(currentSelection, ChangeSource.local);
                            _editorFocusNode.requestFocus();
                          });
                        },
                        style: IconButton.styleFrom(
                          minimumSize: const Size(32, 32),
                          padding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    // 斜体按钮
                    Container(
                      decoration: BoxDecoration(
                        color: _isItalic 
                          ? colorScheme.primaryContainer 
                          : colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: _isItalic 
                            ? colorScheme.primary 
                            : colorScheme.outline.withValues(alpha: 0.2)
                        ),
                      ),
                      child: IconButton(
                        icon: Icon(
                          Icons.format_italic,
                          color: _isItalic ? colorScheme.primary : null,
                        ),
                        iconSize: 18,
                        onPressed: () {
                          // 保存当前选择状态
                          final currentSelection = _contentController.selection;
                          
                          // 直接切换状态，然后应用格式
                          final newItalicState = !_isItalic;
                          setState(() {
                            _isItalic = newItalicState;
                          });
                          
                          // 应用或移除格式
                          if (newItalicState) {
                            _contentController.formatSelection(Attribute.italic);
                          } else {
                            _contentController.formatSelection(Attribute.clone(Attribute.italic, null));
                          }
                          
                          // 恢复选择状态和焦点
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            _contentController.updateSelection(currentSelection, ChangeSource.local);
                            _editorFocusNode.requestFocus();
                          });
                        },
                        style: IconButton.styleFrom(
                          minimumSize: const Size(32, 32),
                          padding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    // 删除线按钮
                    Container(
                      decoration: BoxDecoration(
                        color: _isStrikethrough 
                          ? colorScheme.primaryContainer 
                          : colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: _isStrikethrough 
                            ? colorScheme.primary 
                            : colorScheme.outline.withValues(alpha: 0.2)
                        ),
                      ),
                      child: IconButton(
                        icon: Icon(
                          Icons.format_strikethrough,
                          color: _isStrikethrough ? colorScheme.primary : null,
                        ),
                        iconSize: 18,
                        onPressed: () {
                          // 保存当前选择状态
                          final currentSelection = _contentController.selection;
                          
                          // 直接切换状态，然后应用格式
                          final newStrikethroughState = !_isStrikethrough;
                          setState(() {
                            _isStrikethrough = newStrikethroughState;
                          });
                          
                          // 应用或移除格式
                          if (newStrikethroughState) {
                            _contentController.formatSelection(Attribute.strikeThrough);
                          } else {
                            _contentController.formatSelection(Attribute.clone(Attribute.strikeThrough, null));
                          }
                          
                          // 恢复选择状态和焦点
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            _contentController.updateSelection(currentSelection, ChangeSource.local);
                            _editorFocusNode.requestFocus();
                          });
                        },
                        style: IconButton.styleFrom(
                          minimumSize: const Size(32, 32),
                          padding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // 减小字号按钮
                    Container(
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.text_decrease),
                        iconSize: 18,
                        onPressed: _decreaseFontSize,
                        style: IconButton.styleFrom(
                          minimumSize: const Size(32, 32),
                          padding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    // 字号输入框
                    Container(
                      width: 50,
                      height: 32,
                      decoration: BoxDecoration(
                        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.3)),
                        borderRadius: BorderRadius.circular(6),
                        color: colorScheme.surface,
                      ),
                      child: Center(
                        child: TextField(
                          controller: _fontSizeController,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: colorScheme.onSurface,
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                            isDense: true,
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: _onFontSizeChanged,
                          onSubmitted: _onFontSizeChanged,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    // 增大字号按钮
                    Container(
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.text_increase),
                        iconSize: 18,
                        onPressed: _increaseFontSize,
                        style: IconButton.styleFrom(
                          minimumSize: const Size(32, 32),
                          padding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: colorScheme.outline),
                  borderRadius: BorderRadius.circular(12), // MD3 圆角
                  color: colorScheme.surface,
                ),
                child: QuillEditor.basic(
                   controller: _contentController,
                   focusNode: _editorFocusNode,
                   config: QuillEditorConfig(
                     padding: const EdgeInsets.all(16),
                     autoFocus: false,
                     showCursor: true,
                     placeholder: '请输入作业内容...',
                   ),
                 ),
              ),
            ),
            const SizedBox(height: 24),
            
            // 操作按钮 - MD3 风格
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: widget.onCancel,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20), // MD3 圆角
                    ),
                  ),
                  child: const Text('取消'),
                ),
                const SizedBox(width: 12),
                FilledButton( // MD3 FilledButton
                  onPressed: _save,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20), // MD3 圆角
                    ),
                  ),
                  child: const Text('保存'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAddTagDialog() {
    showDialog(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;
        
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)), // MD3 圆角
          title: Text('添加新标签', 
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          content: TextField(
            controller: _newTagController,
            decoration: InputDecoration(
              hintText: '输入标签名称',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12), // MD3 圆角
              ),
              filled: true,
              fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            ),
            autofocus: true,
            onSubmitted: (_) {
              _addNewTag();
              Navigator.of(context).pop();
            },
          ),
          actions: [
            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20), // MD3 圆角
                ),
              ),
              child: const Text('取消'),
            ),
            FilledButton( // MD3 FilledButton
              onPressed: () {
                _addNewTag();
                Navigator.of(context).pop();
              },
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20), // MD3 圆角
                ),
              ),
              child: const Text('添加'),
            ),
          ],
        );
      },
    );
  }
}