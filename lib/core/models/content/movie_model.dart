import 'package:flutter/foundation.dart';

@immutable
class Movie {
  final String id;
  final String title;
  final int? year;
  final String filePath;
  final String? thumbnailPath;
  final int? durationMs;
  final String? overview;

  const Movie({
    required this.id,
    required this.title,
    this.year,
    required this.filePath,
    this.thumbnailPath,
    this.durationMs,
    this.overview,
  });

  String get displayTitle {
    if (year != null && year! > 0) {
      return '$title ($year)';
    }
    return title;
  }

  Movie copyWith({
    String? id,
    String? title,
    int? year,
    String? filePath,
    String? thumbnailPath,
    int? durationMs,
    String? overview,
  }) {
    return Movie(
      id: id ?? this.id,
      title: title ?? this.title,
      year: year ?? this.year,
      filePath: filePath ?? this.filePath,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      durationMs: durationMs ?? this.durationMs,
      overview: overview ?? this.overview,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'year': year,
      'filePath': filePath,
      'thumbnailPath': thumbnailPath,
      'durationMs': durationMs,
      'overview': overview,
    };
  }

  factory Movie.fromMap(Map<String, dynamic> map) {
    return Movie(
      id: map['id'] as String,
      title: map['title'] as String,
      year: map['year'] as int?,
      filePath: map['filePath'] as String,
      thumbnailPath: map['thumbnailPath'] as String?,
      durationMs: map['durationMs'] as int?,
      overview: map['overview'] as String?,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is Movie &&
            runtimeType == other.runtimeType &&
            id == other.id &&
            title == other.title &&
            year == other.year &&
            filePath == other.filePath &&
            thumbnailPath == other.thumbnailPath &&
            durationMs == other.durationMs &&
            overview == other.overview;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      title,
      year,
      filePath,
      thumbnailPath,
      durationMs,
      overview,
    );
  }

  @override
  String toString() {
    return 'Movie($displayTitle, path: $filePath)';
  }
}
