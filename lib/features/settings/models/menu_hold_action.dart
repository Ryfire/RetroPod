import 'package:flutter/cupertino.dart';
import 'package:retropod/core/extensions/build_context_extensions.dart';
import 'package:retropod/core/utils/enum_from_name.dart';

/// Where a Menu button long press jumps while the Now Playing screen is
/// open. [none] keeps the press as a haptic-only no-op so the shortcut
/// stays disabled; every other value pushes that section straight onto
/// the navigation stack and pops back to Now Playing on return.
enum MenuHoldAction {
  none,
  notes,
  brick,
  musicQuiz,
  sleepTimer;

  const MenuHoldAction();

  static MenuHoldAction fromName(String? raw) =>
      enumFromName(values, raw, none);

  String title(BuildContext context) {
    switch (this) {
      case none:
        return context.localization.menuHoldActionNone;
      case notes:
        return context.localization.menuHoldActionNotes;
      case brick:
        return context.localization.menuHoldActionBrick;
      case musicQuiz:
        return context.localization.menuHoldActionMusicQuiz;
      case sleepTimer:
        return context.localization.menuHoldActionSleepTimer;
    }
  }
}
