import 'package:flutter/cupertino.dart';
import 'package:retropod/core/extensions/build_context_extensions.dart';
import 'package:retropod/core/utils/enum_from_name.dart';

/// How far each long-press seek step jumps while scrubbing a track on the
/// Now Playing screen. Useful for audiobooks and podcasts where jumping in
/// larger chunks is more practical than second-by-second scrubbing.
enum SeekInterval {
  five(5),
  ten(10),
  thirty(30),
  sixty(60);

  const SeekInterval(this.seconds);

  static SeekInterval fromName(String? raw) => enumFromName(values, raw, five);

  /// The seek step in seconds handed to the audio player.
  final int seconds;

  String title(BuildContext context) {
    return context.localization.seekIntervalSecondsValue('$seconds');
  }
}
