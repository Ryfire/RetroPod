import 'package:flutter_test/flutter_test.dart';
import 'package:retropod/features/settings/models/seek_interval.dart';
import 'package:retropod/features/settings/models/sleep_timer_action.dart';
import 'package:retropod/features/settings/models/status_bar_clock_format.dart';

void main() {
  group('SeekInterval', () {
    test('each value maps to its seconds', () {
      expect(SeekInterval.five.seconds, 5);
      expect(SeekInterval.ten.seconds, 10);
      expect(SeekInterval.thirty.seconds, 30);
      expect(SeekInterval.sixty.seconds, 60);
    });

    test('fromName resolves stored names', () {
      expect(SeekInterval.fromName('thirty'), SeekInterval.thirty);
    });

    test('fromName falls back to five on unknown values', () {
      expect(SeekInterval.fromName(null), SeekInterval.five);
      expect(SeekInterval.fromName('nonsense'), SeekInterval.five);
    });
  });

  group('SleepTimerAction', () {
    test('fromName resolves stored names', () {
      expect(SleepTimerAction.fromName('powerOff'), SleepTimerAction.powerOff);
      expect(
        SleepTimerAction.fromName('stopMusic'),
        SleepTimerAction.stopMusic,
      );
    });

    test('fromName falls back to stopMusic on unknown values', () {
      expect(SleepTimerAction.fromName(null), SleepTimerAction.stopMusic);
      expect(SleepTimerAction.fromName('nonsense'), SleepTimerAction.stopMusic);
    });
  });

  group('StatusBarClockFormat', () {
    final DateTime morning = DateTime(2026, 11, 5, 9, 5);
    final DateTime afternoon = DateTime(2026, 11, 5, 15, 5);
    final DateTime midnight = DateTime(2026, 11, 5, 0, 7);

    test('twentyFourHour renders zero-padded hours', () {
      expect(StatusBarClockFormat.twentyFourHour.format(afternoon), '15:05');
      expect(StatusBarClockFormat.twentyFourHour.format(midnight), '00:07');
    });

    test('twelveHour renders AM/PM and rolls midnight to 12', () {
      expect(StatusBarClockFormat.twelveHour.format(morning), '9:05 AM');
      expect(StatusBarClockFormat.twelveHour.format(afternoon), '3:05 PM');
      expect(StatusBarClockFormat.twelveHour.format(midnight), '12:07 AM');
    });

    test('fromName falls back to twentyFourHour on unknown values', () {
      expect(
        StatusBarClockFormat.fromName(null),
        StatusBarClockFormat.twentyFourHour,
      );
      expect(
        StatusBarClockFormat.fromName('nonsense'),
        StatusBarClockFormat.twentyFourHour,
      );
    });
  });
}
