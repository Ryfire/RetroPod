import 'package:flutter/cupertino.dart';
import 'package:retropod/core/constants/assets.dart';
import 'package:retropod/core/extensions/build_context_extensions.dart';

enum AppTheme {
  light,
  dark;

  static AppTheme fromName(String value) {
    return AppTheme.values.firstWhere(
      (theme) => theme.name == value,
      orElse: () => AppTheme.light,
    );
  }

  String title(BuildContext context) {
    switch (this) {
      case AppTheme.light:
        return context.localization.lightThemeTitle;
      case AppTheme.dark:
        return context.localization.darkThemeTitle;
    }
  }

  /// [backgroundColor] and [textColor] are the picked Screen Background and
  /// Font Color overrides; null keeps the theme's own colors.
  CupertinoThemeData toCupertinoTheme({
    Color? backgroundColor,
    Color? textColor,
  }) {
    switch (this) {
      case AppTheme.light:
        return CupertinoThemeData(
          brightness: Brightness.light,
          scaffoldBackgroundColor:
              backgroundColor ?? CupertinoColors.white,
          barBackgroundColor: backgroundColor ?? CupertinoColors.white,
          primaryColor: CupertinoColors.activeBlue,
          textTheme: CupertinoTextThemeData(
            textStyle: TextStyle(
              color: textColor ?? CupertinoColors.black,
              fontFamily: Assets.appFont,
            ),
          ),
        );
      case AppTheme.dark:
        return CupertinoThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor:
              backgroundColor ?? const Color(0xFF1F1F21),
          barBackgroundColor:
              backgroundColor ?? const Color(0xFF2C2C2E),
          primaryColor: CupertinoColors.activeBlue,
          textTheme: CupertinoTextThemeData(
            textStyle: TextStyle(
              color: textColor ?? CupertinoColors.white,
              fontFamily: Assets.appFont,
            ),
          ),
        );
    }
  }
}
