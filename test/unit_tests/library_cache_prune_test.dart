import 'package:flutter_test/flutter_test.dart';
import 'package:retropod/core/models/music_metadata.dart';
import 'package:retropod/core/utils/library_cache_prune.dart';

MusicMetadata _song({required String filePath, int originalSongIndex = 0}) {
  return MusicMetadata(
    filePath: filePath,
    originalSongIndex: originalSongIndex,
  );
}

void main() {
  group('staleCacheKeys', () {
    test('returns keys whose file no longer exists', () {
      final stale = staleCacheKeys(
        filePathsByCacheKey: {1: '/music/a.mp3', 2: '/music/gone.mp3'},
        existingFilePaths: {'/music/a.mp3'},
      );
      expect(stale, {2});
    });

    test('returns nothing when every cached file still exists', () {
      final stale = staleCacheKeys(
        filePathsByCacheKey: {1: '/music/a.mp3', 2: '/music/b.mp3'},
        existingFilePaths: {'/music/a.mp3', '/music/b.mp3'},
      );
      expect(stale, isEmpty);
    });

    test('an empty source listing prunes nothing', () {
      // A transient empty query must never wipe the cached library.
      final stale = staleCacheKeys(
        filePathsByCacheKey: {1: '/music/a.mp3', 2: '/music/b.mp3'},
        existingFilePaths: {},
      );
      expect(stale, isEmpty);
    });
  });

  group('reindexedLibrary', () {
    test('assigns contiguous sequential original song indexes', () {
      final reindexed = reindexedLibrary(
        metadataByCacheKey: {
          4: _song(filePath: '/music/a.mp3', originalSongIndex: 4),
          9: _song(filePath: '/music/b.mp3', originalSongIndex: 7),
          12: _song(filePath: '/music/c.mp3', originalSongIndex: 10),
        },
      );
      expect(reindexed.values.map((metadata) => metadata.originalSongIndex), [
        0,
        1,
        2,
      ]);
      // The cache keys survive unchanged so the same rows are updated.
      expect(reindexed.keys, {4, 9, 12});
      expect(reindexed[9]!.filePath, '/music/b.mp3');
    });

    test('a single remaining entry is reindexed to zero', () {
      final reindexed = reindexedLibrary(
        metadataByCacheKey: {
          5: _song(filePath: '/music/last.mp3', originalSongIndex: 5),
        },
      );
      expect(reindexed[5]!.originalSongIndex, 0);
    });
  });
}
