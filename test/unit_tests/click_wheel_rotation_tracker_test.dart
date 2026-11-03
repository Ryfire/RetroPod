import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:retropod/features/device/models/click_wheel_rotation_tracker.dart';

void main() {
  const Offset wheelCenter = Offset(100, 100);
  const double radius = 40;
  const double innerDeadzoneRadius = 10;

  ClickWheelRotationTracker createTracker({
    double thresholdDegrees = 45,
    double accelerationFactor = 1,
  }) {
    return ClickWheelRotationTracker(
      thresholdDegrees: thresholdDegrees,
      minVelocityDegreesPerSecond: 90,
      maxVelocityDegreesPerSecond: 1080,
      accelerationFactor: accelerationFactor,
      maxStepsPerEvent: 8,
    );
  }

  /// Simulates a pointer moving [totalDegrees] around the wheel in
  /// [stepDegrees] increments spaced [stepDuration] apart and returns the
  /// total number of emitted scroll steps.
  int simulateRotation({
    required ClickWheelRotationTracker tracker,
    required double totalDegrees,
    required double stepDegrees,
    required Duration stepDuration,
  }) {
    const int pointerId = 1;
    tracker.begin(
      pointerId: pointerId,
      wheelCenter: wheelCenter,
      innerDeadzoneRadius: innerDeadzoneRadius,
    );
    int totalSteps = 0;
    double angleDegrees = 0;
    Duration timestamp = const Duration(milliseconds: 500);
    // The first sample only anchors the angle so start the circle at zero
    // degrees and emit the requested rotation with the following samples.
    tracker.update(
      pointerId: pointerId,
      localPosition: wheelCenter + const Offset(radius, 0),
      timeStamp: timestamp,
    );
    while (angleDegrees.abs() < totalDegrees.abs()) {
      angleDegrees += stepDegrees;
      timestamp += stepDuration;
      final double angleRadians = angleDegrees * math.pi / 180;
      totalSteps += tracker.update(
        pointerId: pointerId,
        localPosition:
            wheelCenter +
            Offset(
              radius * math.cos(angleRadians),
              radius * math.sin(angleRadians),
            ),
        timeStamp: timestamp,
      );
    }
    tracker.end(pointerId: pointerId);
    return totalSteps;
  }

  group('click_wheel_rotation_tracker', () {
    test('linear tracking emits the same steps regardless of speed', () {
      final ClickWheelRotationTracker tracker = createTracker();
      // 400 degrees at a 45 degree threshold equals 8 steps. The rotation
      // overshoots a full revolution slightly so per-sample angle rounding
      // can never drop the last step.
      // 10 degrees every 200 milliseconds is 50 degrees per second, well
      // below the acceleration floor.
      final int slowSteps = simulateRotation(
        tracker: tracker,
        totalDegrees: 400,
        stepDegrees: 10,
        stepDuration: const Duration(milliseconds: 200),
      );
      // 10 degrees every 5 milliseconds is 2000 degrees per second, above
      // the maximum accelerated velocity.
      final int fastSteps = simulateRotation(
        tracker: tracker,
        totalDegrees: 400,
        stepDegrees: 10,
        stepDuration: const Duration(milliseconds: 5),
      );

      expect(slowSteps, 8);
      expect(fastSteps, slowSteps);
    });

    test('accelerated tracking emits more steps when spinning fast', () {
      final ClickWheelRotationTracker tracker = createTracker(
        accelerationFactor: 4,
      );
      final int slowSteps = simulateRotation(
        tracker: tracker,
        totalDegrees: 400,
        stepDegrees: 10,
        stepDuration: const Duration(milliseconds: 200),
      );
      final int fastSteps = simulateRotation(
        tracker: tracker,
        totalDegrees: 400,
        stepDegrees: 10,
        stepDuration: const Duration(milliseconds: 5),
      );

      expect(slowSteps, 8);
      expect(fastSteps, greaterThan(slowSteps));
    });

    test('counter clockwise rotation emits backward steps', () {
      final ClickWheelRotationTracker tracker = createTracker();
      final int steps = simulateRotation(
        tracker: tracker,
        totalDegrees: -400,
        stepDegrees: -10,
        stepDuration: const Duration(milliseconds: 200),
      );

      expect(steps, -8);
    });

    test('partial rotation below the threshold emits no steps', () {
      final ClickWheelRotationTracker tracker = createTracker();
      final int steps = simulateRotation(
        tracker: tracker,
        totalDegrees: 30,
        stepDegrees: 10,
        stepDuration: const Duration(milliseconds: 200),
      );

      expect(steps, 0);
    });
  });
}
