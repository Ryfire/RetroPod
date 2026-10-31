import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:retropod/core/constants/constants.dart';
import 'package:retropod/features/notes/models/note_file_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _kNoteFontSizesKey = 'note_font_sizes';

const String _kNoteBookmarksKey = 'note_bookmarks';

const String _kNoteBookmarkOffsetsKey = 'note_bookmark_offsets';

/// Font sizes (in points) of the legacy 0-based index values stored in
/// [Constants] before the granular global font size setting existed.
const List<int> _kLegacyNoteFontSizePresets = [12, 14, 18];

const List<String> _kNoteExtensions = ['.txt', '.md'];

const int _kMaxNoteFileSize = 2 * 1024 * 1024;

/// The single folder scanned for notes. Users manage note files externally
/// (for example a file manager in split screen) and hit Refresh in the
/// notes list to pick up changes.
String notesDirectoryPath() {
  if (Platform.isAndroid) {
    return '/storage/emulated/0/Documents/Notes';
  }
  if (Platform.isIOS) {
    return '';
  }
  if (Platform.isWindows) {
    final userProfile =
        Platform.environment['USERPROFILE'] ?? 'C:\\Users\\User';
    return p.join(userProfile, 'Documents', 'Notes');
  }
  final home = Platform.environment['HOME'] ?? '/';
  return p.join(home, 'Documents', 'Notes');
}

List<NoteFileModel> scanNotesDirectory(String dirPath) {
  final List<NoteFileModel> files = [];
  if (dirPath.isEmpty) {
    return files;
  }
  final dir = Directory(dirPath);
  if (!dir.existsSync()) {
    return files;
  }
  try {
    for (final entity in dir.listSync(recursive: true, followLinks: false)) {
      if (entity is! File) continue;
      final ext = p.extension(entity.path).toLowerCase();
      if (!_kNoteExtensions.contains(ext)) continue;
      try {
        final stat = entity.statSync();
        if (stat.size > _kMaxNoteFileSize) continue;
        files.add(
          NoteFileModel(
            path: entity.path,
            name: p.basenameWithoutExtension(entity.path),
            dateModified: stat.modified,
            fileSize: stat.size,
          ),
        );
      } catch (_) {
        // Skip unreadable files
      }
    }
  } catch (_) {
    // Skip inaccessible directories
  }
  files.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  return files;
}

