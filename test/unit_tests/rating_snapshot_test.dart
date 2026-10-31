import 'package:flutter_test/flutter_test.dart';
import 'package:retropod/core/models/music_metadata.dart';
import 'package:retropod/core/utils/rating_snapshot.dart';

MusicMetadata _metadata({
  String? filePath,
  int rating = 0,
  int originalSongIndex = 0,
}) {
  return MusicMetadata(
    trackName: 'Test Song',
    filePath: filePath,
    rating: rating,
    originalSongIndex: originalSongIndex,
  );
}

void main() {
  group('extractRatingSnapshot', () {
    test('returns an empty snapshot when no songs are rated', () {
      final Map<String, int> snapshot = extractRatingSnapshot([
        _metadata(filePath: '/music/song_a.mp3'),
        _metadata(filePath: '/music/song_b.mp3'),
      ]);

      expect(snapshot, isEmpty);
    });

    test('extracts ratings of one star and above keyed by filePath', () {
      final Map<String, int> snapshot = extractRatingSnapshot([
        _metadata(filePath: '/music/song_a.mp3'),
        _metadata(filePath: '/music/song_b.mp3', rating: 1),
        _metadata(filePath: '/music/song_c.mp3', rating: 5),
      ]);

      expect(snapshot, {'/music/song_b.mp3': 1, '/music/song_c.mp3': 5});
    });

    test('skips songs without a usable filePath', () {
      final Map<String, int> snapshot = extractRatingSnapshot([
        _metadata(rating: 3),
        _metadata(filePath: '', rating: 3),
      ]);

      expect(snapshot, isEmpty);
    });
  });

  group('applyRatingSnapshot', () {
    test('returns the list unchanged when the snapshot is empty', () {
      final List<MusicMetadata> metadataList = [
        _metadata(filePath: '/music/song_a.mp3', rating: 2),
      ];

      final List<MusicMetadata> result = applyRatingSnapshot(
        metadataList,
        const {},
      );

      expect(identical(result, metadataList), isTrue);
      expect(result.single.rating, 2);
    });

    test('restores ratings onto freshly parsed metadata by filePath', () {
      final List<MusicMetadata> freshlyParsed = [
        _metadata(filePath: '/music/song_b.mp3', originalSongIndex: 1),
        _metadata(filePath: '/music/song_c.mp3', originalSongIndex: 2),
      ];

      final List<MusicMetadata> result = applyRatingSnapshot(freshlyParsed, {
        '/music/song_b.mp3': 4,
        '/music/song_c.mp3': 5,
      });

      expect(result[0].rating, 4);
      expect(result[0].originalSongIndex, 1);
      expect(result[1].rating, 5);
      expect(result[1].originalSongIndex, 2);
    });

    test('keeps freshly parsed metadata untouched when its path is not in '
        'the snapshot', () {
      final List<MusicMetadata> freshlyParsed = [
        _metadata(filePath: '/music/renamed_song.mp3'),
      ];

      final List<MusicMetadata> result = applyRatingSnapshot(freshlyParsed, {
        '/music/song_a.mp3': 3,
      });

      expect(result.single.rating, 0);
    });

    test('does not drop songs that have no filePath', () {
      final List<MusicMetadata> freshlyParsed = [_metadata()];

      final List<MusicMetadata> result = applyRatingSnapshot(freshlyParsed, {
        '/music/song_a.mp3': 3,
      });

      expect(result, hasLength(1));
      expect(result.single.rating, 0);
    });
  });

  group('encodeRatingSnapshot / decodeRatingSnapshot', () {
    test('round-trips a snapshot', () {
      const Map<String, int> snapshot = {
        '/music/song_a.mp3': 1,
        '/music/song_b.mp3': 5,
      };

      final Map<String, int> decoded = decodeRatingSnapshot(
        encodeRatingSnapshot(snapshot),
      );

      expect(decoded, snapshot);
    });

    test('decode returns an empty map for null and empty input', () {
      expect(decodeRatingSnapshot(null), isEmpty);
      expect(decodeRatingSnapshot(''), isEmpty);
    });

    test('decode returns an empty map for malformed input', () {
      expect(decodeRatingSnapshot('not json'), isEmpty);
      expect(decodeRatingSnapshot('[1, 2, 3]'), isEmpty);
    });

    test('decode coerces numeric values and rejects unexpected shapes', () {
      expect(decodeRatingSnapshot('{"a": 3.0}'), {'a': 3});
      expect(decodeRatingSnapshot('{"a": "3"}'), isEmpty);
    });
  });
}
