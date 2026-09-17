import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:retropod/core/models/content/audiobook_models.dart';
import 'package:retropod/core/models/content/content_type.dart';
import 'package:retropod/core/models/content/movie_model.dart';
import 'package:retropod/core/models/content/podcast_models.dart';
import 'package:retropod/core/models/content/tv_show_models.dart';
import 'package:retropod/core/services/embedded_metadata_reader.dart';
import 'package:retropod/core/utils/media_naming_parser.dart';

abstract class OnlineMetadataEnricher {
  Future<TvEpisode?> enrichTvEpisode(TvEpisode episode);
  Future<Movie?> enrichMovie(Movie movie);
  Future<PodcastEpisode?> enrichPodcastEpisode(PodcastEpisode episode);
  Future<Audiobook?> enrichAudiobook(Audiobook audiobook);
}

class DisabledOnlineMetadataEnricher implements OnlineMetadataEnricher {
  const DisabledOnlineMetadataEnricher();

  @override
  Future<TvEpisode?> enrichTvEpisode(TvEpisode episode) async => null;

  @override
  Future<Movie?> enrichMovie(Movie movie) async => null;

  @override
  Future<PodcastEpisode?> enrichPodcastEpisode(PodcastEpisode episode) async =>
      null;

  @override
  Future<Audiobook?> enrichAudiobook(Audiobook audiobook) async => null;
}

class IngestedMediaResult {
  final ContentType contentType;
  final TvEpisode? tvEpisode;
  final Movie? movie;
  final PodcastEpisode? podcastEpisode;
  final Audiobook? audiobook;

  const IngestedMediaResult.tvEpisode(this.tvEpisode)
    : contentType = ContentType.tvShow,
      movie = null,
      podcastEpisode = null,
      audiobook = null;

  const IngestedMediaResult.movie(this.movie)
    : contentType = ContentType.movie,
      tvEpisode = null,
      podcastEpisode = null,
      audiobook = null;

  const IngestedMediaResult.podcastEpisode(this.podcastEpisode)
    : contentType = ContentType.podcast,
      tvEpisode = null,
      movie = null,
      audiobook = null;

  const IngestedMediaResult.audiobook(this.audiobook)
    : contentType = ContentType.audiobook,
      tvEpisode = null,
      movie = null,
      podcastEpisode = null;

  const IngestedMediaResult.music()
    : contentType = ContentType.music,
      tvEpisode = null,
      movie = null,
      podcastEpisode = null,
      audiobook = null;
}

class ContentIngestionService {
  final EmbeddedMetadataReader embeddedReader;
  final OnlineMetadataEnricher onlineEnricher;
  final String? thumbnailsDirectoryPath;

  const ContentIngestionService({
    this.embeddedReader = const EmbeddedMetadataReader(),
    this.onlineEnricher = const DisabledOnlineMetadataEnricher(),
    this.thumbnailsDirectoryPath,
  });

