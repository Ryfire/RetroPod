import 'dart:collection';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:retropod/core/constants/constants.dart';
import 'package:retropod/core/models/music_metadata.dart';
import 'package:retropod/core/providers/filtered_audio_files_provider.dart';
import 'package:retropod/features/music/album/models/album_model.dart';
import 'package:retropod/features/music/playlist/models/playlist_model.dart';
import 'package:retropod/features/music/playlist/providers/on_the_go_playlist_provider.dart';
import 'package:retropod/features/music/playlist/providers/playlists_provider.dart';
import 'package:retropod/features/music/playlist/providers/starred_playlist_provider.dart';
import 'package:retropod/hive/hive_registrar.g.dart';

class TestAudioFilesNotifier extends Notifier<List<MusicMetadata>> {
  @override
  List<MusicMetadata> build() => [];

  set songs(List<MusicMetadata> songs) => state = songs;
}

final testAudioFilesProvider =
    NotifierProvider<TestAudioFilesNotifier, List<MusicMetadata>>(
      TestAudioFilesNotifier.new,
    );

MusicMetadata metadata({
  required int originalSongIndex,
  int rating = 0,
}) {
  return MusicMetadata(
    trackName: 'Song $originalSongIndex',
    originalSongIndex: originalSongIndex,
    rating: rating,
  );
}

