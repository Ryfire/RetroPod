import 'package:flutter/cupertino.dart';
import 'package:retropod/core/extensions/build_context_extensions.dart';
import 'package:retropod/core/utils/enum_from_name.dart';

enum ClickWheelSensitivity {
  veryLow,
  low,
  medium,
  mediumHigh,
  high;

  static ClickWheelSensitivity fromName(String? raw) =>
      enumFromName(values, raw, medium);

  String title(BuildContext context) {
    switch (this) {
      case veryLow:
        return context.localization.veryLow;
      case low:
        return context.localization.low;
      case medium:
        return context.localization.medium;
      case mediumHigh:
        return context.localization.mediumHigh;
      case high:
        return context.localization.high;
    }
  }
}
