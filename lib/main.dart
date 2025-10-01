import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:window_manager/window_manager.dart';
import 'package:launch_at_startup/launch_at_startup.dart';
import 'package:win32/win32.dart' as win32;
import 'models/subject.dart';
import 'models/homework.dart';
import 'widgets/homework_card.dart';
import 'widgets/subject_header.dart';
import 'widgets/homework_editor.dart';
import 'widgets/empty_state.dart';
import 'widgets/settings_window.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    await windowManager.ensureInitialized();
    
    // 初始化开机自启功能
    launchAtStartup.setup(
      appName: "FinitoBoard",
      appPath: Platform.resolvedExecutable,
      packageName: 'dev.xwei1645.finitoboard',
    );
    
    WindowOptions windowOptions = const WindowOptions(
      size: Size(1200, 800),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: true,
      titleBarStyle: TitleBarStyle.hidden,
      windowButtonVisibility: false,
    );
    
    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
      // 初始状态设置为锁定（无边框，不可调整大小）
      await windowManager.setAsFrameless();
      await windowManager.setHasShadow(false);
      await windowManager.setResizable(false);
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

  String? _selectedHomeworkId;
  Timer? _selectionTimer;
  
  // 界面缩放倍数（百分比）
  double _scaleFactor = 100.0;
  
  // 作业列数
  int _columnCount = 3;
  
  // 快捷菜单显示状态
  bool _isQuickMenuVisible = false;
  
  // 全屏状态
  bool _isFullScreen = false;
  
  // 窗口锁定状态
  bool _isWindowLocked = true;
  
  // 拖动状态
  bool _isDragging = false;
  
  // 开机自启状态
  bool _isAutoStart = false;
  
  // 窗口置底状态
  bool _isAlwaysOnBottom = false;
  
  // 窗口置底维持定时器
  Timer? _alwaysOnBottomTimer;

  @override
  void initState() {
    super.initState();
    _distributeHomeworksToColumns();
    _checkAutoStartStatus();
  }
  
  // 检查开机自启状态
  void _checkAutoStartStatus() async {
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      try {
        bool isEnabled = await launchAtStartup.isEnabled();
        setState(() {
          _isAutoStart = isEnabled;
        });
      } catch (e) {
        // 如果检查失败，默认为false
        setState(() {
          _isAutoStart = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _selectionTimer?.cancel();
    _stopAlwaysOnBottomTimer();
    super.dispose();
  }

  void _selectHomework(String homeworkId) {
    setState(() {
      _selectedHomeworkId = homeworkId;
    });
    
    _selectionTimer?.cancel();
    
    _selectionTimer = Timer(const Duration(seconds: 10), () {
      setState(() {
        _selectedHomeworkId = null;
      });
    });
  }

  void _showCustomSnackBar(String message) {
    // 先清除当前显示的SnackBar，实现覆盖效果
    ScaffoldMessenger.of(context).clearSnackBars();
    
    // 显示新的SnackBar
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

  void _toggleFullScreen() async {
    setState(() {
      _isFullScreen = !_isFullScreen;
    });
    
    if (_isFullScreen) {
      await windowManager.setFullScreen(true);
      _showCustomSnackBar('已进入全屏模式');
    } else {
      await windowManager.setFullScreen(false);
      _showCustomSnackBar('已退出全屏模式');
    }
  }

  // 切换窗口锁定状态
  void _toggleWindowLock() async {
    setState(() {
      _isWindowLocked = !_isWindowLocked;
    });
    
    if (_isWindowLocked) {
      // 锁定窗口 - 设置为无边框并禁用调整大小
      await windowManager.setAsFrameless();
      await windowManager.setResizable(false);
      _showCustomSnackBar('窗口已锁定');
    } else {
      // 解锁窗口 - 恢复边框但隐藏标题栏，允许调整大小
      await windowManager.setTitleBarStyle(TitleBarStyle.hidden);
      await windowManager.setResizable(true);
      // 确保窗口不是全屏状态，这样边缘才能拖拽
      if (_isFullScreen) {
        await windowManager.setFullScreen(false);
        setState(() {
          _isFullScreen = false;
        });
      }
      _showCustomSnackBar('窗口已解锁，可调整大小或按住底部操纵杆拖动窗口');
    }
  }

  // 开始拖动窗口
  void _startDragWindow() async {
    if (!_isWindowLocked) {
      setState(() {
        _isDragging = true;
      });
      await windowManager.startDragging();
      setState(() {
        _isDragging = false;
      });
    }
  }



  void _onEditHomework(String homeworkId) {
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



  // 将所有作业分配到动态列数中 - 改进的分配逻辑
  List<List<Widget>> _distributeHomeworksToColumns() {
    List<List<Widget>> columns = List.generate(_columnCount, (index) => <Widget>[]);
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
        currentColumn = (currentColumn + 1) % _columnCount;
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
      body: GestureDetector(
        onTap: () {
          setState(() {
            // 隐藏快捷菜单
            if (_isQuickMenuVisible) {
              _isQuickMenuVisible = false;
            }
            // 取消选中卡片
            if (_selectedHomeworkId != null) {
              _selectedHomeworkId = null;
              _selectionTimer?.cancel(); // 取消定时器
            }
          });
        },
        child: Stack(
          children: [
          // 背景容器 - 填满整个窗口
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              color: _isFullScreen 
                  ? Colors.white 
                  : Colors.white.withValues(alpha: 0.92),
              borderRadius: _isFullScreen 
                  ? BorderRadius.zero 
                  : BorderRadius.circular(12),
            ),
            child: hasHomework
                ? Theme(
                    data: Theme.of(context).copyWith(
                      textTheme: Theme.of(context).textTheme.apply(
                        fontSizeFactor: _scaleFactor / 100.0,
                      ),
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(12),
                      child: IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: List.generate(_columnCount, (index) {
                            EdgeInsets padding;
                            if (_columnCount == 1) {
                              padding = EdgeInsets.zero;
                            } else if (index == 0) {
                              padding = const EdgeInsets.only(right: 6);
                            } else if (index == _columnCount - 1) {
                              padding = const EdgeInsets.only(left: 6);
                            } else {
                              padding = const EdgeInsets.symmetric(horizontal: 6);
                            }
                            
                            return Expanded(
                              child: Padding(
                                padding: padding,
                                child: Column(
                                  children: index < columns.length ? columns[index] : [],
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                    ),
                  )
                : Theme(
                    data: Theme.of(context).copyWith(
                      textTheme: Theme.of(context).textTheme.apply(
                        fontSizeFactor: _scaleFactor / 100.0,
                      ),
                    ),
                    child: const EmptyState(),
                  ),
          ),
          // 底部拖动条 - 仅在窗口解锁时显示
          if (!_isWindowLocked && !_isFullScreen)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildDragBar(),
            ),
          // 悬浮工具栏 - 吸附在窗口右下角边缘
          Positioned(
            bottom: 16,
            right: 16,
            child: _buildFloatingToolbar(),
          ),
          // 快捷菜单
          if (_isQuickMenuVisible)
            Positioned(
              bottom: 70,
              right: 16,
              child: _buildQuickMenu(),
            ),
        ],
        ),
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
            icon: _isFullScreen ? Icons.fullscreen_exit : Icons.fullscreen,
            onPressed: _toggleFullScreen,
            tooltip: _isFullScreen ? '退出全屏' : '全屏',
          ),
          const SizedBox(width: 4),
          _buildToolbarButton(
            icon: Icons.menu,
            onPressed: _toggleQuickMenu,
            tooltip: '快捷菜单',
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

  // 构建快捷菜单
  Widget _buildQuickMenu() {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 更多选项
          _buildMenuButton(
            icon: Icons.more_horiz,
            text: '更多选项...',
            onPressed: _openSettingsWindow,
          ),
          const SizedBox(height: 12),
          // 窗口控制
          _buildMenuSection(
            title: '窗口控制',
            child: Row(
              children: [
                Expanded(
                  child: _buildMenuButton(
                    icon: _isWindowLocked ? Icons.lock_open : Icons.lock,
                    text: _isWindowLocked ? '解锁' : '锁定',
                    onPressed: _toggleWindowLock,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMenuButton(
                    icon: Icons.picture_in_picture_alt,
                    text: '收起',
                    onPressed: () {
                      // TODO: 实现收起功能
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // 编辑选项
          _buildMenuSection(
            title: '编辑...',
            child: Row(
              children: [
                Expanded(
                  child: _buildMenuButton(
                    icon: Icons.subject,
                    text: '科目',
                    onPressed: () {
                      // TODO: 实现科目编辑功能
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMenuButton(
                    icon: Icons.label,
                    text: '标签',
                    onPressed: () {
                      // TODO: 实现标签编辑功能
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // 界面设置
          _buildMenuSection(
            title: '界面设置',
            child: Column(
              children: [
              // 界面缩放
              Row(
                children: [
                  Text(
                    '界面缩放',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[700],
                    ),
                  ),
                  const Spacer(),
                  _buildScaleButton(
                    icon: Icons.remove,
                    onPressed: () => _adjustScale(-10),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 50,
                    child: Text(
                      '${_scaleFactor.toInt()}%',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildScaleButton(
                    icon: Icons.add,
                    onPressed: () => _adjustScale(10),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // 作业列数
              Row(
                children: [
                  Text(
                    '作业列数',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[700],
                    ),
                  ),
                  const Spacer(),
                  _buildScaleButton(
                    icon: Icons.remove,
                    onPressed: () => _adjustColumnCount(-1),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 50,
                    child: Text(
                      '$_columnCount 列',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildScaleButton(
                    icon: Icons.add,
                    onPressed: () => _adjustColumnCount(1),
                  ),
                ],
              ),
            ],
            ),
          ),
          const SizedBox(height: 12),
          // 退出选项
          _buildMenuButton(
            icon: Icons.exit_to_app,
            text: '退出...',
            onPressed: _exitApplication,
            isDestructive: true,
          ),
        ],
      ),
    );
  }

  // 构建菜单区块
  Widget _buildMenuSection({
    required String title,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[700],
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }

  // 构建菜单按钮
  Widget _buildMenuButton({
    required IconData icon,
    required String text,
    required VoidCallback onPressed,
    bool isDestructive = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isDestructive ? Colors.red[50] : Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 18,
                color: isDestructive ? Colors.red[600] : Colors.grey[700],
              ),
              const SizedBox(width: 8),
              Text(
                text,
                style: TextStyle(
                  fontSize: 14,
                  color: isDestructive ? Colors.red[700] : Colors.grey[800],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 构建缩放按钮
  Widget _buildScaleButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            icon,
            size: 16,
            color: Colors.grey[700],
          ),
        ),
      ),
    );
  }

  // 调整界面缩放
  void _adjustScale(double delta) {
    setState(() {
      _scaleFactor = (_scaleFactor + delta).clamp(50.0, 200.0);
    });
  }

  // 调整作业列数
  void _adjustColumnCount(int delta) {
    setState(() {
      _columnCount = (_columnCount + delta).clamp(1, 5);
    });
  }

  // 切换快捷菜单显示状态
  void _toggleQuickMenu() {
    setState(() {
      _isQuickMenuVisible = !_isQuickMenuVisible;
    });
  }

  // 切换窗口置底状态
  void _toggleAlwaysOnBottom() async {
    if (!Platform.isWindows) {
      _showCustomSnackBar('窗口置底功能仅支持Windows系统');
      return;
    }
    
    setState(() {
      _isAlwaysOnBottom = !_isAlwaysOnBottom;
    });
    
    if (_isAlwaysOnBottom) {
      _startAlwaysOnBottomTimer();
      _showCustomSnackBar('窗口已置底');
    } else {
      _stopAlwaysOnBottomTimer();
      _showCustomSnackBar('已取消窗口置底');
    }
  }
  
  // 开始窗口置底定时器
  void _startAlwaysOnBottomTimer() {
    _stopAlwaysOnBottomTimer(); // 确保之前的定时器被清理
    
    // 立即执行一次
    _setWindowToBottom();
    
    // 每500毫秒检查一次并维持窗口在底层
    _alwaysOnBottomTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (_isAlwaysOnBottom) {
        _setWindowToBottom();
      } else {
        timer.cancel();
      }
    });
  }
  
  // 停止窗口置底定时器
  void _stopAlwaysOnBottomTimer() {
    _alwaysOnBottomTimer?.cancel();
    _alwaysOnBottomTimer = null;
    
    // 恢复窗口到正常层级
    if (Platform.isWindows) {
      try {
        final hwnd = win32.GetActiveWindow();
        if (hwnd != 0) {
          win32.SetWindowPos(
            hwnd,
            win32.HWND_NOTOPMOST,
            0, 0, 0, 0,
            win32.SWP_NOMOVE | win32.SWP_NOSIZE | win32.SWP_NOACTIVATE,
          );
        }
      } catch (e) {
        // 忽略错误
      }
    }
  }
  
  // 设置窗口到底层
  void _setWindowToBottom() {
    if (!Platform.isWindows) return;
    
    try {
      final hwnd = win32.GetActiveWindow();
      if (hwnd != 0) {
        win32.SetWindowPos(
          hwnd,
          win32.HWND_BOTTOM,
          0, 0, 0, 0,
          win32.SWP_NOMOVE | win32.SWP_NOSIZE | win32.SWP_NOACTIVATE,
        );
      }
    } catch (e) {
      // 忽略错误，避免频繁显示错误消息
    }
  }

  // 打开设置窗口
  void _openSettingsWindow() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SettingsWindow(
          isAlwaysOnBottom: _isAlwaysOnBottom,
          isAutoStart: _isAutoStart,
          onAlwaysOnBottomChanged: (value) {
            setState(() {
              _isAlwaysOnBottom = value;
            });
            _toggleAlwaysOnBottom();
          },
          onAutoStartChanged: (value) {
            setState(() {
              _isAutoStart = value;
            });
            _toggleAutoStart();
          },
        ),
      ),
    );
  }

  // 切换开机自启状态
  void _toggleAutoStart() async {
    try {
      if (_isAutoStart) {
        // 禁用开机自启
        await launchAtStartup.disable();
        setState(() {
          _isAutoStart = false;
        });
        _showCustomSnackBar('已取消开机自启');
      } else {
        // 启用开机自启
        await launchAtStartup.enable();
        setState(() {
          _isAutoStart = true;
        });
        _showCustomSnackBar('已设置开机自启');
      }
    } catch (e) {
      _showCustomSnackBar('设置开机自启失败: $e');
    }
  }

  // 退出应用
  void _exitApplication() {
    // 显示确认对话框
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('确认退出'),
          content: const Text('确定要退出应用程序吗？'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // 退出应用
                windowManager.close();
              },
              child: Text(
                '退出',
                style: TextStyle(color: Colors.red[600]),
              ),
            ),
          ],
        );
      },
    );
  }

  // 构建底部拖动条
  Widget _buildDragBar() {
    return GestureDetector(
      onPanStart: (_) {
        _startDragWindow();
      },
      child: Container(
        height: 16, // 减小容器高度，为snackbar留出空间
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.transparent,
        ),
        child: Center(
          child: Container(
            width: 150,
            height: 4,
            decoration: BoxDecoration(
              color: _isDragging
                  ? Colors.grey[600] // 拖动时变暗
                  : Colors.grey[400], // 正常状态
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      ),
    );
  }

}
