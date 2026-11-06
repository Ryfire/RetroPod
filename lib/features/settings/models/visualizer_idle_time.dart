import 'package:flutter/cupertino.dart';
import 'package:retropod/core/extensions/build_context_extensions.dart';
import 'package:retropod/core/utils/enum_from_name.dart';

/// How long the Now Playing screen waits without input before the
/// full-screen EQ visualizer screensaver takes over.
enum VisualizerIdleTime {
  off,
  s5,
  s10,
  s20,
  s30;

  static VisualizerIdleTime fromName(String? name) {
    return enumFromName(VisualizerIdleTime.values, name, VisualizerIdleTime.off);
  }

  /// The idle delay before the visualizer activates; null when off.
  Duration? get duration {
    switch (this) {
      case VisualizerIdleTime.off:
        return null;
      case VisualizerIdleTime.s5:
        return const Duration(seconds: 5);
      case VisualizerIdleTime.s10:
        return const Duration(seconds: 10);
      case VisualizerIdleTime.s20:
        return const Duration(seconds: 20);
      case VisualizerIdleTime.s30:
        return const Duration(seconds: 30);
    }
  }

  String title(BuildContext context) {
    switch (this) {
      case VisualizerIdleTime.off:
        return context.localization.tileValueOff;
      case VisualizerIdleTime.s5:
        return context.localization.visualizerIdleTime5Seconds;
      case VisualizerIdleTime.s10:
        return context.localization.visualizerIdleTime10Seconds;
      case VisualizerIdleTime.s20:
        return context.localization.visualizerIdleTime20Seconds;
      case VisualizerIdleTime.s30:
        return context.localization.visualizerIdleTime30Seconds;
    }
  }
}
