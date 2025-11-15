import 'package:flutter/material.dart';
import 'homework_board.dart';

class MainWindow extends StatelessWidget {
  final VoidCallback? onThemeChanged;
  
  const MainWindow({super.key, this.onThemeChanged});

  @override
  Widget build(BuildContext context) {
    return HomeworkBoard(onThemeChanged: onThemeChanged);
  }
}
