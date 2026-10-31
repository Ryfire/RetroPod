import 'package:flutter/cupertino.dart';
import 'package:retropod/core/extensions/build_context_extensions.dart';
import 'package:retropod/features/settings/models/device_color.dart';

/// Global note text color setting. [theme] follows the app theme
/// (light or dark); every other value pins the text to the matching
/// device color swatch.
enum NoteFontColor {
  theme,
  silver,
  black,
  oledBlack,
  red,
  orange,
  yellow,
  gold,
  lime,
  green,
  blue,
  pink,
  purple,
  brown;

  static NoteFontColor fromName(String raw) {
    try {
      return NoteFontColor.values.byName(raw);
    } catch (_) {
      return NoteFontColor.theme;
    }
  }

  String title(BuildContext context) {
    switch (this) {
      case theme:
        return context.localization.defaultFontColor;
      default:
        return DeviceColor.fromName(name).title(context);
    }
  }

  /// The resolved text color, or null when the note text should follow
  /// the current app theme color instead.
  Color? get textColor {
    switch (this) {
      case theme:
        return null;
      default:
        return DeviceColor.fromName(name).textColor;
    }
  }
}
