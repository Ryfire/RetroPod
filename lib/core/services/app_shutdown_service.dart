import 'dart:async';
import 'dart:io' as io;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retropod/core/services/audio_player_service.dart';

/// Exits the application the same way the main menu Power Off option does:
/// stop audio first, then close the app (navigator pop on web/iOS, process
/// exit elsewhere). The exit routine is injectable so tests can verify a
/// shutdown was requested without actually killing the process.
typedef AppExit = Future<void> Function();

Future<void> defaultAppExit() async {
  if (kIsWeb || io.Platform.isIOS) {
    await SystemNavigator.pop();
  } else {
    io.exit(0);
  }
}

final appShutdownServiceProvider = Provider<AppShutdownService>((ref) {
  return AppShutdownService(
    stopAudio: ref.read(audioPlayerServiceProvider.notifier).stop,
    exit: defaultAppExit,
  );
});

class AppShutdownService {
  final Future<void> Function() stopAudio;
  final Future<void> Function() exit;

  const AppShutdownService({required this.stopAudio, required this.exit});

  /// Stops playback, then exits the app. Mirrors the main menu Power Off
  /// behavior so the sleep timer can power the app down identically.
  Future<void> powerOff() async {
    await stopAudio();
    await Future<void>.delayed(const Duration(milliseconds: 200));
    await exit();
  }
}
