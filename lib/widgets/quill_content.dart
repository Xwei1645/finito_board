import 'dart:convert';
import 'package:flutter/material.dart';

class QuillContent extends StatelessWidget {
  final String content;
  final TextScaler textScaler;

  const QuillContent({
    super.key,
    required this.content,
    this.textScaler = TextScaler.noScaling,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final defaultTextStyle = theme.textTheme.bodyMedium ?? const TextStyle();

    try {
      final deltaJson = jsonDecode(content);
      final delta = deltaJson as List;

      if (delta.isEmpty) {
        return const SizedBox.shrink();
      }

      final spans = <TextSpan>[];
      for (final op in delta) {
        if (op is Map && op.containsKey('insert')) {
          final text = op['insert'] as String;
          final attributes = op['attributes'] as Map<String, dynamic>?;

          TextStyle style = defaultTextStyle;
          if (attributes != null) {
            if (attributes.containsKey('bold')) {
              style = style.copyWith(fontWeight: FontWeight.bold);
            }
            if (attributes.containsKey('italic')) {
              style = style.copyWith(fontStyle: FontStyle.italic);
            }
            if (attributes.containsKey('strike')) {
              style = style.copyWith(decoration: TextDecoration.lineThrough);
            }
            if (attributes.containsKey('underline')) {
              style = style.copyWith(decoration: TextDecoration.underline);
            }
            if (attributes.containsKey('size')) {
              final fontSize = double.tryParse(attributes['size'].toString());
              if (fontSize != null) {
                style = style.copyWith(fontSize: fontSize);
              }
            }
          }

          spans.add(TextSpan(text: text, style: style));
        }
      }

      return RichText(
        text: TextSpan(children: spans),
        textScaler: textScaler,
      );
    } catch (e) {
      // Fallback for plain text
      return Text(
        content,
        style: defaultTextStyle,
        textScaler: textScaler,
      );
    }
  }
}