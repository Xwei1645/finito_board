import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:window_manager/window_manager.dart';

class AppearanceWidgets {
  static Widget buildOpacitySlider({
    required BuildContext context,
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
            child: Icon(icon, color: colorScheme.onPrimaryContainer, size: 24),
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
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

  static Widget buildThemeColorPicker({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required int? value,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final displayColor = value != null ? Color(value) : colorScheme.primary;

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
            child: Icon(icon, color: colorScheme.onPrimaryContainer, size: 24),
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
                    GestureDetector(
                      onTap: onTap,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: displayColor,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: colorScheme.outline.withValues(alpha: 0.3),
                            width: 1,
                          ),
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
              ],
            ),
          ),
        ],
      ),
    );
  }

  static void showColorPickerDialog(
    BuildContext context,
    int? currentThemeColor,
    ValueChanged<int?> onChanged,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    Color selectedColor = currentThemeColor != null
        ? Color(currentThemeColor)
        : colorScheme.primary;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text(
            '选择主题色',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: SizedBox(
            width: 320,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: double.infinity,
                  height: 60,
                  decoration: BoxDecoration(
                    color: selectedColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: colorScheme.outline.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '#${selectedColor.toARGB32().toRadixString(16).padLeft(8, '0').toUpperCase()}',
                      style: TextStyle(
                        color: selectedColor.computeLuminance() > 0.5
                            ? Colors.black
                            : Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _buildColorSlider(
                  label: '红',
                  value: (selectedColor.r * 255.0).roundToDouble(),
                  onChanged: (value) {
                    setState(() {
                      selectedColor = Color.fromARGB(
                        (selectedColor.a * 255.0).round(),
                        value.toInt(),
                        (selectedColor.g * 255.0).round(),
                        (selectedColor.b * 255.0).round(),
                      );
                    });
                  },
                  activeColor: Colors.red,
                ),
                _buildColorSlider(
                  label: '绿',
                  value: (selectedColor.g * 255.0).roundToDouble(),
                  onChanged: (value) {
                    setState(() {
                      selectedColor = Color.fromARGB(
                        (selectedColor.a * 255.0).round(),
                        (selectedColor.r * 255.0).round(),
                        value.toInt(),
                        (selectedColor.b * 255.0).round(),
                      );
                    });
                  },
                  activeColor: Colors.green,
                ),
                _buildColorSlider(
                  label: '蓝',
                  value: (selectedColor.b * 255.0).roundToDouble(),
                  onChanged: (value) {
                    setState(() {
                      selectedColor = Color.fromARGB(
                        (selectedColor.a * 255.0).round(),
                        (selectedColor.r * 255.0).round(),
                        (selectedColor.g * 255.0).round(),
                        value.toInt(),
                      );
                    });
                  },
                  activeColor: Colors.blue,
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children:
                      [
                            colorScheme.primary,
                            Colors.red,
                            Colors.pink,
                            Colors.purple,
                            Colors.deepPurple,
                            Colors.indigo,
                            Colors.blue,
                            Colors.lightBlue,
                            Colors.cyan,
                            Colors.teal,
                            Colors.green,
                            Colors.lightGreen,
                            Colors.lime,
                            Colors.yellow,
                            Colors.amber,
                            Colors.orange,
                            Colors.deepOrange,
                            Colors.brown,
                            Colors.grey,
                            Colors.blueGrey,
                          ]
                          .map(
                            (color) => GestureDetector(
                              onTap: () {
                                setState(() {
                                  selectedColor = color;
                                });
                              },
                              child: Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: color,
                                  borderRadius: BorderRadius.circular(4),
                                  border:
                                      selectedColor.toARGB32() ==
                                          color.toARGB32()
                                      ? Border.all(
                                          color: colorScheme.primary,
                                          width: 2,
                                        )
                                      : Border.all(
                                          color: colorScheme.outline.withValues(
                                            alpha: 0.3,
                                          ),
                                          width: 1,
                                        ),
                                ),
                              ),
                            ),
                          )
                          .toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () {
                onChanged(selectedColor.toARGB32());
                Navigator.of(context).pop();
              },
              child: const Text('确定'),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildColorSlider({
    required String label,
    required double value,
    required ValueChanged<double> onChanged,
    required Color activeColor,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 20,
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: Slider(
            value: value,
            min: 0,
            max: 255,
            divisions: 255,
            onChanged: onChanged,
            activeColor: activeColor,
          ),
        ),
        SizedBox(
          width: 40,
          child: Text(
            value.toInt().toString(),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12),
          ),
        ),
      ],
    );
  }

  static Widget buildBackgroundImagePicker({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required String? path,
    required int mode,
    required double opacity,
    required ValueChanged<String?> onPathChanged,
    required ValueChanged<int> onModeChanged,
    required ValueChanged<double> onOpacityChanged,
    required VoidCallback onClear,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasImage = path != null && path.isNotEmpty;

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
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
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
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () async {
                          final result = await FilePicker.platform.pickFiles(
                            type: FileType.image,
                            allowMultiple: false,
                          );
                          if (result != null && result.files.isNotEmpty) {
                            onPathChanged(result.files.first.path);
                          }
                        },
                        icon: const Icon(Icons.folder_open, size: 18),
                        label: Text(hasImage ? '更换图片' : '选择图片'),
                      ),
                    ),
                    if (hasImage) ...[
                      const SizedBox(width: 12),
                      TextButton.icon(
                        onPressed: onClear,
                        icon: const Icon(Icons.clear, size: 18),
                        label: const Text('清空'),
                      ),
                    ],
                  ],
                ),
                if (hasImage) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Row(
                          children: [
                            Text(
                              '显示模式:',
                              style: TextStyle(
                                fontSize: 14,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: DropdownButton<int>(
                                value: mode,
                                underline: const SizedBox.shrink(),
                                dropdownColor: colorScheme.surface,
                                elevation: 1,
                                borderRadius: const BorderRadius.all(
                                  Radius.circular(8),
                                ),
                                items: const [
                                  DropdownMenuItem(value: 0, child: Text('适应')),
                                  DropdownMenuItem(value: 1, child: Text('填充')),
                                  DropdownMenuItem(value: 2, child: Text('拉伸')),
                                ],
                                onChanged: (v) {
                                  if (v != null) {
                                    onModeChanged(v);
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        flex: 8,
                        child: Row(
                          children: [
                            Text(
                              '混合比例:',
                              style: TextStyle(
                                fontSize: 14,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Slider(
                                value: opacity,
                                min: 0.0,
                                max: 1.0,
                                divisions: 100,
                                onChanged: onOpacityChanged,
                                activeColor: colorScheme.primary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '${(opacity * 100).round()}%',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 1,
            child: hasImage
                ? FutureBuilder<Size>(
                    future: _getWindowSize(),
                    builder: (context, snapshot) {
                      final windowSize = snapshot.data ?? const Size(1200, 800);
                      final aspectRatio = windowSize.width / windowSize.height;

                      return LayoutBuilder(
                        builder: (context, constraints) {
                          final availableHeight = constraints.maxHeight;
                          final availableWidth = constraints.maxWidth;

                          double innerWidth = availableWidth - 16;
                          double innerHeight = availableHeight - 16;

                          if (innerWidth / innerHeight > aspectRatio) {
                            innerWidth = innerHeight * aspectRatio;
                          } else {
                            innerHeight = innerWidth / aspectRatio;
                          }

                          return Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: SizedBox(
                                  width: innerWidth,
                                  height: innerHeight,
                                  child: Stack(
                                    children: [
                                      Container(color: colorScheme.surface),
                                      Opacity(
                                        opacity: opacity,
                                        child: FittedBox(
                                          fit: BoxFit.fill,
                                          child: SizedBox(
                                            width: innerWidth,
                                            height: innerHeight,
                                            child: Image.file(
                                              File(path),
                                              fit: _getBoxFitFromMode(mode),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  )
                : Container(
                    height: 120,
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest.withValues(
                        alpha: 0.3,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: colorScheme.outline.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.image_not_supported,
                        size: 48,
                        color: colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.5,
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  static BoxFit _getBoxFitFromMode(int mode) {
    switch (mode) {
      case 0:
        return BoxFit.contain;
      case 1:
        return BoxFit.cover;
      case 2:
        return BoxFit.fill;
      default:
        return BoxFit.contain;
    }
  }

  static Future<Size> _getWindowSize() async {
    try {
      final bounds = await windowManager.getBounds();
      return Size(bounds.width, bounds.height);
    } catch (e) {
      return const Size(1200, 800);
    }
  }
}
