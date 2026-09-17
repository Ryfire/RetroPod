import 'package:flutter_test/flutter_test.dart';
import 'package:retropod/core/models/content/content_type.dart';
import 'package:retropod/core/utils/media_naming_parser.dart';

void main() {
  group('MediaNamingParser - TV Shows', () {
    test('parses standard SxxExx with quality noise', () {
      const path =
          '/storage/videos/The.Office.US.S02E04.The.Fire.1080p.WEBRip.x265-RARBG.mp4';
      final parsed = MediaNamingParser.parsePath(path);

      expect(parsed.contentType, ContentType.tvShow);
      expect(parsed.tvInfo, isNotNull);
      expect(parsed.tvInfo!.showTitle, 'The Office US');
      expect(parsed.tvInfo!.seasonNumber, 2);
      expect(parsed.tvInfo!.episodeNumber, 4);
      expect(parsed.tvInfo!.episodeTitle, 'The Fire');
    });

    test('parses hyphen separated SxxExx format', () {
      const path =
          "/media/TV Shows/Breaking Bad/Season 01/Breaking Bad - S01E03 - And the Bag's in the River.mkv";
      final parsed = MediaNamingParser.parsePath(path);

      expect(parsed.contentType, ContentType.tvShow);
      expect(parsed.tvInfo!.showTitle, 'Breaking Bad');
      expect(parsed.tvInfo!.seasonNumber, 1);
      expect(parsed.tvInfo!.episodeNumber, 3);
      expect(parsed.tvInfo!.episodeTitle, "And the Bag's in the River");
    });

    test('parses 1x03 notation', () {
      const path =
          '/videos/Stranger Things - 1x01 - Chapter One The Vanishing.avi';
      final parsed = MediaNamingParser.parsePath(path);

      expect(parsed.contentType, ContentType.tvShow);
      expect(parsed.tvInfo!.showTitle, 'Stranger Things');
      expect(parsed.tvInfo!.seasonNumber, 1);
      expect(parsed.tvInfo!.episodeNumber, 1);
      expect(parsed.tvInfo!.episodeTitle, 'Chapter One The Vanishing');
    });

    test('parses directory hierarchy when filename only has episode', () {
      const path =
          '/home/user/Series/Chernobyl/Season 1/02 - Please Remain Calm.mp4';
      final parsed = MediaNamingParser.parsePath(path);

      expect(parsed.contentType, ContentType.tvShow);
      expect(parsed.tvInfo!.showTitle, 'Chernobyl');
      expect(parsed.tvInfo!.seasonNumber, 1);
      expect(parsed.tvInfo!.episodeNumber, 2);
      expect(parsed.tvInfo!.episodeTitle, 'Please Remain Calm');
    });

    test('parses Spanish season folder (Temporada)', () {
      const path = '/Series/La Casa de Papel/Temporada 02/Episodio 05.mkv';
      final parsed = MediaNamingParser.parsePath(path);

      expect(parsed.contentType, ContentType.tvShow);
      expect(parsed.tvInfo!.showTitle, 'La Casa de Papel');
      expect(parsed.tvInfo!.seasonNumber, 2);
      expect(parsed.tvInfo!.episodeNumber, 5);
      expect(parsed.tvInfo!.episodeTitle, 'Episode 5');
    });
  });

  group('MediaNamingParser - Movies', () {
    test('parses movie with year in parentheses', () {
      const path = '/storage/Movies/Inception (2010).mp4';
      final parsed = MediaNamingParser.parsePath(path);

      expect(parsed.contentType, ContentType.movie);
      expect(parsed.movieInfo, isNotNull);
      expect(parsed.movieInfo!.title, 'Inception');
      expect(parsed.movieInfo!.year, 2010);
    });

    test('parses movie with dot separation and release tags', () {
      const path =
          '/media/movies/The.Matrix.1999.2160p.UHD.BluRay.x265.Remux.mkv';
      final parsed = MediaNamingParser.parsePath(path);

      expect(parsed.contentType, ContentType.movie);
      expect(parsed.movieInfo!.title, 'The Matrix');
      expect(parsed.movieInfo!.year, 1999);
    });

    test('parses movie in nested folder', () {
      const path =
          '/Peliculas/Interstellar (2014)/Interstellar (2014) [1080p].mp4';
      final parsed = MediaNamingParser.parsePath(path);

      expect(parsed.contentType, ContentType.movie);
      expect(parsed.movieInfo!.title, 'Interstellar');
      expect(parsed.movieInfo!.year, 2014);
    });

    test('parses movie without year gracefully', () {
      const path = '/videos/Spirited Away.mp4';
      final parsed = MediaNamingParser.parsePath(path);

      expect(parsed.contentType, ContentType.movie);
      expect(parsed.movieInfo!.title, 'Spirited Away');
      expect(parsed.movieInfo!.year, isNull);
    });
  });

  group('MediaNamingParser - Podcasts', () {
    test('parses date-prefixed podcast episode in folder', () {
      const path =
          '/storage/Podcasts/Huberman Lab/2023-04-10 - Sleep Toolkit.mp3';
      final parsed = MediaNamingParser.parsePath(path);

      expect(parsed.contentType, ContentType.podcast);
      expect(parsed.podcastInfo, isNotNull);
      expect(parsed.podcastInfo!.podcastTitle, 'Huberman Lab');
      expect(parsed.podcastInfo!.episodeTitle, 'Sleep Toolkit');
      expect(parsed.podcastInfo!.publishDate, DateTime(2023, 4, 10));
    });

    test('parses podcast without date prefix', () {
      const path = '/media/podcast/The Daily/Inflation and the Economy.m4a';
      final parsed = MediaNamingParser.parsePath(path);

      expect(parsed.contentType, ContentType.podcast);
      expect(parsed.podcastInfo!.podcastTitle, 'The Daily');
      expect(parsed.podcastInfo!.episodeTitle, 'Inflation and the Economy');
      expect(parsed.podcastInfo!.publishDate, isNull);
    });
  });

  group('MediaNamingParser - Audiobooks', () {
    test('parses multi-chapter audiobook with author folder', () {
      const path =
          '/Audiobooks/Brandon Sanderson/The Way of Kings/01 - Stormblessed.m4a';
      final parsed = MediaNamingParser.parsePath(path);

      expect(parsed.contentType, ContentType.audiobook);
      expect(parsed.audiobookInfo, isNotNull);
      expect(parsed.audiobookInfo!.author, 'Brandon Sanderson');
      expect(parsed.audiobookInfo!.bookTitle, 'The Way of Kings');
      expect(parsed.audiobookInfo!.chapterIndex, 1);
      expect(parsed.audiobookInfo!.chapterTitle, 'Stormblessed');
    });

    test('parses audiobook with Author - Title folder pattern', () {
      const path =
          '/storage/Audiolibros/Frank Herbert - Dune/02 - Chapter 2.mp3';
      final parsed = MediaNamingParser.parsePath(path);

      expect(parsed.contentType, ContentType.audiobook);
      expect(parsed.audiobookInfo!.author, 'Frank Herbert');
      expect(parsed.audiobookInfo!.bookTitle, 'Dune');
      expect(parsed.audiobookInfo!.chapterIndex, 2);
      expect(parsed.audiobookInfo!.chapterTitle, 'Chapter 2');
    });

    test('parses standalone .m4b file as audiobook', () {
      const path = '/Downloads/Andy Weir - Project Hail Mary.m4b';
      final parsed = MediaNamingParser.parsePath(path);

      expect(parsed.contentType, ContentType.audiobook);
      expect(parsed.audiobookInfo!.author, 'Andy Weir');
      expect(parsed.audiobookInfo!.bookTitle, 'Project Hail Mary');
      expect(parsed.audiobookInfo!.chapterTitle, 'Complete Audiobook');
    });
  });

  group('MediaNamingParser - Music fallback', () {
    test('plain audio file outside special folders falls back to music', () {
      const path =
          '/storage/Music/Queen/A Night at the Opera/04 - Bohemian Rhapsody.flac';
      final parsed = MediaNamingParser.parsePath(path);

      expect(parsed.contentType, ContentType.music);
      expect(parsed.tvInfo, isNull);
      expect(parsed.movieInfo, isNull);
    });
  });
}
