import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:retropod/features/notes/services/notes_service.dart';

void main() {
  group('scanNotesDirectory', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('notes_scan_test');
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    File writeNote(String relativePath) {
      final file = File(p.join(tempDir.path, relativePath));
      file.parent.createSync(recursive: true);
      file.writeAsStringSync('note content');
      return file;
    }

    test('finds txt and md files recursively and ignores other extensions', () {
      writeNote('a.txt');
      writeNote('sub/b.md');
      writeNote('sub/skip.log');

      final notes = scanNotesDirectory(tempDir.path);

      expect(notes.length, 2);
      expect(notes.map((note) => note.name), containsAll(['a', 'b']));
    });

    test('skips files larger than the size limit', () {
      writeNote('small.txt');
      final big = File(p.join(tempDir.path, 'big.txt'));
      final raf = big.openSync(mode: FileMode.write);
      raf.truncateSync(2 * 1024 * 1024 + 1);
      raf.closeSync();

      final notes = scanNotesDirectory(tempDir.path);

      expect(notes.single.name, 'small');
    });

    test('returns an empty list when the folder does not exist', () {
      final missing = p.join(tempDir.path, 'does_not_exist');

      final notes = scanNotesDirectory(missing);

      expect(notes, isEmpty);
    });

    test('returns an empty list for an empty path', () {
      expect(scanNotesDirectory(''), isEmpty);
    });
  });
}
