import 'package:flutter/cupertino.dart';
import 'package:retropod/core/extensions/build_context_extensions.dart';
import 'package:retropod/core/utils/enum_from_name.dart';

/// Which screensaver takes over the Now Playing screen after the configured
/// idle time.
enum ScreensaverType {
  visualizer,
  photoSlideshow;

  static ScreensaverType fromName(String? name) {
    return enumFromName(
      ScreensaverType.values,
      name,
      ScreensaverType.visualizer,
    );
  }

  String title(BuildContext context) {
    switch (this) {
      case ScreensaverType.visualizer:
        return context.localization.screensaverTypeVisualizer;
      case ScreensaverType.photoSlideshow:
        return context.localization.screensaverTypePhotoSlideshow;
    }
  }
}
