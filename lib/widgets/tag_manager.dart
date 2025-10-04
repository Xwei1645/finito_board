import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/tag.dart';
import '../services/storage/hive_storage_service.dart';

class TagManager extends StatefulWidget {
  final VoidCallback? onTagsChanged;

  const TagManager({
    super.key,
    this.onTagsChanged,
  });

  @override
  State<TagManager> createState() => _TagManagerState();
}

class _TagManagerState extends State<TagManager> {
  late List<Tag> _tags;
  final TextEditingController _newTagController = TextEditingController();
  final TextEditingController _editTagController = TextEditingController();
  String? _editingTagUuid;

  @override
  void initState() {
    super.initState();
    _loadTags();
  }

  void _loadTags() {
    _tags = HiveStorageService.instance.getAllTags();
  }

  @override
  void dispose() {
    _newTagController.dispose();
    _editTagController.dispose();
    super.dispose();
  }

  void _addTag() async {
    final newTagName = _newTagController.text.trim();
    if (newTagName.isNotEmpty && !_tags.any((t) => t.name == newTagName)) {
      final newTag = Tag(
        uuid: const Uuid().v4(),
        name: newTagName,
      );
      
      await HiveStorageService.instance.saveTag(newTag);
      
      setState(() {
        _loadTags();
      });
      _newTagController.clear();
      widget.onTagsChanged?.call();
    }
  }

  void _deleteTag(Tag tag) async {
    await HiveStorageService.instance.deleteTag(tag.uuid);
    setState(() {
      _loadTags();
    });
    widget.onTagsChanged?.call();
  }

  void _startEditTag(Tag tag) {
    setState(() {
      _editingTagUuid = tag.uuid;
      _editTagController.text = tag.name;
    });
  }

  void _saveEditTag() async {
    final newName = _editTagController.text.trim();
    if (newName.isNotEmpty && _editingTagUuid != null) {
      final tag = _tags.firstWhere((t) => t.uuid == _editingTagUuid);
      final updatedTag = Tag(
        uuid: tag.uuid,
        name: newName,
      );
      
      await HiveStorageService.instance.saveTag(updatedTag);
      
      setState(() {
        _loadTags();
        _editingTagUuid = null;
      });
      _editTagController.clear();
      widget.onTagsChanged?.call();
    }
  }

  void _cancelEdit() {
    setState(() {
      _editingTagUuid = null;
    });
    _editTagController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: 450,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题
            Row(
              children: [
                Icon(
                  Icons.label,
                  color: colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  '标签管理',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 添加新标签
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '添加常用标签',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _newTagController,
                          decoration: InputDecoration(
                            hintText: '输入标签名称',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: colorScheme.outline),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: colorScheme.primary, width: 2),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                          onSubmitted: (_) => _addTag(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        height: 48, // 与文本框高度一致
                        width: 48,
                        child: ElevatedButton(
                          onPressed: _addTag,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.primary,
                            foregroundColor: colorScheme.onPrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: EdgeInsets.zero,
                          ),
                          child: const Icon(Icons.add),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 现有标签列表
            Text(
              '现有标签',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            
            Container(
              constraints: const BoxConstraints(maxHeight: 350),
              child: _tags.isEmpty
                  ? Container(
                      padding: const EdgeInsets.all(32),
                      child: Center(
                        child: Text(
                          '暂无标签',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    )
                  : SingleChildScrollView(
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _tags.map((tag) {
                          final isEditing = _editingTagUuid == tag.uuid;
                          
                          if (isEditing) {
                            return Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: colorScheme.surface,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(
                                    width: 100,
                                    child: TextField(
                                      controller: _editTagController,
                                      decoration: InputDecoration(
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        contentPadding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        isDense: true,
                                      ),
                                      style: theme.textTheme.bodySmall,
                                      onSubmitted: (_) => _saveEditTag(),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  GestureDetector(
                                    onTap: _saveEditTag,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: colorScheme.primary,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Icon(
                                        Icons.check,
                                        size: 16,
                                        color: colorScheme.onPrimary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 2),
                                  GestureDetector(
                                    onTap: _cancelEdit,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: colorScheme.surfaceContainerHighest,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Icon(
                                        Icons.close,
                                        size: 16,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }
                          
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  tag.name,
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    color: colorScheme.onPrimaryContainer,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                GestureDetector(
                                  onTap: () => _startEditTag(tag),
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: BoxDecoration(
                                      color: colorScheme.onPrimaryContainer.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                    child: Icon(
                                      Icons.edit_outlined,
                                      size: 14,
                                      color: colorScheme.onPrimaryContainer,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 2),
                                GestureDetector(
                                  onTap: () => _deleteTag(tag),
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: BoxDecoration(
                                      color: colorScheme.errorContainer,
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                    child: Icon(
                                      Icons.close_outlined,
                                      size: 14,
                                      color: colorScheme.onErrorContainer,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
            ),
            const SizedBox(height: 24),

            // 底部按钮
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('关闭'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}