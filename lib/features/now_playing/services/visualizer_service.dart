import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retropod/core/services/audio_player_service.dart';

/// Dart bridge for the Android audio visualizer: attaches the platform
/// Visualizer to the player's audio session and streams FFT and waveform
/// capture frames. See android/app/src/main/kotlin/com/rchrdariza/retropod/
/// MainActivity.kt for the native implementation.
final visualizerServiceProvider = Provider<VisualizerService>((ref) {
  return VisualizerService(ref);
});

/// A single capture frame from the native visualizer: either FFT bytes
/// (signed real/imaginary pairs) or waveform bytes (unsigned samples
/// centered at 128).
class VisualizerFrame {
  const VisualizerFrame({required this.isFft, required this.data});

  final bool isFft;
  final Uint8List data;
}

class VisualizerService {
  final Ref ref;

  VisualizerService(this.ref);

  static const MethodChannel _channel = MethodChannel('retropod/visualizer');
  static const EventChannel _eventsChannel = EventChannel(
    'retropod/visualizer_events',
  );

  Stream<VisualizerFrame>? _framesStream;

  /// Capture frames from the native Visualizer, in the range [-128, 127].
  /// Only available while the visualizer is attached and supported.
  Stream<VisualizerFrame> get framesStream {
    _framesStream ??= _eventsChannel
        .receiveBroadcastStream()
        .map<VisualizerFrame>((dynamic event) {
          if (event is Map) {
            final dynamic data = event['data'];
            final Uint8List bytes = data is Uint8List
                ? data
                : Uint8List.fromList((data as List<dynamic>).cast<int>());
            return VisualizerFrame(
              isFft: event['type'] == 'fft',
              data: bytes,
            );
          }
          // Backwards compatibility with the original raw-FFT events.
          final Uint8List bytes = event is Uint8List
              ? event
              : Uint8List.fromList((event as List<dynamic>).cast<int>());
          return VisualizerFrame(isFft: true, data: bytes);
        });
    return _framesStream!;
  }

  /// Attaches the FFT/waveform capture to the audio player's Android
  /// session. Returns false when the session is unavailable (or on
  /// platforms that do not support the visualizer), so the caller can fall
  /// back to the animated visualizer.
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
    } on PlatformException catch (error) {
      debugPrint('Visualizer attach failed: ${error.message}');
      return false;
    } catch (_) {
      // Unsupported platforms throw MissingPluginException here.
      return false;
    }
  }

  /// Releases the native FFT capture.
  Future<void> detach() async {
    try {
      await _channel.invokeMethod<void>('detach');
    } catch (_) {
      // Already detached or unsupported; nothing else to do.
    }
  }
}
