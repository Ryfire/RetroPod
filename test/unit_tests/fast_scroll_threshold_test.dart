import 'package:flutter_test/flutter_test.dart';
import 'package:retropod/core/widgets/fast_scroll_indicator.dart';
import 'package:retropod/features/settings/models/click_wheel_speed.dart';

void main() {
  group('wheelFastScrollRows', () {
    test('the coarse reference speed keeps the historical threshold', () {
      expect(
        wheelFastScrollRows(
          stepsPerRevolution: ClickWheelSpeed.coarse.stepsPerRevolution,
        ),
        fastScrollWheelBaseRows,
      );
      expect(fastScrollWheelBaseRows, fastScrollTouchRows);
    });

    test('the threshold scales proportionally with the speed setting', () {
      // Half the steps per revolution means half the threshold so the same
      // finger effort triggers fast scroll.
      expect(
        wheelFastScrollRows(
          stepsPerRevolution: ClickWheelSpeed.veryCoarse.stepsPerRevolution,
        ),
        fastScrollTouchRows / 2,
      );
      expect(
        wheelFastScrollRows(
          stepsPerRevolution: ClickWheelSpeed.medium.stepsPerRevolution,
        ),
        fastScrollTouchRows * 2,
      );
      expect(
        wheelFastScrollRows(
          stepsPerRevolution: ClickWheelSpeed.ultraFine.stepsPerRevolution,
        ),
        fastScrollTouchRows * 12,
      );
    });
  });
}
