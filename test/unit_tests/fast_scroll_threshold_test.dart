import 'package:flutter_test/flutter_test.dart';
import 'package:retropod/core/constants/constants.dart';
import 'package:retropod/core/widgets/fast_scroll_indicator.dart';
import 'package:retropod/features/settings/models/click_wheel_speed.dart';

void main() {
  group('wheelFastScrollRows', () {
    test('the coarse reference speed uses the linear-reachable anchor', () {
      expect(
        wheelFastScrollRows(
          stepsPerRevolution: ClickWheelSpeed.coarse.stepsPerRevolution,
        ),
        fastScrollWheelBaseRows,
      );
      // The wheel anchor is a separate constant from the touch threshold;
      // touch scrolling keeps its own 12-row requirement.
      expect(fastScrollTouchRows, 12);
      expect(fastScrollWheelBaseRows, 4);
    });

    test('the threshold scales proportionally with the speed setting', () {
      // Half the steps per revolution means half the threshold so the same
      // finger effort triggers fast scroll.
      expect(
        wheelFastScrollRows(
          stepsPerRevolution: ClickWheelSpeed.veryCoarse.stepsPerRevolution,
        ),
        fastScrollWheelBaseRows / 2,
      );
      expect(
        wheelFastScrollRows(
          stepsPerRevolution: ClickWheelSpeed.medium.stepsPerRevolution,
        ),
        fastScrollWheelBaseRows * 2,
      );
      expect(
        wheelFastScrollRows(
          stepsPerRevolution: ClickWheelSpeed.ultraFine.stepsPerRevolution,
        ),
        fastScrollWheelBaseRows * 12,
      );
    });

    test('the threshold is reachable by linear tracking at every speed', () {
      // Linear tracking emits at most 0.6 * stepsPerRevolution steps within
      // the 200 ms movement window: the max angular velocity (1080 deg/s)
      // covers 216 degrees in 200 ms, which is 0.6 of a revolution. Every
      // speed's threshold must fall below that physical cap or fast scroll
      // could never trigger without acceleration.
      for (final speed in ClickWheelSpeed.values) {
        final threshold = wheelFastScrollRows(
          stepsPerRevolution: speed.stepsPerRevolution,
        );
        final linearCap = Constants.clickWheelMaxAngularVelocityDegreesPerSecond *
            200 * // fast scroll movement window in milliseconds
            speed.stepsPerRevolution /
            1000 /
            360;
        expect(
          threshold,
          lessThan(linearCap),
          reason:
              'Speed ${speed.name} requires $threshold rows but linear '
              'tracking can emit at most $linearCap rows per window',
        );
      }
    });
  });
}
