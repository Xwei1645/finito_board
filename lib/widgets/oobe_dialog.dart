import 'dart:io';
import 'package:flutter/material.dart';
import '../services/settings_service.dart';

class OOBEDialog extends StatefulWidget {
  final VoidCallback? onCompleted;
  final VoidCallback? onThemeChanged;
  
  const OOBEDialog({
    super.key,
    this.onCompleted,
    this.onThemeChanged,
  });

  @override
  State<OOBEDialog> createState() => _OOBEDialogState();
}

class _OOBEDialogState extends State<OOBEDialog> {
  bool _autoStart = false;
  bool _createDesktopShortcut = false;
  bool _createStartMenuShortcut = false;
  bool _isDarkMode = false;
  bool _isApplying = false;

  /// 检查是否为Windows平台
  bool get _isWindows => Platform.isWindows;

  @override
  void initState() {
    super.initState();
    _loadCurrentSettings();
  }

  Future<void> _loadCurrentSettings() async {
    final settingsService = SettingsService.instance;
    
    // 获取实际的开机自启状态
    final actualAutoStart = await settingsService.checkAutoStartStatus();
    
    setState(() {
      _autoStart = actualAutoStart;
      _isDarkMode = settingsService.getDarkMode();
    });
  }

  Future<void> _applySettings() async {
    setState(() {
      _isApplying = true;
    });

    try {
      final settingsService = SettingsService.instance;
      
      // 应用开机自启设置
      await settingsService.setAutoStart(_autoStart);
      
      // 应用主题设置
      await settingsService.setDarkMode(_isDarkMode);
      
      // 创建快捷方式（仅在Windows平台）
      if (_isWindows) {
        if (_createDesktopShortcut) {
          final desktopResult = await settingsService.createDesktopShortcut();
          if (!desktopResult.success && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('创建桌面快捷方式失败: ${desktopResult.error}'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
        
        if (_createStartMenuShortcut) {
          final startMenuResult = await settingsService.createStartMenuShortcut();
          if (!startMenuResult.success && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('创建开始菜单快捷方式失败: ${startMenuResult.error}'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
      }
      
      // 标记OOBE已完成
      await _markOOBECompleted();
      
      if (widget.onCompleted != null) {
        widget.onCompleted!();
      }
      
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      // 处理错误
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('设置应用失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isApplying = false;
        });
      }
    }
  }

  Future<void> _markOOBECompleted() async {
    final settingsService = SettingsService.instance;
    await settingsService.markOOBECompleted();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: 480,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题
            Row(
              children: [
                Icon(
                  Icons.rocket_launch,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).primaryColor,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  '欢迎使用 FinitoBoard',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '让我们快速设置一下，以获得最佳体验',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
            const SizedBox(height: 24),
            
            // 设置选项
            _buildSettingItem(
              icon: Icons.power_settings_new,
              title: '开机自启',
              subtitle: '在系统启动时自动运行本应用',
              value: _autoStart,
              onChanged: (value) {
                setState(() {
                  _autoStart = value;
                });
              },
            ),
            
            if (_isWindows)
              _buildSettingItem(
                icon: Icons.desktop_windows,
                title: '创建桌面快捷方式',
                subtitle: '在桌面上添加软件快捷方式',
                value: _createDesktopShortcut,
                onChanged: (value) {
                  setState(() {
                    _createDesktopShortcut = value;
                  });
                },
              ),
            
            if (_isWindows)
              _buildSettingItem(
                icon: Icons.apps,
                title: '创建开始菜单快捷方式',
                subtitle: '在开始菜单上添加软件快捷方式',
                value: _createStartMenuShortcut,
                onChanged: (value) {
                  setState(() {
                    _createStartMenuShortcut = value;
                  });
                },
              ),
            
            const SizedBox(height: 16),
            
            // 主题选择
            Text(
              '主题设置',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            
            Row(
              children: [
                Expanded(
                  child: _buildThemeOption(
                    context,
                    icon: Icons.light_mode,
                    title: '浅色模式',
                    isSelected: !_isDarkMode,
                    onTap: () async {
                      setState(() {
                        _isDarkMode = false;
                      });
                      // 立即应用主题变化
                      final settingsService = SettingsService.instance;
                      await settingsService.setDarkMode(false);
                      if (widget.onThemeChanged != null) {
                        widget.onThemeChanged!();
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildThemeOption(
                    context,
                    icon: Icons.dark_mode,
                    title: '深色模式',
                    isSelected: _isDarkMode,
                    onTap: () async {
                      setState(() {
                        _isDarkMode = true;
                      });
                      // 立即应用主题变化
                      final settingsService = SettingsService.instance;
                      await settingsService.setDarkMode(true);
                      if (widget.onThemeChanged != null) {
                        widget.onThemeChanged!();
                      }
                    },
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 32),
            
            // 按钮
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _isApplying ? null : () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('跳过'),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: _isApplying ? null : _applySettings,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: _isApplying
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('完成设置'),
                ),
              ],
            ),
          ],
        ),
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: (Theme.of(context).brightness == Brightness.dark
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).primaryColor)
                  .withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).primaryColor,
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
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
              ],
            ),
          ),
          Checkbox(
            value: value,
            onChanged: (bool? value) => onChanged(value ?? false),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected
                ? (Theme.of(context).brightness == Brightness.dark
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).primaryColor)
                : Theme.of(context).dividerColor,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected
              ? (Theme.of(context).brightness == Brightness.dark
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).primaryColor)
                  .withValues(alpha: 0.05)
              : null,
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? (Theme.of(context).brightness == Brightness.dark
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).primaryColor)
                  : Theme.of(context).iconTheme.color,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isSelected
                    ? (Theme.of(context).brightness == Brightness.dark
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).primaryColor)
                    : null,
                fontWeight: isSelected ? FontWeight.w600 : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}