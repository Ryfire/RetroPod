import 'package:flutter_test/flutter_test.dart';
import 'package:retropod/features/notes/models/note_file_model.dart';
import 'package:retropod/features/notes/services/notes_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

NoteFileModel _note(String path, String name) =>
    NoteFileModel(path: path, name: name, fileSize: 10);

void main() {
  group('filterBookmarkedNotes', () {
    final apple = _note('/notes/apple.txt', 'Apple');
    final banana = _note('/notes/banana.txt', 'Banana');
    final cherry = _note('/notes/cherry.md', 'Cherry');

    test('returns only the bookmarked notes', () {
      final result = filterBookmarkedNotes(
        [apple, banana, cherry],
        {apple.path, cherry.path},
      );

      expect(result.map((note) => note.path), [apple.path, cherry.path]);
    });

    test('drops bookmarks whose files no longer exist', () {
      final result = filterBookmarkedNotes(
        [apple, banana],
        {apple.path, banana.path, '/notes/deleted.txt'},
      );

      expect(result.map((note) => note.path), [apple.path, banana.path]);
    });

    test('returns empty when no bookmarks are saved', () {
      expect(filterBookmarkedNotes([apple, banana], <String>{}), isEmpty);
    });

    test('returns empty when no notes are scanned', () {
      expect(filterBookmarkedNotes([], {apple.path}), isEmpty);
    });

    test('sorts alphabetically case-insensitive', () {
      final lower = _note('/notes/b.txt', 'banana');
      final upper = _note('/notes/a.txt', 'Apple');

      final result = filterBookmarkedNotes(
        [lower, upper],
        {lower.path, upper.path},
      );

      expect(result.map((note) => note.name), ['Apple', 'banana']);
    });
  });

  group('getBookmarkedPaths', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('returns the stored bookmark paths', () async {
      final notifier = NotesServiceNotifier();
      await notifier.setBookmarkOffset('/notes/a.txt', 42);
      await notifier.setBookmarkOffset('/notes/b.txt', 7);

      expect(await notifier.getBookmarkedPaths(), {
        '/notes/a.txt',
        '/notes/b.txt',
      });
    });

    test('returns empty when no bookmarks are stored', () async {
      final notifier = NotesServiceNotifier();

      expect(await notifier.getBookmarkedPaths(), isEmpty);
    });

    test('reflects removed bookmarks', () async {
      final notifier = NotesServiceNotifier();
      await notifier.setBookmarkOffset('/notes/a.txt', 42);
      await notifier.removeBookmark('/notes/a.txt');

      expect(await notifier.getBookmarkedPaths(), isEmpty);
    });
  });
}
