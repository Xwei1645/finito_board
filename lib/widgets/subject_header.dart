import 'package:flutter/material.dart';

class SubjectHeader extends StatelessWidget {
  final String subjectName;
  final int homeworkCount;

  const SubjectHeader({
    super.key,
    required this.subjectName,
    required this.homeworkCount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textScaleFactor = MediaQuery.textScalerOf(context).scale(1.0);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8, top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          Text(
            subjectName,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: Colors.black87,
              fontSize: (theme.textTheme.titleLarge?.fontSize ?? 22) * textScaleFactor,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$homeworkCount',
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w500,
                color: Colors.blue,
                fontSize: (theme.textTheme.labelSmall?.fontSize ?? 11) * textScaleFactor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}