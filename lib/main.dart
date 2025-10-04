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
import 'widgets/settings.dart';
import 'widgets/subject_manager.dart';
import 'widgets/tag_manager.dart';
import 'services/settings_service.dart';
import 'services/storage/hive_storage_service.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 初始化Hive存储服务
  await HiveStorageService.instance.init();
  
  // 初始化设置服务
  await SettingsService.instance.initialize();
  
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    await windowManager.ensureInitialized();
    
    // 尝试恢复窗口状态
    final savedWindowState = SettingsService.instance.getWindowState();
    final windowSize = savedWindowState != null 
        ? Size(savedWindowState.width, savedWindowState.height)
        : const Size(1200, 800);
    
    WindowOptions windowOptions = WindowOptions(
      size: windowSize,
      center: savedWindowState == null,
      backgroundColor: Colors.transparent,
      skipTaskbar: true,
      titleBarStyle: TitleBarStyle.hidden,
      windowButtonVisibility: false,
    );
    
    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
      
      // 恢复窗口状态
      if (savedWindowState != null) {
        await SettingsService.instance.restoreWindowState();
      }
      
      // 初始状态设置为锁定（无边框，不可调整大小）
      await windowManager.setAsFrameless();
      await windowManager.setHasShadow(false);
      await windowManager.setResizable(false);
    });
  }
  
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _loadThemeSettings();
  }

  Future<void> _loadThemeSettings() async {
    final settingsService = SettingsService.instance;
    final isDarkMode = settingsService.getDarkMode();
    
    setState(() {
      _isDarkMode = isDarkMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Finito Board',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        fontFamily: 'HarmonyOS Sans SC',
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        fontFamily: 'HarmonyOS Sans SC',
      ),
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
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
      home: MainWindow(onThemeChanged: _loadThemeSettings),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MainWindow extends StatelessWidget {
  final VoidCallback? onThemeChanged;
  
  const MainWindow({super.key, this.onThemeChanged});

  @override
  Widget build(BuildContext context) {
    return HomeworkBoard(onThemeChanged: onThemeChanged);
  }
}

class HomeworkBoard extends StatefulWidget {
  final VoidCallback? onThemeChanged;
  
  const HomeworkBoard({super.key, this.onThemeChanged});

  @override
  State<HomeworkBoard> createState() => _HomeworkBoardState();
}

class _HomeworkBoardState extends State<HomeworkBoard> with WindowListener {
  List<Subject> subjects = [];

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
  
  // 背景不透明度
  double _backgroundOpacity = 1.0;
  


  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    _loadDataFromHive();
    _loadBackgroundSettings();
  }

  Future<void> _loadDataFromHive() async {
    final storageService = HiveStorageService.instance;
    final homeworks = storageService.getAllHomework();
    
    // 加载界面设置
    final appConfig = storageService.getAppConfig();
    
    // 按科目分组作业
    Map<String, List<Homework>> homeworksBySubject = {};
    for (var homework in homeworks) {
      if (!homeworksBySubject.containsKey(homework.subject)) {
        homeworksBySubject[homework.subject] = [];
      }
      homeworksBySubject[homework.subject]!.add(homework);
    }
    
    // 创建Subject对象
    List<Subject> loadedSubjects = [];
    for (var entry in homeworksBySubject.entries) {
      loadedSubjects.add(Subject(
        name: entry.key,
        homeworks: entry.value,
      ));
    }
    
    setState(() {
      subjects = loadedSubjects;
      // 从存储中恢复界面设置
      _scaleFactor = appConfig.scaleFactor;
      _columnCount = appConfig.columnCount;
    });
    
    _distributeHomeworksToColumns();
  }
  
  void _loadBackgroundSettings() {
    final settingsService = SettingsService.instance;
    setState(() {
      _backgroundOpacity = settingsService.getBackgroundOpacity();
    });
  }
  
  @override
  void dispose() {
    windowManager.removeListener(this);
    _selectionTimer?.cancel();
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

  Future<void> _onDeleteHomework(String homeworkId) async {
    final storageService = HiveStorageService.instance;
    
    // 从Hive中删除作业
    await storageService.deleteHomework(homeworkId);
    
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

  Future<void> _saveHomework(Homework homework) async {
    final storageService = HiveStorageService.instance;
    
    // 查找是否已存在该作业（编辑模式）
    bool found = false;
    
    // 检查是否为编辑模式
    try {
      final existingHomework = storageService.getHomeworkById(homework.id);
      if (existingHomework != null) {
        found = true;
      }
    } catch (e) {
      // 作业不存在，是新建模式
      found = false;
    }
    
    // 保存到Hive
    await storageService.saveHomework(homework);
    
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

    if (mounted && context.mounted) {
      Navigator.of(context).pop();
    }
    if (mounted) {
      _showCustomSnackBar(found ? '作业已更新' : '作业已创建');
    }
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
              key: ValueKey('${homework.id}_$_backgroundOpacity'),
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
      body: Stack(
        children: [
          // 背景容器 - 填满整个窗口
          GestureDetector(
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
            child: Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                color: _isFullScreen 
                    ? Theme.of(context).colorScheme.surface
                    : Theme.of(context).colorScheme.surface.withValues(alpha: _backgroundOpacity),
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
    );
  }

  // 构建悬浮工具栏
  Widget _buildFloatingToolbar() {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.15),
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
            onPressed: () {
              _showHomeworkEditor();
            },
            tooltip: '新建',
          ),
          const SizedBox(width: 4),
          _buildToolbarButton(
            icon: _isFullScreen ? Icons.fullscreen_exit : Icons.fullscreen,
            onPressed: () {
              _toggleFullScreen();
            },
            tooltip: _isFullScreen ? '退出全屏' : '全屏',
          ),
          const SizedBox(width: 4),
          _buildToolbarButton(
            icon: Icons.menu,
            onPressed: () {
              _toggleQuickMenu();
            },
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
    final colorScheme = Theme.of(context).colorScheme;
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
              color: colorScheme.onSurface.withValues(alpha: 0.7),
              size: 20,
            ),
          ),
        ),
      ),
    );
  }

  // 构建快捷菜单
  Widget _buildQuickMenu() {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: 220,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: (_backgroundOpacity + 0.2).clamp(0.0, 1.0)),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.15),
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
                      _showSubjectManager();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMenuButton(
                    icon: Icons.label,
                    text: '标签',
                    onPressed: () {
                      _showTagManager();
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
                      color: colorScheme.onSurface.withValues(alpha: 0.7),
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
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: colorScheme.onSurface,
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
                      color: colorScheme.onSurface.withValues(alpha: 0.7),
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
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: colorScheme.onSurface,
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
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            color: colorScheme.onSurface.withValues(alpha: 0.7),
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
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isDestructive 
                ? colorScheme.errorContainer.withValues(alpha: 0.3)
                : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 18,
                color: isDestructive 
                    ? colorScheme.error 
                    : colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              const SizedBox(width: 8),
              Text(
                text,
                style: TextStyle(
                  fontSize: 14,
                  color: isDestructive 
                      ? colorScheme.error 
                      : colorScheme.onSurface.withValues(alpha: 0.8),
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
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            icon,
            size: 16,
            color: colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
      ),
    );
  }

  // 调整界面缩放
  void _adjustScale(double delta) async {
    final newScaleFactor = (_scaleFactor + delta).clamp(50.0, 200.0);
    setState(() {
      _scaleFactor = newScaleFactor;
    });
    
    // 保存到持久化存储
    await HiveStorageService.instance.saveScaleFactor(newScaleFactor);
  }

  // 调整作业列数
  void _adjustColumnCount(int delta) async {
    final newColumnCount = (_columnCount + delta).clamp(1, 5);
    setState(() {
      _columnCount = newColumnCount;
    });
    
    // 保存到持久化存储
    await HiveStorageService.instance.saveColumnCount(newColumnCount);
  }

  // 切换快捷菜单显示状态
  void _toggleQuickMenu() {
    setState(() {
      _isQuickMenuVisible = !_isQuickMenuVisible;
    });
  }



  // 打开设置窗口
  void _openSettingsWindow() async {
    await showDialog(
      context: context,
      builder: (context) => SettingsWindow(
        onThemeChanged: widget.onThemeChanged,
        onSettingsChanged: _loadBackgroundSettings,
      ),
    );
  }

  // 退出应用
  void _exitApplication() {
    // 显示确认对话框
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('确认退出'),
          content: const Text('确定要退出应用程序吗？'),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                foregroundColor: Theme.of(context).colorScheme.onSurface,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop();
                // 退出应用
                windowManager.close();
              },
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                backgroundColor: Colors.red[600],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text('退出'),
            ),
          ],
        );
      },
    );
  }

  // 显示科目管理对话框
  void _showSubjectManager() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return SubjectManager(
          subjects: SampleData.getAvailableSubjects(),
          onSubjectsChanged: (updatedSubjects) {
            // 这里可以添加更新科目列表的逻辑
            // 目前只是显示提示信息
            _showCustomSnackBar('科目列表已更新');
          },
        );
      },
    );
  }

  // 显示标签管理对话框
  void _showTagManager() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return TagManager(
          tags: SampleData.getAvailableTags(),
          onTagsChanged: (updatedTags) {
            // 这里可以添加更新标签列表的逻辑
            // 目前只是显示提示信息
            _showCustomSnackBar('标签列表已更新');
          },
        );
      },
    );
  }

  // 构建底部拖动条
  Widget _buildDragBar() {
    final colorScheme = Theme.of(context).colorScheme;
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
                  ? colorScheme.onSurface.withValues(alpha: 0.6) // 拖动时变暗
                  : colorScheme.onSurface.withValues(alpha: 0.4), // 正常状态
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      ),
    );
  }

  // WindowListener 方法
  @override
  void onWindowMoved() {
    _saveWindowState();
  }

  @override
  void onWindowResized() {
    _saveWindowState();
  }

  @override
  void onWindowMaximize() {
    _saveWindowState();
  }

  @override
  void onWindowUnmaximize() {
    _saveWindowState();
  }

  @override
  void onWindowMinimize() {
    _saveWindowState();
  }

  @override
  void onWindowRestore() {
    _saveWindowState();
  }

  Future<void> _saveWindowState() async {
    try {
      final bounds = await windowManager.getBounds();
      final isMaximized = await windowManager.isMaximized();
      final isMinimized = await windowManager.isMinimized();
      final isFullScreen = await windowManager.isFullScreen();

      await SettingsService.instance.saveWindowState(
        x: bounds.left,
        y: bounds.top,
        width: bounds.width,
        height: bounds.height,
        maximized: isMaximized,
        minimized: isMinimized,
        fullscreen: isFullScreen,
      );
    } catch (e) {
      // 保存失败，静默处理
    }
  }
}
