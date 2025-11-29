import 'package:flutter/material.dart';
import '../../services/storage/backup_service.dart';
import '../../services/storage/snapshot_service.dart';

class StorageWidgets {
  static Widget buildCheckboxOption({
    required ColorScheme colorScheme,
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
        child: Row(
          children: [
            Icon(icon, size: 20, color: colorScheme.onSurfaceVariant),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
            Checkbox(value: value, onChanged: (v) => onChanged(v ?? false)),
          ],
        ),
      ),
    );
  }

  static Widget buildSwitchOption({
    required ColorScheme colorScheme,
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurface,
              ),
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }

  static Widget buildCountControl({
    required ColorScheme colorScheme,
    required String title,
    required int value,
    required VoidCallback onDecrement,
    required VoidCallback onIncrement,
    bool canDecrement = true,
  }) {
    return Row(
      children: [
        Icon(Icons.inventory_2, size: 20, color: colorScheme.onSurfaceVariant),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: colorScheme.onSurface,
          ),
        ),
        const Spacer(),
        IconButton(
          onPressed: canDecrement ? onDecrement : null,
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
            '$value',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
            ),
          ),
        ),
        const SizedBox(width: 12),
        IconButton(onPressed: onIncrement, icon: const Icon(Icons.add)),
      ],
    );
  }

  static Future<void> performManualBackup(Function(String) showSnackBar) async {
    showSnackBar('正在备份...');
    final success = await BackupService.instance.performBackup(isAuto: false);
    if (success) {
      showSnackBar('备份成功');
    } else {
      showSnackBar('备份失败，请检查权限');
    }
  }

  static Future<void> openBackupDirectory(Function(String) showSnackBar) async {
    final success = await BackupService.instance.openBackupDirectory();
    if (!success) {
      showSnackBar('无法打开备份目录');
    }
  }

  static Future<void> createManualSnapshot(
    Function(String) showSnackBar,
  ) async {
    showSnackBar('正在创建快照...');
    final success = await SnapshotService.instance.createSnapshot(
      isAuto: false,
      trigger: 'manual',
    );
    if (success) {
      showSnackBar('快照创建成功');
    } else {
      showSnackBar('快照创建失败，可能没有作业数据');
    }
  }

  static Future<void> openSnapshotDirectory(
    Function(String) showSnackBar,
  ) async {
    final success = await SnapshotService.instance.openSnapshotDirectory();
    if (!success) {
      showSnackBar('无法打开快照目录');
    }
  }
}
