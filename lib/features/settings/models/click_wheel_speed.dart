import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:retropod/core/extensions/build_context_extensions.dart';
import 'package:retropod/core/utils/enum_from_name.dart';

/// How far a full revolution of the click wheel scrolls, expressed as the
/// number of scroll steps one revolution produces.
///
/// This replaces the retired sensitivity and step settings: both of them only
/// scaled the degrees of rotation required per scroll step, so a single
/// steps-per-revolution value describes their combined effect.
enum ClickWheelSpeed {
  veryCoarse(4),
  coarse(8),
  medium(16),
  fine(32),
  veryFine(64),
  ultraFine(96);

  const ClickWheelSpeed(this.stepsPerRevolution);

  static ClickWheelSpeed fromName(String? raw) =>
      enumFromName(values, raw, coarse);

  final int stepsPerRevolution;

  /// Degrees of rotation required to emit a single scroll step.
  double get thresholdDegrees => 360 / stepsPerRevolution;

  /// Maps a stored sensitivity and step pair to the nearest speed value so
  /// existing installations keep the scroll feel they had before.
  static ClickWheelSpeed fromLegacySettings({
    required double thresholdDegrees,
    required double stepMultiplier,
  }) {
    final double target = 360 / (thresholdDegrees / stepMultiplier);
    ClickWheelSpeed nearest = values.first;
    double nearestDistance = double.infinity;
    for (final ClickWheelSpeed speed in values) {
      final double distance =
          (math.log(speed.stepsPerRevolution) - math.log(target)).abs();
      if (distance < nearestDistance) {
        nearestDistance = distance;
        nearest = speed;
      }
    }
    return nearest;
  }

  /// Degrees per scroll step of the retired sensitivity settings.
  static const Map<String, double> _legacySensitivityThresholds = {
    'veryLow': 90,
    'low': 60,
    'medium': 45,
    'mediumHigh': 36,
    'high': 22.5,
  };

  /// Threshold dividers of the retired step settings.
  static const Map<String, double> _legacyStepMultipliers = {
    'coarse': 0.5,
    'normal': 1,
    'fine': 2,
    'veryFine': 4,
    'ultraFine': 6,
  };

  /// Migrates the stored names of the retired sensitivity and step settings.
  /// Unknown or missing names fall back to the previous defaults, which map
  /// to the [coarse] speed.
  static ClickWheelSpeed fromLegacyNames({
    String? sensitivityName,
    String? stepName,
  }) {
    return fromLegacySettings(
      thresholdDegrees: _legacySensitivityThresholds[sensitivityName] ?? 45,
      stepMultiplier: _legacyStepMultipliers[stepName] ?? 1,
    );
  }

  String title(BuildContext context) {
    switch (this) {
      case veryCoarse:
        return context.localization.veryCoarse;
      case coarse:
        return context.localization.coarse;
      case medium:
        return context.localization.medium;
      case fine:
        return context.localization.fine;
      case veryFine:
        return context.localization.veryFine;
      case ultraFine:
        return context.localization.ultraFine;
    }
  }
}
