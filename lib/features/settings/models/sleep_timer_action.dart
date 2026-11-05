import 'package:flutter/cupertino.dart';
import 'package:retropod/core/extensions/build_context_extensions.dart';
import 'package:retropod/core/utils/enum_from_name.dart';

/// What happens when the sleep timer elapses. [stopMusic] is the classic
/// behavior of pausing playback; [powerOff] additionally exits the app the
/// same way the main menu Power Off option does.
enum SleepTimerAction {
  stopMusic,
  powerOff;

  const SleepTimerAction();

  static SleepTimerAction fromName(String? raw) =>
      enumFromName(values, raw, stopMusic);

  String title(BuildContext context) {
    switch (this) {
      case stopMusic:
        return context.localization.sleepTimerActionStopMusic;
      case powerOff:
        return context.localization.sleepTimerActionPowerOff;
    }
  }
}
