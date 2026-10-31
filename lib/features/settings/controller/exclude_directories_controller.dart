import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:path/path.dart' as p;
import 'package:retropod/core/constants/constants.dart';
import 'package:retropod/core/services/audio_files_service.dart';
import 'package:retropod/features/music/album/providers/album_details_provider.dart';
import 'package:retropod/features/music/artists/providers/artist_names_provider.dart';
import 'package:retropod/features/music/genres/providers/genres_provider.dart';
import 'package:retropod/features/music/playlist/providers/playlists_provider.dart';
import 'package:retropod/features/music/songs/provider/songs_provider.dart';
import 'package:retropod/features/settings/models/exclude_directory_model.dart';

final excludedDirectoriesProvider =
    NotifierProvider<ExcludeDirectoryNotifier, List<ExcludeDirectoryModel>>(
      ExcludeDirectoryNotifier.new,
    );

final excludedNameFiltersProvider =
    NotifierProvider<ExcludedNameFiltersNotifier, List<String>>(
      ExcludedNameFiltersNotifier.new,
    );

/// Parses audio files that became visible after un-excluding folders or
/// removing a filter rule, then refreshes the library providers.
Future<void> refreshLibraryAfterExclusionChange(Ref ref) async {
  await ref.read(audioFilesServiceProvider.notifier).refreshMissingFiles();
  ref.invalidate(albumDetailsProvider);
  ref.invalidate(artistNamesProvider);
  ref.invalidate(songsProvider);
  ref.invalidate(playlistsProvider);
  ref.invalidate(genresProvider);
  ref.read(playlistsProvider.notifier).refreshProvider();
}

class ExcludedNameFiltersNotifier extends Notifier<List<String>> {
  final Box<String> _nameFiltersBox = Hive.box<String>(
    Constants.excludedNameFiltersBoxName,
  );

  @override
  List<String> build() {
    return _nameFiltersBox.values.toList();
  }

  Future<void> addNameFilter(String rawName) async {
    final String name = rawName.trim();
    if (name.isEmpty) {
      return;
    }
    final bool alreadyExists = state.any(
      (filter) => filter.toLowerCase() == name.toLowerCase(),
    );
    if (alreadyExists) {
      return;
    }
    await _nameFiltersBox.add(name);
    state = _nameFiltersBox.values.toList();
  }

  Future<void> removeNameFilter(String name) async {
    final String target = name.toLowerCase();
    dynamic keyToRemove;
    for (final key in _nameFiltersBox.keys) {
      final String? value = _nameFiltersBox.get(key);
      if (value != null && value.toLowerCase() == target) {
        keyToRemove = key;
        break;
      }
    }
    if (keyToRemove != null) {
      await _nameFiltersBox.delete(keyToRemove);
      state = _nameFiltersBox.values.toList();
      await refreshLibraryAfterExclusionChange(ref);
    }
  }
}

class ExcludeDirectoryNotifier extends Notifier<List<ExcludeDirectoryModel>> {
  /// System folders that contain notification-like sounds and are excluded
  /// from the library by default (e.g. Android's Ringtones folder).
  static const Set<String> _autoExcludedDirectoryNames = {
    'alarms',
    'notifications',
    'ringtones',
  };

  final Box<ExcludeDirectoryModel> _excludeDirectoryBox =
      Hive.box<ExcludeDirectoryModel>(Constants.excludedDirectoriesBoxName);

  @override
  List<ExcludeDirectoryModel> build() {
    return _excludeDirectoryBox.values.toList();
  }

  List<String> get _parentDirectoryPaths {
    return _excludeDirectoryBox.values
        .map((excludeDirectoryModel) => excludeDirectoryModel.directoryPath)
        .toList();
  }

  /// Creates a row for every unseen parent directory, auto-excluding system
  /// sound folders by name. Returns true when new rows were added.
  Future<bool> syncDirectoryRows({
    required Iterable<String> parentDirectoryPaths,
  }) async {
    final Set<String> knownPaths = _parentDirectoryPaths.toSet();
    bool didChange = false;
    for (final String directoryPath in parentDirectoryPaths) {
      if (knownPaths.contains(directoryPath)) {
        continue;
      }
      final bool isAutoExcluded = _autoExcludedDirectoryNames.contains(
        p.basename(directoryPath).toLowerCase(),
      );
      await _excludeDirectoryBox.add(
        ExcludeDirectoryModel(
          directoryPath: directoryPath,
          isExcluded: isAutoExcluded,
        ),
      );
      knownPaths.add(directoryPath);
      didChange = true;
    }
    if (didChange) {
      state = _excludeDirectoryBox.values.toList();
    }
    return didChange;
  }

  Future<void> createDefaultDirectories() async {
    final audioFiles = ref.read(audioFilesServiceProvider).requireValue;
    final parentDirectoryPaths = audioFiles
        .map((musicMetadata) => musicMetadata.parentDirectoryPath)
        .whereType<String>();
    await syncDirectoryRows(parentDirectoryPaths: parentDirectoryPaths);
  }

  Future<void> toggleExcludeDirectory({
    required dynamic excludeDirectoryModelKey,
  }) async {
    if (excludeDirectoryModelKey == null) {
      return;
    } else {
      final excludeDirectory = _excludeDirectoryBox.get(
        excludeDirectoryModelKey,
      );
      if (excludeDirectory != null) {
        final ExcludeDirectoryModel updatedDirectory = excludeDirectory
            .copyWith(isExcluded: !excludeDirectory.isExcluded);
        await _excludeDirectoryBox.put(
          excludeDirectoryModelKey,
          updatedDirectory,
        );
        state = _excludeDirectoryBox.values.toList();
        if (!updatedDirectory.isExcluded) {
          await refreshLibraryAfterExclusionChange(ref);
        }
      }
    }
  }
}
