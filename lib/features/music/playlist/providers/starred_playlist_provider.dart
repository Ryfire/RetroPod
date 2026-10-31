import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retropod/core/providers/filtered_audio_files_provider.dart';
import 'package:retropod/features/music/playlist/models/playlist_model.dart';

/// Virtual playlist holding every song that has been rated with at least
/// one star. It is derived from [filteredAudioFilesProvider], so it updates
/// automatically whenever a song rating changes and persists across app
/// restarts because ratings live in the metadata box.
final starredPlaylistProvider = Provider<PlaylistModel>((ref) {
  final filteredAudioFiles = ref.watch(filteredAudioFilesProvider).value;

  final starredSongs = filteredAudioFiles
      ?.where((metadata) => metadata.rating >= 1)
      .toList();

  return PlaylistModel(name: 'Starred', songs: starredSongs ?? const []);
});
