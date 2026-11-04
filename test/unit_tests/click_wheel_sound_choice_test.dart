import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retropod/features/settings/models/click_wheel_sound_choice.dart';
import 'package:retropod/features/settings/models/click_wheel_volume_level.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('click_wheel_sound_choice', () {
    test('unknown persisted names fall back to classic', () {
      expect(ClickWheelSoundChoice.fromName(null),
          ClickWheelSoundChoice.classic);
      expect(
        ClickWheelSoundChoice.fromName('not_a_sound'),
        ClickWheelSoundChoice.classic,
      );
      expect(
        ClickWheelSoundChoice.fromName(ClickWheelSoundChoice.mechanical.name),
        ClickWheelSoundChoice.mechanical,
      );
    });

    test('every choice has a unique non-empty asset path', () {
      final Set<String> assetPaths = ClickWheelSoundChoice.values
          .map((ClickWheelSoundChoice choice) => choice.assetPath)
          .toSet();
      expect(assetPaths.length, ClickWheelSoundChoice.values.length);
      for (final ClickWheelSoundChoice choice in ClickWheelSoundChoice.values) {
        expect(choice.assetPath, isNotEmpty);
        expect(choice.assetPath, endsWith('.wav'));
      }
    });

    test('bundled sound assets load with audio data', () async {
      for (final ClickWheelSoundChoice choice in ClickWheelSoundChoice.values) {
        final ByteData data =
            await rootBundle.load('assets/${choice.assetPath}');
        expect(
          data.lengthInBytes,
          greaterThan(0),
          reason: '${choice.assetPath} should exist in the bundle',
        );
      }
    });
  });

  group('click_wheel_volume_level', () {
    test('unknown persisted names fall back to max', () {
      expect(ClickWheelVolumeLevel.fromName(null), ClickWheelVolumeLevel.max);
      expect(
        ClickWheelVolumeLevel.fromName('not_a_level'),
        ClickWheelVolumeLevel.max,
      );
      expect(
        ClickWheelVolumeLevel.fromName(ClickWheelVolumeLevel.mute.name),
        ClickWheelVolumeLevel.mute,
      );
    });

    test('levels map to the playback volume range', () {
      final Set<double> values = ClickWheelVolumeLevel.values
          .map((ClickWheelVolumeLevel level) => level.value)
          .toSet();
      expect(values.length, ClickWheelVolumeLevel.values.length);
      for (final ClickWheelVolumeLevel level in ClickWheelVolumeLevel.values) {
        expect(level.value, inInclusiveRange(0, 1));
      }
      expect(ClickWheelVolumeLevel.mute.value, 0);
      expect(ClickWheelVolumeLevel.max.value, 1);
    });
  });
}
