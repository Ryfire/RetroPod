import 'package:flutter/services.dart';

/// Dart bridge for the FLAG_KEEP_SCREEN_ON window flag. See
/// android/app/src/main/kotlin/com/rchrdariza/retropod/MainActivity.kt for
/// the native implementation.
final keepScreenOnService = KeepScreenOnService();

class KeepScreenOnService {
  static const MethodChannel _channel = MethodChannel(
    'retropod/keep_screen_on',
  );

  bool _isEnabled = false;

  bool get isEnabled => _isEnabled;

  /// Adds the FLAG_KEEP_SCREEN_ON window flag so the device display stays
  /// awake while the Now Playing screen is open. No-op on platforms that
  /// do not implement the channel.
  Future<void> enable() async {
    try {
      await _channel.invokeMethod<void>('set', <String, dynamic>{
        'enable': true,
      });
      _isEnabled = true;
    } on PlatformException {
      // Unsupported platform; nothing else to do.
    }
  }

  /// Clears the FLAG_KEEP_SCREEN_ON window flag, restoring the normal
  /// screen timeout.
  Future<void> disable() async {
    try {
      await _channel.invokeMethod<void>('set', <String, dynamic>{
        'enable': false,
      });
      _isEnabled = false;
    } on PlatformException {
      // Unsupported platform; nothing else to do.
    }
  }
}
