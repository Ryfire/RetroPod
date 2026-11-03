import 'dart:async';
import 'dart:collection';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:retropod/core/constants/constants.dart';
import 'package:retropod/core/constants/online_audio_files_metadata.dart';
import 'package:retropod/core/models/music_metadata.dart';
import 'package:retropod/core/providers/device_directory_provider.dart';
import 'package:retropod/core/repositories/metadata_reader_repository.dart';
import 'package:retropod/core/utils/directory_exclusion.dart';
import 'package:retropod/core/utils/rating_snapshot.dart';
import 'package:retropod/features/settings/controller/exclude_directories_controller.dart';
import 'package:retropod/features/settings/controller/settings_preferences_controller.dart';
import 'package:retropod/features/settings/repository/settings_preferences_repository.dart';

final audioFilesServiceProvider =
    AsyncNotifierProvider<
      AudioFilesServiceNotifier,
      UnmodifiableListView<MusicMetadata>
    >(AudioFilesServiceNotifier.new);

class AudioFilesServiceNotifier
    extends AsyncNotifier<UnmodifiableListView<MusicMetadata>> {
  /// Guards against concurrent background refreshes parsing the same
  /// missing files twice and duplicating cache entries across provider
  /// rebuilds.
  static bool _isMissingFilesRefreshInProgress = false;

  @override
  Future<UnmodifiableListView<MusicMetadata>> build() async {
    return getAudioFilesMetadata();
  }

  /// Replaces a single metadata entry in the current state so dependent
  /// providers (library lists, starred playlist) immediately see rating or
  /// metadata changes without waiting for a full rescan.
  void updateSongMetadata(MusicMetadata updatedMetadata) {
    final currentSongs = state.value;
    if (currentSongs == null) {
      return;
    }

    state = AsyncData(
      UnmodifiableListView([
        for (final metadata in currentSongs)
          if (metadata.originalSongIndex == updatedMetadata.originalSongIndex)
            updatedMetadata
          else
            metadata,
      ]),
    );
  }

  /// Re-applies the star ratings that were snapshotted before a rescan onto
  /// freshly parsed metadata (matched on `filePath`), then clears the
  /// snapshot so it cannot leak into unrelated future scans. Returns the
  /// list unchanged when no snapshot is present (e.g. the user cancelled the
  /// directory picker and the snapshot must be kept for a later scan).
  Future<List<MusicMetadata>> _restoreSavedRatings(
    List<MusicMetadata> freshlyParsedMetadata,
  ) async {
    final SettingsPreferencesRepository settingsPreferencesRepository = ref
        .read(settingsPreferencesRepositoryProvider);
    final Map<String, int> ratingSnapshot = settingsPreferencesRepository
        .getRatingSnapshot();
    if (ratingSnapshot.isEmpty) {
      return freshlyParsedMetadata;
    }
    await settingsPreferencesRepository.clearRatingSnapshot();
    return applyRatingSnapshot(freshlyParsedMetadata, ratingSnapshot);
  }

  Future<UnmodifiableListView<MusicMetadata>> getAudioFilesMetadata() async {
    state = const AsyncLoading();
    try {
      if (ref.read(settingsPreferencesControllerProvider).fetchOnlineMusic) {
        return UnmodifiableListView(onlineDemoAudioFilesMetaData);
      }
      // Fetch metadata from local files
      else {
        final Box<MusicMetadata> metadataBox = Hive.box<MusicMetadata>(
          Constants.metadataBoxName,
        );
        // Check if the metadata box is empty
        if (metadataBox.isEmpty) {
          if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
            final newDirectory = await FilePicker.getDirectoryPath(
              dialogTitle: "Select Music Directory",
              lockParentWindow: true,
              initialDirectory: ref
                  .read(deviceDirectoryProvider)
                  .requireValue
                  .musicFolderPath,
            );
            if (newDirectory != null) {
              final (
                Set<String> excludedDirectoryPaths,
                List<String> nameFilters,
              ) = _currentExclusionState();
              final result = await compute(
                ref
                    .read(metadataReaderRepositoryProvider)
                    .extractMetadataFromDirectory,
                (
                  directoryPath: newDirectory,
                  excludedDirectoryPaths: excludedDirectoryPaths,
                  nameFilters: nameFilters,
                ),
              );
              final restoredResult = await _restoreSavedRatings(result);
              await metadataBox.addAll(restoredResult);
              return UnmodifiableListView(restoredResult);
            } else {
              return UnmodifiableListView([]);
            }
          } else if (Platform.isIOS) {
            final pickedFiles = await FilePicker.pickFiles(
              allowMultiple: true,
              dialogTitle: "Pick Song Files",
            );

            if (pickedFiles == null || pickedFiles.files.isEmpty) {
              return UnmodifiableListView([]);
            }

            final result = await compute(
              ref
                  .read(metadataReaderRepositoryProvider)
                  .extractMetadataFromFiles,
              pickedFiles.files.map((f) => f.path!).toList(),
            );

            final restoredResult = await _restoreSavedRatings(result);
            await metadataBox.addAll(restoredResult);
            return UnmodifiableListView(restoredResult);
          }
          // On Android Automatically Fetch Music Files
          else {
            final List<String> filePaths = await _queryMediaStorePaths();
            await _syncExcludeRows(filePaths);
            final result = await compute(
              ref
                  .read(metadataReaderRepositoryProvider)
                  .extractMetadataFromFiles,
              _filterExcludedPaths(filePaths),
            );
            final restoredResult = await _restoreSavedRatings(result);
            await metadataBox.addAll(restoredResult);
            return UnmodifiableListView(restoredResult);
          }
        }
        // Return cached metadata
        else {
          // Hand the cached library back immediately and merge newly added
          // files in the background so startup never waits on a media store
          // query.
          final UnmodifiableListView<MusicMetadata> cachedMetadata =
              UnmodifiableListView(metadataBox.values);
          _scheduleMissingFilesRefresh();
          return cachedMetadata;
        }
      }
    } catch (e) {
      return UnmodifiableListView([]);
    }
  }

  Future<List<String>> _queryMediaStorePaths() async {
    final OnAudioQuery audioQuery = OnAudioQuery();
    final queriedSongs = await audioQuery.querySongs();
    return queriedSongs.map((e) => e.data).toList(growable: false);
  }

  (Set<String>, List<String>) _currentExclusionState() {
    final Set<String> excludedDirectoryPaths = ref
        .read(excludedDirectoriesProvider)
        .where((excludeDirectoryModel) => excludeDirectoryModel.isExcluded)
        .map((excludeDirectoryModel) => excludeDirectoryModel.directoryPath)
        .toSet();
    return (excludedDirectoryPaths, ref.read(excludedNameFiltersProvider));
  }

  List<String> _filterExcludedPaths(List<String> filePaths) {
    final (Set<String> excludedDirectoryPaths, List<String> nameFilters) =
        _currentExclusionState();
    return filePaths
        .where(
          (path) => !isDirectoryExcluded(
            directoryPath: parentDirectoryPathOf(path),
            excludedDirectoryPaths: excludedDirectoryPaths,
            nameFilters: nameFilters,
          ),
        )
        .toList(growable: false);
  }

  Future<void> _syncExcludeRows(List<String> filePaths) async {
    final parentDirectoryPaths = filePaths
        .map(parentDirectoryPathOf)
        .whereType<String>()
        .toSet();
    await ref
        .read(excludedDirectoriesProvider.notifier)
        .syncDirectoryRows(parentDirectoryPaths: parentDirectoryPaths);
  }

  /// Runs [refreshMissingFiles] once the current provider build has handed
  /// its state back so the background merge can update the UI afterwards.
  void _scheduleMissingFilesRefresh() {
    unawaited(
      Future<void>.delayed(Duration.zero, () async {
        try {
          await refreshMissingFiles();
        } catch (e) {
          debugPrint("Background missing files refresh failed: $e");
        }
      }),
    );
  }

  /// Parses audio files that are not cached yet and are not excluded,
  /// merging them into the metadata cache. Android only: relies on the
  /// media store to enumerate candidate files.
  Future<void> refreshMissingFiles() async {
    if (_isMissingFilesRefreshInProgress) {
      return;
    }
    _isMissingFilesRefreshInProgress = true;
    try {
      if (kIsWeb ||
          !Platform.isAndroid ||
          ref.read(settingsPreferencesControllerProvider).fetchOnlineMusic) {
        return;
      }
      final Box<MusicMetadata> metadataBox = Hive.box<MusicMetadata>(
        Constants.metadataBoxName,
      );
      final List<String> filePaths = await _queryMediaStorePaths();
      await _syncExcludeRows(filePaths);
      final Set<String> cachedFilePaths = metadataBox.values
          .map((musicMetadata) => musicMetadata.filePath)
          .whereType<String>()
          .toSet();
      final List<String> missingPaths = _filterExcludedPaths(
        filePaths,
      ).where((path) => !cachedFilePaths.contains(path)).toList(
            growable: false,
          );
      if (missingPaths.isEmpty) {
        return;
      }
      final List<MusicMetadata> result = await compute(
        ref.read(metadataReaderRepositoryProvider).extractMetadataFromFiles,
        missingPaths,
      );
      final int startIndex = metadataBox.length;
      final List<MusicMetadata> adjustedResult = [
        for (final (int index, MusicMetadata metadata) in result.indexed)
          metadata.copyWith(originalSongIndex: startIndex + index),
      ];
      await metadataBox.addAll(adjustedResult);
      try {
        state = AsyncData(UnmodifiableListView(metadataBox.values));
      } catch (e) {
        // The notifier may have been replaced by a full rescan while this
        // background refresh was running; the replacement picks the merged
        // cache up on its next build.
        debugPrint("Skipped state update after background refresh: $e");
      }
    } finally {
      _isMissingFilesRefreshInProgress = false;
    }
  }
}
