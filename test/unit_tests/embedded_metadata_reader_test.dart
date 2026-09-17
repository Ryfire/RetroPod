import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:retropod/core/models/content/content_type.dart';
import 'package:retropod/core/services/embedded_metadata_reader.dart';

Uint8List _createDataAtom(int type, Uint8List payload) {
  final bb = BytesBuilder();
  // data atom header: size (4), 'data' (4), type (4), locale (4)
  final size = 16 + payload.length;
  bb.add([
    (size >> 24) & 0xFF,
    (size >> 16) & 0xFF,
    (size >> 8) & 0xFF,
    size & 0xFF,
  ]);
  bb.add(utf8.encode('data'));
  bb.add([
    (type >> 24) & 0xFF,
    (type >> 16) & 0xFF,
    (type >> 8) & 0xFF,
    type & 0xFF,
  ]);
  bb.add([0, 0, 0, 0]); // locale
  bb.add(payload);
  return bb.toBytes();
}

Uint8List _createMetadataBox(String fourcc, Uint8List dataAtom) {
  final bb = BytesBuilder();
  final size = 8 + dataAtom.length;
  bb.add([
    (size >> 24) & 0xFF,
    (size >> 16) & 0xFF,
    (size >> 8) & 0xFF,
    size & 0xFF,
  ]);
  bb.add(fourcc.codeUnits);
  bb.add(dataAtom);
  return bb.toBytes();
}

Uint8List _wrapBox(String fourcc, Uint8List payload) {
  final bb = BytesBuilder();
  final size = 8 + payload.length;
  bb.add([
    (size >> 24) & 0xFF,
    (size >> 16) & 0xFF,
    (size >> 8) & 0xFF,
    size & 0xFF,
  ]);
  bb.add(fourcc.codeUnits);
  bb.add(payload);
  return bb.toBytes();
}

void main() {
  group('EmbeddedMetadataReader', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('retropod_metadata_test');
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('parses TV show atoms (tvsh, tvsn, tves, stik, desc)', () async {
      final ilstBuilder = BytesBuilder();

      // stik = 10 (TV Show)
      ilstBuilder.add(
        _createMetadataBox(
          'stik',
          _createDataAtom(21, Uint8List.fromList([10])),
        ),
      );

      // tvsh = 'The Mandalorian'
      ilstBuilder.add(
        _createMetadataBox(
          'tvsh',
          _createDataAtom(1, utf8.encode('The Mandalorian')),
        ),
      );

      // tvsn = 2
      ilstBuilder.add(
        _createMetadataBox(
          'tvsn',
          _createDataAtom(21, Uint8List.fromList([0, 0, 0, 2])),
        ),
      );

      // tves = 1
      ilstBuilder.add(
        _createMetadataBox(
          'tves',
          _createDataAtom(21, Uint8List.fromList([0, 0, 0, 1])),
        ),
      );

      // ©nam = 'Chapter 9: The Marshal'
      ilstBuilder.add(
        _createMetadataBox(
          '©nam',
          _createDataAtom(1, utf8.encode('Chapter 9: The Marshal')),
        ),
      );

      // desc = 'The Mandalorian searches for other Mandalorians.'
      ilstBuilder.add(
        _createMetadataBox(
          'desc',
          _createDataAtom(
            1,
            utf8.encode('The Mandalorian searches for other Mandalorians.'),
          ),
        ),
      );

      final ilstBytes = _wrapBox('ilst', ilstBuilder.toBytes());

      // meta box (FullBox: 4 bytes version/flags + ilst)
      final metaBuilder = BytesBuilder();
      metaBuilder.add([0, 0, 0, 0]); // version & flags
      metaBuilder.add(ilstBytes);
      final metaBytes = _wrapBox('meta', metaBuilder.toBytes());

      // udta box
      final udtaBytes = _wrapBox('udta', metaBytes);

      // moov box
      final moovBytes = _wrapBox('moov', udtaBytes);

      final testFile = File('${tempDir.path}/test_tv_show.mp4');
      await testFile.writeAsBytes(moovBytes);

      const reader = EmbeddedMetadataReader();
      final result = await reader.readMp4Metadata(testFile);

      expect(result, isNotNull);
      expect(result!.inferredContentType, ContentType.tvShow);
      expect(result.mediaKind, 10);
      expect(result.showTitle, 'The Mandalorian');
      expect(result.seasonNumber, 2);
      expect(result.episodeNumber, 1);
      expect(result.title, 'Chapter 9: The Marshal');
      expect(
        result.description,
        'The Mandalorian searches for other Mandalorians.',
      );
      expect(result.hasTvMetadata, isTrue);
    });

    test('parses chpl chapters atom for audiobooks', () async {
      // Create chpl payload
      final chplBuilder = BytesBuilder();
      chplBuilder.add([0, 0, 0, 0]); // version & flags
      chplBuilder.add([0, 0, 0, 0]); // reserved
      chplBuilder.add([2]); // chapter count = 2

      // Chapter 1: start = 0, title = 'Prologue'
      chplBuilder.add([0, 0, 0, 0, 0, 0, 0, 0]);
      final title1 = utf8.encode('Prologue');
      chplBuilder.add([title1.length]);
      chplBuilder.add(title1);

      // Chapter 2: start = 60s in 100ns = 600,000,000
      const start2 = 600000000;
      chplBuilder.add([
        (start2 >> 56) & 0xFF,
        (start2 >> 48) & 0xFF,
        (start2 >> 40) & 0xFF,
        (start2 >> 32) & 0xFF,
        (start2 >> 24) & 0xFF,
        (start2 >> 16) & 0xFF,
        (start2 >> 8) & 0xFF,
        start2 & 0xFF,
      ]);
      final title2 = utf8.encode('Chapter 1');
      chplBuilder.add([title2.length]);
      chplBuilder.add(title2);

      final chplBytes = _wrapBox('chpl', chplBuilder.toBytes());

      // udta box
      final udtaBytes = _wrapBox('udta', chplBytes);
      // moov box
      final moovBytes = _wrapBox('moov', udtaBytes);

      final testFile = File('${tempDir.path}/test_audiobook.m4b');
      await testFile.writeAsBytes(moovBytes);

      const reader = EmbeddedMetadataReader();
      final result = await reader.readMp4Metadata(testFile);

      expect(result, isNotNull);
      expect(result!.chapters.length, 2);
      expect(result.chapters[0].title, 'Prologue');
      expect(result.chapters[0].startMs, 0);
      expect(result.chapters[1].title, 'Chapter 1');
      expect(result.chapters[1].startMs, 60000);
      expect(result.hasAudiobookMetadata, isTrue);
    });
  });
}
