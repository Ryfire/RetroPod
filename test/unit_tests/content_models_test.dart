import 'package:flutter_test/flutter_test.dart';
import 'package:retropod/core/models/content/audiobook_models.dart';
import 'package:retropod/core/models/content/movie_model.dart';
import 'package:retropod/core/models/content/podcast_models.dart';
import 'package:retropod/core/models/content/tv_show_models.dart';

void main() {
  group('TV Show Models', () {
    test('TvEpisode serialization and helpers', () {
      final ep = TvEpisode(
        id: 'ep1',
        showTitle: 'Breaking Bad',
        seasonNumber: 1,
        episodeNumber: 3,
        title: "And the Bag's in the River",
        filePath: '/videos/bb_s01e03.mp4',
        durationMs: 2880000,
        overview: 'Walt and Jesse clean up the mess.',
        airDate: DateTime(2008, 2, 10),
      );

      expect(ep.episodeLabel, 'S01E03');
      final map = ep.toMap();
      final fromMap = TvEpisode.fromMap(map);
      expect(fromMap, equals(ep));
      expect(fromMap.hashCode, equals(ep.hashCode));
      expect(ep.toString(), contains('S01E03'));

      final modified = ep.copyWith(title: 'New Title');
      expect(modified.title, 'New Title');
      expect(modified.episodeNumber, 3);
    });

    test('TvSeason calculates count and handles specials', () {
      const ep1 = TvEpisode(
        id: 'ep1',
        showTitle: 'Doctor Who',
        seasonNumber: 0,
        episodeNumber: 1,
        title: 'The Christmas Invasion',
        filePath: '/path/ep1.mp4',
      );
      final ep2 = ep1.copyWith(id: 'ep2', episodeNumber: 2);

      final specialsSeason = TvSeason(
        showTitle: 'Doctor Who',
        seasonNumber: 0,
        episodes: [ep1, ep2],
      );

      expect(specialsSeason.seasonTitle, 'Specials');
      expect(specialsSeason.episodeCount, 2);

      final season1 = specialsSeason.copyWith(seasonNumber: 1);
      expect(season1.seasonTitle, 'Season 1');
      expect(season1.episodes.length, 2);
    });

    test('TvShow computes totals accurately', () {
      const ep1 = TvEpisode(
        id: '1',
        showTitle: 'Show',
        seasonNumber: 1,
        episodeNumber: 1,
        title: 'Ep 1',
        filePath: '/1.mp4',
      );
      const ep2 = TvEpisode(
        id: '2',
        showTitle: 'Show',
        seasonNumber: 2,
        episodeNumber: 1,
        title: 'Ep 2',
        filePath: '/2.mp4',
      );

      const s1 = TvSeason(showTitle: 'Show', seasonNumber: 1, episodes: [ep1]);
      const s2 = TvSeason(showTitle: 'Show', seasonNumber: 2, episodes: [ep2]);

      const show = TvShow(title: 'Show', seasons: [s1, s2]);

      expect(show.seasonCount, 2);
      expect(show.totalEpisodes, 2);
      expect(show.toString(), contains('seasons: 2'));
    });
  });

  group('Movie Model', () {
    test('Movie serialization and display title', () {
      const movie = Movie(
        id: 'm1',
        title: 'Inception',
        year: 2010,
        filePath: '/movies/Inception.2010.mp4',
        durationMs: 8880000,
        overview: 'A thief who steals corporate secrets...',
      );

      expect(movie.displayTitle, 'Inception (2010)');
      final map = movie.toMap();
      final fromMap = Movie.fromMap(map);
      expect(fromMap, equals(movie));

      const noYearMovie = Movie(
        id: 'm2',
        title: 'Short Film',
        filePath: '/movies/Short.mp4',
      );
      expect(noYearMovie.displayTitle, 'Short Film');
    });
  });

  group('Podcast Models', () {
    test('PodcastEpisode and PodcastShow tracking', () {
      final ep1 = PodcastEpisode(
        id: 'p1',
        podcastTitle: 'Tech News',
        title: 'Episode 100',
        filePath: '/podcasts/ep100.mp3',
        publishDate: DateTime(2023),
        isCompleted: true,
      );
      final ep2 = PodcastEpisode(
        id: 'p2',
        podcastTitle: 'Tech News',
        title: 'Episode 101',
        filePath: '/podcasts/ep101.mp3',
        publishDate: DateTime(2023, 1, 8),
      );

      final map = ep1.toMap();
      final restored = PodcastEpisode.fromMap(map);
      expect(restored, equals(ep1));

      final show = PodcastShow(
        title: 'Tech News',
        author: 'Host Name',
        episodes: [ep1, ep2],
      );

      expect(show.totalEpisodes, 2);
      expect(show.unplayedCount, 1);
    });
  });

  group('Audiobook Models', () {
    test('Audiobook and AudiobookChapter serialization', () {
      const ch1 = AudiobookChapter(
        index: 1,
        title: 'Prologue',
        durationMs: 1200000,
        filePath: '/books/book1.m4b',
      );
      const ch2 = AudiobookChapter(
        index: 2,
        title: 'Chapter 1',
        startMs: 1200000,
        durationMs: 2400000,
        filePath: '/books/book1.m4b',
      );

      final chMap = ch1.toMap();
      expect(AudiobookChapter.fromMap(chMap), equals(ch1));

      const book = Audiobook(
        id: 'b1',
        title: 'Dune',
        author: 'Frank Herbert',
        filePath: '/books/Dune.m4b',
        chapters: [ch1, ch2],
        playbackPositionMs: 500000,
        playbackSpeed: 1.25,
        lastChapterIndex: 1,
      );

      expect(book.chapterCount, 2);
      final bookMap = book.toMap();
      final restoredBook = Audiobook.fromMap(bookMap);
      expect(restoredBook, equals(book));
      expect(restoredBook.playbackSpeed, 1.25);
    });
  });
}
