import 'package:flutter/cupertino.dart';
import 'package:retropod/core/extensions/build_context_extensions.dart';
import 'package:retropod/core/utils/enum_from_name.dart';

/// The playback volume applied to click wheel ticks.
enum ClickWheelVolumeLevel {
  mute(0),
  low(0.25),
  medium(0.5),
  high(0.75),
  max(1);

  const ClickWheelVolumeLevel(this.value);

  static ClickWheelVolumeLevel fromName(String? raw) =>
      enumFromName(values, raw, max);

  /// Playback volume in the 0.0-1.0 range handed to the sound pool.
  final double value;

  String title(BuildContext context) {
    switch (this) {
      case mute:
        return context.localization.clickVolumeMute;
      case low:
        return context.localization.clickVolumeLow;
      case medium:
        return context.localization.clickVolumeMedium;
      case high:
        return context.localization.clickVolumeHigh;
      case max:
        return context.localization.clickVolumeMax;
    }
  }
}
