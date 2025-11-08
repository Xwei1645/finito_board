import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../services/settings_service.dart';
import 'oobe_dialog.dart';


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

class _MoreOptionsWindowState extends State<MoreOptionsWindow> {
  bool _autoStartEnabled = false;
  // 0 = 常规, 1 = 置顶, 2 = 置底
  int _windowLayer = 0;
  // 0 = 亮色, 1 = 暗色
  int _themeMode = 0;
  bool _showInTaskbarEnabled = false;
  double _backgroundOpacity = 0.95;
  int? _themeColor; // 自定义主题色
  bool _isLoading = true;

  int _selectedNavIndex = 0;
  final ScrollController _scrollController = ScrollController();
  final Map<int, GlobalKey> _categoryKeys = {
    0: GlobalKey(),
    1: GlobalKey(),
    2: GlobalKey(),
    3: GlobalKey(),
    4: GlobalKey(),
  };

  bool _manualSelection = false;
  Timer? _manualSelectionTimer;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _manualSelectionTimer?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (_manualSelection) return;
    int newIndex = 0;

    for (var i = _categoryKeys.length - 1; i >= 0; i--) {
      final key = _categoryKeys[i];
      if (key?.currentContext != null) {
        final RenderBox box = key!.currentContext!.findRenderObject() as RenderBox;
        final position = box.localToGlobal(Offset.zero, ancestor: context.findRenderObject());

        if (position.dy <= 100) {
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

    final actualAutoStart = await settingsService.checkAutoStartStatus();

    setState(() {
      _autoStartEnabled = actualAutoStart;
      _windowLayer = savedWindowLevel;
      _themeMode = savedDarkMode ? 1 : 0;
      _backgroundOpacity = savedBackgroundOpacity;
      _showInTaskbarEnabled = savedShowInTaskbar;
      _themeColor = savedThemeColor;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text(
          '更多选项',
          style: TextStyle(fontWeight: FontWeight.bold),
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
          _buildCategoryHeader(0, '系统', colorScheme),
          const SizedBox(height: 16),
          _buildSettingItem(
            icon: Icons.power_settings_new,
            title: '开机自启',
            subtitle: '系统启动时自动运行',
            value: _autoStartEnabled,
            onChanged: _onAutoStartChanged,
          ),
          const SizedBox(height: 32),

          _buildCategoryHeader(1, '显示', colorScheme),
          const SizedBox(height: 16),
          _buildWindowLayerItem(
            icon: Icons.layers,
            title: '窗口层级',
            subtitle: '设置窗口的显示层级',
            value: _windowLayer,
            onChanged: _onWindowLayerChanged,
          ),
          const SizedBox(height: 32),

          _buildCategoryHeader(2, '外观', colorScheme),
          const SizedBox(height: 16),
          _buildThemeModeItem(
            icon: Icons.brightness_6,
            title: '明暗主题',
            subtitle: '选择应用的主题',
            value: _themeMode,
            onChanged: _onThemeModeChanged,
          ),
          const SizedBox(height: 16),
          _buildOpacitySlider(
            icon: Icons.opacity,
            title: '背景不透明度',
            subtitle: '调整窗口背景的透明度',
            value: _backgroundOpacity,
            onChanged: _onBackgroundOpacityChanged,
          ),
          const SizedBox(height: 16),
          _buildThemeColorPicker(
            icon: Icons.color_lens,
            title: '主题色',
            subtitle: '自定义应用的主题色',
            value: _themeColor,
            onChanged: _onThemeColorChanged,
          ),
          const SizedBox(height: 32),

          _buildCategoryHeader(3, '高级', colorScheme),
          const SizedBox(height: 16),
          _buildSettingItem(
            icon: Icons.task,
            title: '在任务栏显示',
            subtitle: '在任务栏中显示应用图标',
            value: _showInTaskbarEnabled,
            onChanged: _onShowInTaskbarChanged,
          ),
          const SizedBox(height: 16),
          _buildActionItem(
            icon: Icons.rocket_launch,
            title: '打开 OOBE',
            subtitle: '重新打开首次使用向导',
            onTap: _showOOBEDialog,
          ),
          const SizedBox(height: 32),

          _buildCategoryHeader(4, '关于', colorScheme),
          const SizedBox(height: 16),
          _buildAboutCard(colorScheme),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildCategoryHeader(int index, String title, ColorScheme colorScheme) {
    return Container(
      key: _categoryKeys[index],
      padding: const EdgeInsets.only(bottom: 16, top: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: colorScheme.onSurface,
          letterSpacing: 0,
        ),
      ),
    );
  }

  Widget _buildOpacitySlider({
    required IconData icon,
    required String title,
    required String subtitle,
    required double value,
    required ValueChanged<double> onChanged,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: colorScheme.onPrimaryContainer,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${(value * 100).round()}%',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Slider(
                  value: value,
                  min: 0.3,
                  max: 1.0,
                  divisions: 14,
                  onChanged: onChanged,
                  activeColor: colorScheme.primary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeColorPicker({
    required IconData icon,
    required String title,
    required String subtitle,
    required int? value,
    required ValueChanged<int?> onChanged,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final displayColor = value != null ? Color(value) : colorScheme.primary;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: colorScheme.onPrimaryContainer,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _showColorPickerDialog(onChanged),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: displayColor,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: colorScheme.outline.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
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
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
          ),
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
    } else {
      // 设置失败，静默处理
    }
  }

  // 窗口层级变化处理：0=常规,1=置顶,2=置底
  Future<void> _onWindowLayerChanged(int value) async {
    final settingsService = SettingsService.instance;

    try {
      final success = await settingsService.setWindowLevel(value);
      if (success) {
        setState(() {
          _windowLayer = value;
        });
        widget.onSettingsChanged?.call();
      }
    } catch (e) {
      // 静默处理异常
    }
  }

  Widget _buildWindowLayerItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required int value,
    required ValueChanged<int> onChanged,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
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
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButton<int>(
              value: value,
              underline: const SizedBox.shrink(),
              dropdownColor: colorScheme.surface,
              elevation: 1,
              borderRadius: BorderRadius.all(Radius.circular(12)),
              items: const [
                DropdownMenuItem(value: 1, child: Text('置顶')),
                DropdownMenuItem(value: 0, child: Text('常规')),
                DropdownMenuItem(value: 2, child: Text('置底')),
              ],
              onChanged: (v) {
                if (v == null) return;
                onChanged(v);
              },
            ),
          ),
        ],
      ),
    );
  }


  // 主题选择：0=亮色,1=暗色
  Future<void> _onThemeModeChanged(int value) async {
    final settingsService = SettingsService.instance;
    try {
      final success = await settingsService.setDarkMode(value == 1);
      if (success) {
        setState(() {
          _themeMode = value;
        });
        widget.onThemeChanged?.call();
      }
    } catch (e) {
      // 静默处理
    }
  }

  Widget _buildThemeModeItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required int value,
    required ValueChanged<int> onChanged,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
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
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButton<int>(
              value: value,
              underline: const SizedBox.shrink(),
              dropdownColor: colorScheme.surface,
              elevation: 1,
              borderRadius: BorderRadius.all(Radius.circular(12)),
              items: const [
                DropdownMenuItem(value: 0, child: Text('亮色')),
                DropdownMenuItem(value: 1, child: Text('暗色')),
              ],
              onChanged: (v) {
                if (v == null) return;
                onChanged(v);
              },
            ),
          ),
        ],
      ),
    );
  }


  // 已由 _onThemeModeChanged 处理主题切换

  Future<void> _onBackgroundOpacityChanged(double value) async {
    final settingsService = SettingsService.instance;
    final success = await settingsService.setBackgroundOpacity(value);
    
    if (success) {
      setState(() {
        _backgroundOpacity = value;
      });
      widget.onSettingsChanged?.call();
    } else {
      // 设置失败，静默处理
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
    } else {
      // 设置失败，静默处理
    }
  }

  Future<void> _onShowInTaskbarChanged(bool value) async {
    final settingsService = SettingsService.instance;
    final success = await settingsService.setShowInTaskbar(value);
    
    if (success) {
      setState(() {
        _showInTaskbarEnabled = value;
      });
      widget.onSettingsChanged?.call();
    } else {
      // 设置失败，静默处理
    }
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

  Widget _buildActionItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
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
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutCard(ColorScheme colorScheme) {
    return FutureBuilder<PackageInfo>(
      future: PackageInfo.fromPlatform(),
      builder: (context, snapshot) {
        final version = snapshot.data?.version ?? '加载中...';
        
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
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
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.info_outline,
                      color: colorScheme.onPrimaryContainer,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'FinitoBoard',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '版本 $version',
                          style: TextStyle(
                            fontSize: 14,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                '集中布置作业！',
                style: TextStyle(
                  fontSize: 15,
                  color: colorScheme.onSurface,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  TextButton.icon(
                    onPressed: () async {
                      final uri = Uri.parse('https://github.com/Xwei1645/finito_board');
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri);
                      }
                    },
                    icon: const Icon(Icons.open_in_new, size: 18),
                    label: const Text('GitHub'),
                  ),
                  TextButton.icon(
                    onPressed: () => _showLicenseDialog(context),
                    icon: const Icon(Icons.description, size: 18),
                    label: const Text('开放源代码许可'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showLicenseDialog(BuildContext context) async {
    try {
      final licenseText = await rootBundle.loadString('LICENSE');
      
      if (!context.mounted) return;
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('开放源代码许可'),
          content: SizedBox(
            width: 500,
            height: 400,
            child: SingleChildScrollView(
              child: SelectableText(
                licenseText,
                style: const TextStyle(
                  fontSize: 14,
                ),
              ),
            ),
          ),
          actionsAlignment: MainAxisAlignment.spaceBetween,
          actions: [
            TextButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                showLicensePage(
                  context: context,
                  applicationName: 'FinitoBoard',
                  applicationVersion: null,
                );
              },
              icon: const Icon(Icons.extension, size: 18),
              label: const Text('第三方库'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text('确定'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('无法加载许可证文件: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showColorPickerDialog(ValueChanged<int?> onChanged) {
    final colorScheme = Theme.of(context).colorScheme;
    Color selectedColor = _themeColor != null ? Color(_themeColor!) : colorScheme.primary;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text(
            '选择主题色',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: SizedBox(
            width: 320,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: double.infinity,
                  height: 60,
                  decoration: BoxDecoration(
                    color: selectedColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: colorScheme.outline.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '#${selectedColor.toARGB32().toRadixString(16).padLeft(8, '0').toUpperCase()}',
                      style: TextStyle(
                        color: selectedColor.computeLuminance() > 0.5 ? Colors.black : Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _buildColorSlider(
                  label: '红',
                  value: (selectedColor.r * 255.0).roundToDouble(),
                  onChanged: (value) {
                    setState(() {
                      selectedColor = Color.fromARGB(
                        (selectedColor.a * 255.0).round(),
                        value.toInt(),
                        (selectedColor.g * 255.0).round(),
                        (selectedColor.b * 255.0).round(),
                      );
                    });
                  },
                  activeColor: Colors.red,
                ),
                _buildColorSlider(
                  label: '绿',
                  value: (selectedColor.g * 255.0).roundToDouble(),
                  onChanged: (value) {
                    setState(() {
                      selectedColor = Color.fromARGB(
                        (selectedColor.a * 255.0).round(),
                        (selectedColor.r * 255.0).round(),
                        value.toInt(),
                        (selectedColor.b * 255.0).round(),
                      );
                    });
                  },
                  activeColor: Colors.green,
                ),
                _buildColorSlider(
                  label: '蓝',
                  value: (selectedColor.b * 255.0).roundToDouble(),
                  onChanged: (value) {
                    setState(() {
                      selectedColor = Color.fromARGB(
                        (selectedColor.a * 255.0).round(),
                        (selectedColor.r * 255.0).round(),
                        (selectedColor.g * 255.0).round(),
                        value.toInt(),
                      );
                    });
                  },
                  activeColor: Colors.blue,
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    colorScheme.primary,
                    Colors.red,
                    Colors.pink,
                    Colors.purple,
                    Colors.deepPurple,
                    Colors.indigo,
                    Colors.blue,
                    Colors.lightBlue,
                    Colors.cyan,
                    Colors.teal,
                    Colors.green,
                    Colors.lightGreen,
                    Colors.lime,
                    Colors.yellow,
                    Colors.amber,
                    Colors.orange,
                    Colors.deepOrange,
                    Colors.brown,
                    Colors.grey,
                    Colors.blueGrey,
                  ].map((color) => GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedColor = color;
                      });
                    },
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(4),
                        border: selectedColor.toARGB32() == color.toARGB32()
                            ? Border.all(color: colorScheme.primary, width: 2)
                            : Border.all(color: colorScheme.outline.withValues(alpha: 0.3), width: 1),
                      ),
                    ),
                  )).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () {
                onChanged(selectedColor.toARGB32());
                Navigator.of(context).pop();
              },
              child: const Text('确定'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorSlider({
    required String label,
    required double value,
    required ValueChanged<double> onChanged,
    required Color activeColor,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 20,
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: Slider(
            value: value,
            min: 0,
            max: 255,
            divisions: 255,
            onChanged: onChanged,
            activeColor: activeColor,
          ),
        ),
        SizedBox(
          width: 40,
          child: Text(
            value.toInt().toString(),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12),
          ),
        ),
      ],
    );
  }
}
