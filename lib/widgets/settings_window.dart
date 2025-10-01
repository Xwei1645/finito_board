import 'package:flutter/material.dart';

class SettingsWindow extends StatefulWidget {
  final bool isAlwaysOnBottom;
  final bool isAutoStart;
  final Function(bool) onAlwaysOnBottomChanged;
  final Function(bool) onAutoStartChanged;

  const SettingsWindow({
    super.key,
    required this.isAlwaysOnBottom,
    required this.isAutoStart,
    required this.onAlwaysOnBottomChanged,
    required this.onAutoStartChanged,
  });

  @override
  State<SettingsWindow> createState() => _SettingsWindowState();
}

class _SettingsWindowState extends State<SettingsWindow> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('更多设置'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
      ),
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSettingSection(
              title: '窗口设置',
              children: [
                _buildSwitchTile(
                  title: '始终置底',
                  subtitle: '窗口始终保持在其他窗口下方',
                  value: widget.isAlwaysOnBottom,
                  onChanged: widget.onAlwaysOnBottomChanged,
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildSettingSection(
              title: '系统设置',
              children: [
                _buildSwitchTile(
                  title: '开机自启',
                  subtitle: '系统启动时自动运行应用',
                  value: widget.isAutoStart,
                  onChanged: widget.onAutoStartChanged,
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildSettingSection(
              title: '其他设置',
              children: [
                _buildActionTile(
                  title: '关于应用',
                  subtitle: '查看应用版本和信息',
                  icon: Icons.info_outline,
                  onTap: () {
                    // TODO: 显示关于对话框
                  },
                ),
                _buildActionTile(
                  title: '反馈建议',
                  subtitle: '提交问题或建议',
                  icon: Icons.feedback_outlined,
                  onTap: () {
                    // TODO: 打开反馈页面
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return ListTile(
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey[600],
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeThumbColor: Colors.blue,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }

  Widget _buildActionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: Colors.grey[600],
        size: 20,
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey[600],
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: Colors.grey[400],
        size: 20,
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }
}