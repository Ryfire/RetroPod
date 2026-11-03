import 'package:retropod/core/models/music_metadata.dart';

/// Computes the cache keys of library entries whose file is no longer
/// present in the source listing (e.g. the Android media store), so a
/// bidirectional incremental sync can prune them.
///
/// A source query that unexpectedly returns nothing is treated as
/// unreliable rather than as proof that every file vanished; pruning is
/// skipped in that case so a transient empty query can never wipe the
/// cached library.
Set<K> staleCacheKeys<K>({
  required Map<K, String> filePathsByCacheKey,
  required Set<String> existingFilePaths,
}) {
  if (existingFilePaths.isEmpty) {
    return const {};
  }
  return {
    for (final MapEntry(key: key, value: filePath)
        in filePathsByCacheKey.entries)
      if (!existingFilePaths.contains(filePath)) key,
  };
}

/// Rebuilds the library entries with contiguous sequential
/// [MusicMetadata.originalSongIndex] values so pruned rows do not leave
/// gaps in the playlist indexes.
Map<K, MusicMetadata> reindexedLibrary<K>({
  required Map<K, MusicMetadata> metadataByCacheKey,
}) {
  return {
    for (final (index, entry) in metadataByCacheKey.entries.indexed)
      entry.key: entry.value.copyWith(originalSongIndex: index),
  };
}
