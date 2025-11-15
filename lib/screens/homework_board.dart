import 'dart:async';
import 'dart:io' show Platform, File;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import '../models/subject.dart';
import '../models/homework.dart';
import '../widgets/homework_card.dart';
import '../widgets/subject_header.dart';
import '../widgets/homework_editor.dart';
import '../widgets/empty_state.dart';
import '../widgets/more_options.dart';
import '../widgets/subject_manager.dart';
import '../widgets/tag_manager.dart';
import '../widgets/oobe_dialog.dart';
import '../widgets/floating_toolbar.dart';
import '../widgets/quick_menu.dart';
import '../services/settings_service.dart';
import '../services/storage/json_storage_service.dart';

class HomeworkBoard extends StatefulWidget {
  final VoidCallback? onThemeChanged;
  
  const HomeworkBoard({super.key, this.onThemeChanged});

  @override
  State<HomeworkBoard> createState() => _HomeworkBoardState();
}

class _HomeworkBoardState extends State<HomeworkBoard> with WindowListener, TickerProviderStateMixin {
  List<Subject> subjects = [];

  String? _selectedHomeworkId;
  Timer? _selectionTimer;
  Timer? _quickMenuAutoHideTimer;
  Timer? _toolbarOpacityTimer;
  
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
  
  // 背景图片相关
  String? _backgroundImagePath;
  int _backgroundImageMode = 0;
  double _backgroundImageOpacity = 1.0;
  
  // 快捷菜单动画控制器
  late AnimationController _quickMenuAnimationController;
  late Animation<double> _quickMenuOpacityAnimation;
  late Animation<Offset> _quickMenuSlideAnimation;
  
