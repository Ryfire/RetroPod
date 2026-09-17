import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:retropod/core/models/content/audiobook_models.dart';
import 'package:retropod/core/models/content/content_type.dart';

class EmbeddedMediaMetadata {
  final ContentType? inferredContentType;
  final int?
  mediaKind; // iTunes stik atom: 0=Movie, 2=Audiobook, 10/23=TV, 21=Podcast
  final String? title;
  final String? artistOrAuthor;
  final String? albumOrBook;
  final String? showTitle;
  final int? seasonNumber;
  final int? episodeNumber;
  final String? description;
  final DateTime? releaseDate;
  final Uint8List? coverArtBytes;
  final List<AudiobookChapter> chapters;

  const EmbeddedMediaMetadata({
    this.inferredContentType,
    this.mediaKind,
    this.title,
    this.artistOrAuthor,
    this.albumOrBook,
    this.showTitle,
    this.seasonNumber,
    this.episodeNumber,
    this.description,
    this.releaseDate,
    this.coverArtBytes,
    this.chapters = const [],
  });

  bool get hasTvMetadata =>
      showTitle != null ||
      (seasonNumber != null && episodeNumber != null) ||
      mediaKind == 10 ||
      mediaKind == 23;

  bool get hasAudiobookMetadata => mediaKind == 2 || chapters.isNotEmpty;

  bool get hasPodcastMetadata => mediaKind == 21;

  bool get hasMovieMetadata => mediaKind == 0 || mediaKind == 9;
}

class EmbeddedMetadataReader {
  const EmbeddedMetadataReader();

  /// Reads embedded metadata from an MP4/M4V/M4A/M4B file.
  Future<EmbeddedMediaMetadata?> readMp4Metadata(File file) async {
    if (!await file.exists()) return null;

    RandomAccessFile? raf;
    try {
      raf = await file.open();
      final fileLength = await raf.length();
      return _parseMp4Boxes(raf, fileLength, file.path);
    } catch (_) {
      return null;
    } finally {
      await raf?.close();
    }
  }

  EmbeddedMediaMetadata _parseMp4Boxes(
    RandomAccessFile raf,
    int fileLength,
    String filePath,
  ) {
    int offset = 0;
    int? mediaKind;
    String? title;
    String? artistOrAuthor;
    String? albumOrBook;
    String? showTitle;
    int? seasonNumber;
    int? episodeNumber;
    String? description;
    DateTime? releaseDate;
    Uint8List? coverArtBytes;
    final List<AudiobookChapter> chapters = [];

    while (offset + 8 <= fileLength) {
      raf.setPositionSync(offset);
      final header = raf.readSync(8);
      if (header.length < 8) break;

      int boxSize = _readUint32(header, 0);
      final boxType = String.fromCharCodes(header.sublist(4, 8));

      int headerSize = 8;
      if (boxSize == 1) {
        // Extended 64-bit size
        final extBytes = raf.readSync(8);
        if (extBytes.length < 8) break;
        boxSize = _readUint64(extBytes, 0);
        headerSize = 16;
      } else if (boxSize == 0) {
        boxSize = fileLength - offset;
      }

      if (boxSize < headerSize) break;

      if (boxType == 'moov') {
        _parseMoov(raf, offset + headerSize, offset + boxSize, (
          kind,
          t,
          art,
          alb,
          sh,
          sn,
          ep,
          desc,
          date,
          covr,
          chaps,
        ) {
          if (kind != null) mediaKind = kind;
          if (t != null) title = t;
          if (art != null) artistOrAuthor = art;
          if (alb != null) albumOrBook = alb;
          if (sh != null) showTitle = sh;
          if (sn != null) seasonNumber = sn;
          if (ep != null) episodeNumber = ep;
          if (desc != null) description = desc;
          if (date != null) releaseDate = date;
          if (covr != null) coverArtBytes = covr;
          if (chaps.isNotEmpty) chapters.addAll(chaps);
        }, filePath);
      }

      offset += boxSize;
    }

    ContentType? inferredType;
    if (mediaKind == 10 || mediaKind == 23 || showTitle != null) {
      inferredType = ContentType.tvShow;
    } else if (mediaKind == 0 || mediaKind == 9) {
      inferredType = ContentType.movie;
    } else if (mediaKind == 21) {
      inferredType = ContentType.podcast;
    } else if (mediaKind == 2 || chapters.isNotEmpty) {
      inferredType = ContentType.audiobook;
    }

    return EmbeddedMediaMetadata(
      inferredContentType: inferredType,
      mediaKind: mediaKind,
      title: title,
      artistOrAuthor: artistOrAuthor,
      albumOrBook: albumOrBook,
      showTitle: showTitle,
      seasonNumber: seasonNumber,
      episodeNumber: episodeNumber,
      description: description,
      releaseDate: releaseDate,
      coverArtBytes: coverArtBytes,
      chapters: chapters,
    );
  }

