import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retropod/core/services/audio_player_service.dart';
import 'package:retropod/features/settings/controller/settings_preferences_controller.dart';
import 'package:retropod/features/settings/models/click_wheel_sound_choice.dart';

/// Preloaded low latency players so rapid wheel steps overlap like the
/// ticks of a real iPod click wheel instead of cutting each other off.
const int _kPlayerCount = 4;

final clickSoundServiceProvider = Provider<ClickSoundService>((ref) {
  final ClickSoundService service = ClickSoundService(
    initialChoice: ref
        .read(settingsPreferencesControllerProvider)
        .clickWheelSoundChoice,
    // Clicks only sound while no music is playing, so the tick never
    // interferes with (or gets masked by) a running song.
    shouldPlay: () => !ref.read(audioPlayerProvider).playing,
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

/// Plays the selected built-in click wheel sound through Android's low
/// latency audio path so every wheel step ticks instantly.
///
/// A fixed pool of players is used instead of [AudioPool] because low
/// latency playback has no completion events: pool-managed players would
/// never return to the pool and a new player would be created per tick.
class ClickSoundService {
  ClickSoundService({
    ClickWheelSoundChoice initialChoice = ClickWheelSoundChoice.classic,
    bool Function()? shouldPlay,
  }) : _shouldPlay = shouldPlay ?? _alwaysPlay {
    unawaited(load(initialChoice));
  }

  static bool _alwaysPlay() => true;

  final bool Function() _shouldPlay;
  final List<AudioPlayer> _players = <AudioPlayer>[];
  ClickWheelSoundChoice? _loadedChoice;
  int _nextPlayer = 0;
  int _loadGeneration = 0;

  /// (Re)loads the player pool for [choice]; the newest load always wins.
  Future<void> load(ClickWheelSoundChoice choice) async {
    final int generation = ++_loadGeneration;
    if (_loadedChoice == choice && _players.isNotEmpty) {
      return;
    }
    final List<AudioPlayer> players = <AudioPlayer>[];
    for (int i = 0; i < _kPlayerCount; i++) {
      final AudioPlayer player = AudioPlayer();
      try {
        // The default audio context is kept on purpose: overriding it with
        // audioFocus none was tested on device and made the low latency
        // players silent (playback never starts). Music interference is
        // prevented by muting ticks while music plays instead.
        await player.setPlayerMode(PlayerMode.lowLatency);
        await player.setSource(AssetSource(choice.assetPath));
        await player.setReleaseMode(ReleaseMode.stop);
        players.add(player);
      } on Exception {
        // Without a loadable sound the wheel simply stays silent instead
        // of dropping the previous working pool.
        for (final AudioPlayer created in players) {
          await created.dispose();
        }
        return;
      }
    }
    if (generation != _loadGeneration) {
      for (final AudioPlayer created in players) {
        await created.dispose();
      }
      return;
    }
    final List<AudioPlayer> oldPlayers = List<AudioPlayer>.of(_players);
    _players
      ..clear()
      ..addAll(players);
    _loadedChoice = choice;
    _nextPlayer = 0;
    for (final AudioPlayer oldPlayer in oldPlayers) {
      await oldPlayer.dispose();
    }
  }

  /// Fire-and-forget tick; safe to call once per scroll step.
  void play() {
    if (!_shouldPlay()) {
      return;
    }
    final List<AudioPlayer> players = _players;
    if (players.isEmpty) {
      return;
    }
    final AudioPlayer player = players[_nextPlayer++ % players.length];
    unawaited(_replay(player));
  }

  Future<void> _replay(AudioPlayer player) async {
    try {
      // stop resets the position; resume then plays the tick from the
      // start without releasing the preloaded source.
      await player.stop();
      await player.resume();
    } on Exception {
      // Transient playback errors are ignored; the next tick retries.
    }
  }

  Future<void> dispose() async {
    _loadGeneration++;
    _loadedChoice = null;
    final List<AudioPlayer> players = List<AudioPlayer>.of(_players);
    _players.clear();
    for (final AudioPlayer player in players) {
      await player.dispose();
    }
  }
}
