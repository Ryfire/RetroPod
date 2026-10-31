import 'package:flutter_test/flutter_test.dart';
import 'package:retropod/core/constants/constants.dart';
import 'package:retropod/features/notes/services/notes_service.dart';
import 'package:retropod/features/settings/models/note_font_color.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('per-note font sizes', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('returns null when no per-note size is saved', () async {
      final notifier = NotesServiceNotifier();

      expect(await notifier.getFontSize('/notes/a.txt'), isNull);
    });

    test('set then get returns the saved point size', () async {
      final notifier = NotesServiceNotifier();

      await notifier.setFontSize('/notes/a.txt', 15);

      expect(await notifier.getFontSize('/notes/a.txt'), 15);
    });

    test('stored point sizes are clamped to the supported range', () async {
      final notifier = NotesServiceNotifier();

      await notifier.setFontSize('/notes/a.txt', 25);
      expect(
        await notifier.getFontSize('/notes/a.txt'),
        Constants.maxNoteFontSize,
      );

      await notifier.setFontSize('/notes/b.txt', 5);
      expect(
        await notifier.getFontSize('/notes/b.txt'),
        Constants.minNoteFontSize,
      );
    });

    test('legacy preset indices are migrated to point sizes', () async {
      SharedPreferences.setMockInitialValues({
        'note_font_sizes':
            '{"/notes/a.txt": 0, "/notes/b.txt": 1, "/notes/c.txt": 2}',
      });
      final notifier = NotesServiceNotifier();

      expect(await notifier.getFontSize('/notes/a.txt'), 12);
      expect(await notifier.getFontSize('/notes/b.txt'), 14);
      expect(await notifier.getFontSize('/notes/c.txt'), 18);
    });

    test('corrupted stored sizes fall back into the supported range', () async {
      SharedPreferences.setMockInitialValues({
        'note_font_sizes': '{"/notes/a.txt": 5}',
      });
      final notifier = NotesServiceNotifier();

      expect(
        await notifier.getFontSize('/notes/a.txt'),
        Constants.minNoteFontSize,
      );
    });

    test('clearAllFontSizes removes every per-note override', () async {
      final notifier = NotesServiceNotifier();
      await notifier.setFontSize('/notes/a.txt', 16);
      await notifier.setFontSize('/notes/b.txt', 17);

      await notifier.clearAllFontSizes();

      expect(await notifier.getFontSize('/notes/a.txt'), isNull);
      expect(await notifier.getFontSize('/notes/b.txt'), isNull);
    });
  });

  group('NoteFontColor', () {
    test('fromName resolves known values', () {
      expect(NoteFontColor.fromName('theme'), NoteFontColor.theme);
      expect(NoteFontColor.fromName('blue'), NoteFontColor.blue);
      expect(NoteFontColor.fromName('brown'), NoteFontColor.brown);
    });

    test('fromName falls back to theme for unknown names', () {
      expect(NoteFontColor.fromName('nonsense'), NoteFontColor.theme);
      expect(NoteFontColor.fromName(''), NoteFontColor.theme);
    });

    test('theme resolves to no fixed color', () {
      expect(NoteFontColor.theme.textColor, isNull);
    });

    test('device colors resolve to a fixed color', () {
      for (final color in NoteFontColor.values.skip(1)) {
        expect(
          color.textColor,
          isNotNull,
          reason: '${color.name} has no color',
        );
      }
    });
  });
}
