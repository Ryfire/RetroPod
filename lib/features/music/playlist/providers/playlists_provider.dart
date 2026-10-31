import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:retropod/core/constants/constants.dart';
import 'package:retropod/core/models/music_metadata.dart';
import 'package:retropod/features/music/album/models/album_model.dart';
import 'package:retropod/features/music/playlist/models/playlist_model.dart';
import 'package:retropod/features/music/playlist/providers/on_the_go_playlist_provider.dart';
import 'package:retropod/features/music/playlist/providers/starred_playlist_provider.dart';

final playlistsProvider =
    NotifierProvider<PlaylistsNotifier, List<PlaylistModel>>(
      PlaylistsNotifier.new,
    );

class PlaylistsNotifier extends Notifier<List<PlaylistModel>> {
  final Box<PlaylistModel> _playlistBox = Hive.box<PlaylistModel>(
    Constants.playlistBoxName,
  );

  @override
  List<PlaylistModel> build() {
    return [
      ref.watch(onTheGoPlaylistProvider),
      ref.watch(starredPlaylistProvider),
      ..._playlistBox.values,
    ];
  }

  void refreshProvider() {
    state = [
      ref.read(onTheGoPlaylistProvider),
      ref.read(starredPlaylistProvider),
      ..._playlistBox.values,
    ];
  }

  Future<void> saveNewPlaylist({
    required String newPlaylistPlaceholderString,
    required List<MusicMetadata> songs,
  }) async {
    if (songs.isEmpty) {
      return;
    }

    final newPlaylist = PlaylistModel(name: '', songs: songs);
    final newKey = await _playlistBox.add(newPlaylist);
    await _playlistBox.put(
      newKey,
      newPlaylist.copyWith(name: "$newPlaylistPlaceholderString ${newKey + 1}"),
    );
    refreshProvider();
  }

  Future<void> renamePlaylist({
    required dynamic playlistKey,
    required String newPlaylistName,
  }) async {
    // Can't rename the on-the-go or starred playlist options
    if (playlistKey == null || playlistKey == PlaylistModel.starredKey) {
      return;
    } else {
      final currentPlaylist = _playlistBox.get(playlistKey);
      if (currentPlaylist != null) {
        await _playlistBox.put(
          playlistKey,
          currentPlaylist.copyWith(name: newPlaylistName),
        );
        refreshProvider();
      }
    }
  }

  Future<void> clearPlaylist({required dynamic playlistKey}) async {
    // Can't clear the starred playlist option
    if (playlistKey == PlaylistModel.starredKey) {
      return;
    }

    // Clear the on-the-go playlist option
    if (playlistKey == null) {
      ref.read(onTheGoPlaylistProvider.notifier).clearPlaylist();
      return;
    }

    Future.delayed(const Duration(seconds: 1), () async {
      await _playlistBox.delete(playlistKey);
      refreshProvider();
    });
  }

  void addSongToPlaylist(MusicMetadata? song) {
    ref.read(onTheGoPlaylistProvider.notifier).addSongToPlaylist(song);
  }

  void addAlbumToPlaylist(AlbumModel? albumDetail) {
    ref.read(onTheGoPlaylistProvider.notifier).addAlbumToPlaylist(albumDetail);
  }

  Future<void> removeSongFromPlaylist({
    required PlaylistModel playlistModel,
    MusicMetadata? song,
  }) async {
    if (song == null) {
      return;
    }

    // Virtual playlists aren't backed by the box: songs are removed from the
    // on-the-go state, while starred songs are derived from ratings and can
    // only be removed by un-rating them
    if (playlistModel.key == null ||
        playlistModel.key == PlaylistModel.starredKey) {
      if (playlistModel.name == 'On The Go') {
        ref.read(onTheGoPlaylistProvider.notifier).removeSongFromPlaylist(song);
      }
      return;
    }

    await _playlistBox.put(
      playlistModel.key,
      playlistModel.removeSongFromPlaylist(song),
    );
    refreshProvider();
  }
}
