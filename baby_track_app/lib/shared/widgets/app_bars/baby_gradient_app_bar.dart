import 'package:flutter/material.dart';

class BabyGradientAppBar extends StatelessWidget implements PreferredSizeWidget {
  const BabyGradientAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.actions,
    this.showBackButton = true,
    this.onBack,
    this.toolbarHeight,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final List<Widget>? actions;
  final bool showBackButton;
  final VoidCallback? onBack;
  final double? toolbarHeight;

  @override
  Size get preferredSize => Size.fromHeight(toolbarHeight ?? kToolbarHeight);

  LinearGradient _buildGradient(ColorScheme colorScheme) {
    final blendedColor =
        Color.lerp(colorScheme.primary, colorScheme.secondary, 0.5) ?? colorScheme.primary;

    return LinearGradient(
      colors: [colorScheme.primary, blendedColor, colorScheme.secondary],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final titleStyle = textTheme.titleMedium?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ) ??
        const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 18,
          letterSpacing: 0.5,
        );

    final subtitleStyle = textTheme.bodySmall?.copyWith(
          color: Colors.white.withOpacity(0.85),
          fontWeight: FontWeight.w600,
        ) ??
        TextStyle(
          color: Colors.white.withOpacity(0.85),
          fontSize: 13,
          fontWeight: FontWeight.w500,
        );

    final iconWidget = icon == null
        ? null
        : Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.3)),
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          );

    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      automaticallyImplyLeading: false,
      toolbarHeight: toolbarHeight,
      leadingWidth: showBackButton ? 56 : 0,
      leading: showBackButton
          ? Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: IconButton(
                onPressed: onBack ?? () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                tooltip: 'Volver',
              ),
            )
          : null,
      flexibleSpace: Container(
        decoration: BoxDecoration(gradient: _buildGradient(colorScheme)),
      ),
      title: Row(
        children: [
          if (iconWidget != null) iconWidget,
          if (iconWidget != null) const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, style: titleStyle),
                if (subtitle != null) Text(subtitle!, style: subtitleStyle),
              ],
            ),
          ),
        ],
      ),
      actions: actions,
    );
  }
}
