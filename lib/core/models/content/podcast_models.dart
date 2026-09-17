import 'package:flutter/foundation.dart';

@immutable
class PodcastEpisode {
  final String id;
  final String podcastTitle;
  final String title;
  final String filePath;
  final String? thumbnailPath;
  final int? durationMs;
  final DateTime? publishDate;
  final String? description;
  final int playbackPositionMs;
  final bool isCompleted;

  const PodcastEpisode({
    required this.id,
    required this.podcastTitle,
    required this.title,
    required this.filePath,
    this.thumbnailPath,
    this.durationMs,
    this.publishDate,
    this.description,
    this.playbackPositionMs = 0,
    this.isCompleted = false,
  });

  PodcastEpisode copyWith({
    String? id,
    String? podcastTitle,
    String? title,
    String? filePath,
    String? thumbnailPath,
    int? durationMs,
    DateTime? publishDate,
    String? description,
    int? playbackPositionMs,
    bool? isCompleted,
  }) {
    return PodcastEpisode(
      id: id ?? this.id,
      podcastTitle: podcastTitle ?? this.podcastTitle,
      title: title ?? this.title,
      filePath: filePath ?? this.filePath,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      durationMs: durationMs ?? this.durationMs,
      publishDate: publishDate ?? this.publishDate,
      description: description ?? this.description,
      playbackPositionMs: playbackPositionMs ?? this.playbackPositionMs,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'podcastTitle': podcastTitle,
      'title': title,
      'filePath': filePath,
      'thumbnailPath': thumbnailPath,
      'durationMs': durationMs,
      'publishDate': publishDate?.toIso8601String(),
      'description': description,
      'playbackPositionMs': playbackPositionMs,
      'isCompleted': isCompleted,
    };
  }

  factory PodcastEpisode.fromMap(Map<String, dynamic> map) {
    return PodcastEpisode(
      id: map['id'] as String,
      podcastTitle: map['podcastTitle'] as String,
      title: map['title'] as String,
      filePath: map['filePath'] as String,
      thumbnailPath: map['thumbnailPath'] as String?,
      durationMs: map['durationMs'] as int?,
      publishDate: map['publishDate'] != null
          ? DateTime.tryParse(map['publishDate'] as String)
          : null,
      description: map['description'] as String?,
      playbackPositionMs: (map['playbackPositionMs'] as int?) ?? 0,
      isCompleted: (map['isCompleted'] as bool?) ?? false,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is PodcastEpisode &&
            runtimeType == other.runtimeType &&
            id == other.id &&
            podcastTitle == other.podcastTitle &&
            title == other.title &&
            filePath == other.filePath &&
            thumbnailPath == other.thumbnailPath &&
            durationMs == other.durationMs &&
            publishDate == other.publishDate &&
            description == other.description &&
            playbackPositionMs == other.playbackPositionMs &&
            isCompleted == other.isCompleted;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      podcastTitle,
      title,
      filePath,
      thumbnailPath,
      durationMs,
      publishDate,
      description,
      playbackPositionMs,
      isCompleted,
    );
  }

  @override
  String toString() {
    return 'PodcastEpisode($title, podcast: $podcastTitle)';
  }
}

@immutable
class PodcastShow {
  final String title;
  final String? author;
  final List<PodcastEpisode> episodes;
  final String? thumbnailPath;

  const PodcastShow({
    required this.title,
    this.author,
    required this.episodes,
    this.thumbnailPath,
  });

  int get totalEpisodes => episodes.length;

  int get unplayedCount {
    return episodes.where((e) => !e.isCompleted).length;
  }

  PodcastShow copyWith({
    String? title,
    String? author,
    List<PodcastEpisode>? episodes,
    String? thumbnailPath,
  }) {
    return PodcastShow(
      title: title ?? this.title,
      author: author ?? this.author,
      episodes: episodes ?? this.episodes,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is PodcastShow &&
            runtimeType == other.runtimeType &&
            title == other.title &&
            author == other.author &&
            listEquals(episodes, other.episodes) &&
            thumbnailPath == other.thumbnailPath;
  }

  @override
  int get hashCode {
    return Object.hash(title, author, Object.hashAll(episodes), thumbnailPath);
  }

  @override
  String toString() {
    return 'PodcastShow($title, episodes: $totalEpisodes, unplayed: $unplayedCount)';
  }
}