  // 工具栏透明度相关
  double _toolbarOpacity = 1.0;
  late AnimationController _toolbarOpacityAnimationController;
  late Animation<double> _toolbarOpacityAnimation;
  



  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    
    // 初始化快捷菜单动画控制器
    _quickMenuAnimationController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    
    // 透明度动画（淡入淡出）
    _quickMenuOpacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _quickMenuAnimationController,
      curve: Curves.easeInOut,
    ));
    
    // 滑动动画（从右下角滑入）
    _quickMenuSlideAnimation = Tween<Offset>(
      begin: const Offset(0.3, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _quickMenuAnimationController,
      curve: Curves.easeOutBack,
    ));
    
    // 初始化工具栏透明度动画控制器
    _toolbarOpacityAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    // 工具栏透明度动画（从1.0到0.3）
    _toolbarOpacityAnimation = Tween<double>(
      begin: 1.0,
      end: 0.3,
    ).animate(CurvedAnimation(
      parent: _toolbarOpacityAnimationController,
      curve: Curves.easeInOut,
    ));
    
    // 监听动画变化更新透明度状态
    _toolbarOpacityAnimation.addListener(() {
      setState(() {
        _toolbarOpacity = _toolbarOpacityAnimation.value;
      });
    });
    
    _loadData();
    _loadBackgroundSettings();
    
    // 确保主窗口完全加载后再检查并显示OOBE
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndShowOOBE();
      // 启动工具栏透明度定时器
      _startToolbarOpacityTimer();
    });
  }

  Future<void> _loadData() async {
    final storageService = JsonStorageService.instance;
    final homeworks = storageService.getAllHomework();
    final allSubjects = storageService.getAllSubjects();
    
    // 加载界面设置
    final appConfig = storageService.getAppConfig();
    
    // 按科目UUID分组作业
    Map<String, List<Homework>> homeworksBySubjectUuid = {};
    for (var homework in homeworks) {
      if (!homeworksBySubjectUuid.containsKey(homework.subjectUuid)) {
        homeworksBySubjectUuid[homework.subjectUuid] = [];
      }
      homeworksBySubjectUuid[homework.subjectUuid]!.add(homework);
    }
    
    // 创建Subject对象（包含作业信息用于显示）
    List<Subject> loadedSubjects = [];
    for (var subject in allSubjects) {
      // 创建一个临时的Subject对象用于UI显示，包含作业信息
      loadedSubjects.add(Subject(
        uuid: subject.uuid,
        name: subject.name,
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
      _backgroundImagePath = settingsService.getBackgroundImagePath();
      _backgroundImageMode = settingsService.getBackgroundImageMode();
      _backgroundImageOpacity = settingsService.getBackgroundImageOpacity();
    });
  }

  /// 检查并显示OOBE对话框
  Future<void> _checkAndShowOOBE() async {
    final settingsService = SettingsService.instance;
    if (settingsService.isFirstLaunch() && mounted) {
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => OOBEDialog(
            onCompleted: () {
              // OOBE完成后重新加载主题设置
              if (widget.onThemeChanged != null) {
                widget.onThemeChanged!();
              }
              _loadBackgroundSettings();
            },
            onThemeChanged: widget.onThemeChanged,
          ),
        );
      }
    }
  }
  
  @override
  void dispose() {
    windowManager.removeListener(this);
    _selectionTimer?.cancel();
    _quickMenuAutoHideTimer?.cancel();
    _toolbarOpacityTimer?.cancel();
    _quickMenuAnimationController.dispose();
    _toolbarOpacityAnimationController.dispose();
    super.dispose();
  }

  void _selectHomework(String homeworkUuid) {
    setState(() {
      _selectedHomeworkId = homeworkUuid;
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

  // 简化的全屏前窗口锁定状态记录
  bool _windowLockedBeforeFullScreen = false;
  
  /// 切换全屏状态
  /// 优化后的实现：减少setState调用，简化状态管理，提高性能
  Future<void> _toggleFullScreen() async {
    final willEnterFullScreen = !_isFullScreen;
    
    // 进入全屏前的准备工作
    if (willEnterFullScreen) {
      // 记录当前窗口锁定状态
      _windowLockedBeforeFullScreen = _isWindowLocked;
      
      // 如果窗口当前是锁定的，需要先解锁（不显示提示）
      if (_isWindowLocked) {
        await _unlockWindowSilently();
      }
    }
  
    // 一次性更新所有相关状态，减少重绘
    setState(() {
      _isFullScreen = willEnterFullScreen;
      // 进入全屏时，窗口必须是解锁状态
      if (willEnterFullScreen) {
        _isWindowLocked = false;
      }
    });
  
    // 执行窗口管理器的全屏切换
    await windowManager.setFullScreen(willEnterFullScreen);
    
    // 显示状态提示
    _showCustomSnackBar(willEnterFullScreen ? '已进入全屏模式' : '已退出全屏模式');
  
    // 退出全屏后的恢复工作
    if (!willEnterFullScreen) {
      // 恢复之前的窗口锁定状态
      if (_windowLockedBeforeFullScreen) {
        await _lockWindowSilently();
        setState(() {
          _isWindowLocked = true;
        });
      } else {
        // 确保窗口保持解锁状态（不显示提示）
        await _unlockWindowSilently();
      }
    }
  }

  // 切换窗口锁定状态
  Future<void> _toggleWindowLock() async {
    final willLock = !_isWindowLocked;
    
    setState(() {
      _isWindowLocked = willLock;
    });

    if (willLock) {
      await _lockWindow();
    } else {
      await _unlockWindow();
    }
  }

  // 锁定窗口
  Future<void> _lockWindow() async {
    await windowManager.setResizable(false);
    await windowManager.setAsFrameless();
    _showCustomSnackBar('窗口已锁定');
  }

  // 解锁窗口
  Future<void> _unlockWindow() async {
    if (Platform.isLinux) {
      await windowManager.setTitleBarStyle(TitleBarStyle.normal);
    }
    else {
      await windowManager.setTitleBarStyle(TitleBarStyle.hidden);
    }
    await windowManager.setResizable(true);
    _showCustomSnackBar('窗口已解锁，可从四边调整大小');
  }

  // 静默锁定窗口（不显示提示，用于全屏切换）
  Future<void> _lockWindowSilently() async {
    await windowManager.setResizable(false);
    await windowManager.setAsFrameless();
  }

  // 静默解锁窗口（不显示提示，用于全屏切换）
  Future<void> _unlockWindowSilently() async {
    await windowManager.setTitleBarStyle(TitleBarStyle.hidden);
    await windowManager.setResizable(true);
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



  void _onEditHomework(String homeworkUuid) {
    final storageService = JsonStorageService.instance;
    final homeworkToEdit = storageService.getHomeworkByUuid(homeworkUuid);

    if (homeworkToEdit != null) {
      _showHomeworkEditor(homeworkToEdit);
    }
  }

  Future<void> _onDeleteHomework(String homeworkUuid) async {
    final storageService = JsonStorageService.instance;
    
    // 从JSON存储中删除作业
    await storageService.deleteHomework(homeworkUuid);
    
    // 重新加载数据以更新UI
    await _loadData();
    
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
    final storageService = JsonStorageService.instance;
    
    // 检查是否为编辑模式
    final existingHomework = storageService.getHomeworkByUuid(homework.uuid);
    final isEdit = existingHomework != null;
    
    // 保存到JSON存储
    await storageService.saveHomework(homework);
    
    // 重新加载数据以更新UI
    await _loadData();

    if (mounted && context.mounted) {
      Navigator.of(context).pop();
    }
    if (mounted) {
      _showCustomSnackBar(isEdit ? '作业已更新' : '作业已创建');
    }
  }



  // 所有作业分配
  List<List<Widget>> _distributeHomeworksToColumns() {
    List<List<Widget>> columns = List.generate(_columnCount, (index) => <Widget>[]);
    int currentColumn = 0;
    final storageService = JsonStorageService.instance;
    
    // 为每个学科创建标题和作业卡片，保持在同一列
    for (var subject in subjects) {
      final subjectHomeworks = storageService.getHomeworkBySubjectUuid(subject.uuid);
      
      if (subjectHomeworks.isNotEmpty) {
        // 添加学科标题到当前列
        columns[currentColumn].add(
          SubjectHeader(
            subjectName: subject.name,
            homeworkCount: subjectHomeworks.length,
          ),
        );
        
        // 添加该学科的所有作业到同一列
        for (var homework in subjectHomeworks) {
          columns[currentColumn].add(
            HomeworkCard(
              key: ValueKey('${homework.uuid}_$_backgroundOpacity'),
              homework: homework,
              isSelected: _selectedHomeworkId == homework.uuid,
              onTap: () => _selectHomework(homework.uuid),
              onEdit: () => _onEditHomework(homework.uuid),
              onDelete: () => _onDeleteHomework(homework.uuid),
            ),
          );
        }
        
        // 移动到下一列
        currentColumn = (currentColumn + 1) % _columnCount;
      }
    }
    
    // 处理无效科目UUID的作业
    final allHomeworks = storageService.getAllHomework();
    final allSubjects = storageService.getAllSubjects();
    final invalidSubjectHomeworks = allHomeworks.where((homework) {
      return !allSubjects.any((s) => s.uuid == homework.subjectUuid);
    }).toList();
    
    if (invalidSubjectHomeworks.isNotEmpty) {
      // 添加"未知"科目标题
      columns[currentColumn].add(
        SubjectHeader(
          subjectName: '未知',
          homeworkCount: invalidSubjectHomeworks.length,
        ),
      );
      
      // 添加无效科目UUID的作业
      for (var homework in invalidSubjectHomeworks) {
        columns[currentColumn].add(
          HomeworkCard(
            key: ValueKey('${homework.uuid}_$_backgroundOpacity'),
            homework: homework,
            isSelected: _selectedHomeworkId == homework.uuid,
            onTap: () => _selectHomework(homework.uuid),
            onEdit: () => _onEditHomework(homework.uuid),
            onDelete: () => _onDeleteHomework(homework.uuid),
          ),
        );
      }
    }
    
    return columns;
  }

  @override
  Widget build(BuildContext context) {
    final columns = _distributeHomeworksToColumns();
    final storageService = JsonStorageService.instance;
    
    // 检查是否有作业（包括有效科目的作业和无效科目UUID的作业）
    final hasValidSubjectHomework = subjects.any((subject) => 
        storageService.getHomeworkBySubjectUuid(subject.uuid).isNotEmpty);
    
    final allHomeworks = storageService.getAllHomework();
    final allSubjects = storageService.getAllSubjects();
    final hasInvalidSubjectHomework = allHomeworks.any((homework) {
      return !allSubjects.any((s) => s.uuid == homework.subjectUuid);
    });
    
    final hasHomework = hasValidSubjectHomework || hasInvalidSubjectHomework;
    
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // 背景容器
          GestureDetector(
            onTap: () {
              // 隐藏快捷菜单
              if (_isQuickMenuVisible) {
                // 取消自动隐藏定时器
                _quickMenuAutoHideTimer?.cancel();
                _quickMenuAnimationController.reverse().then((_) {
                  if (mounted) {
                    setState(() {
                      _isQuickMenuVisible = false;
                    });
                  }
                });
              }
              // 取消选中卡片
              if (_selectedHomeworkId != null) {
                setState(() {
                  _selectedHomeworkId = null;
                });
                _selectionTimer?.cancel(); // 取消定时器
              }
            },
            child: Opacity(
              opacity: _isFullScreen ? 1.0 : _backgroundOpacity,
              child: Container(
                width: double.infinity,
                height: double.infinity,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  image: _backgroundImagePath != null && _backgroundImagePath!.isNotEmpty
                      ? DecorationImage(
                          image: FileImage(File(_backgroundImagePath!)),
                          fit: _getBoxFitFromMode(_backgroundImageMode),
                          opacity: _backgroundImageOpacity,
                        )
                      : null,
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
            child: FloatingToolbar(
              opacity: _toolbarOpacity,
              backgroundOpacity: _backgroundOpacity,
              isFullScreen: _isFullScreen,
              onMouseEnter: _resetToolbarOpacity,
              onMouseExit: _startToolbarOpacityTimer,
              onNewHomework: () {
                _resetToolbarOpacity();
                _showHomeworkEditor();
              },
              onToggleFullScreen: () {
                _resetToolbarOpacity();
                _toggleFullScreen();
              },
              onToggleMenu: () {
                _resetToolbarOpacity();
                _toggleQuickMenu();
              },
            ),
          ),
          // 快捷菜单
          if (_isQuickMenuVisible)
            Positioned(
              bottom: 70,
              right: 16,
              child: SlideTransition(
                position: _quickMenuSlideAnimation,
                child: FadeTransition(
                  opacity: _quickMenuOpacityAnimation,
                  child: QuickMenu(
                    backgroundOpacity: _backgroundOpacity,
                    isFullScreen: _isFullScreen,
                    isWindowLocked: _isWindowLocked,
                    windowLockedBeforeFullScreen: _windowLockedBeforeFullScreen,
                    scaleFactor: _scaleFactor,
                    columnCount: _columnCount,
                    onMoreOptions: () => _hideMenuAndExecute(_openMoreOptionsWindow),
                    onToggleWindowLock: _toggleWindowLock,
                    onMinimize: () {
                      // TODO: 实现收起功能
                    },
                    onManageSubjects: () => _hideMenuAndExecute(_showSubjectManager),
                    onManageTags: () => _hideMenuAndExecute(_showTagManager),
                    onScaleIncrease: () => _adjustScale(10),
                    onScaleDecrease: () => _adjustScale(-10),
                    onColumnIncrease: () => _adjustColumnCount(1),
                    onColumnDecrease: () => _adjustColumnCount(-1),
                    onExit: () => _hideMenuAndExecute(_exitApplication),
                    onInteraction: _resetQuickMenuTimer,
                  ),
                ),
              ),
            ),
        ],
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
    await JsonStorageService.instance.saveScaleFactor(newScaleFactor);
  }

  // 调整作业列数
  void _adjustColumnCount(int delta) async {
    final newColumnCount = (_columnCount + delta).clamp(1, 5);
    setState(() {
      _columnCount = newColumnCount;
    });
    
    // 保存到持久化存储
    await JsonStorageService.instance.saveColumnCount(newColumnCount);
  }

  // 切换快捷菜单显示状态
  void _toggleQuickMenu() {
    if (_isQuickMenuVisible) {
      // 隐藏菜单：取消自动隐藏定时器，播放反向动画，然后隐藏
      _quickMenuAutoHideTimer?.cancel();
      _quickMenuAnimationController.reverse().then((_) {
        if (mounted) {
          setState(() {
            _isQuickMenuVisible = false;
          });
        }
      });
    } else {
      // 显示菜单：先显示，然后播放正向动画，启动10秒自动隐藏定时器
      setState(() {
        _isQuickMenuVisible = true;
      });
      _quickMenuAnimationController.forward();
      
      // 启动10秒自动隐藏定时器
      _quickMenuAutoHideTimer?.cancel(); // 取消之前的定时器
      _quickMenuAutoHideTimer = Timer(const Duration(seconds: 10), () {
        if (mounted && _isQuickMenuVisible) {
          _toggleQuickMenu(); // 自动隐藏菜单
        }
      });
    }
  }

  // 隐藏快捷菜单并执行操作
  void _hideMenuAndExecute(VoidCallback action) {
    if (_isQuickMenuVisible) {
      // 取消自动隐藏定时器
      _quickMenuAutoHideTimer?.cancel();
      _quickMenuAnimationController.reverse().then((_) {
        if (mounted) {
          setState(() {
            _isQuickMenuVisible = false;
          });
          // 在菜单隐藏后执行操作
          action();
        }
      });
    } else {
      // 如果菜单已经隐藏，直接执行操作
      action();
    }
  }

  // 启动工具栏透明度定时器
  void _startToolbarOpacityTimer() {
    _toolbarOpacityTimer?.cancel();
    _toolbarOpacityTimer = Timer(const Duration(seconds: 20), () {
      if (mounted) {
        // 20秒后开始透明度动画
        _toolbarOpacityAnimationController.forward();
      }
    });
  }

  // 重置工具栏透明度
  void _resetToolbarOpacity() {
    _toolbarOpacityTimer?.cancel();
    if (_toolbarOpacityAnimationController.isCompleted) {
      // 如果当前是透明状态，恢复到不透明
      _toolbarOpacityAnimationController.reverse();
    }
    // 重新启动定时器
    _startToolbarOpacityTimer();
  }

  // 重置快捷菜单自动隐藏定时器
  void _resetQuickMenuTimer() {
    if (_isQuickMenuVisible) {
      _quickMenuAutoHideTimer?.cancel();
      _quickMenuAutoHideTimer = Timer(const Duration(seconds: 10), () {
        if (mounted && _isQuickMenuVisible) {
          _toggleQuickMenu(); // 自动隐藏菜单
        }
      });
    }
  }

  // 打开设置窗口
  void _openMoreOptionsWindow() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MoreOptionsWindow(
          onThemeChanged: widget.onThemeChanged,
          onSettingsChanged: _loadBackgroundSettings,
        ),
      ),
    );
  }

  // 退出应用
  void _exitApplication() {
    // 直接退出应用
    windowManager.close();
  }

  // 显示科目管理对话框
  void _showSubjectManager() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return SubjectManager(
          onSubjectsChanged: () {
            // 重新加载作业数据以反映科目变化
            _loadData();
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
          onTagsChanged: () {
            // 重新加载作业数据以反映标签变化
            _loadData();
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

  BoxFit _getBoxFitFromMode(int mode) {
    switch (mode) {
      case 0:
        return BoxFit.contain; // 适应
      case 1:
        return BoxFit.cover; // 填充
      case 2:
        return BoxFit.fill; // 拉伸
      default:
        return BoxFit.contain;
    }
  }
}
