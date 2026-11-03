import 'package:retropod/core/models/music_metadata.dart';

/// Removes tracks whose file names match an earlier track in the scan order,
/// case-insensitively.
///
/// This targets the same physical file being discovered more than once
/// through different paths (for example aliased storage mounts or content
/// URIs), which would otherwise show up as repeated songs in the library.
/// Tracks with unknown or opaque paths are always kept.
List<MusicMetadata> withoutDuplicateFileNames(Iterable<MusicMetadata> songs) {
  final seen = <String>{};
  return [
    for (final song in songs)
      if (_keep(song.filePath, seen)) song,
  ];
}

bool _keep(String? path, Set<String> seen) {
  if (path == null || path.isEmpty) return true;
  var normalized = path.replaceAll('\\', '/');
  if (normalized.startsWith('content://')) return true;
  if (normalized.startsWith('file:') ||
      normalized.startsWith('http://') ||
      normalized.startsWith('https://')) {
    final uri = Uri.tryParse(normalized);
    if (uri == null || uri.pathSegments.isEmpty) return true;
    normalized = uri.pathSegments.last;
  } else {
    normalized = normalized.split('/').last;
  }
  if (normalized.isEmpty) return true;
  return seen.add(normalized.toLowerCase());
}
