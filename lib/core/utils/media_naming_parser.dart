import 'package:retropod/core/models/content/content_type.dart';

class ParsedTvInfo {
  final String showTitle;
  final int seasonNumber;
  final int episodeNumber;
  final String episodeTitle;

  const ParsedTvInfo({
    required this.showTitle,
    required this.seasonNumber,
    required this.episodeNumber,
    required this.episodeTitle,
  });

  @override
  String toString() {
    return 'ParsedTvInfo(show: $showTitle, S${seasonNumber}E$episodeNumber, title: $episodeTitle)';
  }
}

class ParsedMovieInfo {
  final String title;
  final int? year;

  const ParsedMovieInfo({required this.title, this.year});

  @override
  String toString() {
    return 'ParsedMovieInfo(title: $title, year: $year)';
  }
}

class ParsedPodcastInfo {
  final String podcastTitle;
  final String episodeTitle;
  final DateTime? publishDate;

  const ParsedPodcastInfo({
    required this.podcastTitle,
    required this.episodeTitle,
    this.publishDate,
  });

  @override
  String toString() {
    return 'ParsedPodcastInfo(podcast: $podcastTitle, episode: $episodeTitle, date: $publishDate)';
  }
}

class ParsedAudiobookInfo {
  final String bookTitle;
  final String? author;
  final int chapterIndex;
  final String chapterTitle;

  const ParsedAudiobookInfo({
    required this.bookTitle,
    this.author,
    required this.chapterIndex,
    required this.chapterTitle,
  });

  @override
  String toString() {
    return 'ParsedAudiobookInfo(book: $bookTitle, author: $author, chapter: $chapterIndex - $chapterTitle)';
  }
}

class ParsedMediaInfo {
  final ContentType contentType;
  final ParsedTvInfo? tvInfo;
  final ParsedMovieInfo? movieInfo;
  final ParsedPodcastInfo? podcastInfo;
  final ParsedAudiobookInfo? audiobookInfo;

  const ParsedMediaInfo.tv({required ParsedTvInfo info})
    : contentType = ContentType.tvShow,
      tvInfo = info,
      movieInfo = null,
      podcastInfo = null,
      audiobookInfo = null;

  const ParsedMediaInfo.movie({required ParsedMovieInfo info})
    : contentType = ContentType.movie,
      tvInfo = null,
      movieInfo = info,
      podcastInfo = null,
      audiobookInfo = null;

  const ParsedMediaInfo.podcast({required ParsedPodcastInfo info})
    : contentType = ContentType.podcast,
      tvInfo = null,
      movieInfo = null,
      podcastInfo = info,
      audiobookInfo = null;

  const ParsedMediaInfo.audiobook({required ParsedAudiobookInfo info})
    : contentType = ContentType.audiobook,
      tvInfo = null,
      movieInfo = null,
      podcastInfo = null,
      audiobookInfo = info;

  const ParsedMediaInfo.music()
    : contentType = ContentType.music,
      tvInfo = null,
      movieInfo = null,
      podcastInfo = null,
      audiobookInfo = null;
}

class MediaNamingParser {
  const MediaNamingParser._();

  static const Set<String> videoExtensions = {
    '.mp4',
    '.m4v',
    '.mkv',
    '.mov',
    '.avi',
    '.webm',
    '.wmv',
    '.flv',
    '.3gp',
  };

  static const Set<String> audioExtensions = {
    '.mp3',
    '.m4a',
    '.m4b',
    '.flac',
    '.aac',
    '.ogg',
    '.opus',
    '.wav',
    '.aif',
    '.aiff',
  };

  static bool isVideoFile(String path) {
    final lower = path.toLowerCase();
    return videoExtensions.any(lower.endsWith);
  }

  static bool isAudioFile(String path) {
    final lower = path.toLowerCase();
    return audioExtensions.any(lower.endsWith);
  }

  static final RegExp _noiseRegex = RegExp(
    r'\b(1080p|720p|2160p|4k|480p|576p|x264|x265|h264|h265|hevc|avc|xvid|divx|bluray|blu-ray|web-dl|webdl|webrip|web|hdtv|dvdrip|dvd|remux|aac|ac3|dts|dd5\.1|truehd|atmos|proper|repack|rerip)\b',
    caseSensitive: false,
  );

