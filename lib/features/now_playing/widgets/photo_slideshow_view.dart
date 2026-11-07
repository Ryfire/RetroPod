import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:retropod/core/extensions/build_context_extensions.dart';
import 'package:retropod/features/media/models/media_file_model.dart';
import 'package:retropod/features/media/services/media_files_service.dart';
import 'package:retropod/features/now_playing/widgets/visualizer_view.dart';
import 'package:retropod/features/settings/controller/settings_preferences_controller.dart';
import 'package:retropod/features/settings/models/settings_preferences_model.dart';

/// How long the incoming photo takes to dissolve over the current one.
const Duration _kDissolveDuration = Duration(seconds: 1);

/// Full-screen photo slideshow for the Now Playing screensaver. Plays the
/// photos found by the media scan (minus the folders disabled in the
/// Slideshow Folders setting) in a shuffled, looping order. Each advance
/// dissolves the next photo over the current one, so the screen never
/// hard-cuts between photos. Falls back to the EQ visualizer while the
/// scan is loading and when no enabled folder has photos.
class PhotoSlideshowView extends ConsumerStatefulWidget {
  const PhotoSlideshowView({super.key});

  @override
  ConsumerState<PhotoSlideshowView> createState() =>
      _PhotoSlideshowViewState();
}

class _PhotoSlideshowViewState extends ConsumerState<PhotoSlideshowView>
    with SingleTickerProviderStateMixin {
  Timer? _advanceTimer;
  late final AnimationController _dissolveController;
  List<MediaFileModel> _photos = const <MediaFileModel>[];
  int _currentIndex = 0;
  int? _incomingIndex;

  @override
  void initState() {
    super.initState();
    _dissolveController = AnimationController(
      vsync: this,
      duration: _kDissolveDuration,
    );
    _scheduleNextAdvance();
  }

  @override
  void dispose() {
    _advanceTimer?.cancel();
    _dissolveController.dispose();
    super.dispose();
  }

  /// One-shot timer armed when each dissolve starts, so the configured
  /// slideshow duration is the period between photo changes. Re-arming on
  /// every advance means duration setting edits apply without restarting
  /// the screensaver.
  void _scheduleNextAdvance() {
    _advanceTimer?.cancel();
    final Duration duration = ref
        .read(settingsPreferencesControllerProvider)
        .slideshowDuration
        .duration;
    _advanceTimer = Timer(
      duration,
      () => unawaited(_advanceToNextPhoto()),
    );
  }

  Future<void> _advanceToNextPhoto() async {
    if (!mounted) {
      return;
    }
    if (_photos.length < 2 || _dissolveController.isAnimating) {
      _scheduleNextAdvance();
      return;
    }
    // Find the next photo that actually decodes; broken files are skipped
    // instead of dissolving into the error placeholder.
    int nextIndex = _currentIndex;
    bool foundNext = false;
    for (int attempt = 0; attempt < _photos.length - 1; attempt++) {
      nextIndex = (nextIndex + 1) % _photos.length;
      if (await _precachePhoto(_photos[nextIndex])) {
        foundNext = true;
        break;
      }
      if (!mounted) {
        return;
      }
    }
    if (!mounted) {
      return;
    }
    if (!foundNext) {
      _scheduleNextAdvance();
      return;
    }
    unawaited(_startDissolve(nextIndex));
    _scheduleNextAdvance();
  }

  /// Dissolves the photo at [nextIndex] over the current one. Once the
  /// fade finishes, the new photo becomes the fully visible base layer.
  Future<void> _startDissolve(int nextIndex) async {
    setState(() => _incomingIndex = nextIndex);
    try {
      await _dissolveController.forward(from: 0).orCancel;
    } on TickerCanceled {
      // Disposed mid-dissolve; nothing left to clean up.
      return;
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _currentIndex = _incomingIndex ?? _currentIndex;
      _incomingIndex = null;
    });
  }

  /// All scanned photos from folders still enabled for the slideshow,
  /// deduplicated by path so overlapping scan directories cannot show
  /// the same photo twice.
  List<MediaFileModel> _enabledPhotos(SettingsPreferencesModel settings) {
    final List<MediaFileModel> mediaFiles =
        ref.watch(mediaFilesServiceProvider).value ??
        const <MediaFileModel>[];
    final Set<String> seenPaths = <String>{};
    final List<MediaFileModel> photos = <MediaFileModel>[];
    for (final MediaFileModel mediaFile in mediaFiles) {
      if (mediaFile.type != MediaFileType.photo) {
        continue;
      }
      final bool isExcluded = settings.excludedSlideshowFolders.contains(
        p.dirname(mediaFile.path),
      );
      if (isExcluded || !seenPaths.add(mediaFile.path)) {
        continue;
      }
      photos.add(mediaFile);
    }
    return photos;
  }

  /// Screen-width decode target so full-resolution camera photos never
  /// balloon memory.
  int get _cacheWidth {
    final double devicePixelRatio = MediaQuery.devicePixelRatioOf(context);
    return (context.screenSize.width * devicePixelRatio).round();
  }

  /// Warms the photo into the image cache before its dissolve starts.
  /// Returns false when the file cannot be decoded.
  Future<bool> _precachePhoto(MediaFileModel photo) async {
    bool didError = false;
    await precacheImage(
      _imageProviderFor(photo, _cacheWidth),
      context,
      onError: (Object exception, StackTrace? stackTrace) {
        didError = true;
      },
    );
    return !didError;
  }

  @override
  Widget build(BuildContext context) {
    final SettingsPreferencesModel settings =
        ref.watch(settingsPreferencesControllerProvider);
    final List<MediaFileModel> photos = _enabledPhotos(settings);
    if (photos.isEmpty) {
      // Still scanning, or every folder is disabled: fall back to the EQ
      // visualizer screensaver.
      _photos = const <MediaFileModel>[];
      _incomingIndex = null;
      return const VisualizerView(
        key: ValueKey('slideshow-visualizer-fallback'),
      );
    }
    if (photos.length != _photos.length) {
      // First frame with data, or a rescan/folder toggle changed the set.
      _photos = List<MediaFileModel>.of(photos)..shuffle();
      _currentIndex = 0;
      _incomingIndex = null;
    }
    final int baseIndex = _currentIndex.clamp(0, _photos.length - 1);
    final MediaFileModel basePhoto = _photos[baseIndex];
    final int? incomingIndex = (_incomingIndex != null &&
            _incomingIndex! < _photos.length)
        ? _incomingIndex
        : null;
    final int cacheWidth = _cacheWidth;
    // Always black, independent of the theme: letterboxed areas around
    // photos stay true black like a photo frame, regardless of the screen
    // background color.
    return ColoredBox(
      color: CupertinoColors.black,
      child: SizedBox.expand(
        child: Stack(
          fit: StackFit.expand,
          children: [
            _SlideshowPhoto(photo: basePhoto, cacheWidth: cacheWidth),
            if (incomingIndex != null)
              FadeTransition(
                opacity: _dissolveController,
                child: _SlideshowPhoto(
                  photo: _photos[incomingIndex],
                  cacheWidth: cacheWidth,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// One slideshow photo, decoded at screen resolution.
class _SlideshowPhoto extends StatelessWidget {
  const _SlideshowPhoto({required this.photo, required this.cacheWidth});

  final MediaFileModel photo;
  final int cacheWidth;

  @override
  Widget build(BuildContext context) {
    return Image(
      image: _imageProviderFor(photo, cacheWidth),
      width: double.infinity,
      height: double.infinity,
      fit: BoxFit.contain,
      errorBuilder: (_, _, _) => const Center(
        child: Icon(
          CupertinoIcons.photo,
          size: 48,
          color: CupertinoColors.systemGrey,
        ),
      ),
    );
  }
}

/// The downscaled provider both the display and the precache use, so a
/// warmed photo is always an exact cache hit when its dissolve starts.
ImageProvider _imageProviderFor(MediaFileModel photo, int cacheWidth) {
  if (photo.isRemote) {
    return NetworkImage(photo.path);
  }
  return ResizeImage(FileImage(File(photo.path)), width: cacheWidth);
}
