import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retropod/core/services/audio_player_service.dart';
import 'package:retropod/features/settings/controller/settings_preferences_controller.dart';
import 'package:retropod/features/settings/models/click_wheel_sound_choice.dart';

/// Platform channel hosting the click wheel sound pool on Android; see
/// android/app/src/main/kotlin/com/rchrdariza/retropod/MainActivity.kt.
const MethodChannel _clickSoundChannel = MethodChannel(
  'retropod/click_sound',
);

final clickSoundServiceProvider = Provider<ClickSoundService>((ref) {
  final ClickSoundService service = ClickSoundService(
    initialChoice: ref
        .read(settingsPreferencesControllerProvider)
        .clickWheelSoundChoice,
    // Ticks play on a raw sound pool that never requests Android audio
    // focus, so they cannot pause or deadlock music playback in any state
    // (the app preloads the music library into the player at startup, so
    // player based gates cannot distinguish idle from a paused song). They
    // are only muted while a song is actively playing so the tick does not
    // mix over the music.
    shouldPlay: () => !ref.read(audioPlayerProvider).playing,
    // The volume level is read per tick so cycling the setting applies
    // immediately.
    volumeLevel: () => ref
        .read(settingsPreferencesControllerProvider)
        .clickWheelVolumeLevel
        .value,
  );
  ref.onDispose(service.dispose);
  ref.listen(
    settingsPreferencesControllerProvider,
    (previous, next) {
      if (previous?.clickWheelSoundChoice != next.clickWheelSoundChoice) {
        unawaited(service.load(next.clickWheelSoundChoice));
      }
    },
  );
  return service;
});

/// Plays the selected built-in click wheel sound through Android's Sound
/// Pool so every wheel step ticks instantly.
///
/// SoundPool never touches Android audio focus, which previously made
/// ticks race the music player's own focus requests and pause or deadlock
/// playback; with this engine that interference is impossible. Sounds are
/// loaded once into memory per choice and replayed directly from cache.
class ClickSoundService {
  ClickSoundService({
    ClickWheelSoundChoice initialChoice = ClickWheelSoundChoice.classic,
    bool Function()? shouldPlay,
    double Function()? volumeLevel,
  })  : _shouldPlay = shouldPlay ?? _alwaysPlay,
        _volumeLevel = volumeLevel ?? _fullVolume {
    unawaited(load(initialChoice));
  }

  static bool _alwaysPlay() => true;

  static double _fullVolume() => 1;

  /// Android hosts the raw sound pool implementation; every other platform
  /// falls back to the pre-existing system click sound.
  static final bool _hasSoundPool =
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  final bool Function() _shouldPlay;
  final double Function() _volumeLevel;
  final Map<ClickWheelSoundChoice, int> _soundIds =
      <ClickWheelSoundChoice, int>{};
  bool _soundPoolUnavailable = false;
  ClickWheelSoundChoice _selectedChoice = ClickWheelSoundChoice.classic;

  /// Ensures the sound for [choice] is cached in memory; sounds stay
  /// cached for the whole app session so switching choices is instant.
  Future<void> load(ClickWheelSoundChoice choice) async {
    _selectedChoice = choice;
    if (_soundIds.containsKey(choice) ||
        _soundPoolUnavailable ||
        !_hasSoundPool) {
      return;
    }
    try {
      final ByteData soundData =
          await rootBundle.load('assets/${choice.assetPath}');
      final int? soundId = await _clickSoundChannel
          .invokeMethod<int>('load', <String, Object>{
        'name': choice.name,
        'bytes': soundData.buffer
            .asUint8List(soundData.offsetInBytes, soundData.lengthInBytes),
      });
      if (soundId != null && soundId > 0) {
        _soundIds[choice] = soundId;
      }
    } on MissingPluginException {
      // No implementation on this platform or flavor; use the system
      // click instead.
      _soundPoolUnavailable = true;
    } on Exception {
      // Without a loadable sound the wheel simply stays silent instead of
      // crashing the wheel interaction; the next load attempt retries.
    }
  }

  /// Fire-and-forget tick; safe to call once per scroll step.
  void play() {
    if (!_shouldPlay()) {
      return;
    }
    final double volume = _volumeLevel();
    if (volume <= 0) {
      return;
    }
    if (_hasSoundPool && !_soundPoolUnavailable) {
      final int? soundId = _soundIds[_selectedChoice];
      if (soundId != null) {
        unawaited(_tick(soundId, volume));
      }
    } else {
      unawaited(SystemSound.play(SystemSoundType.click));
    }
  }

  Future<void> _tick(int soundId, double volume) async {
    try {
      await _clickSoundChannel.invokeMethod<int>(
        'play',
        <String, Object>{'soundId': soundId, 'volume': volume},
      );
    } on Exception {
      // Transient playback errors are ignored; the next tick retries.
    }
  }

  void dispose() {
    _soundIds.clear();
  }
}
