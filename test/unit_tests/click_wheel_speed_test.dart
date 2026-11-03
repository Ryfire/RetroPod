import 'package:flutter_test/flutter_test.dart';
import 'package:retropod/features/settings/models/click_wheel_speed.dart';

void main() {
  group('click_wheel_speed', () {
    test('threshold degrees cover one revolution exactly', () {
      for (final ClickWheelSpeed speed in ClickWheelSpeed.values) {
        expect(speed.thresholdDegrees * speed.stepsPerRevolution, 360);
      }
    });

    test('previous default feel maps to the coarse speed', () {
      // Medium sensitivity + normal step was 45 degrees per step, which is
      // exactly 8 steps per revolution.
      expect(
        ClickWheelSpeed.fromLegacySettings(
          thresholdDegrees: 45,
          stepMultiplier: 1,
        ),
        ClickWheelSpeed.coarse,
      );
    });

    test('legacy combinations snap to the nearest speed', () {
      // Very low sensitivity + coarse step was 180 degrees per step.
      expect(
        ClickWheelSpeed.fromLegacySettings(
          thresholdDegrees: 90,
          stepMultiplier: 0.5,
        ),
        ClickWheelSpeed.veryCoarse,
      );
      // High sensitivity + ultra fine step was 3.75 degrees per step, which
      // is exactly 96 steps per revolution.
      expect(
        ClickWheelSpeed.fromLegacySettings(
          thresholdDegrees: 22.5,
          stepMultiplier: 6,
        ),
        ClickWheelSpeed.ultraFine,
      );
      // Medium high sensitivity + fine step was 18 degrees per step (20
      // steps per revolution), which snaps to mediumFine (24).
      expect(
        ClickWheelSpeed.fromLegacySettings(
          thresholdDegrees: 36,
          stepMultiplier: 2,
        ),
        ClickWheelSpeed.mediumFine,
      );
    });

    test('legacy names migrate with safe fallbacks', () {
      expect(
        ClickWheelSpeed.fromLegacyNames(
          sensitivityName: 'medium',
          stepName: 'normal',
        ),
        ClickWheelSpeed.coarse,
      );
      expect(
        ClickWheelSpeed.fromLegacyNames(
          sensitivityName: 'high',
          stepName: 'ultraFine',
        ),
        ClickWheelSpeed.ultraFine,
      );
      // Unknown or missing names fall back to the previous defaults.
      expect(
        ClickWheelSpeed.fromLegacyNames(sensitivityName: 'corrupted'),
        ClickWheelSpeed.coarse,
      );
    });
  });
}
