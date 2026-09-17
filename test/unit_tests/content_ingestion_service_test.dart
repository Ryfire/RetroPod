import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:retropod/core/models/content/content_type.dart';
import 'package:retropod/core/services/content_ingestion_service.dart';

void main() {
  group('ContentIngestionService', () {
    late Directory tempDir;
    late ContentIngestionService service;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('ingestion_test');
      service = ContentIngestionService(
        thumbnailsDirectoryPath: '${tempDir.path}/thumbnails',
      );
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('ingests TV show episode via filename and groups correctly', () async {
      final ep1File = File(
        '${tempDir.path}/TV Shows/Better Call Saul/Season 01/S01E01 - Uno.mp4',
      );
      await ep1File.create(recursive: true);

      final ep2File = File(
        '${tempDir.path}/TV Shows/Better Call Saul/Season 01/S01E02 - Mijo.mp4',
      );
      await ep2File.create(recursive: true);

      final res1 = await service.ingestFile(ep1File.path);
      final res2 = await service.ingestFile(ep2File.path);

      expect(res1.contentType, ContentType.tvShow);
      expect(res1.tvEpisode, isNotNull);
      expect(res1.tvEpisode!.showTitle, 'Better Call Saul');
      expect(res1.tvEpisode!.seasonNumber, 1);
      expect(res1.tvEpisode!.episodeNumber, 1);
      expect(res1.tvEpisode!.title, 'Uno');

      expect(res2.tvEpisode!.episodeNumber, 2);
      expect(res2.tvEpisode!.title, 'Mijo');

      final shows = ContentIngestionService.groupTvShows([
        res1.tvEpisode!,
        res2.tvEpisode!,
      ]);

      expect(shows.length, 1);
      expect(shows.first.title, 'Better Call Saul');
      expect(shows.first.seasonCount, 1);
      expect(shows.first.seasons.first.episodeCount, 2);
    });

    test('ingests Movie and detects sibling poster.jpg', () async {
      final movieFolder = Directory('${tempDir.path}/Movies/Alien (1979)');
      await movieFolder.create(recursive: true);

      final movieFile = File('${movieFolder.path}/Alien (1979).mkv');
      await movieFile.create();

      final posterFile = File('${movieFolder.path}/poster.jpg');
      await posterFile.writeAsString('fake_image_bytes');

      final res = await service.ingestFile(movieFile.path);

      expect(res.contentType, ContentType.movie);
      expect(res.movie, isNotNull);
      expect(res.movie!.title, 'Alien');
      expect(res.movie!.year, 1979);
      expect(res.movie!.thumbnailPath, posterFile.path);
    });

    test('ingests Podcast episode and groups into show', () async {
      final podcastFolder = Directory('${tempDir.path}/Podcasts/Radiolab');
      await podcastFolder.create(recursive: true);

      final epFile = File(
        '${podcastFolder.path}/2023-05-19 - The Cataclysm.mp3',
      );
      await epFile.create();

      final res = await service.ingestFile(epFile.path);

      expect(res.contentType, ContentType.podcast);
      expect(res.podcastEpisode, isNotNull);
      expect(res.podcastEpisode!.podcastTitle, 'Radiolab');
      expect(res.podcastEpisode!.title, 'The Cataclysm');
      expect(res.podcastEpisode!.publishDate, DateTime(2023, 5, 19));

      final shows = ContentIngestionService.groupPodcastShows([
        res.podcastEpisode!,
      ]);
      expect(shows.length, 1);
      expect(shows.first.title, 'Radiolab');
      expect(shows.first.totalEpisodes, 1);
    });

    test('ingests Audiobook with chapter', () async {
      final bookFolder = Directory(
        '${tempDir.path}/Audiobooks/Isaac Asimov/Foundation',
      );
      await bookFolder.create(recursive: true);

      final chFile = File('${bookFolder.path}/01 - The Psychohistorians.m4a');
      await chFile.create();

      final res = await service.ingestFile(chFile.path);

      expect(res.contentType, ContentType.audiobook);
      expect(res.audiobook, isNotNull);
      expect(res.audiobook!.author, 'Isaac Asimov');
      expect(res.audiobook!.title, 'Foundation');
      expect(res.audiobook!.chapters.length, 1);
      expect(res.audiobook!.chapters.first.title, 'The Psychohistorians');
    });
  });
}
