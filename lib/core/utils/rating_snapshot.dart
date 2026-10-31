import 'dart:convert';

import 'package:retropod/core/models/music_metadata.dart';

/// Utilities to preserve star ratings across a full library rescan.
///
/// `rescanMusicFiles` wipes the metadata cache and rebuilds it from file
/// tags, which would reset every song's rating (and therefore the Starred
/// playlist). To keep the Starred playlist intact, the ratings are snapshotted
/// into a `filePath -> rating` map before the cache is cleared and re-applied
/// (matched on `filePath`, a stable identity, instead of the scan-order
/// `originalSongIndex`) once the cache has been rebuilt.

/// Extracts a `filePath -> rating` snapshot for every rated song.
/// Songs without a usable file path or without at least one star are skipped.
Map<String, int> extractRatingSnapshot(List<MusicMetadata> metadataList) {
  final Map<String, int> ratingSnapshot = <String, int>{};
  for (final MusicMetadata metadata in metadataList) {
    final String? filePath = metadata.filePath;
    if (metadata.rating >= 1 && filePath != null && filePath.isNotEmpty) {
      ratingSnapshot[filePath] = metadata.rating;
    }
  }
  return ratingSnapshot;
}

/// Re-applies ratings from [ratingSnapshot] onto freshly parsed metadata by
/// matching on `filePath`. Songs whose path no longer exists in the snapshot
/// (e.g. moved or renamed files) keep their freshly parsed rating of 0.
List<MusicMetadata> applyRatingSnapshot(
  List<MusicMetadata> metadataList,
  Map<String, int> ratingSnapshot,
) {
  if (ratingSnapshot.isEmpty) {
    return metadataList;
  }
  return <MusicMetadata>[
    for (final MusicMetadata metadata in metadataList)
      if (metadata.filePath != null &&
          ratingSnapshot.containsKey(metadata.filePath))
        metadata.copyWith(rating: ratingSnapshot[metadata.filePath])
      else
        metadata,
  ];
}

/// Serializes a rating snapshot for storage in SharedPreferences.
String encodeRatingSnapshot(Map<String, int> ratingSnapshot) =>
    jsonEncode(ratingSnapshot);

/// Deserializes a rating snapshot. Returns an empty map for null, empty or
/// malformed input so a corrupted snapshot never breaks a scan.
Map<String, int> decodeRatingSnapshot(String? encoded) {
  if (encoded == null || encoded.isEmpty) {
    return const <String, int>{};
  }
  try {
    final Object? decoded = jsonDecode(encoded);
    if (decoded is! Map) {
      return const <String, int>{};
    }
    return decoded.map(
      (key, value) => MapEntry(key as String, (value as num).toInt()),
    );
  } on FormatException {
    return const <String, int>{};
  } on TypeError {
    return const <String, int>{};
  }
}
