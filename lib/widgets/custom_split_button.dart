import 'package:flutter/material.dart';
import 'package:split_button_m3e/split_button_m3e.dart';

/// 自定义 SplitButton 组件
///
/// 基于 split_button_m3e，修改了：
/// 1. 菜单显示在按钮下方（默认位置）
/// 2. 箭头方向互换（默认向上，展开时向下）
/// 3. 菜单背景色为白色
class CustomSplitButton<T> extends StatefulWidget {
  const CustomSplitButton({
    super.key,
    this.shape = SplitButtonM3EShape.round,
    this.size = SplitButtonM3ESize.sm,
    this.emphasis = SplitButtonM3EEmphasis.tonal,
    this.label,
    this.leadingIcon,
    this.onPressed,
    required this.menuBuilder,
    this.onSelected,
    this.leadingTooltip,
    this.trailingTooltip,
    this.enabled = true,
    this.scaleFactor = 1.0,
  });

  final SplitButtonM3ESize size;
  final SplitButtonM3EShape shape;
  final SplitButtonM3EEmphasis emphasis;
  final String? label;
  final IconData? leadingIcon;
  final VoidCallback? onPressed;
  final List<PopupMenuEntry<T>> Function(BuildContext) menuBuilder;
  final ValueChanged<T>? onSelected;
  final String? leadingTooltip;
  final String? trailingTooltip;
  final bool enabled;
  final double scaleFactor;

  @override
  State<CustomSplitButton<T>> createState() => _CustomSplitButtonState<T>();
}

class _CustomSplitButtonState<T> extends State<CustomSplitButton<T>> {
  bool _menuOpen = false;
  final GlobalKey _buttonKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // 获取按钮的颜色配置
    final (Color containerColor, Color onContainerColor) = _getColors(
      colorScheme,
    );