ProviderContainer createContainer() {
  final container = ProviderContainer(
    overrides: [
      filteredAudioFilesProvider.overrideWith(
        (ref) => UnmodifiableListView(ref.watch(testAudioFilesProvider)),
      ),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('retropod_playlists_test');
    Hive.init(tempDir.path);
    Hive.registerAdapters();
    await Hive.openBox<PlaylistModel>(Constants.playlistBoxName);
  });

  tearDownAll(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  setUp(() async {
    await Hive.box<PlaylistModel>(Constants.playlistBoxName).clear();
  });

  group('onTheGoPlaylistProvider', () {
    test('starts empty', () {
      final container = createContainer();
      final playlist = container.read(onTheGoPlaylistProvider);
      expect(playlist.name, 'On The Go');
      expect(playlist.songs, isEmpty);
    });

    test('adds songs and dedupes', () {
      final container = createContainer();
      final notifier = container.read(onTheGoPlaylistProvider.notifier);
      notifier.addSongToPlaylist(metadata(originalSongIndex: 1));
      notifier.addSongToPlaylist(metadata(originalSongIndex: 1));
      expect(container.read(onTheGoPlaylistProvider).songs.length, 1);
    });

    test('addAlbumToPlaylist adds every album song', () {
      final container = createContainer();
final album = AlbumModel(
        albumName: 'Album',
        albumArtistName: 'Artist',
        albumSongs: [
          metadata(originalSongIndex: 1),
          metadata(originalSongIndex: 2),
        ],
      );
      container
          .read(onTheGoPlaylistProvider.notifier)
          .addAlbumToPlaylist(album);
      expect(container.read(onTheGoPlaylistProvider).songs.length, 2);
    });

    test('removeSongFromPlaylist removes a single song', () {
      final container = createContainer();
      final notifier = container.read(onTheGoPlaylistProvider.notifier);
      notifier.addSongToPlaylist(metadata(originalSongIndex: 1));
      notifier.addSongToPlaylist(metadata(originalSongIndex: 2));
      notifier.removeSongFromPlaylist(metadata(originalSongIndex: 1));
      expect(
        container.read(onTheGoPlaylistProvider).songs.length,
        1,
      );
    });

    test('clearPlaylist empties the songs after the delay', () async {
      final container = createContainer();
      final notifier = container.read(onTheGoPlaylistProvider.notifier);
      notifier.addSongToPlaylist(metadata(originalSongIndex: 1));
      notifier.clearPlaylist();
      await Future<void>.delayed(const Duration(milliseconds: 400));
      expect(container.read(onTheGoPlaylistProvider).songs, isEmpty);
    });
  });

  group('playlistsProvider', () {
    test('composes on-the-go, starred and saved playlists', () async {
      final box = Hive.box<PlaylistModel>(Constants.playlistBoxName);
      await box.add(PlaylistModel(name: 'Saved', songs: []));
      final container = createContainer();
      container
          .read(testAudioFilesProvider.notifier)
          .songs = [
            metadata(originalSongIndex: 0),
            metadata(originalSongIndex: 1, rating: 1),
            metadata(originalSongIndex: 2, rating: 5),
          ];
      await Future<void>.delayed(Duration.zero);

      final playlists = container.read(playlistsProvider);
      expect(playlists.map((e) => e.name), ['On The Go', 'Starred', 'Saved']);
      expect(
        playlists[1].songs.map((e) => e.originalSongIndex),
        [1, 2],
      );
    });

    test('on-the-go songs survive an audio files rebuild', () async {
      final container = createContainer();
      container.read(playlistsProvider);
      container
          .read(onTheGoPlaylistProvider.notifier)
          .addSongToPlaylist(metadata(originalSongIndex: 9));
      container
          .read(testAudioFilesProvider.notifier)
          .songs = [
            metadata(originalSongIndex: 0),
            metadata(originalSongIndex: 1, rating: 2),
          ];
      await Future<void>.delayed(Duration.zero);

      final playlists = container.read(playlistsProvider);
      expect(
        playlists[0].songs.map((e) => e.originalSongIndex),
        [9],
      );
      expect(
        playlists[1].songs.map((e) => e.originalSongIndex),
        [1],
      );
    });

    test('un-rating a song removes it from starred', () async {
      final container = createContainer();
      container
          .read(testAudioFilesProvider.notifier)
          .songs = [metadata(originalSongIndex: 1, rating: 1)];

      await Future<void>.delayed(Duration.zero);
      expect(
        container.read(starredPlaylistProvider).songs.length,
        1,
      );

      container
          .read(testAudioFilesProvider.notifier)
          .songs = [metadata(originalSongIndex: 1)];
      await Future<void>.delayed(Duration.zero);
      expect(
        container.read(starredPlaylistProvider).songs,
        isEmpty,
      );
    });

    test('renamePlaylist ignores the virtual playlists', () async {
      final container = createContainer();
      final notifier = container.read(playlistsProvider.notifier);
      await notifier.renamePlaylist(
        playlistKey: PlaylistModel.starredKey,
        newPlaylistName: 'X',
      );
      await notifier.renamePlaylist(playlistKey: null, newPlaylistName: 'X');
      expect(
        container
            .read(playlistsProvider)
            .where((e) => e.key == null)
            .map((e) => e.name),
        ['On The Go', 'Starred'],
      );
    });

    test('clearPlaylist empties the on-the-go playlist', () async {
      final container = createContainer();
      container
          .read(onTheGoPlaylistProvider.notifier)
          .addSongToPlaylist(metadata(originalSongIndex: 1));
      await container
          .read(playlistsProvider.notifier)
          .clearPlaylist(playlistKey: null);
      await Future<void>.delayed(const Duration(milliseconds: 400));
      expect(container.read(onTheGoPlaylistProvider).songs, isEmpty);
    });

    test('removeSongFromPlaylist removes from on-the-go', () async {
      final container = createContainer();
      container
          .read(onTheGoPlaylistProvider.notifier)
          .addSongToPlaylist(metadata(originalSongIndex: 1));
      container
          .read(onTheGoPlaylistProvider.notifier)
          .addSongToPlaylist(metadata(originalSongIndex: 2));
      final onTheGo = container.read(onTheGoPlaylistProvider);
      await container
          .read(playlistsProvider.notifier)
          .removeSongFromPlaylist(
            playlistModel: onTheGo,
            song: metadata(originalSongIndex: 1),
          );
      expect(
        container.read(onTheGoPlaylistProvider).songs.length,
        1,
      );
    });

    test('removeSongFromPlaylist leaves the starred playlist alone', () async {
      final container = createContainer();
      container
          .read(testAudioFilesProvider.notifier)
          .songs = [metadata(originalSongIndex: 1, rating: 1)];
      await Future<void>.delayed(Duration.zero);
      final starred = container.read(starredPlaylistProvider);
      await container
          .read(playlistsProvider.notifier)
          .removeSongFromPlaylist(
            playlistModel: starred,
            song: metadata(originalSongIndex: 1),
          );
      expect(
        container.read(starredPlaylistProvider).songs.length,
        1,
      );
    });

    test('removeSongFromPlaylist persists for saved playlists', () async {
      final box = Hive.box<PlaylistModel>(Constants.playlistBoxName);
      await box.add(
        PlaylistModel(
          name: 'Saved',
          songs: [
            metadata(originalSongIndex: 1),
            metadata(originalSongIndex: 2),
          ],
        ),
      );
      final container = createContainer();
      final saved = container
          .read(playlistsProvider)
          .firstWhere((e) => e.name == 'Saved');
      await container
          .read(playlistsProvider.notifier)
          .removeSongFromPlaylist(
            playlistModel: saved,
            song: metadata(originalSongIndex: 1),
          );
      expect(
        container
            .read(playlistsProvider)
            .firstWhere((e) => e.name == 'Saved')
            .songs
            .length,
        1,
      );
    });
  });
}
