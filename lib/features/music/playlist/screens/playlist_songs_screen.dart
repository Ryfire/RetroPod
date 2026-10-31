import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:retropod/core/extensions/build_context_extensions.dart';
import 'package:retropod/core/models/music_metadata.dart';
import 'package:retropod/core/navigation/routes.dart';
import 'package:retropod/core/services/audio_player_service.dart';
import 'package:retropod/core/widgets/empty_state_widget.dart';
import 'package:retropod/core/widgets/fast_scroll_indicator.dart';
import 'package:retropod/features/custom_screen_elements/custom_screen.dart';
import 'package:retropod/features/music/playlist/models/playlist_model.dart';
import 'package:retropod/features/music/playlist/models/playlist_option_type.dart';
import 'package:retropod/features/music/playlist/providers/playlists_provider.dart';
import 'package:retropod/features/music/playlist/providers/starred_playlist_provider.dart';
import 'package:retropod/features/music/playlist/widgets/playlist_option_list_tile.dart';
import 'package:retropod/features/music/playlist/widgets/playlist_song_list_tile.dart';
import 'package:retropod/features/now_playing/provider/now_playing_details_provider.dart';
import 'package:retropod/features/status_bar/widgets/status_bar.dart';

class PlaylistSongsScreen extends ConsumerStatefulWidget {
  final int? playlistKey;

  const PlaylistSongsScreen({super.key, required this.playlistKey});

  @override
  ConsumerState createState() => _PlaylistsSongsScreenState();
}

class _PlaylistsSongsScreenState extends ConsumerState<PlaylistSongsScreen>
    with CustomScreen {
  @override
  String get routeName => Routes.playlistSongs.name;

  @override
  double get displayTileHeight => 54;

  // The starred playlist is derived from song ratings, so it has no
  // save/rename and clear option rows
  bool get isStarredPlaylist => widget.playlistKey == PlaylistModel.starredKey;

  @override
  int get extraDisplayItems => isStarredPlaylist ? 0 : 2;

  PlaylistModel get playlist {
    if (isStarredPlaylist) {
      return ref.watch(starredPlaylistProvider);
    }
    return ref
        .watch(playlistsProvider)
        .firstWhere((e) => e.key == widget.playlistKey);
  }

  @override
  List<MusicMetadata> get displayItems => playlist.songs;

  @override
  Future<void> onSelectPressed() => _performAction(selectedDisplayItem);

  @override
  Future<void> onSelectLongPress() =>
      _performLongPressAction(selectedDisplayItem);

  Future<void> _performAction(int index) async {
    if (!isStarredPlaylist) {
      final isSavingEmptyOnTheGoPlaylist =
          index == 0 && widget.playlistKey == null && displayItems.isEmpty;
      if (isSavingEmptyOnTheGoPlaylist) {
        return;
      }

      setState(() => selectedDisplayItem = index);
      if (index == 0) {
        if (widget.playlistKey == null) {
          await ref
              .read(playlistsProvider.notifier)
              .saveNewPlaylist(
                newPlaylistPlaceholderString: context.localization.newPlaylist,
                songs: playlist.songs,
              );
          if (mounted) {
            context.pop();
          }
        }
        // If the playlist is not on-the-go, it means we are renaming an existing playlist
        else {
          final newPlaylistName = await context.pushNamed(
            Routes.playlistRename.name,
            extra: playlist.name,
          );
          if (newPlaylistName != null &&
              newPlaylistName is String &&
              newPlaylistName.isNotEmpty) {
            await ref
                .read(playlistsProvider.notifier)
                .renamePlaylist(
                  playlistKey: widget.playlistKey,
                  newPlaylistName: newPlaylistName,
                );
          }
        }
        return;
      } else if (index == 1) {
        await ref
            .read(playlistsProvider.notifier)
            .clearPlaylist(playlistKey: widget.playlistKey);
        if (mounted) {
          context.pop();
        }
        return;
      }
    }

    // Starred songs start at index 0, other playlists have 2 option rows
    final songIndex = isStarredPlaylist ? index : index - 2;
    setState(() => selectedDisplayItem = index);
    await ref
        .read(audioPlayerServiceProvider.notifier)
        .playPlaylist(playlistDetail: playlist, songIndex: songIndex);
    if (mounted) {
      await context.pushNamed(Routes.nowPlaying.name);
    }
  }

  Future<void> _performLongPressAction(int index) async {
    // Starred songs can't be removed individually, un-rate the song instead
    if (isStarredPlaylist) {
      return;
    }

    if (displayItems.isEmpty) return;
    setState(() => selectedDisplayItem = index);
    if (index < 2) {
      return;
    } else {
      final result = await context.pushNamed(
        Routes.playlistSongsMoreOptions.name,
      );
      if (result == true) {
        await ref
            .read(playlistsProvider.notifier)
            .removeSongFromPlaylist(
              playlistModel: playlist,
              song: displayItems[index - 2],
            );
        if (playlist.songs.isEmpty) {
          return _performAction(1);
        } else {
          setState(() {
            selectedDisplayItem = index - 1;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final int optionRowCount = isStarredPlaylist ? 0 : 2;

    if (displayItems.isEmpty) {
      return CupertinoPageScaffold(
        child: Column(
          children: [
            StatusBar(title: playlist.name),
            Expanded(
              child: EmptyStateWidget(
                emptyDescription: context.localization.noMusicFilesFound,
              ),
            ),
          ],
        ),
      );
    }

    final int? currentlyPlayingOriginalIndex = ref
        .watch(nowPlayingDetailsProvider.select((e) => e.currentMetadata))
        ?.originalSongIndex;

    return CupertinoPageScaffold(
      child: Column(
        children: [
          StatusBar(title: playlist.name),
          Flexible(
            child: FastScrollIndicator(
              wheelScrollIndex: wheelScrollIndex,
              itemCount: displayItems.length + optionRowCount,
              itemExtent: displayTileHeight,
              labelAt: (index) => index < optionRowCount
                  ? ''
                  : displayItems[index - optionRowCount].getTrackName,
              child: CupertinoScrollbar(
                controller: scrollController,
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: displayItems.length + optionRowCount,
                  prototypeItem: isStarredPlaylist
                      ? PlaylistSongListTile(
                          songMetadata: displayItems.first,
                          isSelected: false,
                          isCurrentlyPlaying: false,
                          onTap: () {},
                          onLongPress: () {},
                        )
                      : PlaylistOptionListTile(
                          onTap: () {},
                          isSelected: false,
                          type: PlaylistOptionType.savePlaylist,
                        ),
                  itemBuilder: (context, index) {
                    if (index == 0 && !isStarredPlaylist) {
                      return PlaylistOptionListTile(
                        onTap: () async => _performAction(0),
                        isSelected: selectedDisplayItem == 0,
                        type: widget.playlistKey == null
                            ? PlaylistOptionType.savePlaylist
                            : PlaylistOptionType.renamePlaylist,
                      );
                    } else if (index == 1 && !isStarredPlaylist) {
                      return PlaylistOptionListTile(
                        onTap: () async => _performAction(1),
                        isSelected: selectedDisplayItem == 1,
                        type: PlaylistOptionType.clearPlaylist,
                      );
                    }

                    return PlaylistSongListTile(
                      songMetadata: displayItems[index - optionRowCount],
                      isSelected: selectedDisplayItem == index,
                      isCurrentlyPlaying:
                          currentlyPlayingOriginalIndex ==
                          displayItems[index - optionRowCount]
                              .originalSongIndex,
                      onTap: () async => _performAction(index),
                      onLongPress: () async => _performLongPressAction(index),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
