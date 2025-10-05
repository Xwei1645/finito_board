import 'package:flutter/material.dart';

class EmptyState extends StatelessWidget {
  final VoidCallback? onAddHomework;

  const EmptyState({
    super.key,
    this.onAddHomework,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    // 获取字体缩放因子
    final textScaleFactor = MediaQuery.textScalerOf(context).scale(1.0);
    final iconSize = 64 * textScaleFactor;
    final containerSize = 120 * textScaleFactor;

    return Center(
      child: Container(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 空状态图标
            Container(
              width: containerSize,
              height: containerSize,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(containerSize / 2),
              ),
              child: Icon(
                Icons.assignment,
                size: iconSize,
                color: colorScheme.primary.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 32),
            
            // 主要提示文字
            Text(
              '暂无作业',
              style: theme.textTheme.headlineMedium?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w600,
                fontSize: (theme.textTheme.headlineMedium?.fontSize ?? 28) * textScaleFactor,
              ),
            ),
            const SizedBox(height: 12),
            
            // 副标题提示文字
            Text(
              '点击右下角的 + 按钮开始添加作业',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontSize: (theme.textTheme.bodyLarge?.fontSize ?? 16) * textScaleFactor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}