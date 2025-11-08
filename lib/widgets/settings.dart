import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../services/settings_service.dart';
import 'oobe_dialog.dart';


class SettingsWindow extends StatefulWidget {
  final VoidCallback? onThemeChanged;
  final VoidCallback? onSettingsChanged;

  const SettingsWindow({
    super.key,
    this.onThemeChanged,
    this.onSettingsChanged,
  });

  @override
  State<SettingsWindow> createState() => _SettingsWindowState();
}

class _SettingsWindowState extends State<SettingsWindow> {
  bool _autoStartEnabled = false;
  bool _alwaysOnBottomEnabled = false;
  bool _darkModeEnabled = false;
  double _backgroundOpacity = 0.95;
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

    final savedAlwaysOnBottom = settingsService.getAlwaysOnBottom();
    final savedDarkMode = settingsService.getDarkMode();
    final savedBackgroundOpacity = settingsService.getBackgroundOpacity();

    final actualAutoStart = await settingsService.checkAutoStartStatus();

    setState(() {
      _autoStartEnabled = actualAutoStart;
      _alwaysOnBottomEnabled = savedAlwaysOnBottom;
      _darkModeEnabled = savedDarkMode;
      _backgroundOpacity = savedBackgroundOpacity;
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
                        icon: Icon(Icons.power_settings_new_outlined, size: 28),
                        selectedIcon: Icon(Icons.power_settings_new, size: 28),
                        label: Text('系统'),
                        padding: EdgeInsets.symmetric(vertical: 8),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.window_outlined, size: 28),
                        selectedIcon: Icon(Icons.window, size: 28),
                        label: Text('窗口'),
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
                        label: Text('其他'),
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

          _buildCategoryHeader(1, '窗口', colorScheme),
          const SizedBox(height: 16),
          _buildSettingItem(
            icon: Icons.vertical_align_bottom,
            title: '始终置底',
            subtitle: '始终保窗口在其他窗口下方',
            value: _alwaysOnBottomEnabled,
            onChanged: _onAlwaysOnBottomChanged,
          ),
          const SizedBox(height: 32),

          _buildCategoryHeader(2, '外观', colorScheme),
          const SizedBox(height: 16),
          _buildSettingItem(
            icon: Icons.dark_mode,
            title: '深色模式',
            subtitle: '切换应用的明暗主题',
            value: _darkModeEnabled,
            onChanged: _onDarkModeChanged,
          ),
          const SizedBox(height: 16),
          _buildOpacitySlider(
            icon: Icons.opacity,
            title: '背景不透明度',
            subtitle: '调整窗口背景的透明度',
            value: _backgroundOpacity,
            onChanged: _onBackgroundOpacityChanged,
          ),
          const SizedBox(height: 32),

          _buildCategoryHeader(3, '其他', colorScheme),
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

  /// 构建设置项
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

  /// 开机自启设置变更回调
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

  /// 始终置底设置变更回调
  Future<void> _onAlwaysOnBottomChanged(bool value) async {
    final settingsService = SettingsService.instance;
    final success = await settingsService.setAlwaysOnBottom(value);
    
    if (success) {
      setState(() {
        _alwaysOnBottomEnabled = value;
      });
    } else {
      // 设置失败，静默处理
    }
  }


  /// 明暗模式设置变更回调
  Future<void> _onDarkModeChanged(bool value) async {
    final settingsService = SettingsService.instance;
    final success = await settingsService.setDarkMode(value);
    
    if (success) {
      setState(() {
        _darkModeEnabled = value;
      });
      // 通知主应用主题已变更
      widget.onThemeChanged?.call();
    } else {
      // 设置失败，静默处理
    }
  }

  /// 背景不透明度设置变更回调
  Future<void> _onBackgroundOpacityChanged(double value) async {
    final settingsService = SettingsService.instance;
    final success = await settingsService.setBackgroundOpacity(value);
    
    if (success) {
      setState(() {
        _backgroundOpacity = value;
      });
      // 通知主应用更新背景设置
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
          // OOBE完成后重新加载设置页面的状态
          _loadSettings();
          
          // 通知主应用主题和设置变更
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

  // 构建关于卡片 - 大卡片展示应用信息
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
            // 左侧的第三方库按钮
            TextButton.icon(
              onPressed: () {
                Navigator.of(context).pop(); // 关闭当前对话框
                showLicensePage(
                  context: context,
                  applicationName: 'FinitoBoard',
                  applicationVersion: null, // 会自动从 pubspec.yaml 获取
                );
              },
              icon: const Icon(Icons.extension, size: 18),
              label: const Text('第三方库'),
            ),
            // 右侧的确定按钮
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
}