import 'package:flutter/material.dart';

class SubjectHeader extends StatelessWidget {
  final String subjectName;
  final int homeworkCount;
  final double scaleFactor;

  const SubjectHeader({
    super.key,
    required this.subjectName,
    required this.homeworkCount,
    this.scaleFactor = 100.0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final s = scaleFactor / 100.0;

    return Container(
      margin: EdgeInsets.only(bottom: 2 * s, top: 8 * s),
      padding: EdgeInsets.symmetric(horizontal: 12 * s, vertical: 6 * s),
      child: Row(
        children: [
          Text(
            subjectName,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          SizedBox(width: 8 * s),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8 * s, vertical: 2 * s),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12 * s),
            ),
            child: Text(
              '$homeworkCount',
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w500,
                color: colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
