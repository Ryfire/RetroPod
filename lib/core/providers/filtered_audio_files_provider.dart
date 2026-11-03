import 'dart:collection';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retropod/core/models/music_metadata.dart';
import 'package:retropod/core/services/audio_files_service.dart';
import 'package:retropod/core/utils/directory_exclusion.dart';
import 'package:retropod/core/utils/duplicate_tracks.dart';
import 'package:retropod/features/settings/controller/exclude_directories_controller.dart';
import 'package:retropod/features/settings/controller/prevent_duplicate_tracks_controller.dart';

final filteredAudioFilesProvider =
    FutureProvider<UnmodifiableListView<MusicMetadata>>((ref) async {
      final preventDuplicates = ref.watch(preventDuplicateTracksProvider);
      // Load the audio files metadata
      final audioFilesMetadata = await ref.watch(
        audioFilesServiceProvider.future,
      );

      final excludedParentDirectories = ref
          .watch(excludedDirectoriesProvider)
          .where((excludeDirectoryModel) => excludeDirectoryModel.isExcluded)
          .map((excludedDirectoryModel) => excludedDirectoryModel.directoryPath)
          .toSet();
      final nameFilters = ref.watch(excludedNameFiltersProvider);

      final List<MusicMetadata> filteredList = [];
      for (final audioFileMetadata in audioFilesMetadata) {
        if (!isDirectoryExcluded(
          directoryPath: audioFileMetadata.parentDirectoryPath,
          excludedDirectoryPaths: excludedParentDirectories,
          nameFilters: nameFilters,
        )) {
          filteredList.add(audioFileMetadata);
        }
      }

      return UnmodifiableListView(
        preventDuplicates
            ? withoutDuplicateFileNames(filteredList)
            : filteredList,
      );
    });
