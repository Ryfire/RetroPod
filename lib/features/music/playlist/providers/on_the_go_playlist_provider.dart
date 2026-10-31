import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retropod/core/models/music_metadata.dart';
import 'package:retropod/features/music/album/models/album_model.dart';
import 'package:retropod/features/music/playlist/models/playlist_model.dart';

/// Holds the unsaved "On The Go" playlist in its own provider so that it
/// survives rebuilds of [playlistsProvider] (e.g. after a song rating
/// changes) instead of being wiped.
final onTheGoPlaylistProvider =
    NotifierProvider<OnTheGoPlaylistNotifier, PlaylistModel>(
      OnTheGoPlaylistNotifier.new,
    );

class OnTheGoPlaylistNotifier extends Notifier<PlaylistModel> {
  @override
  PlaylistModel build() {
    return PlaylistModel(name: 'On The Go', songs: []);
  }

  void addSongToPlaylist(MusicMetadata? song) {
    if (song != null) {
      state = state.addSongToPlaylist(song);
    }
  }

  void addAlbumToPlaylist(AlbumModel? albumDetail) {
    if (albumDetail != null) {
      albumDetail.albumSongs.forEach(addSongToPlaylist);
    }
  }

  /// Removes a single song from the on-the-go playlist.
  void removeSongFromPlaylist(MusicMetadata? song) {
    if (song != null) {
      state = state.removeSongFromPlaylist(song);
    }
  }

  /// Clears the on-the-go songs after a short delay so the screen pop
  /// animation can finish first.
  void clearPlaylist() {
    Future.delayed(const Duration(milliseconds: 350), () {
      state = PlaylistModel(name: 'On The Go', songs: []);
    });
  }
}
