import 'package:flutter/cupertino.dart';
import 'package:retropod/core/extensions/build_context_extensions.dart';
import 'package:retropod/core/utils/enum_from_name.dart';

/// The clock format shown in the status bar when the clock is enabled.
enum StatusBarClockFormat {
  twelveHour,
  twentyFourHour;

  const StatusBarClockFormat();

  static StatusBarClockFormat fromName(String? raw) =>
      enumFromName(values, raw, twentyFourHour);

  String title(BuildContext context) {
    switch (this) {
      case twelveHour:
        return context.localization.statusBarClockTwelveHour;
      case twentyFourHour:
        return context.localization.statusBarClockTwentyFourHour;
    }
  }

  /// Formats [time] for the status bar, e.g. "3:05 PM" or "15:05".
  String format(DateTime time) {
    switch (this) {
      case twelveHour:
        final int hour12 = time.hour % 12 == 0 ? 12 : time.hour % 12;
        final String marker = time.hour < 12 ? 'AM' : 'PM';
        return '$hour12:${time.minute.toString().padLeft(2, '0')} $marker';
      case twentyFourHour:
        return '${time.hour.toString().padLeft(2, '0')}:'
            '${time.minute.toString().padLeft(2, '0')}';
    }
  }
}
