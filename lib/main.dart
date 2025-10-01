import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:window_manager/window_manager.dart';
import 'models/subject.dart';
import 'models/homework.dart';
import 'widgets/homework_card.dart';
import 'widgets/subject_header.dart';
import 'widgets/homework_editor.dart';
import 'widgets/empty_state.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 只在桌面平台初始化窗口管理器
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    await windowManager.ensureInitialized();
    
    WindowOptions windowOptions = const WindowOptions(
      size: Size(1200, 800),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: true,
      titleBarStyle: TitleBarStyle.hidden, // 隐藏标题栏
      windowButtonVisibility: false, // 隐藏窗口按钮
    );
    
    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
      // 确保移除所有系统装饰
      await windowManager.setAsFrameless();
      await windowManager.setHasShadow(false);
    });
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Finito Board',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
        fontFamily: 'HarmonyOS Sans SC',
      ),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        FlutterQuillLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', 'US'),
        Locale('zh', 'CN'),
      ],
      home: const MainWindow(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MainWindow extends StatelessWidget {
  const MainWindow({super.key});

  @override
  Widget build(BuildContext context) {
    return const HomeworkBoard();
  }
}

class HomeworkBoard extends StatefulWidget {
  const HomeworkBoard({super.key});

  @override
  State<HomeworkBoard> createState() => _HomeworkBoardState();
}

class _HomeworkBoardState extends State<HomeworkBoard> {
  List<Subject> subjects = SampleData.getSubjects();

  String? _selectedHomeworkId; // 当前选中的作业ID
  Timer? _selectionTimer; // 10秒自动取消选择的定时器

  @override
  void initState() {
    super.initState();
    _distributeHomeworksToColumns();
  }

  @override
  void dispose() {
    _selectionTimer?.cancel();
    super.dispose();
  }

  void _selectHomework(String homeworkId) {
    setState(() {
      _selectedHomeworkId = homeworkId;
    });
    
    // 取消之前的定时器
    _selectionTimer?.cancel();
    
    // 设置10秒后自动取消选择
    _selectionTimer = Timer(const Duration(seconds: 10), () {
      setState(() {
        _selectedHomeworkId = null;
      });
    });
  }

  // 显示自定义样式的SnackBar，避免挡住工具栏
  void _showCustomSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(
          left: 200,
          right: 200,
          bottom: 16,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  void _onEditHomework(String homeworkId) {
    // 查找要编辑的作业
    Homework? homeworkToEdit;
    for (var subject in subjects) {
      for (var homework in subject.homeworks) {
        if (homework.id == homeworkId) {
          homeworkToEdit = homework;
          break;
        }
      }
      if (homeworkToEdit != null) break;
    }

    if (homeworkToEdit != null) {
      _showHomeworkEditor(homeworkToEdit);
    }
  }

  void _onDeleteHomework(String homeworkId) {
    setState(() {
      for (var subject in subjects) {
        subject.homeworks.removeWhere((homework) => homework.id == homeworkId);
      }
      // 移除没有作业的学科
      subjects.removeWhere((subject) => subject.homeworks.isEmpty);
    });
    
    _showCustomSnackBar('作业已删除');
  }

  void _showHomeworkEditor([Homework? homework]) {
    showDialog(
      context: context,
      builder: (context) => HomeworkEditor(
        homework: homework,
        onSave: _saveHomework,
        onCancel: () => Navigator.of(context).pop(),
      ),
    );
  }

  void _saveHomework(Homework homework) {
    // 查找是否已存在该作业（编辑模式）
    bool found = false;
    
    setState(() {
      for (var subject in subjects) {
        for (int i = 0; i < subject.homeworks.length; i++) {
          if (subject.homeworks[i].id == homework.id) {
            subject.homeworks[i] = homework;
            found = true;
            break;
          }
        }
        if (found) break;
      }

      // 如果没找到，说明是新建作业
      if (!found) {
        // 查找对应学科，如果不存在则创建
        Subject? targetSubject;
        for (var subject in subjects) {
          if (subject.name == homework.subject) {
            targetSubject = subject;
            break;
          }
        }

        if (targetSubject != null) {
          targetSubject.homeworks.add(homework);
        } else {
          // 创建新学科
          subjects.add(Subject(
            name: homework.subject,
            homeworks: [homework],
          ));
        }
      }
    });

    Navigator.of(context).pop();
    _showCustomSnackBar(found ? '作业已更新' : '作业已创建');
  }



  // 将所有作业分配到三列中 - 改进的分配逻辑
  List<List<Widget>> _distributeHomeworksToColumns() {
    List<List<Widget>> columns = [[], [], []];
    int currentColumn = 0;
    
    // 为每个学科创建标题和作业卡片，保持在同一列
    for (var subject in subjects) {
      if (subject.homeworks.isNotEmpty) {
        // 添加学科标题到当前列
        columns[currentColumn].add(
          SubjectHeader(
            subjectName: subject.name,
            homeworkCount: subject.homeworks.length,
          ),
        );
        
        // 添加该学科的所有作业到同一列
        for (var homework in subject.homeworks) {
          columns[currentColumn].add(
            HomeworkCard(
              homework: homework,
              isSelected: _selectedHomeworkId == homework.id,
              onTap: () => _selectHomework(homework.id),
              onEdit: () => _onEditHomework(homework.id),
              onDelete: () => _onDeleteHomework(homework.id),
            ),
          );
        }
        
        // 移动到下一列
        currentColumn = (currentColumn + 1) % 3;
      }
    }
    
    return columns;
  }

  @override
  Widget build(BuildContext context) {
    final columns = _distributeHomeworksToColumns();
    
    // 检查是否有作业
    final hasHomework = subjects.any((subject) => subject.homeworks.isNotEmpty);
    
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // 背景容器 - 填满整个窗口
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(12),
            ),
            child: hasHomework
                ? SingleChildScrollView(
                    padding: const EdgeInsets.all(12),
                    child: IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: Column(
                                children: columns[0],
                              ),
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 6),
                              child: Column(
                                children: columns[1],
                              ),
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(left: 6),
                              child: Column(
                                children: columns[2],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : const EmptyState(),
          ),
          // 悬浮工具栏 - 吸附在窗口右下角边缘
          Positioned(
            bottom: 16,
            right: 16,
            child: _buildFloatingToolbar(),
          ),
        ],
      ),
    );
  }

  // 构建悬浮工具栏
  Widget _buildFloatingToolbar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildToolbarButton(
            icon: Icons.add,
            onPressed: () => _showHomeworkEditor(),
            tooltip: '新建',
          ),
          const SizedBox(width: 4),
          _buildToolbarButton(
            icon: Icons.settings,
            onPressed: () {
              // TODO: 实现设置功能
              _showCustomSnackBar('设置功能待实现');
            },
            tooltip: '设置',
          ),
          const SizedBox(width: 4),
          _buildToolbarButton(
            icon: Icons.menu,
            onPressed: () {
              // TODO: 实现菜单功能
              _showCustomSnackBar('菜单功能待实现');
            },
            tooltip: '菜单',
          ),
        ],
      ),
    );
  }

  // 构建工具栏按钮
  Widget _buildToolbarButton({
    required IconData icon,
    required VoidCallback onPressed,
    required String tooltip,
  }) {
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
              color: Colors.grey[600],
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}