  void _parseMoov(
    RandomAccessFile raf,
    int start,
    int end,
    Function(
      int? mediaKind,
      String? title,
      String? artist,
      String? album,
      String? showTitle,
      int? seasonNumber,
      int? episodeNumber,
      String? description,
      DateTime? releaseDate,
      Uint8List? coverArt,
      List<AudiobookChapter> chapters,
    )
    onMetadataFound,
    String filePath,
  ) {
    int offset = start;
    while (offset + 8 <= end) {
      raf.setPositionSync(offset);
      final header = raf.readSync(8);
      if (header.length < 8) break;

      final boxSize = _readUint32(header, 0);
      final boxType = String.fromCharCodes(header.sublist(4, 8));
      if (boxSize < 8 || offset + boxSize > end) break;

      if (boxType == 'udta') {
        _parseUdta(
          raf,
          offset + 8,
          offset + boxSize,
          onMetadataFound,
          filePath,
        );
      }

      offset += boxSize;
    }
  }

  void _parseUdta(
    RandomAccessFile raf,
    int start,
    int end,
    Function(
      int? mediaKind,
      String? title,
      String? artist,
      String? album,
      String? showTitle,
      int? seasonNumber,
      int? episodeNumber,
      String? description,
      DateTime? releaseDate,
      Uint8List? coverArt,
      List<AudiobookChapter> chapters,
    )
    onMetadataFound,
    String filePath,
  ) {
    int offset = start;
    while (offset + 8 <= end) {
      raf.setPositionSync(offset);
      final header = raf.readSync(8);
      if (header.length < 8) break;

      final boxSize = _readUint32(header, 0);
      final boxType = String.fromCharCodes(header.sublist(4, 8));
      if (boxSize < 8 || offset + boxSize > end) break;

      if (boxType == 'meta') {
        // meta box starts with 4 bytes version + flags (FullBox)
        int metaStart = offset + 8;
        if (metaStart + 4 <= offset + boxSize) {
          metaStart += 4;
        }
        _parseMeta(raf, metaStart, offset + boxSize, onMetadataFound, filePath);
      } else if (boxType == 'chpl') {
        final chapters = _parseChpl(
          raf,
          offset + 8,
          offset + boxSize,
          filePath,
        );
        onMetadataFound(
          null,
          null,
          null,
          null,
          null,
          null,
          null,
          null,
          null,
          null,
          chapters,
        );
      }

      offset += boxSize;
    }
  }

  void _parseMeta(
    RandomAccessFile raf,
    int start,
    int end,
    Function(
      int? mediaKind,
      String? title,
      String? artist,
      String? album,
      String? showTitle,
      int? seasonNumber,
      int? episodeNumber,
      String? description,
      DateTime? releaseDate,
      Uint8List? coverArt,
      List<AudiobookChapter> chapters,
    )
    onMetadataFound,
    String filePath,
  ) {
    int offset = start;
    while (offset + 8 <= end) {
      raf.setPositionSync(offset);
      final header = raf.readSync(8);
      if (header.length < 8) break;

      final boxSize = _readUint32(header, 0);
      final boxType = String.fromCharCodes(header.sublist(4, 8));
      if (boxSize < 8 || offset + boxSize > end) break;

      if (boxType == 'ilst') {
        _parseIlst(
          raf,
          offset + 8,
          offset + boxSize,
          onMetadataFound,
          filePath,
        );
      }

      offset += boxSize;
    }
  }