  /// Ingests and organizes a media file using the 4-layer detection approach:
  /// Layer 1: Embedded metadata (MP4 iTunes atoms, ID3)
  /// Layer 2: Regex/Folder naming conventions (fallback)
  /// Layer 3: Automatic thumbnails (extracted cover or local poster)
  /// Layer 4: Online enrichment (if enabled)
  Future<IngestedMediaResult> ingestFile(String filePath) async {
    final file = File(filePath);
    final fileName = filePath.replaceAll(r'\', '/').split('/').last;

    // Layer 1: Read embedded metadata if available
    EmbeddedMediaMetadata? embedded;
    if (MediaNamingParser.isVideoFile(filePath) ||
        filePath.toLowerCase().endsWith('.m4b') ||
        filePath.toLowerCase().endsWith('.m4a')) {
      embedded = await embeddedReader.readMp4Metadata(file);
    }

    // Save embedded artwork if present
    String? thumbnailPath;
    if (embedded?.coverArtBytes != null && thumbnailsDirectoryPath != null) {
      thumbnailPath = await _saveCoverArt(filePath, embedded!.coverArtBytes!);
    } else {
      thumbnailPath = _findSiblingArtwork(filePath);
    }

    // Layer 2: Filename & path convention inference
    final parsed = MediaNamingParser.parsePath(filePath);

    // Determine content type based on Layer 1 priority, then Layer 2
    final resolvedType = embedded?.inferredContentType ?? parsed.contentType;

    switch (resolvedType) {
      case ContentType.tvShow:
        final tv = _buildTvEpisode(
          filePath: filePath,
          fileName: fileName,
          embedded: embedded,
          parsedTv: parsed.tvInfo,
          thumbnailPath: thumbnailPath,
        );
        final enriched = await onlineEnricher.enrichTvEpisode(tv);
        return IngestedMediaResult.tvEpisode(enriched ?? tv);

      case ContentType.movie:
        final movie = _buildMovie(
          filePath: filePath,
          fileName: fileName,
          embedded: embedded,
          parsedMovie: parsed.movieInfo,
          thumbnailPath: thumbnailPath,
        );
        final enriched = await onlineEnricher.enrichMovie(movie);
        return IngestedMediaResult.movie(enriched ?? movie);

      case ContentType.podcast:
        final podcast = _buildPodcastEpisode(
          filePath: filePath,
          fileName: fileName,
          embedded: embedded,
          parsedPodcast: parsed.podcastInfo,
          thumbnailPath: thumbnailPath,
        );
        final enriched = await onlineEnricher.enrichPodcastEpisode(podcast);
        return IngestedMediaResult.podcastEpisode(enriched ?? podcast);

      case ContentType.audiobook:
        final audiobook = _buildAudiobook(
          filePath: filePath,
          fileName: fileName,
          embedded: embedded,
          parsedAudiobook: parsed.audiobookInfo,
          thumbnailPath: thumbnailPath,
        );
        final enriched = await onlineEnricher.enrichAudiobook(audiobook);
        return IngestedMediaResult.audiobook(enriched ?? audiobook);

      case ContentType.music:
        return const IngestedMediaResult.music();
    }
  }

  TvEpisode _buildTvEpisode({
    required String filePath,
    required String fileName,
    EmbeddedMediaMetadata? embedded,
    ParsedTvInfo? parsedTv,
    String? thumbnailPath,
  }) {
    final showTitle =
        embedded?.showTitle ?? parsedTv?.showTitle ?? 'Unknown Show';
    final seasonNumber = embedded?.seasonNumber ?? parsedTv?.seasonNumber ?? 1;
    final episodeNumber =
        embedded?.episodeNumber ?? parsedTv?.episodeNumber ?? 1;
    final title =
        embedded?.title ?? parsedTv?.episodeTitle ?? 'Episode $episodeNumber';

    return TvEpisode(
      id: filePath,
      showTitle: showTitle,
      seasonNumber: seasonNumber,
      episodeNumber: episodeNumber,
      title: title,
      filePath: filePath,
      thumbnailPath: thumbnailPath,
      overview: embedded?.description,
      airDate: embedded?.releaseDate,
    );
  }

  Movie _buildMovie({
    required String filePath,
    required String fileName,
    EmbeddedMediaMetadata? embedded,
    ParsedMovieInfo? parsedMovie,
    String? thumbnailPath,
  }) {
    final title =
        embedded?.title ??
        parsedMovie?.title ??
        MediaNamingParser.cleanTitle(fileName);
    final year = embedded?.releaseDate?.year ?? parsedMovie?.year;

    return Movie(
      id: filePath,
      title: title,
      year: year,
      filePath: filePath,
      thumbnailPath: thumbnailPath,
      overview: embedded?.description,
    );
  }

  PodcastEpisode _buildPodcastEpisode({
    required String filePath,
    required String fileName,
    EmbeddedMediaMetadata? embedded,
    ParsedPodcastInfo? parsedPodcast,
    String? thumbnailPath,
  }) {
    final podcastTitle =
        embedded?.albumOrBook ??
        parsedPodcast?.podcastTitle ??
        'Unknown Podcast';
    final title =
        embedded?.title ??
        parsedPodcast?.episodeTitle ??
        MediaNamingParser.cleanTitle(fileName);
    final publishDate = embedded?.releaseDate ?? parsedPodcast?.publishDate;

    return PodcastEpisode(
      id: filePath,
      podcastTitle: podcastTitle,
      title: title,
      filePath: filePath,
      thumbnailPath: thumbnailPath,
      publishDate: publishDate,
      description: embedded?.description,
    );
  }

  Audiobook _buildAudiobook({
    required String filePath,
    required String fileName,
    EmbeddedMediaMetadata? embedded,
    ParsedAudiobookInfo? parsedAudiobook,
    String? thumbnailPath,
  }) {
    final title =
        embedded?.albumOrBook ??
        embedded?.title ??
        parsedAudiobook?.bookTitle ??
        MediaNamingParser.cleanTitle(fileName);
    final author = embedded?.artistOrAuthor ?? parsedAudiobook?.author;

    List<AudiobookChapter> chapters = embedded?.chapters ?? [];
    if (chapters.isEmpty) {
      chapters = [
        AudiobookChapter(
          index: parsedAudiobook?.chapterIndex ?? 1,
          title: parsedAudiobook?.chapterTitle ?? title,
          filePath: filePath,
        ),
      ];
    }

    return Audiobook(
      id: filePath,
      title: title,
      author: author,
      filePath: filePath,
      thumbnailPath: thumbnailPath,
      chapters: chapters,
    );
  }

  Future<String?> _saveCoverArt(String filePath, Uint8List bytes) async {
    if (thumbnailsDirectoryPath == null) return null;
    try {
      final dir = Directory(thumbnailsDirectoryPath!);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      final safeName = filePath.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
      final targetFile = File('$thumbnailsDirectoryPath/$safeName.jpg');
      await targetFile.writeAsBytes(bytes);
      return targetFile.path;
    } catch (_) {
      return null;
    }
  }

  String? _findSiblingArtwork(String mediaPath) {
    try {
      final parentDir = File(mediaPath).parent;
      if (!parentDir.existsSync()) return null;

      const candidates = [
        'cover.jpg',
        'cover.png',
        'poster.jpg',
        'poster.png',
        'folder.jpg',
        'folder.png',
      ];
      for (final name in candidates) {
        final f = File('${parentDir.path}/$name');
        if (f.existsSync()) return f.path;
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  /// Groups a flat list of TV episodes into hierarchical TvShows and TvSeasons.
  static List<TvShow> groupTvShows(List<TvEpisode> episodes) {
    final Map<String, Map<int, List<TvEpisode>>> grouped = {};

    for (final ep in episodes) {
      grouped
          .putIfAbsent(ep.showTitle, () => {})
          .putIfAbsent(ep.seasonNumber, () => [])
          .add(ep);
    }

    final List<TvShow> shows = [];
    for (final showEntry in grouped.entries) {
      final showTitle = showEntry.key;
      final seasonsMap = showEntry.value;

      final List<TvSeason> seasons = [];
      String? showThumb;

      final sortedSeasonNumbers = seasonsMap.keys.toList()..sort();
      for (final seasonNum in sortedSeasonNumbers) {
        final seasonEps = seasonsMap[seasonNum]!;
        seasonEps.sort((a, b) => a.episodeNumber.compareTo(b.episodeNumber));

        final seasonThumb = seasonEps
            .map((e) => e.thumbnailPath)
            .whereType<String>()
            .firstOrNull;
        showThumb ??= seasonThumb;

        seasons.add(
          TvSeason(
            showTitle: showTitle,
            seasonNumber: seasonNum,
            episodes: seasonEps,
            thumbnailPath: seasonThumb,
          ),
        );
      }

      shows.add(
        TvShow(title: showTitle, seasons: seasons, thumbnailPath: showThumb),
      );
    }

    shows.sort(
      (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
    );
    return shows;
  }

  /// Groups a flat list of podcast episodes into PodcastShows.
  static List<PodcastShow> groupPodcastShows(List<PodcastEpisode> episodes) {
    final Map<String, List<PodcastEpisode>> grouped = {};

    for (final ep in episodes) {
      grouped.putIfAbsent(ep.podcastTitle, () => []).add(ep);
    }

    final List<PodcastShow> shows = [];
    for (final entry in grouped.entries) {
      final eps = entry.value;
      // Sort episodes newest first
      eps.sort((a, b) {
        if (a.publishDate != null && b.publishDate != null) {
          return b.publishDate!.compareTo(a.publishDate!);
        }
        return a.title.toLowerCase().compareTo(b.title.toLowerCase());
      });

      final thumb = eps
          .map((e) => e.thumbnailPath)
          .whereType<String>()
          .firstOrNull;

      shows.add(
        PodcastShow(title: entry.key, episodes: eps, thumbnailPath: thumb),
      );
    }

    shows.sort(
      (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
    );
    return shows;
  }
}
