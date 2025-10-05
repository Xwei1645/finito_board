import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/subject.dart';
import '../services/storage/hive_storage_service.dart';

class SubjectManager extends StatefulWidget {
  final VoidCallback? onSubjectsChanged;

  const SubjectManager({
    super.key,
    this.onSubjectsChanged,
  });

  @override
  State<SubjectManager> createState() => _SubjectManagerState();
}

class _SubjectManagerState extends State<SubjectManager> {
  late List<Subject> _subjects;
  final TextEditingController _newSubjectController = TextEditingController();
  final TextEditingController _editSubjectController = TextEditingController();
  String? _editingSubjectUuid;

  @override
  void initState() {
    super.initState();
    _loadSubjects();
  }

  void _loadSubjects() {
    _subjects = HiveStorageService.instance.getAllSubjects();
  }

  @override
  void dispose() {
    _newSubjectController.dispose();
    _editSubjectController.dispose();
    super.dispose();
  }

  void _addSubject() async {
    final newSubjectName = _newSubjectController.text.trim();
    if (newSubjectName.isNotEmpty && !_subjects.any((s) => s.name == newSubjectName)) {
      final newSubject = Subject(
        uuid: const Uuid().v4(),
        name: newSubjectName,
      );
      
      await HiveStorageService.instance.saveSubject(newSubject);
      
      setState(() {
        _loadSubjects();
      });
      _newSubjectController.clear();
      widget.onSubjectsChanged?.call();
    }
  }

  void _deleteSubject(Subject subject) async {
    await HiveStorageService.instance.deleteSubject(subject.uuid);
    setState(() {
      _loadSubjects();
    });
    widget.onSubjectsChanged?.call();
  }

  void _startEditSubject(Subject subject) {
    setState(() {
      _editingSubjectUuid = subject.uuid;
      _editSubjectController.text = subject.name;
    });
  }

  void _saveEditSubject() async {
    final newName = _editSubjectController.text.trim();
    if (newName.isNotEmpty && _editingSubjectUuid != null) {
      final subject = _subjects.firstWhere((s) => s.uuid == _editingSubjectUuid);
      final updatedSubject = Subject(
        uuid: subject.uuid,
        name: newName,
      );
      
      await HiveStorageService.instance.saveSubject(updatedSubject);
      
      setState(() {
        _loadSubjects();
        _editingSubjectUuid = null;
      });
      _editSubjectController.clear();
      widget.onSubjectsChanged?.call();
    }
  }

  void _cancelEdit() {
    setState(() {
      _editingSubjectUuid = null;
    });
    _editSubjectController.clear();
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
        width: 400,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题
            Row(
              children: [
                Icon(
                  Icons.subject,
                  color: colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  '科目管理',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 添加新科目
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
                    '添加新科目',
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
                          controller: _newSubjectController,
                          decoration: InputDecoration(
                            hintText: '输入科目名称',
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
                          onSubmitted: (_) => _addSubject(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        height: 48, // 与文本框高度一致
                        width: 48,
                        child: ElevatedButton(
                          onPressed: _addSubject,
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

            // 现有科目列表
            Text(
              '现有科目',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            
            Container(
              constraints: const BoxConstraints(maxHeight: 300),
              child: _subjects.isEmpty
                  ? Container(
                      padding: const EdgeInsets.all(32),
                      child: Center(
                        child: Text(
                          '暂无科目',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: _subjects.length,
                      itemBuilder: (context, index) {
                        final subject = _subjects[index];
                        final isEditing = _editingSubjectUuid == subject.uuid;
                        
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: colorScheme.surface,

                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: isEditing
                              ? Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: _editSubjectController,
                                        decoration: InputDecoration(
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          contentPadding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                        ),
                                        onSubmitted: (_) => _saveEditSubject(),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      onPressed: _saveEditSubject,
                                      icon: const Icon(Icons.check, size: 20),
                                      style: IconButton.styleFrom(
                                        backgroundColor: colorScheme.primary,
                                        foregroundColor: colorScheme.onPrimary,
                                        minimumSize: const Size(32, 32),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    IconButton(
                                      onPressed: _cancelEdit,
                                      icon: const Icon(Icons.close, size: 20),
                                      style: IconButton.styleFrom(
                                        backgroundColor: colorScheme.surfaceContainerHighest,
                                        minimumSize: const Size(32, 32),
                                      ),
                                    ),
                                  ],
                                )
                              : Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                   subject.name,
                                   style: theme.textTheme.bodyLarge?.copyWith(
                                     color: colorScheme.onSurfaceVariant,
                                     fontWeight: FontWeight.w500,
                                   ),
                                 ),
                                    ),
                                    IconButton(
                                      onPressed: () => _startEditSubject(subject),
                                      icon: const Icon(Icons.edit, size: 18),
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
                                    IconButton(
                                      onPressed: () => _deleteSubject(subject),
                                      icon: const Icon(Icons.delete, size: 18),
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
                        );
                      },
                    ),
            ),
            const SizedBox(height: 24),

            // 底部按钮
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
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