  void _parseIlst(
    RandomAccessFile raf,
    int start,
    int end,
    Function(
      int? mediaKind,
      String? title,
      String? artist,
      String? album,
      String? showTitle,
      int? seasonNumber,
      int? episodeNumber,
      String? description,
      DateTime? releaseDate,
      Uint8List? coverArt,
      List<AudiobookChapter> chapters,
    )
    onMetadataFound,
    String filePath,
  ) {
    int offset = start;
    int? mediaKind;
    String? title;
    String? artistOrAuthor;
    String? albumOrBook;
    String? showTitle;
    int? seasonNumber;
    int? episodeNumber;
    String? description;
    DateTime? releaseDate;
    Uint8List? coverArtBytes;

    while (offset + 8 <= end) {
      raf.setPositionSync(offset);
      final header = raf.readSync(8);
      if (header.length < 8) break;

      final boxSize = _readUint32(header, 0);
      final boxType = String.fromCharCodes(header.sublist(4, 8));
      if (boxSize < 8 || offset + boxSize > end) break;

      final payload = _readIlstDataPayload(raf, offset + 8, offset + boxSize);
      if (payload != null) {
        switch (boxType) {
          case 'stik':
            if (payload.isNotEmpty) mediaKind = payload[0];
            break;
          case 'tvsh':
            showTitle = _decodeUtf8OrLatin(payload);
            break;
          case 'tvsn':
            seasonNumber = _readPayloadInt(payload);
            break;
          case 'tves':
            episodeNumber = _readPayloadInt(payload);
            break;
          case 'desc':
          case 'ldes':
          case '©des':
            description = _decodeUtf8OrLatin(payload);
            break;
          case '©nam':
            title = _decodeUtf8OrLatin(payload);
            break;
          case '©ART':
          case 'aART':
            artistOrAuthor = _decodeUtf8OrLatin(payload);
            break;
          case '©alb':
            albumOrBook = _decodeUtf8OrLatin(payload);
            break;
          case '©day':
            final dateStr = _decodeUtf8OrLatin(payload);
            releaseDate = DateTime.tryParse(dateStr);
            break;
          case 'covr':
            coverArtBytes = payload;
            break;
        }
      }

      offset += boxSize;
    }

    onMetadataFound(
      mediaKind,
      title,
      artistOrAuthor,
      albumOrBook,
      showTitle,
      seasonNumber,
      episodeNumber,
      description,
      releaseDate,
      coverArtBytes,
      const [],
    );
  }

  Uint8List? _readIlstDataPayload(RandomAccessFile raf, int start, int end) {
    int offset = start;
    while (offset + 8 <= end) {
      raf.setPositionSync(offset);
      final header = raf.readSync(8);
      if (header.length < 8) break;

      final size = _readUint32(header, 0);
      final type = String.fromCharCodes(header.sublist(4, 8));
      if (size < 8 || offset + size > end) break;

      if (type == 'data') {
        // data atom has 4 bytes type indicator + 4 bytes locale = 8 bytes prefix
        if (size > 16) {
          raf.setPositionSync(offset + 16);
          return raf.readSync(size - 16);
        }
      }

      offset += size;
    }
    return null;
  }

  List<AudiobookChapter> _parseChpl(
    RandomAccessFile raf,
    int start,
    int end,
    String filePath,
  ) {
    final length = end - start;
    if (length < 9) return const [];

    raf.setPositionSync(start);
    final bytes = raf.readSync(length);
    if (bytes.length < 9) return const [];

    // Layout: 4 bytes version/flags, 4 bytes reserved, 1 byte chapter count
    int offset = 8;
    int chapterCount = bytes[offset];
    offset += 1;

    // Alternative layout without 4 reserved bytes:
    if (chapterCount == 0 && bytes.length > 5) {
      chapterCount = bytes[4];
      offset = 5;
    }

    final List<AudiobookChapter> chapters = [];
    for (int i = 0; i < chapterCount; i++) {
      if (offset + 9 > bytes.length) break;

      final start100ns = _readUint64(bytes, offset);
      offset += 8;

      final titleLen = bytes[offset];
      offset += 1;

      if (offset + titleLen > bytes.length) break;
      final titleBytes = bytes.sublist(offset, offset + titleLen);
      offset += titleLen;

      final startMs = (start100ns / 10000).round();
      final title = _decodeUtf8OrLatin(titleBytes);

      chapters.add(
        AudiobookChapter(
          index: i + 1,
          title: title.isEmpty ? 'Chapter ${i + 1}' : title,
          startMs: startMs,
          filePath: filePath,
        ),
      );
    }

    return chapters;
  }

  static int _readPayloadInt(Uint8List payload) {
    if (payload.isEmpty) return 0;
    if (payload.length == 1) return payload[0];
    if (payload.length == 2) {
      return (payload[0] << 8) | payload[1];
    }
    if (payload.length >= 4) {
      return (payload[0] << 24) |
          (payload[1] << 16) |
          (payload[2] << 8) |
          payload[3];
    }
    return int.tryParse(_decodeUtf8OrLatin(payload)) ?? 0;
  }

  static int _readUint32(List<int> bytes, int offset) {
    return (bytes[offset] << 24) |
        (bytes[offset + 1] << 16) |
        (bytes[offset + 2] << 8) |
        bytes[offset + 3];
  }

  static int _readUint64(List<int> bytes, int offset) {
    final high = _readUint32(bytes, offset);
    final low = _readUint32(bytes, offset + 4);
    return (high << 32) | low;
  }

  static String _decodeUtf8OrLatin(Uint8List bytes) {
    try {
      return utf8.decode(bytes);
    } catch (_) {
      return latin1.decode(bytes);
    }
  }
}