  static final RegExp _bracketNoiseRegex = RegExp(
    r'\[[^\]]*\]|\([^\)]*?\b(1080p|720p|2160p|4k|x264|x265|bluray|web)\b[^\)]*?\)',
    caseSensitive: false,
  );

  static final RegExp _releaseGroupRegex = RegExp(r'-[A-Za-z0-9]+$');

  static final RegExp _sxxExxRegex = RegExp(
    r'[sS](\d{1,2})[eE](\d{1,3})(?:-[eE]?\d+)?',
  );

  static final RegExp _xNotationRegex = RegExp(
    r'(?:^|[ ._-])(\d{1,2})x(\d{1,3})(?:[ ._-]|$)',
  );

  static final RegExp _seasonFolderRegex = RegExp(
    r'^(?:Season|Temporada|Saison|Staffel|Stagione)\s*(\d{1,2})$',
    caseSensitive: false,
  );

  static final RegExp _yearRegex = RegExp(
    r'(?:^|[ ._\(\[-])(19\d\d|20\d\d)(?:[ ._\)\]-]|$)',
  );

  static final RegExp _datePrefixRegex = RegExp(
    r'^(\d{4})[-_.](\d{2})[-_.](\d{2})',
  );

  static final RegExp _chapterTrackRegex = RegExp(
    r'^(?:(?:Chapter|Capitulo|Track|Pista)\s*)?(\d{1,3})[ ._-]+(.*)$',
    caseSensitive: false,
  );

  /// Cleans noise tags, file extensions, dots, and underscores from [rawTitle].
  static String cleanTitle(String rawTitle) {
    var s = rawTitle;
    s = s.replaceAll(_bracketNoiseRegex, ' ');
    s = s.replaceAll(_noiseRegex, ' ');
    s = s.replaceAll(_releaseGroupRegex, '');
    s = s.replaceAll(RegExp(r'[._]'), ' ');
    s = s.replaceAll(RegExp(r'\s+'), ' ').trim();
    s = s.replaceAll(RegExp(r'^[-–—\s]+|[-–—\s]+$'), '').trim();
    return s;
  }

