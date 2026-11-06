import 'package:flutter/cupertino.dart';
import 'package:retropod/core/extensions/build_context_extensions.dart';
import 'package:retropod/core/utils/enum_from_name.dart';

/// How long each photo stays on screen while the photo slideshow
/// screensaver is running.
enum SlideshowDuration {
  s3,
  s5,
  s10,
  s20,
  s30;

  static SlideshowDuration fromName(String? name) {
    return enumFromName(SlideshowDuration.values, name, SlideshowDuration.s5);
  }

  Duration get duration {
    switch (this) {
      case SlideshowDuration.s3:
        return const Duration(seconds: 3);
      case SlideshowDuration.s5:
        return const Duration(seconds: 5);
      case SlideshowDuration.s10:
        return const Duration(seconds: 10);
      case SlideshowDuration.s20:
        return const Duration(seconds: 20);
      case SlideshowDuration.s30:
        return const Duration(seconds: 30);
    }
  }

  String title(BuildContext context) {
    switch (this) {
      case SlideshowDuration.s3:
        return context.localization.slideshowDuration3Seconds;
      case SlideshowDuration.s5:
        return context.localization.slideshowDuration5Seconds;
      case SlideshowDuration.s10:
        return context.localization.slideshowDuration10Seconds;
      case SlideshowDuration.s20:
        return context.localization.slideshowDuration20Seconds;
      case SlideshowDuration.s30:
        return context.localization.slideshowDuration30Seconds;
    }
  }
}
