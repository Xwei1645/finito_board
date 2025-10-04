import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../services/settings_service.dart';


class SettingsWindow extends StatefulWidget {
  const SettingsWindow({
    super.key,
  });

  @override
  State<SettingsWindow> createState() => _SettingsWindowState();
}

class _SettingsWindowState extends State<SettingsWindow> {
  bool _autoStartEnabled = false;
  bool _alwaysOnBottomEnabled = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settingsService = SettingsService.instance;
    
    // 获取保存的设置
    final savedAlwaysOnBottom = settingsService.getAlwaysOnBottom();
    
    // 检查系统中的实际开机自启状态
    final actualAutoStart = await settingsService.checkAutoStartStatus();
    
    // 如果保存的状态与实际状态不一致，使用实际状态
    // (静默处理状态不一致的情况)
    
    setState(() {
      _autoStartEnabled = actualAutoStart; // 使用实际状态
      _alwaysOnBottomEnabled = savedAlwaysOnBottom;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        width: 500,
        height: 600,
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题栏
            Row(
              children: [
                Icon(
                  Icons.more_horiz,
                  color: colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  '更多选项',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // 内容区域
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_isLoading)
                      const Center(
                        child: CircularProgressIndicator(),
                      )
                    else ...[
                      // 开机自启设置
                      if (SettingsService.instance.isAutoStartSupported)
                        _buildSettingItem(
                          icon: Icons.power_settings_new,
                          title: '开机自启',
                          subtitle: '系统启动时自动运行',
                          value: _autoStartEnabled,
                          onChanged: _onAutoStartChanged,
                        ),
                      
                      // 始终置底设置
                      if (SettingsService.instance.isAlwaysOnBottomSupported)
                        _buildSettingItem(
                          icon: Icons.vertical_align_bottom,
                          title: '始终置底',
                          subtitle: '始终保窗口在其他窗口下方',
                          value: _alwaysOnBottomEnabled,
                          onChanged: _onAlwaysOnBottomChanged,
                        ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // 底部按钮
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton.icon(
                  onPressed: () {
                    _showAboutDialog(context);
                  },
                  icon: Icon(
                    Icons.info_outlined,
                    size: 18,
                    color: colorScheme.primary,
                  ),
                  label: Text(
                    '关于 FinitoBoard',
                    style: TextStyle(
                      color: colorScheme.primary,
                    ),
                  ),
                ),
                FilledButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
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
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: colorScheme.primary,
              size: 20,
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
                    fontSize: 14,
                    color: colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: colorScheme.primary,
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



  void _showAboutDialog(BuildContext context) async {
    final packageInfo = await PackageInfo.fromPlatform();
    
    if (!context.mounted) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('关于 FinitoBoard'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('FinitoBoard'),
            const SizedBox(height: 8),
            Text('版本: ${packageInfo.version}'),
            const SizedBox(height: 8),
            const Text('集中布置作业！'),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () async {
                final uri = Uri.parse('https://github.com/Xwei1645/finito_board');
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri);
                }
              },
              icon: const Icon(Icons.open_in_new),
              label: const Text('GitHub'),
            ),
          ],
        ),
        actions: [
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
  }
}