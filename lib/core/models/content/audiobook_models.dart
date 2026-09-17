import 'package:flutter/foundation.dart';

@immutable
class AudiobookChapter {
  final int index;
  final String title;
  final int startMs;
  final int? durationMs;
  final String filePath;

  const AudiobookChapter({
    required this.index,
    required this.title,
    this.startMs = 0,
    this.durationMs,
    required this.filePath,
  });

  AudiobookChapter copyWith({
    int? index,
    String? title,
    int? startMs,
    int? durationMs,
    String? filePath,
  }) {
    return AudiobookChapter(
      index: index ?? this.index,
      title: title ?? this.title,
      startMs: startMs ?? this.startMs,
      durationMs: durationMs ?? this.durationMs,
      filePath: filePath ?? this.filePath,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'index': index,
      'title': title,
      'startMs': startMs,
      'durationMs': durationMs,
      'filePath': filePath,
    };
  }

  factory AudiobookChapter.fromMap(Map<String, dynamic> map) {
    return AudiobookChapter(
      index: map['index'] as int,
      title: map['title'] as String,
      startMs: (map['startMs'] as int?) ?? 0,
      durationMs: map['durationMs'] as int?,
      filePath: map['filePath'] as String,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is AudiobookChapter &&
            runtimeType == other.runtimeType &&
            index == other.index &&
            title == other.title &&
            startMs == other.startMs &&
            durationMs == other.durationMs &&
            filePath == other.filePath;
  }

  @override
  int get hashCode {
    return Object.hash(index, title, startMs, durationMs, filePath);
  }

  @override
  String toString() {
    return 'AudiobookChapter($index: $title, start: ${startMs}ms)';
  }
}

@immutable
class Audiobook {
  final String id;
  final String title;
  final String? author;
  final String filePath;
  final String? thumbnailPath;
  final int? durationMs;
  final List<AudiobookChapter> chapters;
  final int playbackPositionMs;
  final double playbackSpeed;
  final int lastChapterIndex;

  const Audiobook({
    required this.id,
    required this.title,
    this.author,
    required this.filePath,
    this.thumbnailPath,
    this.durationMs,
    required this.chapters,
    this.playbackPositionMs = 0,
    this.playbackSpeed = 1.0,
    this.lastChapterIndex = 0,
  });

  int get chapterCount => chapters.length;

  Audiobook copyWith({
    String? id,
    String? title,
    String? author,
    String? filePath,
    String? thumbnailPath,
    int? durationMs,
    List<AudiobookChapter>? chapters,
    int? playbackPositionMs,
    double? playbackSpeed,
    int? lastChapterIndex,
  }) {
    return Audiobook(
      id: id ?? this.id,
      title: title ?? this.title,
      author: author ?? this.author,
      filePath: filePath ?? this.filePath,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      durationMs: durationMs ?? this.durationMs,
      chapters: chapters ?? this.chapters,
      playbackPositionMs: playbackPositionMs ?? this.playbackPositionMs,
      playbackSpeed: playbackSpeed ?? this.playbackSpeed,
      lastChapterIndex: lastChapterIndex ?? this.lastChapterIndex,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'author': author,
      'filePath': filePath,
      'thumbnailPath': thumbnailPath,
      'durationMs': durationMs,
      'chapters': chapters.map((c) => c.toMap()).toList(),
      'playbackPositionMs': playbackPositionMs,
      'playbackSpeed': playbackSpeed,
      'lastChapterIndex': lastChapterIndex,
    };
  }

  factory Audiobook.fromMap(Map<String, dynamic> map) {
    return Audiobook(
      id: map['id'] as String,
      title: map['title'] as String,
      author: map['author'] as String?,
      filePath: map['filePath'] as String,
      thumbnailPath: map['thumbnailPath'] as String?,
      durationMs: map['durationMs'] as int?,
      chapters:
          (map['chapters'] as List<dynamic>?)
              ?.map((e) => AudiobookChapter.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      playbackPositionMs: (map['playbackPositionMs'] as int?) ?? 0,
      playbackSpeed: (map['playbackSpeed'] as num?)?.toDouble() ?? 1.0,
      lastChapterIndex: (map['lastChapterIndex'] as int?) ?? 0,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is Audiobook &&
            runtimeType == other.runtimeType &&
            id == other.id &&
            title == other.title &&
            author == other.author &&
            filePath == other.filePath &&
            thumbnailPath == other.thumbnailPath &&
            durationMs == other.durationMs &&
            listEquals(chapters, other.chapters) &&
            playbackPositionMs == other.playbackPositionMs &&
            playbackSpeed == other.playbackSpeed &&
            lastChapterIndex == other.lastChapterIndex;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      title,
      author,
      filePath,
      thumbnailPath,
      durationMs,
      Object.hashAll(chapters),
      playbackPositionMs,
      playbackSpeed,
      lastChapterIndex,
    );
  }

  @override
  String toString() {
    return 'Audiobook($title by ${author ?? "Unknown"}, chapters: $chapterCount)';
  }
}