/// Returns the notes from [notes] whose paths are present in
/// [bookmarkedPaths], sorted alphabetically like the main notes list.
/// Paths that no longer match a scanned file are dropped.
List<NoteFileModel> filterBookmarkedNotes(
  List<NoteFileModel> notes,
  Set<String> bookmarkedPaths,
) {
  final bookmarked = notes
      .where((note) => bookmarkedPaths.contains(note.path))
      .toList();
  bookmarked.sort(
    (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
  );
  return bookmarked;
}

final notesServiceProvider =
    AsyncNotifierProvider<NotesServiceNotifier, List<NoteFileModel>>(
      NotesServiceNotifier.new,
    );

class NotesServiceNotifier extends AsyncNotifier<List<NoteFileModel>> {
  @override
  Future<List<NoteFileModel>> build() {
    return _loadNotes();
  }

  Future<List<NoteFileModel>> _loadNotes() async {
    if (kIsWeb) {
      return [];
    }
    final String dirPath = notesDirectoryPath();
    if (dirPath.isNotEmpty) {
      try {
        await Directory(dirPath).create(recursive: true);
      } catch (_) {
        // Best effort: without storage access the folder is simply empty.
      }
    }
    return compute(scanNotesDirectory, dirPath);
  }

  /// Re-reads the notes folder while showing the loading spinner.
  Future<void> rescan() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_loadNotes);
  }

  /// Re-reads the notes folder without a spinner, e.g. after returning
  /// from another app that changed files in the notes folder.
  Future<void> refreshSilently() async {
    final result = await AsyncValue.guard(_loadNotes);
    if (!ref.mounted) {
      return;
    }
    state = result;
  }

  Future<Map<String, int>> _loadFontSizes() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kNoteFontSizesKey);
    if (raw == null || raw.isEmpty) {
      return {};
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return decoded.map(
          (key, value) => MapEntry(key, value is int ? value : 0),
        );
      }
    } catch (_) {
      // Corrupted data, fall back to empty map
    }
    return {};
  }

  /// The per-note font size override in points, or null when the note has
  /// no override and should use the global font size setting. Legacy
  /// entries stored a 0-based index into the old [12, 14, 18] preset list
  /// and are migrated on read.
  Future<int?> getFontSize(String notePath) async {
    final sizes = await _loadFontSizes();
    final value = sizes[notePath];
    if (value == null) {
      return null;
    }
    if (value < _kLegacyNoteFontSizePresets.length) {
      return _kLegacyNoteFontSizePresets[value];
    }
    return value.clamp(Constants.minNoteFontSize, Constants.maxNoteFontSize);
  }

  Future<void> setFontSize(String notePath, int pointSize) async {
    final prefs = await SharedPreferences.getInstance();
    final sizes = await _loadFontSizes();
    sizes[notePath] = pointSize.clamp(
      Constants.minNoteFontSize,
      Constants.maxNoteFontSize,
    );
    await prefs.setString(_kNoteFontSizesKey, jsonEncode(sizes));
  }

  /// Removes every per-note font size override, e.g. when the global font
  /// size setting changes so all notes fall back to it.
  Future<void> clearAllFontSizes() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kNoteFontSizesKey);
  }

  Future<Map<String, int>> _loadBookmarkOffsets() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kNoteBookmarkOffsetsKey);
    if (raw == null || raw.isEmpty) {
      return {};
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return decoded.map(
          (key, value) => MapEntry(key, value is int ? value : 0),
        );
      }
    } catch (_) {
      // Corrupted data, fall back to empty map
    }
    return {};
  }

  /// The saved reading position for a note as a zero-based character offset
  /// into the file content, or null when the note has no bookmark. Offsets
  /// survive font-size changes because pagination re-resolves them to pages.
  Future<int?> getBookmarkOffset(String notePath) async {
    final bookmarks = await _loadBookmarkOffsets();
    return bookmarks[notePath];
  }

  /// The set of note paths that currently have a saved bookmark.
  Future<Set<String>> getBookmarkedPaths() async {
    final bookmarks = await _loadBookmarkOffsets();
    return bookmarks.keys.toSet();
  }

  Future<void> setBookmarkOffset(String notePath, int charOffset) async {
    if (charOffset < 0) {
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    final bookmarks = await _loadBookmarkOffsets();
    bookmarks[notePath] = charOffset;
    await prefs.setString(_kNoteBookmarkOffsetsKey, jsonEncode(bookmarks));
  }

  /// Removes the bookmark for a note, including any leftover page-index
  /// entry from the first bookmark implementation.
  Future<void> removeBookmark(String notePath) async {
    final prefs = await SharedPreferences.getInstance();
    final bookmarks = await _loadBookmarkOffsets();
    if (bookmarks.containsKey(notePath)) {
      bookmarks.remove(notePath);
      await prefs.setString(_kNoteBookmarkOffsetsKey, jsonEncode(bookmarks));
    }
    final legacyRaw = prefs.getString(_kNoteBookmarksKey);
    if (legacyRaw == null || legacyRaw.isEmpty) {
      return;
    }
    try {
      final decoded = jsonDecode(legacyRaw);
      if (decoded is Map<String, dynamic> && decoded.containsKey(notePath)) {
        decoded.remove(notePath);
        await prefs.setString(_kNoteBookmarksKey, jsonEncode(decoded));
      }
    } catch (_) {
      // Corrupted legacy data, leave it alone
    }
  }
}
