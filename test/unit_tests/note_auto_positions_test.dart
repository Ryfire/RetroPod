import 'package:flutter_test/flutter_test.dart';
import 'package:retropod/features/notes/services/notes_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('note auto reading positions', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('set then get returns the saved offset', () async {
      final notifier = NotesServiceNotifier();

      await notifier.setAutoPosition('/notes/a.txt', 8347);

      expect(await notifier.getAutoPosition('/notes/a.txt'), 8347);
      expect(await notifier.getAutoPosition('/notes/b.txt'), isNull);
    });

    test('setting again overwrites the previous offset', () async {
      final notifier = NotesServiceNotifier();

      await notifier.setAutoPosition('/notes/a.txt', 100);
      await notifier.setAutoPosition('/notes/a.txt', 905);

      expect(await notifier.getAutoPosition('/notes/a.txt'), 905);
    });

    test('negative offsets are ignored', () async {
      final notifier = NotesServiceNotifier();

      await notifier.setAutoPosition('/notes/a.txt', -1);

      expect(await notifier.getAutoPosition('/notes/a.txt'), isNull);
    });

    test('empty note paths are ignored', () async {
      final notifier = NotesServiceNotifier();

      await notifier.setAutoPosition('', 500);

      expect(await notifier.getAutoPosition(''), isNull);
    });

    test('auto positions live in their own store next to bookmarks', () async {
      final notifier = NotesServiceNotifier();

      await notifier.setBookmarkOffset('/notes/a.txt', 111);
      await notifier.setAutoPosition('/notes/a.txt', 222);

      // The manual bookmark and the auto position never overwrite each
      // other because they are persisted under different keys.
      expect(await notifier.getBookmarkOffset('/notes/a.txt'), 111);
      expect(await notifier.getAutoPosition('/notes/a.txt'), 222);
    });

    test('removeAutoPosition clears only the auto entry', () async {
      final notifier = NotesServiceNotifier();

      await notifier.setBookmarkOffset('/notes/a.txt', 111);
      await notifier.setAutoPosition('/notes/a.txt', 222);
      await notifier.removeAutoPosition('/notes/a.txt');

      expect(await notifier.getAutoPosition('/notes/a.txt'), isNull);
      expect(await notifier.getBookmarkOffset('/notes/a.txt'), 111);
    });

    test('clearAllAutoPositions wipes every auto entry', () async {
      final notifier = NotesServiceNotifier();

      await notifier.setAutoPosition('/notes/a.txt', 1);
      await notifier.setAutoPosition('/notes/b.txt', 2);
      await notifier.clearAllAutoPositions();

      expect(await notifier.getAutoPosition('/notes/a.txt'), isNull);
      expect(await notifier.getAutoPosition('/notes/b.txt'), isNull);
    });

    test('corrupted stored data falls back to no auto positions', () async {
      SharedPreferences.setMockInitialValues({
        'note_auto_positions': 'not json',
      });
      final notifier = NotesServiceNotifier();

      expect(await notifier.getAutoPosition('/notes/a.txt'), isNull);
    });

    test('auto positions persist across notifier instances', () async {
      final first = NotesServiceNotifier();
      await first.setAutoPosition('/notes/a.txt', 424242);

      final second = NotesServiceNotifier();

      expect(await second.getAutoPosition('/notes/a.txt'), 424242);
    });
  });
}
