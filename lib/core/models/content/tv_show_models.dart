import 'package:flutter/foundation.dart';

@immutable
class TvEpisode {
  final String id;
  final String showTitle;
  final int seasonNumber;
  final int episodeNumber;
  final String title;
  final String filePath;
  final String? thumbnailPath;
  final int? durationMs;
  final String? overview;
  final DateTime? airDate;

  const TvEpisode({
    required this.id,
    required this.showTitle,
    required this.seasonNumber,
    required this.episodeNumber,
    required this.title,
    required this.filePath,
    this.thumbnailPath,
    this.durationMs,
    this.overview,
    this.airDate,
  });

  String get episodeLabel {
    final seasonStr = seasonNumber.toString().padLeft(2, '0');
    final episodeStr = episodeNumber.toString().padLeft(2, '0');
    return 'S${seasonStr}E$episodeStr';
  }

  TvEpisode copyWith({
    String? id,
    String? showTitle,
    int? seasonNumber,
    int? episodeNumber,
    String? title,
    String? filePath,
    String? thumbnailPath,
    int? durationMs,
    String? overview,
    DateTime? airDate,
  }) {
    return TvEpisode(
      id: id ?? this.id,
      showTitle: showTitle ?? this.showTitle,
      seasonNumber: seasonNumber ?? this.seasonNumber,
      episodeNumber: episodeNumber ?? this.episodeNumber,
      title: title ?? this.title,
      filePath: filePath ?? this.filePath,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      durationMs: durationMs ?? this.durationMs,
      overview: overview ?? this.overview,
      airDate: airDate ?? this.airDate,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'showTitle': showTitle,
      'seasonNumber': seasonNumber,
      'episodeNumber': episodeNumber,
      'title': title,
      'filePath': filePath,
      'thumbnailPath': thumbnailPath,
      'durationMs': durationMs,
      'overview': overview,
      'airDate': airDate?.toIso8601String(),
    };
  }

  factory TvEpisode.fromMap(Map<String, dynamic> map) {
    return TvEpisode(
      id: map['id'] as String,
      showTitle: map['showTitle'] as String,
      seasonNumber: map['seasonNumber'] as int,
      episodeNumber: map['episodeNumber'] as int,
      title: map['title'] as String,
      filePath: map['filePath'] as String,
      thumbnailPath: map['thumbnailPath'] as String?,
      durationMs: map['durationMs'] as int?,
      overview: map['overview'] as String?,
      airDate: map['airDate'] != null
          ? DateTime.tryParse(map['airDate'] as String)
          : null,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is TvEpisode &&
            runtimeType == other.runtimeType &&
            id == other.id &&
            showTitle == other.showTitle &&
            seasonNumber == other.seasonNumber &&
            episodeNumber == other.episodeNumber &&
            title == other.title &&
            filePath == other.filePath &&
            thumbnailPath == other.thumbnailPath &&
            durationMs == other.durationMs &&
            overview == other.overview &&
            airDate == other.airDate;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      showTitle,
      seasonNumber,
      episodeNumber,
      title,
      filePath,
      thumbnailPath,
      durationMs,
      overview,
      airDate,
    );
  }

  @override
  String toString() {
    return 'TvEpisode($episodeLabel: $title, show: $showTitle)';
  }
}

@immutable
class TvSeason {
  final String showTitle;
  final int seasonNumber;
  final List<TvEpisode> episodes;
  final String? thumbnailPath;

  const TvSeason({
    required this.showTitle,
    required this.seasonNumber,
    required this.episodes,
    this.thumbnailPath,
  });

  int get episodeCount => episodes.length;

  String get seasonTitle {
    if (seasonNumber == 0) {
      return 'Specials';
    }
    return 'Season $seasonNumber';
  }

  TvSeason copyWith({
    String? showTitle,
    int? seasonNumber,
    List<TvEpisode>? episodes,
    String? thumbnailPath,
  }) {
    return TvSeason(
      showTitle: showTitle ?? this.showTitle,
      seasonNumber: seasonNumber ?? this.seasonNumber,
      episodes: episodes ?? this.episodes,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is TvSeason &&
            runtimeType == other.runtimeType &&
            showTitle == other.showTitle &&
            seasonNumber == other.seasonNumber &&
            listEquals(episodes, other.episodes) &&
            thumbnailPath == other.thumbnailPath;
  }

  @override
  int get hashCode {
    return Object.hash(
      showTitle,
      seasonNumber,
      Object.hashAll(episodes),
      thumbnailPath,
    );
  }

  @override
  String toString() {
    return 'TvSeason($showTitle, $seasonTitle, episodes: $episodeCount)';
  }
}

@immutable
class TvShow {
  final String title;
  final List<TvSeason> seasons;
  final String? thumbnailPath;

  const TvShow({
    required this.title,
    required this.seasons,
    this.thumbnailPath,
  });

  int get seasonCount => seasons.length;

  int get totalEpisodes {
    return seasons.fold<int>(0, (total, s) => total + s.episodeCount);
  }

  TvShow copyWith({
    String? title,
    List<TvSeason>? seasons,
    String? thumbnailPath,
  }) {
    return TvShow(
      title: title ?? this.title,
      seasons: seasons ?? this.seasons,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is TvShow &&
            runtimeType == other.runtimeType &&
            title == other.title &&
            listEquals(seasons, other.seasons) &&
            thumbnailPath == other.thumbnailPath;
  }

  @override
  int get hashCode {
    return Object.hash(title, Object.hashAll(seasons), thumbnailPath);
  }

  @override
  String toString() {
    return 'TvShow($title, seasons: $seasonCount, episodes: $totalEpisodes)';
  }
}
