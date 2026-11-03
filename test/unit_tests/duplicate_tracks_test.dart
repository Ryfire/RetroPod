import 'package:flutter_test/flutter_test.dart';
import 'package:retropod/core/models/music_metadata.dart';
import 'package:retropod/core/utils/duplicate_tracks.dart';

void main() {
  test('matches full filenames case-insensitively across folders/platforms', () {
    final first = MusicMetadata(filePath: '/music/Track.MP3');
    final copy = MusicMetadata(filePath: r'C:\copies\track.mp3');
    final otherFormat = MusicMetadata(filePath: '/music/track.flac');
    final different = MusicMetadata(filePath: '/music/Other.mp3');
    expect(withoutDuplicateFileNames([first, copy, otherFormat, different]), [
      first,
      otherFormat,
      different,
    ]);
  });

  test('uses filenames, not titles; preserves unknown and opaque paths', () {
    final songs = [
      MusicMetadata(trackName: 'Same', filePath: '/music/a.mp3'),
      MusicMetadata(trackName: 'Same', filePath: '/music/b.mp3'),
      MusicMetadata(trackName: 'Same'),
      MusicMetadata(trackName: 'Same', filePath: ''),
      MusicMetadata(filePath: 'content://media/audio/1'),
      MusicMetadata(filePath: 'content://other/audio/1'),
    ];
    expect(withoutDuplicateFileNames(songs), songs);
  });

  test('decodes URI filenames without decoding literal filesystem names', () {
    final first = MusicMetadata(filePath: '/music/a b.mp3');
    final encoded = MusicMetadata(filePath: 'file:///copy/a%20b.mp3');
    final literal = MusicMetadata(filePath: '/music/a%20b.mp3');
    expect(withoutDuplicateFileNames([first, encoded, literal]), [
      first,
      literal,
    ]);
  });
}
