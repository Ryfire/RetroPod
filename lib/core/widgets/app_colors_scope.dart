import 'package:flutter/cupertino.dart';

/// Carries the resolved Screen Background and Font Color settings above the
/// navigator so every [BuildContextExtensions] color lookup can apply them.
///
/// A null override means the setting follows the current theme; the
/// extensions then fall back to the static [AppColorScheme] colors. The
/// scope holds raw picked colors only - the Auto contrast resolution for
/// text happens in the extensions, where the effective background is known.
class AppColorsScope extends InheritedWidget {
  /// Picked screen background, null when following the theme.
  final Color? backgroundColor;

  /// Pinned font color, null when the font follows the theme or resolves
  /// automatically from the background.
  final Color? fontColor;

  /// Pinned list selection highlight color, null when following the theme's
  /// static blue.
  final Color? highlightColor;

  const AppColorsScope({
    super.key,
    required super.child,
    this.backgroundColor,
    this.fontColor,
    this.highlightColor,
  });

  static AppColorsScope? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<AppColorsScope>();
  }

  @override
  bool updateShouldNotify(AppColorsScope oldWidget) {
    return backgroundColor != oldWidget.backgroundColor ||
        fontColor != oldWidget.fontColor;
  }
}
