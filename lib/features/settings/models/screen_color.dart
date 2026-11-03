import 'package:flutter/cupertino.dart';
import 'package:retropod/core/extensions/build_context_extensions.dart';
import 'package:retropod/features/settings/models/device_color.dart';

/// Screen color setting shared by the Screen Background and Font Color
/// preferences. [theme] follows the current light/dark theme (and, for the
/// font color, picks black or white automatically from the effective
/// background); every other value pins the matching device color swatch.
enum ScreenColor {
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

  static ScreenColor fromName(String? raw) {
    if (raw == null) return ScreenColor.theme;
    try {
      return ScreenColor.values.byName(raw);
    } catch (_) {
      return ScreenColor.theme;
    }
  }

  /// Label inside the Screen Background picker.
  String backgroundTitle(BuildContext context) {
    switch (this) {
      case theme:
        return context.localization.themeDefaultColorOption;
      default:
        return DeviceColor.fromName(name).title(context);
    }
  }

  /// Label inside the Font Color picker.
  String fontTitle(BuildContext context) {
    switch (this) {
      case theme:
        return context.localization.autoFontColorOption;
      default:
        return DeviceColor.fromName(name).title(context);
    }
  }

  /// The light end of the device color gradient, used as a screen
  /// background swatch, or null when the setting should follow the theme.
  Color? get backgroundColor {
    switch (this) {
      case theme:
        return null;
      default:
        return DeviceColor.fromName(name).textColor;
    }
  }

  /// The darker gradient end, used as a font color swatch so the palette
  /// reads as saturated text colors instead of pastels.
  Color? get fontSwatchColor {
    switch (this) {
      case theme:
        return null;
      default:
        return DeviceColor.fromName(name).deepTextColor;
    }
  }

  /// Picks a readable text color for [background] by its luminance. Used
  /// when the font color setting is on Auto.
  static Color autoContrastTextColor(Color background) {
    return background.computeLuminance() > 0.5
        ? const Color(0xFF101214)
        : const Color(0xFFE6E7EA);
  }
}
