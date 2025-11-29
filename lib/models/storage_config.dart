/// 存储配置模型
class StorageConfig {
  // 快照设置
  final bool snapshotEnabled; // 是否启用快照
  final bool snapshotOnEdit; // 每次编辑后自动快照
  final bool snapshotOnStartup; // 应用启动时自动快照
  final bool snapshotOnExit; // 退出应用时自动快照
  final bool limitSnapshotCount; // 是否限制快照数量
  final int maxSnapshotCount; // 最大快照数量

  // 备份设置
  final bool autoBackupEnabled; // 是否启用自动备份
  final bool backupOnStartup; // 应用启动时备份
  final bool backupOnConfigChange; // 配置修改时备份
  final bool backupOnExit; // 退出应用时备份
  final bool limitBackupCount; // 是否限制备份数量
  final int maxAutoBackupCount; // 最大自动备份数量

  const StorageConfig({
    this.snapshotEnabled = false,
    this.snapshotOnEdit = false,
    this.snapshotOnStartup = false,
    this.snapshotOnExit = false,
    this.limitSnapshotCount = true,
    this.maxSnapshotCount = 20,
    this.autoBackupEnabled = true,
    this.backupOnStartup = true,
    this.backupOnConfigChange = false,
    this.backupOnExit = true,
    this.limitBackupCount = true,
    this.maxAutoBackupCount = 10,
  });

  /// 从JSON创建StorageConfig
  factory StorageConfig.fromJson(Map<String, dynamic> json) {
    return StorageConfig(
      snapshotEnabled: json['snapshotEnabled'] as bool? ?? false,
      snapshotOnEdit: json['snapshotOnEdit'] as bool? ?? false,
      snapshotOnStartup: json['snapshotOnStartup'] as bool? ?? false,
      snapshotOnExit: json['snapshotOnExit'] as bool? ?? false,
      limitSnapshotCount: json['limitSnapshotCount'] as bool? ?? true,
      maxSnapshotCount: json['maxSnapshotCount'] as int? ?? 20,
      autoBackupEnabled: json['autoBackupEnabled'] as bool? ?? true,
      backupOnStartup: json['backupOnStartup'] as bool? ?? true,
      backupOnConfigChange: json['backupOnConfigChange'] as bool? ?? false,
      backupOnExit: json['backupOnExit'] as bool? ?? true,
      limitBackupCount: json['limitBackupCount'] as bool? ?? true,
      maxAutoBackupCount: json['maxAutoBackupCount'] as int? ?? 10,
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'snapshotEnabled': snapshotEnabled,
      'snapshotOnEdit': snapshotOnEdit,
      'snapshotOnStartup': snapshotOnStartup,
      'snapshotOnExit': snapshotOnExit,
      'limitSnapshotCount': limitSnapshotCount,
      'maxSnapshotCount': maxSnapshotCount,
      'autoBackupEnabled': autoBackupEnabled,
      'backupOnStartup': backupOnStartup,
      'backupOnConfigChange': backupOnConfigChange,
      'backupOnExit': backupOnExit,
      'limitBackupCount': limitBackupCount,
      'maxAutoBackupCount': maxAutoBackupCount,
    };
  }

  /// 复制并修改部分字段
  StorageConfig copyWith({
    bool? snapshotEnabled,
    bool? snapshotOnEdit,
    bool? autoBackupEnabled,
    bool? backupOnStartup,
    bool? backupOnConfigChange,
    bool? backupOnExit,
    bool? limitBackupCount,
    int? maxAutoBackupCount,
  }) {
    return StorageConfig(
      snapshotEnabled: snapshotEnabled ?? this.snapshotEnabled,
      snapshotOnEdit: snapshotOnEdit ?? this.snapshotOnEdit,
      autoBackupEnabled: autoBackupEnabled ?? this.autoBackupEnabled,
      backupOnStartup: backupOnStartup ?? this.backupOnStartup,
      backupOnConfigChange: backupOnConfigChange ?? this.backupOnConfigChange,
      backupOnExit: backupOnExit ?? this.backupOnExit,
      limitBackupCount: limitBackupCount ?? this.limitBackupCount,
      maxAutoBackupCount: maxAutoBackupCount ?? this.maxAutoBackupCount,
    );
  }
}