    final height = _getHeight();
    final outerRadius = widget.shape == SplitButtonM3EShape.round
        ? height / 2
        : height * 0.25;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Leading segment (primary action)
        _buildLeadingSegment(
          containerColor: containerColor,
          onContainerColor: onContainerColor,
          height: height,
          outerRadius: outerRadius,
        ),
        SizedBox(width: 2 * widget.scaleFactor), // inner gap
        // Trailing segment (menu trigger)
        _buildTrailingSegment(
          key: _buttonKey,
          containerColor: containerColor,
          onContainerColor: onContainerColor,
          height: height,
          outerRadius: outerRadius,
        ),
      ],
    );
  }

  Widget _buildLeadingSegment({
    required Color containerColor,
    required Color onContainerColor,
    required double height,
    required double outerRadius,
  }) {
    final iconSize = _getIconSize();

    Widget content;
    if (widget.leadingIcon != null && widget.label != null) {
      content = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(widget.leadingIcon, size: iconSize, color: onContainerColor),
          SizedBox(width: 8 * widget.scaleFactor),
          Text(
            widget.label!,
            style: TextStyle(color: onContainerColor, fontSize: 14),
          ),
        ],
      );
    } else if (widget.leadingIcon != null) {
      content = Icon(
        widget.leadingIcon,
        size: iconSize,
        color: onContainerColor,
      );
    } else {
      content = Text(
        widget.label ?? '',
        style: TextStyle(color: onContainerColor, fontSize: 14),
      );
    }

    return Tooltip(
      message: widget.leadingTooltip ?? '',
      child: Material(
        color: containerColor,
        borderRadius: BorderRadius.horizontal(
          left: Radius.circular(outerRadius),
          right: Radius.circular(4 * widget.scaleFactor),
        ),
        child: InkWell(
          onTap: widget.enabled ? widget.onPressed : null,
          borderRadius: BorderRadius.horizontal(
            left: Radius.circular(outerRadius),
            right: Radius.circular(4 * widget.scaleFactor),
          ),
          child: Container(
            height: height,
            padding: EdgeInsets.symmetric(horizontal: _getHorizontalPadding()),
            child: Center(child: content),
          ),
        ),
      ),
    );
  }

  Widget _buildTrailingSegment({
    required Key key,
    required Color containerColor,
    required Color onContainerColor,
    required double height,
    required double outerRadius,
  }) {
    final iconSize = _getIconSize();

    return Tooltip(
      message: widget.trailingTooltip ?? '',
      child: Material(
        key: key,
        color: containerColor,
        borderRadius: BorderRadius.horizontal(
          left: Radius.circular(4 * widget.scaleFactor),
          right: Radius.circular(outerRadius),
        ),
        child: InkWell(
          onTap: widget.enabled ? () => _openMenu(context) : null,
          borderRadius: BorderRadius.horizontal(
            left: Radius.circular(4 * widget.scaleFactor),
            right: Radius.circular(outerRadius),
          ),
          child: Container(
            height: height,
            padding: EdgeInsets.symmetric(horizontal: 12 * widget.scaleFactor),
            child: Center(
              child: AnimatedRotation(
                duration: const Duration(milliseconds: 120),
                // 默认向上，展开时向下（旋转180度）
                turns: _menuOpen ? 0.5 : 0.0,
                curve: Curves.easeOut,
                child: Icon(
                  Icons.keyboard_arrow_up, // 改为向上箭头
                  size: iconSize,
                  color: onContainerColor,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openMenu(BuildContext context) async {
    setState(() => _menuOpen = true);

    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;

    final RenderBox? buttonBox =
        _buttonKey.currentContext?.findRenderObject() as RenderBox?;

    if (buttonBox == null) {
      setState(() => _menuOpen = false);
      return;
    }

    final Offset buttonTopLeft = buttonBox.localToGlobal(
      Offset.zero,
      ancestor: overlay,
    );

    final RelativeRect position = RelativeRect.fromLTRB(
      buttonTopLeft.dx,
      buttonTopLeft.dy,
      overlay.size.width - buttonTopLeft.dx - buttonBox.size.width,
      overlay.size.height - buttonTopLeft.dy - buttonBox.size.height,
    );

    final T? result = await showMenu<T>(
      context: context,
      position: position,
      constraints: BoxConstraints(
        minWidth: buttonBox.size.width * 0.7,
      ), // 减小宽度到按钮宽度的70%
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      items: widget.menuBuilder(context),
    );

    if (mounted) {
      setState(() => _menuOpen = false);
      if (result != null && widget.onSelected != null) {
        widget.onSelected!(result);
      }
    }
  }

  (Color, Color) _getColors(ColorScheme colorScheme) {
    switch (widget.emphasis) {
      case SplitButtonM3EEmphasis.filled:
        return (colorScheme.primary, colorScheme.onPrimary);
      case SplitButtonM3EEmphasis.tonal:
        return (
          colorScheme.secondaryContainer,
          colorScheme.onSecondaryContainer,
        );
      case SplitButtonM3EEmphasis.elevated:
        return (colorScheme.surfaceContainerLow, colorScheme.primary);
      case SplitButtonM3EEmphasis.outlined:
        return (Colors.transparent, colorScheme.primary);
      case SplitButtonM3EEmphasis.text:
        return (Colors.transparent, colorScheme.primary);
    }
  }

  double _getHeight() {
    double baseHeight;
    switch (widget.size) {
      case SplitButtonM3ESize.xs:
        baseHeight = 32;
        break;
      case SplitButtonM3ESize.sm:
        baseHeight = 40;
        break;
      case SplitButtonM3ESize.md:
        baseHeight = 56;
        break;
      case SplitButtonM3ESize.lg:
        baseHeight = 96;
        break;
      case SplitButtonM3ESize.xl:
        baseHeight = 136;
        break;
    }
    return baseHeight * widget.scaleFactor;
  }

  double _getIconSize() {
    double baseSize;
    switch (widget.size) {
      case SplitButtonM3ESize.xs:
        baseSize = 20;
        break;
      case SplitButtonM3ESize.sm:
        baseSize = 24;
        break;
      case SplitButtonM3ESize.md:
        baseSize = 24;
        break;
      case SplitButtonM3ESize.lg:
        baseSize = 32;
        break;
      case SplitButtonM3ESize.xl:
        baseSize = 40;
        break;
    }
    return baseSize * widget.scaleFactor;
  }

  double _getHorizontalPadding() {
    double basePadding;
    switch (widget.size) {
      case SplitButtonM3ESize.xs:
        basePadding = 12;
        break;
      case SplitButtonM3ESize.sm:
        basePadding = 16;
        break;
      case SplitButtonM3ESize.md:
        basePadding = 24;
        break;
      case SplitButtonM3ESize.lg:
        basePadding = 48;
        break;
      case SplitButtonM3ESize.xl:
        basePadding = 64;
        break;
    }
    return basePadding * widget.scaleFactor;
  }
}
