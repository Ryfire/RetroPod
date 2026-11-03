import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:retropod/core/constants/app_color_scheme.dart';
import 'package:retropod/core/widgets/app_colors_scope.dart';
import 'package:retropod/features/settings/models/screen_color.dart';
import 'package:retropod/l10n/generated/app_localizations.dart';

extension BuildContextExtensions on BuildContext {
  Size get screenSize {
    return MediaQuery.sizeOf(this);
  }

  TextStyle get appTextStyle => CupertinoTheme.of(this).textTheme.textStyle;

  GoRouter get router {
    return GoRouter.of(this);
  }

  AppLocalizations get localization {
    return AppLocalizations.of(this)!;
  }
}

extension BuildContextColorExtensions on BuildContext {
  /// The effective screen background: the picked color when the Screen
  /// Background setting is set, otherwise the theme color.
  Color get appBackgroundColor {
    final AppColorsScope? scope = AppColorsScope.maybeOf(this);
    return scope?.backgroundColor ??
        AppColorScheme.screenBackground.resolveFrom(this);
  }

  Color get appSurfaceColor {
    final AppColorsScope? scope = AppColorsScope.maybeOf(this);
    return scope?.backgroundColor ?? AppColorScheme.surface.resolveFrom(this);
  }

  /// The effective primary text color: the pinned font color, the Auto
  /// contrast color derived from the picked background, or the theme
  /// color when no override is active.
  Color get appPrimaryTextColor {
    return _fontColor(
      defaultColor: AppColorScheme.primaryText.resolveFrom(this),
    );
  }

  Color get appSecondaryTextColor {
    final AppColorsScope? scope = AppColorsScope.maybeOf(this);
    if (scope == null ||
        (scope.fontColor == null && scope.backgroundColor == null)) {
      return AppColorScheme.secondaryText.resolveFrom(this);
    }
    return appPrimaryTextColor.withValues(alpha: 0.6);
  }

  /// Text color on highlighted rows. The selection gradient does not
  /// depend on the picked background, so this keeps following the theme.
  Color get appInverseTextColor =>
      AppColorScheme.inverseText.resolveFrom(this);

  /// The effective list selection highlight: the picked Highlight Color,
  /// or the theme's static blue when no override is active.
  Color get appHighlightColor {
    final AppColorsScope? scope = AppColorsScope.maybeOf(this);
    return scope?.highlightColor ??
        AppColorScheme.selectedTile.resolveFrom(this);
  }

  /// The top-to-bottom gradient ends for a highlighted row, derived from
  /// [appHighlightColor] so a picked highlight renders with the same
  /// subtle darkening the theme's blue gradient has.
  List<Color> get appHighlightGradient {
    final Color highlight = appHighlightColor;
    return [
      Color.lerp(highlight, CupertinoColors.white, 0.15)!,
      Color.lerp(highlight, CupertinoColors.black, 0.18)!,
    ];
  }

  /// Text color that stays readable on any picked highlight color.
  Color get appHighlightTextColor =>
      ScreenColor.autoContrastTextColor(appHighlightColor);

  Color get appOutlineColor => AppColorScheme.outline.resolveFrom(this);

  Color get appDeviceScreenBorderColor =>
      AppColorScheme.deviceScreenBorder.resolveFrom(this);

  Color get appDeviceScreenBackgroundColor {
    final AppColorsScope? scope = AppColorsScope.maybeOf(this);
    return scope?.backgroundColor ??
        AppColorScheme.deviceScreenBackground.resolveFrom(this);
  }

  Color get appControlSurfaceColor =>
      AppColorScheme.controlSurface.resolveFrom(this);

  Color get appIconEmphasisColor {
    return _fontColor(
      defaultColor: AppColorScheme.iconEmphasis.resolveFrom(this),
    );
  }

  /// Resolves the font color for the current scope: pinned color, Auto
  /// contrast color derived from the picked background, or [defaultColor]
  /// when no scope or no overrides are present.
  Color _fontColor({required Color defaultColor}) {
    final AppColorsScope? scope = AppColorsScope.maybeOf(this);
    if (scope == null) return defaultColor;
    final Color? pinned = scope.fontColor;
    if (pinned != null) return pinned;
    final Color? background = scope.backgroundColor;
    if (background == null) return defaultColor;
    return ScreenColor.autoContrastTextColor(background);
  }
}
