import 'package:flutter_test/flutter_test.dart';
import 'package:retropod/features/notes/services/notes_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('note bookmark offsets', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('set then get returns the saved offset', () async {
      final notifier = NotesServiceNotifier();

      await notifier.setBookmarkOffset('/notes/a.txt', 4213);

      expect(await notifier.getBookmarkOffset('/notes/a.txt'), 4213);
      expect(await notifier.getBookmarkOffset('/notes/b.txt'), isNull);
    });

    test('setting again overwrites the previous offset', () async {
      final notifier = NotesServiceNotifier();

      await notifier.setBookmarkOffset('/notes/a.txt', 100);
      await notifier.setBookmarkOffset('/notes/a.txt', 780);

      expect(await notifier.getBookmarkOffset('/notes/a.txt'), 780);
    });

    test('removeBookmark clears the saved offset', () async {
      final notifier = NotesServiceNotifier();

      await notifier.setBookmarkOffset('/notes/a.txt', 300);
      await notifier.removeBookmark('/notes/a.txt');

      expect(await notifier.getBookmarkOffset('/notes/a.txt'), isNull);
    });

    test('removing a bookmark for a note without one is a no-op', () async {
      final notifier = NotesServiceNotifier();

      await notifier.removeBookmark('/notes/a.txt');

      expect(await notifier.getBookmarkOffset('/notes/a.txt'), isNull);
    });

    test('negative offsets are ignored', () async {
      final notifier = NotesServiceNotifier();

      await notifier.setBookmarkOffset('/notes/a.txt', -1);

      expect(await notifier.getBookmarkOffset('/notes/a.txt'), isNull);
    });

    test('corrupted stored data falls back to no bookmarks', () async {
      SharedPreferences.setMockInitialValues({
        'note_bookmark_offsets': 'not json',
      });
      final notifier = NotesServiceNotifier();

      expect(await notifier.getBookmarkOffset('/notes/a.txt'), isNull);
    });

    test('bookmarks persist across notifier instances', () async {
      final first = NotesServiceNotifier();
      await first.setBookmarkOffset('/notes/a.txt', 90210);

      final second = NotesServiceNotifier();

      expect(await second.getBookmarkOffset('/notes/a.txt'), 90210);
    });

    test('removeBookmark also clears legacy page-index entries', () async {
      SharedPreferences.setMockInitialValues({
        'note_bookmarks': '{"/notes/a.txt": 3, "/notes/b.txt": 1}',
      });
      final notifier = NotesServiceNotifier();

      await notifier.removeBookmark('/notes/a.txt');

      final prefs = await SharedPreferences.getInstance();
      final legacy = prefs.getString('note_bookmarks');
      expect(legacy, isNotNull);
      expect(legacy, isNot(contains('/notes/a.txt')));
      expect(legacy, contains('/notes/b.txt'));
    });
  });
}
