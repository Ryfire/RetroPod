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

  /// Moves the pointer to [angleDegrees] around the wheel and returns the
  /// number of scroll steps the tracker emitted for this move.
  int rotateTo(
    ClickWheelRotationTracker tracker,
    double angleDegrees,
    Duration timestamp,
  ) {
    final double angleRadians = angleDegrees * math.pi / 180;
    return tracker.update(
      pointerId: 1,
      localPosition:
          wheelCenter +
          Offset(
            radius * math.cos(angleRadians),
            radius * math.sin(angleRadians),
          ),
      timeStamp: timestamp,
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
      timeStamp: const Duration(milliseconds: 500),
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
    tracker.end(pointerId: pointerId, timeStamp: timestamp + stepDuration);
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

    test('configure applies new settings between gestures', () {
      final ClickWheelRotationTracker tracker = createTracker();
      tracker.configure(thresholdDegrees: 90, accelerationFactor: 2);
      expect(tracker.thresholdDegrees, 90);
      expect(tracker.accelerationFactor, 2);
    });

    test('rotation across a quick finger lift carries over', () {
      final ClickWheelRotationTracker tracker = createTracker();
      int steps = 0;
      tracker.begin(
        pointerId: 1,
        wheelCenter: wheelCenter,
        innerDeadzoneRadius: innerDeadzoneRadius,
        timeStamp: const Duration(milliseconds: 500),
      );
      // A short 30 degree drag emits nothing on its own. Four samples are
      // needed because the first one only anchors the angle.
      for (int i = 1; i <= 4; i++) {
        steps += rotateTo(
          tracker,
          10.0 * i,
          Duration(milliseconds: 500 + 200 * i),
        );
      }
      expect(steps, 0);
      tracker.end(pointerId: 1, timeStamp: const Duration(milliseconds: 1500));
      // Touching down again 300 milliseconds later continues the gesture and
      // the combined 60 degrees cross the 45 degree threshold once.
      tracker.begin(
        pointerId: 1,
        wheelCenter: wheelCenter,
        innerDeadzoneRadius: innerDeadzoneRadius,
        timeStamp: const Duration(milliseconds: 1800),
      );
      for (int i = 1; i <= 4; i++) {
        steps += rotateTo(
          tracker,
          40.0 + 10.0 * i,
          Duration(milliseconds: 1800 + 200 * i),
        );
      }
      expect(steps, 1);
      tracker.end(pointerId: 1, timeStamp: const Duration(milliseconds: 2800));
    });

    test('rotation is discarded when the next touch lands too late', () {
      final ClickWheelRotationTracker tracker = createTracker();
      int steps = 0;
      tracker.begin(
        pointerId: 1,
        wheelCenter: wheelCenter,
        innerDeadzoneRadius: innerDeadzoneRadius,
        timeStamp: const Duration(milliseconds: 500),
      );
      for (int i = 1; i <= 4; i++) {
        steps += rotateTo(
          tracker,
          10.0 * i,
          Duration(milliseconds: 500 + 200 * i),
        );
      }
      expect(steps, 0);
      tracker.end(pointerId: 1, timeStamp: const Duration(milliseconds: 1500));
      // Touching down again 600 milliseconds later is outside the carry over
      // window so the leftover 30 degrees are gone and the new drag starts
      // from zero.
      tracker.begin(
        pointerId: 1,
        wheelCenter: wheelCenter,
        innerDeadzoneRadius: innerDeadzoneRadius,
        timeStamp: const Duration(milliseconds: 2100),
      );
      for (int i = 1; i <= 4; i++) {
        steps += rotateTo(
          tracker,
          40.0 + 10.0 * i,
          Duration(milliseconds: 2100 + 200 * i),
        );
      }
      expect(steps, 0);
      tracker.end(pointerId: 1, timeStamp: const Duration(milliseconds: 2900));
    });

    test('reversing direction does not emit an early step', () {
      final ClickWheelRotationTracker tracker = createTracker();
      int steps = 0;
      tracker.begin(
        pointerId: 1,
        wheelCenter: wheelCenter,
        innerDeadzoneRadius: innerDeadzoneRadius,
        timeStamp: const Duration(milliseconds: 500),
      );
      // 40 degrees forward stays below the 45 degree threshold.
      for (int i = 1; i <= 4; i++) {
        steps += rotateTo(
          tracker,
          10.0 * i,
          Duration(milliseconds: 500 + 200 * i),
        );
      }
      expect(steps, 0);
      // 100 degrees backward earns exactly two backward steps once the
      // leftover forward rotation is dropped at the direction change.
      for (int i = 1; i <= 10; i++) {
        steps += rotateTo(
          tracker,
          40.0 - 10.0 * i,
          Duration(milliseconds: 1700 + 200 * i),
        );
      }
      expect(steps, -2);
      tracker.end(pointerId: 1, timeStamp: const Duration(milliseconds: 3700));
    });

    test('jitter while creeping forward keeps its progress', () {
      final ClickWheelRotationTracker tracker = createTracker();
      int steps = 0;
      tracker.begin(
        pointerId: 1,
        wheelCenter: wheelCenter,
        innerDeadzoneRadius: innerDeadzoneRadius,
        timeStamp: const Duration(milliseconds: 500),
      );
      // Digitizer quantization at a pixel boundary: the reported angle
      // alternates +6 and -4 degrees while the finger creeps forward, so
      // the net rotation is +2 degrees per pair. The old behavior wiped
      // the pending arc on every sign flip and never emitted a step; the
      // tracker must erode the jitter instead and pay out the net arc.
      double angleDegrees = 0;
      tracker.update(
        pointerId: 1,
        localPosition: wheelCenter + const Offset(radius, 0),
        timeStamp: const Duration(milliseconds: 500),
      );
      Duration timestamp = const Duration(milliseconds: 500);
      for (int i = 0; i < 200; i++) {
        angleDegrees += i.isEven ? 6.0 : -4.0;
        timestamp += const Duration(milliseconds: 50);
        steps += rotateTo(tracker, angleDegrees, timestamp);
      }
      // 100 jitter pairs advance the finger 200 degrees, which crosses the
      // 45 degree threshold exactly four times.
      expect(steps, 4);
      tracker.end(pointerId: 1, timeStamp: timestamp);
    });

    test('symmetric jitter around a resting finger emits no steps', () {
      final ClickWheelRotationTracker tracker = createTracker();
      int steps = 0;
      tracker.begin(
        pointerId: 1,
        wheelCenter: wheelCenter,
        innerDeadzoneRadius: innerDeadzoneRadius,
        timeStamp: const Duration(milliseconds: 500),
      );
      // A finger resting on a pixel boundary oscillates by the same amount
      // in both directions; the jitter cancels out and no step may fire.
      double angleDegrees = 0;
      tracker.update(
        pointerId: 1,
        localPosition: wheelCenter + const Offset(radius, 0),
        timeStamp: const Duration(milliseconds: 500),
      );
      Duration timestamp = const Duration(milliseconds: 500);
      for (int i = 0; i < 200; i++) {
        angleDegrees += i.isEven ? 0.5 : -0.5;
        timestamp += const Duration(milliseconds: 50);
        steps += rotateTo(tracker, angleDegrees, timestamp);
      }
      expect(steps, 0);
      tracker.end(pointerId: 1, timeStamp: timestamp);
    });

    test('a decisive reversal still discards the pending rotation', () {
      final ClickWheelRotationTracker tracker = createTracker();
      int steps = 0;
      tracker.begin(
        pointerId: 1,
        wheelCenter: wheelCenter,
        innerDeadzoneRadius: innerDeadzoneRadius,
        timeStamp: const Duration(milliseconds: 500),
      );
      // 40 degrees forward stays below the 45 degree threshold.
      for (int i = 1; i <= 4; i++) {
        steps += rotateTo(
          tracker,
          10.0 * i,
          Duration(milliseconds: 500 + 200 * i),
        );
      }
      expect(steps, 0);
      // A single decisive 20 degree backward delta is far above the
      // reversal cutoff, so the leftover 40 forward degrees are dropped
      // right away and the next 30 backward degrees earn one step.
      steps += rotateTo(tracker, 20.0, const Duration(milliseconds: 1700));
      steps += rotateTo(tracker, 10.0, const Duration(milliseconds: 1900));
      steps += rotateTo(tracker, 0.0, const Duration(milliseconds: 2100));
      steps += rotateTo(tracker, -10.0, const Duration(milliseconds: 2300));
      expect(steps, -1);
      tracker.end(pointerId: 1, timeStamp: const Duration(milliseconds: 2500));
    });
  });
}
