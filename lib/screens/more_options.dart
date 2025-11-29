import 'dart:async';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'package:loggy/loggy.dart';
import '../services/settings_service.dart';
import '../services/storage/backup_service.dart';
import '../models/storage_config.dart';
import '../widgets/oobe_dialog.dart';
import 'widgets/common_setting_widgets.dart';
import 'widgets/appearance_widgets.dart';
import 'widgets/storage_widgets.dart';
import 'widgets/about_widgets.dart';

class MoreOptionsWindow extends StatefulWidget {
  final VoidCallback? onThemeChanged;
  final VoidCallback? onSettingsChanged;

  const MoreOptionsWindow({
    super.key,
    this.onThemeChanged,
    this.onSettingsChanged,
  });

  @override
  State<MoreOptionsWindow> createState() => _MoreOptionsWindowState();
}

class _MoreOptionsWindowState extends State<MoreOptionsWindow>
    with WindowListener {
  bool _autoStartEnabled = false;
  int _windowLayer = 0;
  int _themeMode = 0;
  bool _showInTaskbarEnabled = false;
  double _backgroundOpacity = 0.95;
  int? _themeColor;
  String? _backgroundImagePath;
  int _backgroundImageMode = 0;
  double _backgroundImageOpacity = 1.0;
  bool _isLoading = true;

  bool _snapshotEnabled = false;
  bool _snapshotOnEdit = false;
  bool _snapshotOnStartup = false;
  bool _snapshotOnExit = false;
  bool _limitSnapshotCount = true;
  int _maxSnapshotCount = 20;
  bool _autoBackupEnabled = true;
  bool _backupOnStartup = true;
  bool _backupOnConfigChange = false;
  bool _backupOnExit = true;
  bool _limitBackupCount = true;
  int _maxAutoBackupCount = 10;

  int _selectedNavIndex = 0;
  final ScrollController _scrollController = ScrollController();
  final Map<int, GlobalKey> _categoryKeys = {
    0: GlobalKey(),
    1: GlobalKey(),
    2: GlobalKey(),
    3: GlobalKey(),
    4: GlobalKey(),
    5: GlobalKey(),
  };

  bool _manualSelection = false;
  Timer? _manualSelectionTimer;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _scrollController.addListener(_onScroll);
    try {
      windowManager.addListener(this);
    } catch (e) {
      logWarning('添加窗口监听器失败', e);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    try {
      windowManager.removeListener(this);
    } catch (e) {
      logWarning('移除窗口监听器失败', e);
    }
    _manualSelectionTimer?.cancel();
    super.dispose();
  }

  @override
  void onWindowResize() {
    if (mounted) setState(() {});
  }

  void _onScroll() {
    if (_manualSelection) return;
    int newIndex = 0;

    for (var i = _categoryKeys.length - 1; i >= 0; i--) {
      final key = _categoryKeys[i];
      if (key?.currentContext != null) {
        final RenderBox box =
            key!.currentContext!.findRenderObject() as RenderBox;
        final position = box.localToGlobal(
          Offset.zero,
          ancestor: context.findRenderObject(),
        );

        if (position.dy <= 120) {
          newIndex = i;
          break;
        }
      }
    }

    if (newIndex != _selectedNavIndex) {
      setState(() {
        _selectedNavIndex = newIndex;
      });
    }
  }

  void _scrollToCategory(int index) {
    final key = _categoryKeys[index];
    if (key?.currentContext != null) {
      Scrollable.ensureVisible(
        key!.currentContext!,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutCubic,
      );
    }

    setState(() {
      _selectedNavIndex = index;
      _manualSelection = true;
      _manualSelectionTimer?.cancel();
      _manualSelectionTimer = Timer(const Duration(milliseconds: 700), () {
        _manualSelection = false;
      });
    });
  }

  Future<void> _loadSettings() async {
    final settingsService = SettingsService.instance;

    final savedWindowLevel = settingsService.getWindowLevel();
    final savedDarkMode = settingsService.getDarkMode();
    final savedBackgroundOpacity = settingsService.getBackgroundOpacity();
    final savedShowInTaskbar = settingsService.getShowInTaskbar();
    final savedThemeColor = settingsService.getThemeColor();
    final savedBackgroundImagePath = settingsService.getBackgroundImagePath();
    final savedBackgroundImageMode = settingsService.getBackgroundImageMode();
    final savedBackgroundImageOpacity = settingsService
        .getBackgroundImageOpacity();

    final actualAutoStart = await settingsService.checkAutoStartStatus();

    final storageConfig = settingsService.getStorageConfig();

    setState(() {
      _autoStartEnabled = actualAutoStart;
      _windowLayer = savedWindowLevel;
      _themeMode = savedDarkMode ? 1 : 0;
      _backgroundOpacity = savedBackgroundOpacity;
      _showInTaskbarEnabled = savedShowInTaskbar;
      _themeColor = savedThemeColor;
      _backgroundImagePath = savedBackgroundImagePath;
      _backgroundImageMode = savedBackgroundImageMode;
      _backgroundImageOpacity = savedBackgroundImageOpacity;

      _snapshotEnabled = storageConfig.snapshotEnabled;
      _snapshotOnEdit = storageConfig.snapshotOnEdit;
      _snapshotOnStartup = storageConfig.snapshotOnStartup;
      _snapshotOnExit = storageConfig.snapshotOnExit;
      _limitSnapshotCount = storageConfig.limitSnapshotCount;
      _maxSnapshotCount = storageConfig.maxSnapshotCount;
      _autoBackupEnabled = storageConfig.autoBackupEnabled;
      _backupOnStartup = storageConfig.backupOnStartup;
      _backupOnConfigChange = storageConfig.backupOnConfigChange;
      _backupOnExit = storageConfig.backupOnExit;
      _limitBackupCount = storageConfig.limitBackupCount;
      _maxAutoBackupCount = storageConfig.maxAutoBackupCount;

      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: DragToMoveArea(
          child: const SizedBox(
            width: double.infinity,
            child: Text('更多选项', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
        centerTitle: false,
        elevation: 0,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        automaticallyImplyLeading: false,
      ),
      body: Row(
        children: [
          SizedBox(
            width: 120,
            child: Column(
              children: [
                Expanded(
                  child: NavigationRail(
                    selectedIndex: _selectedNavIndex,
                    onDestinationSelected: _scrollToCategory,
                    labelType: NavigationRailLabelType.all,
                    groupAlignment: 0.0,
                    minWidth: 120,
                    destinations: const [
                      NavigationRailDestination(
                        icon: Icon(Icons.build_outlined, size: 28),
                        selectedIcon: Icon(Icons.build, size: 28),
                        label: Text('系统'),
                        padding: EdgeInsets.symmetric(vertical: 8),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.desktop_windows_outlined, size: 28),
                        selectedIcon: Icon(Icons.desktop_windows, size: 28),
                        label: Text('显示'),
                        padding: EdgeInsets.symmetric(vertical: 8),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.palette_outlined, size: 28),
                        selectedIcon: Icon(Icons.palette, size: 28),
                        label: Text('外观'),
                        padding: EdgeInsets.symmetric(vertical: 8),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.save_outlined, size: 28),
                        selectedIcon: Icon(Icons.save, size: 28),
                        label: Text('存储'),
                        padding: EdgeInsets.symmetric(vertical: 8),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.settings_outlined, size: 28),
                        selectedIcon: Icon(Icons.settings, size: 28),
                        label: Text('高级'),
                        padding: EdgeInsets.symmetric(vertical: 8),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.info_outline, size: 28),
                        selectedIcon: Icon(Icons.info, size: 28),
                        label: Text('关于'),
                        padding: EdgeInsets.symmetric(vertical: 8),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back),
                    tooltip: '返回',
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildSettingsContent(colorScheme),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsContent(ColorScheme colorScheme) {
    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CommonSettingWidgets.buildCategoryHeader(
            context,
            _categoryKeys[0]!,
            '系统',
          ),
          const SizedBox(height: 16),
          CommonSettingWidgets.buildSettingItem(
            context: context,
            icon: Icons.power_settings_new,
            title: '开机自启',
            subtitle: '系统启动时自动运行',
            value: _autoStartEnabled,
            onChanged: _onAutoStartChanged,
          ),
          const SizedBox(height: 32),

          CommonSettingWidgets.buildCategoryHeader(
            context,
            _categoryKeys[1]!,
            '显示',
          ),
          const SizedBox(height: 16),
          CommonSettingWidgets.buildWindowLayerItem(
            context: context,
            icon: Icons.layers,
            title: '窗口层级',
            subtitle: '设置窗口的显示层级',
            value: _windowLayer,
            onChanged: _onWindowLayerChanged,
          ),
          const SizedBox(height: 32),

          CommonSettingWidgets.buildCategoryHeader(
            context,
            _categoryKeys[2]!,
            '外观',
          ),
          const SizedBox(height: 16),
          CommonSettingWidgets.buildThemeModeItem(
            context: context,
            icon: Icons.brightness_6,
            title: '明暗主题',
            subtitle: '选择应用的主题',
            value: _themeMode,
            onChanged: _onThemeModeChanged,
          ),
          const SizedBox(height: 16),
          AppearanceWidgets.buildOpacitySlider(
            context: context,
            icon: Icons.opacity,
            title: '背景不透明度',
            subtitle: '调整窗口背景的透明度',
            value: _backgroundOpacity,
            onChanged: _onBackgroundOpacityChanged,
          ),
          const SizedBox(height: 16),
          AppearanceWidgets.buildThemeColorPicker(
            context: context,
            icon: Icons.color_lens,
            title: '主题色',
            subtitle: '自定义应用的主题色',
            value: _themeColor,
            onTap: () => AppearanceWidgets.showColorPickerDialog(
              context,
              _themeColor,
              _onThemeColorChanged,
            ),
          ),
          const SizedBox(height: 16),
          AppearanceWidgets.buildBackgroundImagePicker(
            context: context,
            icon: Icons.image,
            title: '背景图片',
            subtitle: '选择在主界面背景显示的图片',
            path: _backgroundImagePath,
            mode: _backgroundImageMode,
            opacity: _backgroundImageOpacity,
            onPathChanged: _onBackgroundImagePathChanged,
            onModeChanged: _onBackgroundImageModeChanged,
            onOpacityChanged: (value) {
              setState(() {
                _backgroundImageOpacity = value;
              });
              _onBackgroundImageOpacityChanged(value);
            },
            onClear: _onClearBackgroundImage,
          ),
          const SizedBox(height: 32),

          CommonSettingWidgets.buildCategoryHeader(
            context,
            _categoryKeys[3]!,
            '存储',
          ),
          const SizedBox(height: 16),
          _buildStorageSection(colorScheme),
          const SizedBox(height: 32),

          CommonSettingWidgets.buildCategoryHeader(
            context,
            _categoryKeys[4]!,
            '高级',
          ),
          const SizedBox(height: 16),
          CommonSettingWidgets.buildSettingItem(
            context: context,
            icon: Icons.task,
            title: '在任务栏显示',
            subtitle: '在任务栏中显示应用图标',
            value: _showInTaskbarEnabled,
            onChanged: _onShowInTaskbarChanged,
          ),
          const SizedBox(height: 16),
          CommonSettingWidgets.buildActionItem(
            context: context,
            icon: Icons.rocket_launch,
            title: '打开 OOBE',
            subtitle: '重新打开首次使用向导',
            onTap: _showOOBEDialog,
          ),
          const SizedBox(height: 32),

          CommonSettingWidgets.buildCategoryHeader(
            context,
            _categoryKeys[5]!,
            '关于',
          ),
          const SizedBox(height: 16),
          AboutWidgets.buildAboutCard(context, colorScheme),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Future<void> _onAutoStartChanged(bool value) async {
    final settingsService = SettingsService.instance;
    final result = await settingsService.setAutoStart(value);

    if (result.success) {
      setState(() {
        _autoStartEnabled = value;
      });
      logInfo('开机自启已${value ? "启用" : "禁用"}');
    } else {
      logError('设置开机自启失败', result.error);
    }
  }

  Future<void> _onWindowLayerChanged(int value) async {
    final settingsService = SettingsService.instance;

    try {
      final success = await settingsService.setWindowLevel(value);
      if (success) {
        setState(() {
          _windowLayer = value;
        });
        widget.onSettingsChanged?.call();
        logInfo('窗口层级已更改为: $value');
      }
    } catch (e) {
      logError('更改窗口层级失败', e);
    }
  }

  Future<void> _onThemeModeChanged(int value) async {
    final settingsService = SettingsService.instance;
    try {
      final success = await settingsService.setDarkMode(value == 1);
      if (success) {
        setState(() {
          _themeMode = value;
        });
        widget.onThemeChanged?.call();
        logInfo('主题模式已切换为: ${value == 1 ? "深色" : "浅色"}');
      }
    } catch (e) {
      logError('切换主题模式失败', e);
    }
  }

  Future<void> _onBackgroundOpacityChanged(double value) async {
    final settingsService = SettingsService.instance;
    final success = await settingsService.setBackgroundOpacity(value);

    if (success) {
      setState(() {
        _backgroundOpacity = value;
      });
      widget.onSettingsChanged?.call();
      logDebug('背景透明度已更改为: ${(value * 100).toStringAsFixed(0)}%');
    } else {
      logWarning('设置背景透明度失败');
    }
  }

  Future<void> _onThemeColorChanged(int? colorValue) async {
    final settingsService = SettingsService.instance;
    final success = await settingsService.setThemeColor(colorValue);

    if (success) {
      setState(() {
        _themeColor = colorValue;
      });
      widget.onThemeChanged?.call();
    } else {}
  }

  Future<void> _onBackgroundImagePathChanged(String? path) async {
    final settingsService = SettingsService.instance;
    final success = await settingsService.setBackgroundImagePath(path);

    if (success) {
      setState(() {
        _backgroundImagePath = path;
      });
      widget.onSettingsChanged?.call();
    } else {}
  }

  Future<void> _onBackgroundImageModeChanged(int mode) async {
    final settingsService = SettingsService.instance;
    final success = await settingsService.setBackgroundImageMode(mode);

    if (success) {
      setState(() {
        _backgroundImageMode = mode;
      });
      widget.onSettingsChanged?.call();
    } else {}
  }

  Future<void> _onBackgroundImageOpacityChanged(double value) async {
    final settingsService = SettingsService.instance;
    final success = await settingsService.setBackgroundImageOpacity(value);

    if (success) {
      setState(() {
        _backgroundImageOpacity = value;
      });
      widget.onSettingsChanged?.call();
    } else {}
  }

  Future<void> _onClearBackgroundImage() async {
    await _onBackgroundImagePathChanged(null);
  }

  Future<void> _onShowInTaskbarChanged(bool value) async {
    final settingsService = SettingsService.instance;
    final success = await settingsService.setShowInTaskbar(value);

    if (success) {
      setState(() {
        _showInTaskbarEnabled = value;
      });
      widget.onSettingsChanged?.call();
    } else {}
  }

  void _showOOBEDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => OOBEDialog(
        onCompleted: () {
          _loadSettings();
          if (widget.onThemeChanged != null) {
            widget.onThemeChanged!();
          }
          if (widget.onSettingsChanged != null) {
            widget.onSettingsChanged!();
          }
        },
        onThemeChanged: widget.onThemeChanged,
      ),
    );
  }

  Widget _buildStorageSection(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSnapshotCard(colorScheme),
        const SizedBox(height: 16),

        _buildBackupCard(colorScheme),
      ],
    );
  }

  Widget _buildSnapshotCard(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.camera_alt,
                  color: colorScheme.onPrimaryContainer,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '自动快照',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '保存作业内容的历史版本',
                      style: TextStyle(
                        fontSize: 13,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _snapshotEnabled,
                onChanged: _onSnapshotEnabledChanged,
              ),
            ],
          ),

          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOutCubic,
            alignment: Alignment.topCenter,
            child: _snapshotEnabled
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      Divider(
                        color: colorScheme.outlineVariant.withValues(
                          alpha: 0.5,
                        ),
                      ),
                      const SizedBox(height: 16),

                      Padding(
                        padding: const EdgeInsets.only(left: 16, bottom: 12),
                        child: Text(
                          '快照时机',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface.withValues(alpha: 0.8),
                          ),
                        ),
                      ),

                      Padding(
                        padding: const EdgeInsets.only(left: 16),
                        child: _buildCheckboxOption(
                          colorScheme: colorScheme,
                          icon: Icons.edit,
                          title: '每次编辑后',
                          value: _snapshotOnEdit,
                          onChanged: _onSnapshotOnEditChanged,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Padding(
                        padding: const EdgeInsets.only(left: 16),
                        child: _buildCheckboxOption(
                          colorScheme: colorScheme,
                          icon: Icons.power_settings_new,
                          title: '应用启动时',
                          value: _snapshotOnStartup,
                          onChanged: _onSnapshotOnStartupChanged,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Padding(
                        padding: const EdgeInsets.only(left: 16),
                        child: _buildCheckboxOption(
                          colorScheme: colorScheme,
                          icon: Icons.exit_to_app,
                          title: '退出应用时',
                          value: _snapshotOnExit,
                          onChanged: _onSnapshotOnExitChanged,
                        ),
                      ),

                      const SizedBox(height: 12),
                      Divider(
                        color: colorScheme.outlineVariant.withValues(
                          alpha: 0.5,
                        ),
                      ),
                      const SizedBox(height: 12),

                      _buildSwitchOption(
                        colorScheme: colorScheme,
                        icon: Icons.format_list_numbered,
                        title: '限制快照数量',
                        value: _limitSnapshotCount,
                        onChanged: _onLimitSnapshotCountChanged,
                      ),

                      AnimatedSize(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOutCubic,
                        alignment: Alignment.topCenter,
                        child: _limitSnapshotCount
                            ? Column(
                                children: [
                                  const SizedBox(height: 8),
                                  Padding(
                                    padding: const EdgeInsets.only(left: 16),
                                    child: _buildSnapshotCountControl(
                                      colorScheme,
                                    ),
                                  ),
                                ],
                              )
                            : const SizedBox.shrink(),
                      ),
                    ],
                  )
                : const SizedBox.shrink(),
          ),

          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                onPressed: _createManualSnapshot,
                icon: const Icon(Icons.add_a_photo_outlined, size: 20),
                label: const Text('创建快照'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: _openSnapshotDirectory,
                icon: const Icon(Icons.folder_open, size: 20),
                label: const Text('打开快照目录'),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBackupCard(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.backup,
                  color: colorScheme.onPrimaryContainer,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '自动备份',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '自动备份配置、窗口状态、学科/标签等数据',
                      style: TextStyle(
                        fontSize: 13,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _autoBackupEnabled,
                onChanged: _onAutoBackupEnabledChanged,
              ),
            ],
          ),

          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOutCubic,
            alignment: Alignment.topCenter,
            child: _autoBackupEnabled
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      Divider(
                        color: colorScheme.outlineVariant.withValues(
                          alpha: 0.5,
                        ),
                      ),
                      const SizedBox(height: 16),

                      Padding(
                        padding: const EdgeInsets.only(left: 16, bottom: 12),
                        child: Text(
                          '备份时机',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface.withValues(alpha: 0.8),
                          ),
                        ),
                      ),

                      Padding(
                        padding: const EdgeInsets.only(left: 16),
                        child: _buildCheckboxOption(
                          colorScheme: colorScheme,
                          icon: Icons.settings,
                          title: '编辑配置时',
                          value: _backupOnConfigChange,
                          onChanged: _onBackupOnConfigChangeChanged,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Padding(
                        padding: const EdgeInsets.only(left: 16),
                        child: _buildCheckboxOption(
                          colorScheme: colorScheme,
                          icon: Icons.power_settings_new,
                          title: '应用启动时',
                          value: _backupOnStartup,
                          onChanged: _onBackupOnStartupChanged,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Padding(
                        padding: const EdgeInsets.only(left: 16),
                        child: _buildCheckboxOption(
                          colorScheme: colorScheme,
                          icon: Icons.exit_to_app,
                          title: '退出应用时',
                          value: _backupOnExit,
                          onChanged: _onBackupOnExitChanged,
                        ),
                      ),

                      const SizedBox(height: 12),
                      Divider(
                        color: colorScheme.outlineVariant.withValues(
                          alpha: 0.5,
                        ),
                      ),
                      const SizedBox(height: 12),

                      _buildSwitchOption(
                        colorScheme: colorScheme,
                        icon: Icons.format_list_numbered,
                        title: '限制备份数量',
                        value: _limitBackupCount,
                        onChanged: _onLimitBackupCountChanged,
                      ),

                      AnimatedSize(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOutCubic,
                        alignment: Alignment.topCenter,
                        child: _limitBackupCount
                            ? Column(
                                children: [
                                  const SizedBox(height: 8),
                                  Padding(
                                    padding: const EdgeInsets.only(left: 16),
                                    child: _buildBackupCountControl(
                                      colorScheme,
                                      enabled: true,
                                    ),
                                  ),
                                ],
                              )
                            : const SizedBox.shrink(),
                      ),
                    ],
                  )
                : const SizedBox.shrink(),
          ),

          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                onPressed: _performManualBackup,
                icon: const Icon(Icons.backup_outlined, size: 20),
                label: const Text('立即备份'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: _openBackupDirectory,
                icon: const Icon(Icons.folder_open, size: 20),
                label: const Text('打开备份目录'),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCheckboxOption({
    required ColorScheme colorScheme,
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return StorageWidgets.buildCheckboxOption(
      colorScheme: colorScheme,
      icon: icon,
      title: title,
      value: value,
      onChanged: onChanged,
    );
  }

  Widget _buildSwitchOption({
    required ColorScheme colorScheme,
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return StorageWidgets.buildSwitchOption(
      colorScheme: colorScheme,
      icon: icon,
      title: title,
      value: value,
      onChanged: onChanged,
    );
  }

  Widget _buildSnapshotCountControl(ColorScheme colorScheme) {
    return Row(
      children: [
        Icon(Icons.inventory_2, size: 20, color: colorScheme.onSurfaceVariant),
        const SizedBox(width: 12),
        Text(
          '最大快照数量',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: colorScheme.onSurface,
          ),
        ),
        const Spacer(),
        IconButton(
          onPressed: _maxSnapshotCount > 1
              ? () {
                  setState(() {
                    _maxSnapshotCount--;
                  });
                  _saveStorageConfig();
                }
              : null,
          icon: const Icon(Icons.remove),
        ),
        const SizedBox(width: 12),
        Container(
          constraints: const BoxConstraints(minWidth: 60),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '$_maxSnapshotCount',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
            ),
          ),
        ),
        const SizedBox(width: 12),
        IconButton(
          onPressed: () {
            setState(() {
              _maxSnapshotCount++;
            });
            _saveStorageConfig();
          },
          icon: const Icon(Icons.add),
        ),
      ],
    );
  }

  Widget _buildBackupCountControl(
    ColorScheme colorScheme, {
    required bool enabled,
  }) {
    return Row(
      children: [
        Icon(Icons.inventory_2, size: 20, color: colorScheme.onSurfaceVariant),
        const SizedBox(width: 12),
        Text(
          '最大自动备份数量',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: colorScheme.onSurface,
          ),
        ),
        const Spacer(),
        IconButton(
          onPressed: _maxAutoBackupCount > 1
              ? () {
                  setState(() {
                    _maxAutoBackupCount--;
                  });
                  _onMaxAutoBackupCountChanged(_maxAutoBackupCount);
                }
              : null,
          icon: const Icon(Icons.remove),
        ),
        const SizedBox(width: 12),
        Container(
          constraints: const BoxConstraints(minWidth: 60),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '$_maxAutoBackupCount',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
            ),
          ),
        ),
        const SizedBox(width: 12),
        IconButton(
          onPressed: () {
            setState(() {
              _maxAutoBackupCount++;
            });
            _onMaxAutoBackupCountChanged(_maxAutoBackupCount);
          },
          icon: const Icon(Icons.add),
        ),
      ],
    );
  }

  void _onSnapshotEnabledChanged(bool value) async {
    setState(() {
      _snapshotEnabled = value;
      if (!value) {
        _snapshotOnEdit = false;
      }
    });
    await _saveStorageConfig();
  }

  void _onSnapshotOnEditChanged(bool value) async {
    setState(() {
      _snapshotOnEdit = value;
    });
    await _saveStorageConfig();
  }

  void _onSnapshotOnStartupChanged(bool value) async {
    setState(() {
      _snapshotOnStartup = value;
    });
    await _saveStorageConfig();
  }

  void _onSnapshotOnExitChanged(bool value) async {
    setState(() {
      _snapshotOnExit = value;
    });
    await _saveStorageConfig();
  }

  void _onLimitSnapshotCountChanged(bool value) async {
    setState(() {
      _limitSnapshotCount = value;
    });
    await _saveStorageConfig();
  }

  void _onAutoBackupEnabledChanged(bool value) async {
    setState(() {
      _autoBackupEnabled = value;
    });
    await _saveStorageConfig();
  }

  void _onBackupOnStartupChanged(bool value) async {
    setState(() {
      _backupOnStartup = value;
    });
    await _saveStorageConfig();
  }

  void _onBackupOnConfigChangeChanged(bool value) async {
    setState(() {
      _backupOnConfigChange = value;
    });
    await _saveStorageConfig();
  }

  void _onBackupOnExitChanged(bool value) async {
    setState(() {
      _backupOnExit = value;
    });
    await _saveStorageConfig();
  }

  void _onLimitBackupCountChanged(bool value) async {
    setState(() {
      _limitBackupCount = value;
    });
    await _saveStorageConfig();
  }

  void _onMaxAutoBackupCountChanged(int value) async {
    await _saveStorageConfig();
  }

  Future<void> _saveStorageConfig() async {
    final config = StorageConfig(
      snapshotEnabled: _snapshotEnabled,
      snapshotOnEdit: _snapshotOnEdit,
      snapshotOnStartup: _snapshotOnStartup,
      snapshotOnExit: _snapshotOnExit,
      limitSnapshotCount: _limitSnapshotCount,
      maxSnapshotCount: _maxSnapshotCount,
      autoBackupEnabled: _autoBackupEnabled,
      backupOnStartup: _backupOnStartup,
      backupOnConfigChange: _backupOnConfigChange,
      backupOnExit: _backupOnExit,
      limitBackupCount: _limitBackupCount,
      maxAutoBackupCount: _maxAutoBackupCount,
    );
    await SettingsService.instance.saveStorageConfig(config);

    if (_autoBackupEnabled && _backupOnConfigChange) {
      await BackupService.instance.backupOnConfigChange();
    }
  }

  Future<void> _performManualBackup() async {
    await StorageWidgets.performManualBackup(_showSnackBar);
  }

  Future<void> _openBackupDirectory() async {
    await StorageWidgets.openBackupDirectory(_showSnackBar);
  }

  Future<void> _createManualSnapshot() async {
    await StorageWidgets.createManualSnapshot(_showSnackBar);
  }

  Future<void> _openSnapshotDirectory() async {
    await StorageWidgets.openSnapshotDirectory(_showSnackBar);
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }
}
