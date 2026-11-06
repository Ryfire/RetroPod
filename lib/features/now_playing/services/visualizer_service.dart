import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retropod/core/services/audio_player_service.dart';

/// Dart bridge for the Android audio visualizer: attaches the platform
/// Visualizer to the player's audio session and streams raw FFT byte
/// arrays. See android/app/src/main/kotlin/com/rchrdariza/retropod/
/// MainActivity.kt for the native implementation.
final visualizerServiceProvider = Provider<VisualizerService>((ref) {
  return VisualizerService(ref);
});

class VisualizerService {
  final Ref ref;

  VisualizerService(this.ref);

  static const MethodChannel _channel = MethodChannel('retropod/visualizer');
  static const EventChannel _eventsChannel = EventChannel(
    'retropod/visualizer_events',
  );

  Stream<Uint8List>? _fftStream;

  /// Raw FFT frames from the native Visualizer, in the range [-128, 127].
  /// Only available while the visualizer is attached and supported.
  Stream<Uint8List> get fftStream {
    _fftStream ??= _eventsChannel
        .receiveBroadcastStream()
        .map<Uint8List>((dynamic event) {
          if (event is Uint8List) {
            return event;
          }
          if (event is List<dynamic>) {
            return Uint8List.fromList(event.cast<int>());
          }
          return Uint8List(0);
        });
    return _fftStream!;
  }

  /// Attaches the FFT capture to the audio player's Android session.
  /// Returns false when the session is unavailable (or on platforms that
  /// do not support the visualizer), so the caller can fall back to the
  /// animated visualizer.
  Future<bool> attach() async {
    final int? sessionId = ref.read(audioPlayerProvider).androidAudioSessionId;
    if (sessionId == null) {
      return false;
    }
    try {
      await _channel.invokeMethod<bool>('attach', <String, dynamic>{
        'sessionId': sessionId,
      });
      return true;
    } on PlatformException {
      return false;
    }
  }

  /// Releases the native FFT capture.
  Future<void> detach() async {
    try {
      await _channel.invokeMethod<void>('detach');
    } on PlatformException {
      // Already detached or unsupported; nothing else to do.
    }
  }
}
