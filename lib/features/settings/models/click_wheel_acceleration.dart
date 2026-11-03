import 'package:flutter/cupertino.dart';
import 'package:retropod/core/extensions/build_context_extensions.dart';
import 'package:retropod/core/utils/enum_from_name.dart';

/// Speed based multiplier that lowers the click wheel rotation step
/// threshold while the pointer spins quickly.
///
/// A [linear] factor of 1 keeps the step threshold constant so one full
/// revolution of the wheel always produces the same number of scroll steps
/// regardless of how fast the pointer moves.
enum ClickWheelAcceleration {
  linear(1),
  low(2),
  normal(4),
  high(6);

  const ClickWheelAcceleration(this.accelerationFactor);

  static ClickWheelAcceleration fromName(String? raw) =>
      enumFromName(values, raw, normal);

  final double accelerationFactor;

  String title(BuildContext context) {
    switch (this) {
      case linear:
        return context.localization.linear;
      case low:
        return context.localization.low;
      case normal:
        return context.localization.normal;
      case high:
        return context.localization.high;
    }
  }
}