  /// Parses any media file path into typed metadata based on conventions.
  static ParsedMediaInfo parsePath(String filePath) {
    final normalized = filePath.replaceAll(r'\', '/');
    final segments = normalized.split('/').where((s) => s.isNotEmpty).toList();
    if (segments.isEmpty) {
      return const ParsedMediaInfo.music();
    }

    final filenameWithExt = segments.last;
    final dotIndex = filenameWithExt.lastIndexOf('.');
    final ext = dotIndex != -1
        ? filenameWithExt.substring(dotIndex).toLowerCase()
        : '';
    final filename = dotIndex != -1
        ? filenameWithExt.substring(0, dotIndex)
        : filenameWithExt;

    final lowerPath = normalized.toLowerCase();

    // 1. Audiobooks check (.m4b or audiobook directory)
    if (ext == '.m4b' ||
        lowerPath.contains('/audiobooks/') ||
        lowerPath.contains('/audiolibros/') ||
        lowerPath.contains('/audio books/')) {
      final audiobookInfo = parseAudiobook(segments, filename, ext);
      return ParsedMediaInfo.audiobook(info: audiobookInfo);
    }

    // 2. Podcasts check
    if (lowerPath.contains('/podcasts/') || lowerPath.contains('/podcast/')) {
      final podcastInfo = parsePodcast(segments, filename);
      return ParsedMediaInfo.podcast(info: podcastInfo);
    }

    // 3. TV Shows check (folder keywords or SxxExx in video)
    final bool hasTvFolder =
        lowerPath.contains('/tv shows/') ||
        lowerPath.contains('/tv shows') ||
        lowerPath.contains('/tv/') ||
        lowerPath.contains('/series/') ||
        lowerPath.contains('/temporadas/');

    final bool matchesTvPattern =
        _sxxExxRegex.hasMatch(filename) ||
        _xNotationRegex.hasMatch(filename) ||
        (segments.length >= 2 &&
            _seasonFolderRegex.hasMatch(segments[segments.length - 2]));

    if (isVideoFile(filePath) && (hasTvFolder || matchesTvPattern)) {
      final tvInfo = parseTvShow(segments, filename);
      if (tvInfo != null) {
        return ParsedMediaInfo.tv(info: tvInfo);
      }
    }

    // 4. Movies check
    if (isVideoFile(filePath)) {
      final movieInfo = parseMovie(segments, filename);
      return ParsedMediaInfo.movie(info: movieInfo);
    }

    // Default to music for audio files outside specific folders
    return const ParsedMediaInfo.music();
  }

  /// Parses TV Show episode details from path segments and filename.
  static ParsedTvInfo? parseTvShow(List<String> segments, String filename) {
    int? season;
    int? episode;
    String? rawShowName;
    String? rawEpisodeTitle;

    // Try SxxExx
    final match = _sxxExxRegex.firstMatch(filename);
    if (match != null) {
      season = int.tryParse(match.group(1)!);
      episode = int.tryParse(match.group(2)!);
      rawShowName = filename.substring(0, match.start);
      rawEpisodeTitle = filename.substring(match.end);
    } else {
      // Try 1x03 notation
      final xMatch = _xNotationRegex.firstMatch(filename);
      if (xMatch != null) {
        season = int.tryParse(xMatch.group(1)!);
        episode = int.tryParse(xMatch.group(2)!);
        rawShowName = filename.substring(0, xMatch.start);
        rawEpisodeTitle = filename.substring(xMatch.end);
      } else if (segments.length >= 2) {
        // Check if parent directory is a season folder
        final parent = segments[segments.length - 2];
        final seasonMatch = _seasonFolderRegex.firstMatch(parent);
        if (seasonMatch != null) {
          season = int.tryParse(seasonMatch.group(1)!);
          // Check if filename has track/episode number: "03 - Title" or "Episode 03"
          final epMatch = RegExp(
            r'(?:(?:Episode|Ep|Capitulo)[ ._-]*)?(\d{1,3})',
          ).firstMatch(filename);
          if (epMatch != null) {
            episode = int.tryParse(epMatch.group(1)!);
            rawEpisodeTitle = filename.substring(epMatch.end);
          }
        }
      }
    }

    if (season == null || episode == null) {
      return null;
    }

    // Determine show title
    String showTitle = cleanTitle(rawShowName ?? '');
    if (showTitle.isEmpty) {
      // Look up directory hierarchy
      // segments: [... , ShowName, Season 01, filename.mp4]
      for (int i = segments.length - 2; i >= 0; i--) {
        final dir = segments[i];
        if (_seasonFolderRegex.hasMatch(dir) ||
            dir.toLowerCase() == 'season' ||
            dir.toLowerCase() == 'temporada') {
          continue;
        }
        if (dir.toLowerCase() == 'tv shows' ||
            dir.toLowerCase() == 'series' ||
            dir.toLowerCase() == 'tv') {
          continue;
        }
        showTitle = cleanTitle(dir);
        break;
      }
    }

    if (showTitle.isEmpty) {
      showTitle = 'Unknown Show';
    }

    // Determine episode title
    String episodeTitle = cleanTitle(rawEpisodeTitle ?? '');
    if (episodeTitle.isEmpty) {
      episodeTitle = 'Episode $episode';
    }

    return ParsedTvInfo(
      showTitle: showTitle,
      seasonNumber: season,
      episodeNumber: episode,
      episodeTitle: episodeTitle,
    );
  }

  /// Parses movie title and year from filename or folder.
  static ParsedMovieInfo parseMovie(List<String> segments, String filename) {
    int? year;
    String rawTitle = filename;

    // Check filename for year
    final yearMatch = _yearRegex.firstMatch(filename);
    if (yearMatch != null) {
      year = int.tryParse(yearMatch.group(1)!);
      rawTitle = filename.substring(0, yearMatch.start);
    } else if (segments.length >= 2) {
      // Check parent folder e.g. "Movie Title (2020)"
      final parent = segments[segments.length - 2];
      final parentYearMatch = _yearRegex.firstMatch(parent);
      if (parentYearMatch != null) {
        year = int.tryParse(parentYearMatch.group(1)!);
        rawTitle = parent.substring(0, parentYearMatch.start);
      }
    }

    var title = cleanTitle(rawTitle);
    if (title.isEmpty) {
      title = cleanTitle(filename);
    }
    if (title.isEmpty) {
      title = 'Unknown Movie';
    }

    return ParsedMovieInfo(title: title, year: year);
  }

  /// Parses podcast show title, episode title, and date.
  static ParsedPodcastInfo parsePodcast(
    List<String> segments,
    String filename,
  ) {
    DateTime? publishDate;
    String rawEpisode = filename;

    final dateMatch = _datePrefixRegex.firstMatch(filename);
    if (dateMatch != null) {
      final y = int.tryParse(dateMatch.group(1)!);
      final m = int.tryParse(dateMatch.group(2)!);
      final d = int.tryParse(dateMatch.group(3)!);
      if (y != null && m != null && d != null) {
        publishDate = DateTime(y, m, d);
      }
      rawEpisode = filename.substring(dateMatch.end);
    }

    String podcastTitle = 'Unknown Podcast';
    if (segments.length >= 2) {
      final parent = segments[segments.length - 2];
      if (parent.toLowerCase() != 'podcasts' &&
          parent.toLowerCase() != 'podcast') {
        podcastTitle = cleanTitle(parent);
      }
    }

    String episodeTitle = cleanTitle(rawEpisode);
    if (episodeTitle.isEmpty) {
      episodeTitle = filename;
    }

    return ParsedPodcastInfo(
      podcastTitle: podcastTitle,
      episodeTitle: episodeTitle,
      publishDate: publishDate,
    );
  }

  /// Parses audiobook title, author, and chapter info.
  static ParsedAudiobookInfo parseAudiobook(
    List<String> segments,
    String filename,
    String ext,
  ) {
    String bookTitle = 'Unknown Book';
    String? author;
    int chapterIndex = 1;
    String chapterTitle = filename;

    // Check for chapter track number: "01 - Chapter 1" or "Chapter 01 - Title"
    final trackMatch = _chapterTrackRegex.firstMatch(filename);
    if (trackMatch != null) {
      final idx = int.tryParse(trackMatch.group(1)!);
      if (idx != null) {
        chapterIndex = idx;
      }
      chapterTitle = cleanTitle(trackMatch.group(2)!);
      if (chapterTitle.isEmpty) {
        chapterTitle = 'Chapter $chapterIndex';
      }
    } else {
      chapterTitle = cleanTitle(filename);
    }

    // Infer book title and author from path hierarchy or filename
    // Case A: Standalone audiobook file (not a numbered track)
    if (trackMatch == null) {
      if (filename.contains(' - ')) {
        final parts = filename.split(' - ');
        author = cleanTitle(parts.first);
        bookTitle = cleanTitle(parts.sublist(1).join(' - '));
      } else {
        bookTitle = cleanTitle(filename);
      }
      chapterTitle = 'Complete Audiobook';
    } else {
      // Case B: Numbered chapter inside folder structure
      // Pattern 1: Audiobooks / Author / Book Title / 01 - Chapter.mp3
      // Pattern 2: Audiobooks / Book Title / 01 - Chapter.mp3
      // Pattern 3: Audiobooks / Author - Book Title / 01 - Chapter.mp3
      if (segments.length >= 3) {
        final parent = segments[segments.length - 2];
        final grandparent = segments[segments.length - 3];

        final isParentRoot = _isAudiobooksRootDir(parent);

        if (!isParentRoot) {
          if (parent.contains(' - ')) {
            final parts = parent.split(' - ');
            author = cleanTitle(parts.first);
            bookTitle = cleanTitle(parts.sublist(1).join(' - '));
          } else {
            bookTitle = cleanTitle(parent);
            final isGrandparentRoot = _isAudiobooksRootDir(grandparent);
            if (!isGrandparentRoot) {
              author = cleanTitle(grandparent);
            }
          }
        }
      } else if (segments.length == 2) {
        final parent = segments[0];
        if (!_isAudiobooksRootDir(parent)) {
          if (parent.contains(' - ')) {
            final parts = parent.split(' - ');
            author = cleanTitle(parts.first);
            bookTitle = cleanTitle(parts.sublist(1).join(' - '));
          } else {
            bookTitle = cleanTitle(parent);
          }
        }
      }
    }

    return ParsedAudiobookInfo(
      bookTitle: bookTitle,
      author: author,
      chapterIndex: chapterIndex,
      chapterTitle: chapterTitle,
    );
  }

  static bool _isAudiobooksRootDir(String dir) {
    final lower = dir.toLowerCase();
    return lower == 'audiobooks' ||
        lower == 'audiolibros' ||
        lower == 'audio books' ||
        lower == 'downloads' ||
        lower == 'descargas' ||
        lower == 'media';
  }
}
