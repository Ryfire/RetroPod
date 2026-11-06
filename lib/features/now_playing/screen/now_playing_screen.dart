import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:just_audio/just_audio.dart';
import 'package:retropod/core/extensions/build_context_extensions.dart';
import 'package:retropod/core/extensions/go_router_extensions.dart';
import 'package:retropod/core/navigation/routes.dart';
import 'package:retropod/core/services/audio_player_service.dart';
import 'package:retropod/core/widgets/empty_state_widget.dart';
import 'package:retropod/features/device/models/device_action.dart';
import 'package:retropod/features/device/services/device_buttons_service_provider.dart';
import 'package:retropod/features/now_playing/provider/now_playing_details_provider.dart';
import 'package:retropod/features/now_playing/services/keep_screen_on_service.dart';
import 'package:retropod/features/now_playing/widgets/lyrics_view.dart';
import 'package:retropod/features/now_playing/widgets/now_playing_bottom_bar.dart';
import 'package:retropod/features/now_playing/widgets/now_playing_widget.dart';
import 'package:retropod/features/now_playing/widgets/photo_slideshow_view.dart';
import 'package:retropod/features/now_playing/widgets/rating_bar.dart';
import 'package:retropod/features/now_playing/widgets/scrubber_bar.dart';
import 'package:retropod/features/now_playing/widgets/shuffle_segmented_control.dart';
import 'package:retropod/features/now_playing/widgets/visualizer_view.dart';
import 'package:retropod/features/now_playing/widgets/volume_bar.dart';
import 'package:retropod/features/settings/controller/settings_preferences_controller.dart';
import 'package:retropod/features/settings/models/screensaver_type.dart';
import 'package:retropod/features/settings/models/settings_preferences_model.dart';
import 'package:retropod/features/settings/models/visualizer_idle_time.dart';
import 'package:retropod/features/settings/models/volume_mode.dart';
import 'package:retropod/features/status_bar/widgets/status_bar.dart';
import 'package:retropod/features/tutorial/controller/tutorial_controller.dart';
import 'package:volume_controller/volume_controller.dart';

enum _NowPlayingBottomBarPage {
  seekBar,
  scrubberBar,
  volumeBar,
  ratingBar,
  shuffleBar,
  lyrics,
}

class NowPlayingScreen extends ConsumerStatefulWidget {
  const NowPlayingScreen({super.key});

  @override
  ConsumerState createState() => _NowPlayingScreenState();
}

class _NowPlayingScreenState extends ConsumerState<NowPlayingScreen> {
  final PageController _bottomBarPageController = PageController();
  final ScrollController _lyricsScrollController = ScrollController();
  final _scrubber = ScrubberController();
  Timer? _longPressTimer;
  Timer? _barInactivityTimer;
  Timer? _visualizerIdleTimer;
  bool _visualizerActive = false;
  StreamSubscription<PlayerState>? _playerStateSubscription;
  bool _isShuffleEnabled = false;
  _NowPlayingBottomBarPage _bottomBarPage = _NowPlayingBottomBarPage.seekBar;
  int? _lastLyricsSongIndex;
  Future<void>? _progressReturnTransition;
  int? _progressReturnPage;
  int _activeInputs = 0;
  int _ratingAtOpen = 0;
  Future<double>? _volumeAtOpen;

  String get routeName => Routes.nowPlaying.name;

  Future<void> onSelectPressed() async {
    final String? lyrics = ref
        .read(nowPlayingDetailsProvider)
        .currentMetadata
        ?.lyrics;
    final bool hasLyrics = lyrics != null && lyrics.trim().isNotEmpty;

    if (_bottomBarPage == _NowPlayingBottomBarPage.seekBar) {
      await _bottomBarPageController.animateToPage(
        1,
        duration: const Duration(milliseconds: 300),
        curve: Curves.ease,
      );
      if (!mounted) return;
      setState(() {
        _bottomBarPage = _NowPlayingBottomBarPage.scrubberBar;
      });
    } else if (_bottomBarPage == _NowPlayingBottomBarPage.scrubberBar) {
      final changed = await _scrubber.commit();
      if (!mounted) return;
      if (changed) {
        await returnToProgressBar();
        return;
      }
      await _bottomBarPageController.animateToPage(
        2,
        duration: const Duration(milliseconds: 300),
        curve: Curves.ease,
      );
      if (!mounted) return;
      setState(() {
        _ratingAtOpen =
            ref.read(nowPlayingDetailsProvider).currentMetadata?.rating ?? 0;
        _bottomBarPage = _NowPlayingBottomBarPage.ratingBar;
      });
    } else if (_bottomBarPage == _NowPlayingBottomBarPage.ratingBar) {
      final rating =
          ref.read(nowPlayingDetailsProvider).currentMetadata?.rating ?? 0;
      if (rating != _ratingAtOpen) {
        await returnToProgressBar();
        return;
      }
      await _bottomBarPageController.animateToPage(
        3,
        duration: const Duration(milliseconds: 300),
        curve: Curves.ease,
      );
      if (!mounted) return;
      setState(() {
        _isShuffleEnabled = ref
            .read(nowPlayingDetailsProvider)
            .isShuffleEnabled;
        _bottomBarPage = _NowPlayingBottomBarPage.shuffleBar;
      });
    } else if (_bottomBarPage == _NowPlayingBottomBarPage.shuffleBar) {
      await ref
          .read(audioPlayerServiceProvider.notifier)
          .setShuffleMode(_isShuffleEnabled);
      if (hasLyrics) {
        await _bottomBarPageController.animateToPage(
          4,
          duration: const Duration(milliseconds: 300),
          curve: Curves.ease,
        );
        if (!mounted) return;
        setState(() {
          _bottomBarPage = _NowPlayingBottomBarPage.lyrics;
        });
      } else {
        await returnToProgressBar();
      }
    } else if (_bottomBarPage == _NowPlayingBottomBarPage.volumeBar) {
      final initial = await _volumeAtOpen;
      final current = await _readVolume();
      if (initial != null && (current - initial).abs() > 0.0001) {
        await returnToProgressBar();
      }
    } else if (_bottomBarPage == _NowPlayingBottomBarPage.lyrics) {
      await _bottomBarPageController.animateToPage(
        5,
        duration: const Duration(milliseconds: 300),
        curve: Curves.ease,
      );
      if (!mounted) return;
      _bottomBarPageController.jumpToPage(0);
      setState(() {
        _bottomBarPage = _NowPlayingBottomBarPage.seekBar;
      });
    }
  }

  void onSelectLongPress() {
    unawaited(context.pushNamed(Routes.nowPlayingMoreOptions.name));
  }

  Future<void> scrollLyrics(double offsetChange) async {
    if (!_lyricsScrollController.hasClients) {
      return;
    }

    final ScrollPosition position = _lyricsScrollController.position;
    final double targetOffset = (position.pixels + offsetChange).clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );

    if (targetOffset == position.pixels) {
      return;
    }

    await _lyricsScrollController.animateTo(
      targetOffset,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
  }

  Future<double> _readVolume() async {
    if (ref.read(settingsPreferencesControllerProvider).volumeMode ==
        VolumeMode.app) {
      return ref.read(audioPlayerProvider).volume;
    }
    return VolumeController.instance.getVolume();
  }

  Future<void> _adjustVolume({required bool increase}) async {
    await (_volumeAtOpen ??= _readVolume());
    if (!mounted) return;
    final settings = ref.read(settingsPreferencesControllerProvider.notifier);
    await Future.wait([
      showVolumeBar(),
      increase ? settings.increaseVolume() : settings.decreaseVolume(),
    ]);
  }

  Future<void> showVolumeBar() async {
    await _progressReturnTransition;
    if (!mounted || _bottomBarPage == _NowPlayingBottomBarPage.volumeBar) {
      return;
    }
    setState(() {
      _bottomBarPage = _NowPlayingBottomBarPage.volumeBar;
    });
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted || !_bottomBarPageController.hasClients) {
      return;
    }
    await _bottomBarPageController.animateToPage(
      1,
      duration: const Duration(milliseconds: 300),
      curve: Curves.ease,
    );
  }

  Future<void> returnToProgressBar() async {
    if (!mounted || !_bottomBarPageController.hasClients) {
      return;
    }
    if (_bottomBarPage == _NowPlayingBottomBarPage.shuffleBar) {
      await ref
          .read(audioPlayerServiceProvider.notifier)
          .setShuffleMode(_isShuffleEnabled);
      if (!mounted || !_bottomBarPageController.hasClients) {
        return;
      }
    }
    final nextPage = _bottomBarPageController.page!.round() + 1;
    setState(() {
      _progressReturnPage = nextPage;
    });
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted || !_bottomBarPageController.hasClients) {
      return;
    }
    await _bottomBarPageController.animateToPage(
      nextPage,
      duration: const Duration(milliseconds: 300),
      curve: Curves.ease,
    );
    if (!mounted || !_bottomBarPageController.hasClients) {
      return;
    }
    _bottomBarPageController.jumpToPage(0);
    setState(() {
      _bottomBarPage = _NowPlayingBottomBarPage.seekBar;
      _progressReturnPage = null;
      _volumeAtOpen = null;
    });
    await WidgetsBinding.instance.endOfFrame;
  }

  void restartBarInactivityTimer() {
    _barInactivityTimer?.cancel();
    if (!mounted ||
        _activeInputs > 0 ||
        _scrubber.isInteracting ||
        _progressReturnTransition != null ||
        _bottomBarPage == _NowPlayingBottomBarPage.seekBar ||
        _bottomBarPage == _NowPlayingBottomBarPage.lyrics) {
      return;
    }
    _barInactivityTimer = Timer(const Duration(seconds: 4), () {
      _progressReturnTransition = returnToProgressBar().whenComplete(() {
        _progressReturnTransition = null;
      });
    });
  }

  /// Raw touch handler: exits the screensaver immediately on any touch and
  /// re-arms both the bottom bar and screensaver idle timers.
  void _onPointerActivity() {
    _hideVisualizer();
    restartBarInactivityTimer();
    _restartVisualizerIdleTimer();
  }

  /// Restarts the screensaver countdown that swaps the whole Now Playing
  /// screen for the EQ visualizer after the configured idle time.
  void _restartVisualizerIdleTimer() {
    _visualizerIdleTimer?.cancel();
    final VisualizerIdleTime idleTime =
        ref.read(settingsPreferencesControllerProvider).visualizerIdleTime;
    final Duration? idleDuration = idleTime.duration;
    if (idleDuration == null) {
      _hideVisualizer();
      return;
    }
    _visualizerIdleTimer = Timer(idleDuration, () {
      if (!mounted) {
        return;
      }
      final bool isPlaying = ref.read(audioPlayerProvider).playing;
      if (!isPlaying) {
        return;
      }
      // Don't screensaver over the lyrics view; it only exists while the
      // user is actively reading.
      if (_bottomBarPage == _NowPlayingBottomBarPage.lyrics) {
        return;
      }
      setState(() {
        _visualizerActive = true;
      });
    });
  }

  void _hideVisualizer() {
    if (!_visualizerActive) {
      return;
    }
    setState(() {
      _visualizerActive = false;
    });
  }

  /// Keeps the device display awake while this screen is open and music is
  /// playing, when the Keep Screen Awake setting is enabled.
  Future<void> _updateKeepScreenAwake() async {
    final settings = ref.read(settingsPreferencesControllerProvider);
    final bool shouldStayAwake =
        settings.keepScreenAwake && ref.read(audioPlayerProvider).playing;
    if (shouldStayAwake == keepScreenOnService.isEnabled) {
      return;
    }
    if (shouldStayAwake) {
      await keepScreenOnService.enable();
    } else {
      await keepScreenOnService.disable();
    }
  }

  Future<void> handleUserInput(FutureOr<void> Function() action) async {
    _barInactivityTimer?.cancel();
    _visualizerIdleTimer?.cancel();
    _hideVisualizer();
    _activeInputs++;
    try {
      await _progressReturnTransition;
      if (mounted &&
          ModalRoute.of(context)?.isCurrent == true &&
          context.router.locationNamed == routeName) {
        await action();
      }
    } finally {
      _activeInputs--;
      restartBarInactivityTimer();
      _restartVisualizerIdleTimer();
    }
  }

  Future<void> rotateForward() async {
    if (_bottomBarPage == _NowPlayingBottomBarPage.scrubberBar) {
      _scrubber.step(1);
      return;
    } else if (_bottomBarPage == _NowPlayingBottomBarPage.shuffleBar) {
      setState(() {
        _isShuffleEnabled = true;
      });
      return;
    } else if (_bottomBarPage == _NowPlayingBottomBarPage.ratingBar) {
      await ref
          .read(nowPlayingDetailsProvider.notifier)
          .increaseCurrentMetadataRating();
      return;
    } else if (_bottomBarPage == _NowPlayingBottomBarPage.lyrics) {
      await scrollLyrics(60);
      return;
    }
    await _adjustVolume(increase: true);
  }

  Future<void> rotateBackward() async {
    if (_bottomBarPage == _NowPlayingBottomBarPage.scrubberBar) {
      _scrubber.step(-1);
      return;
    } else if (_bottomBarPage == _NowPlayingBottomBarPage.shuffleBar) {
      setState(() {
        _isShuffleEnabled = false;
      });
      return;
    } else if (_bottomBarPage == _NowPlayingBottomBarPage.ratingBar) {
      await ref
          .read(nowPlayingDetailsProvider.notifier)
          .decreaseCurrentMetadataRating();
      return;
    } else if (_bottomBarPage == _NowPlayingBottomBarPage.lyrics) {
      await scrollLyrics(-60);
      return;
    }
    await _adjustVolume(increase: false);
  }

  Future<void> seekForward() async {
    if (_bottomBarPage == _NowPlayingBottomBarPage.shuffleBar) {
      await rotateForward();
      return;
    }
    await ref.read(audioPlayerServiceProvider.notifier).nextSong();
  }

  Future<void> seekBackward() async {
    if (_bottomBarPage == _NowPlayingBottomBarPage.shuffleBar) {
      await rotateBackward();
      return;
    }
    await ref.read(audioPlayerServiceProvider.notifier).seekBackwards();
  }

  void seekForwardLongPress() {
    _longPressTimer?.cancel();
    // One seek fires immediately so holding feels responsive; the tick
    // period scales with the configured interval to keep the same scrub
    // velocity for every interval size.
    unawaited(_longPressSeekTick(1));
    _longPressTimer = Timer.periodic(_longPressTickPeriod(), (_) {
      unawaited(_longPressSeekTick(1));
    });
  }

  void seekBackwardLongPress() {
    _longPressTimer?.cancel();
    unawaited(_longPressSeekTick(-1));
    _longPressTimer = Timer.periodic(_longPressTickPeriod(), (_) {
      unawaited(_longPressSeekTick(-1));
    });
  }

  Duration _longPressTickPeriod() {
    final int stepSeconds = ref
        .read(settingsPreferencesControllerProvider)
        .seekInterval
        .seconds;
    return Duration(milliseconds: stepSeconds * 50);
  }

  Future<void> _longPressSeekTick(int direction) async {
    restartBarInactivityTimer();
    if (_bottomBarPage == _NowPlayingBottomBarPage.scrubberBar) {
      _scrubber.step(direction);
      return;
    }
    if (direction > 0) {
      await ref.read(audioPlayerServiceProvider.notifier).seekForward();
    } else {
      await ref.read(audioPlayerServiceProvider.notifier).seekBackward();
    }
  }

  void onLongPressEnd() {
    if (_longPressTimer?.isActive ?? false) {
      _longPressTimer?.cancel();
      ref.read(deviceButtonsServiceProvider.notifier).resetDeviceAction();
    }
  }

  void onMenuButtonPressed() {
    context.pop();
  }

  @override
  void initState() {
    super.initState();
    _playerStateSubscription = ref
        .read(audioPlayerProvider)
        .playerStateStream
        .listen(_onPlayerStateChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(tutorialControllerProvider.notifier).playNowPlayingTutorial();
      _restartVisualizerIdleTimer();
      unawaited(_updateKeepScreenAwake());
    });
  }

  /// Exits the screensaver and releases the wake lock whenever playback
  /// stops, and re-arms the screensaver when it resumes; covers external
  /// pauses like the sleep timer or a media notification.
  void _onPlayerStateChanged(PlayerState playerState) {
    if (!mounted) {
      return;
    }
    unawaited(_updateKeepScreenAwake());
    if (!playerState.playing) {
      _visualizerIdleTimer?.cancel();
      _hideVisualizer();
      return;
    }
    _restartVisualizerIdleTimer();
  }

  @override
  void dispose() {
    _barInactivityTimer?.cancel();
    _longPressTimer?.cancel();
    _visualizerIdleTimer?.cancel();
    unawaited(_playerStateSubscription?.cancel());
    if (keepScreenOnService.isEnabled) {
      unawaited(keepScreenOnService.disable());
    }
    _bottomBarPageController.dispose();
    _lyricsScrollController.dispose();
    super.dispose();
  }

  Future<void> deviceControlHandler(_, DeviceAction? newState) async {
    if (!mounted ||
        newState == null ||
        ModalRoute.of(context)?.isCurrent != true ||
        context.router.locationNamed != routeName) {
      return;
    }
    await handleUserInput(() async {
      switch (newState) {
        case DeviceAction.menu:
          onMenuButtonPressed();
          break;
        case DeviceAction.select:
          await onSelectPressed();
          break;
        case DeviceAction.selectLongPress:
          onSelectLongPress();
          break;
        case DeviceAction.rotateForward:
          await rotateForward();
          break;
        case DeviceAction.rotateBackward:
          await rotateBackward();
          break;
        case DeviceAction.seekForward:
          await seekForward();
          break;
        case DeviceAction.seekBackward:
          await seekBackward();
          break;
        case DeviceAction.seekForwardLongPress:
          seekForwardLongPress();
          break;
        case DeviceAction.seekBackwardLongPress:
          seekBackwardLongPress();
          break;
        case DeviceAction.playPause:
          break;
        case DeviceAction.longPressEnd:
          onLongPressEnd();
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final nowPlayingDetails = ref.watch(nowPlayingDetailsProvider);
    final String? lyrics = nowPlayingDetails.currentMetadata?.lyrics;
    final bool hasLyrics = lyrics != null && lyrics.trim().isNotEmpty;
    final int? currentLyricsSongIndex =
        nowPlayingDetails.currentMetadata?.originalSongIndex;

    if (_lastLyricsSongIndex != currentLyricsSongIndex) {
      _lastLyricsSongIndex = currentLyricsSongIndex;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_lyricsScrollController.hasClients) {
          return;
        }
        _lyricsScrollController.jumpTo(0);
      });
    }

    if (!hasLyrics &&
        _bottomBarPage == _NowPlayingBottomBarPage.lyrics &&
        _progressReturnTransition == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        if (_bottomBarPageController.hasClients) {
          _bottomBarPageController.jumpToPage(0);
        }
        setState(() {
          _bottomBarPage = _NowPlayingBottomBarPage.seekBar;
        });
      });
    }

    ref.listen(deviceButtonsServiceProvider, deviceControlHandler);
    ref.listen(
      settingsPreferencesControllerProvider,
      (SettingsPreferencesModel? previous, SettingsPreferencesModel next) {
        if (previous != null &&
            previous.keepScreenAwake != next.keepScreenAwake) {
          unawaited(_updateKeepScreenAwake());
        }
      },
    );

    if (nowPlayingDetails.metadataList.isEmpty) {
      return CupertinoPageScaffold(
        child: Column(
          children: [
            StatusBar(title: Routes.nowPlaying.title(context)),
            Expanded(
              child: EmptyStateWidget(
                emptyDescription: context.localization.noMusicFilesFound,
              ),
            ),
          ],
        ),
      );
    }

    final bottomBarPages = <Widget>[
      ...(_bottomBarPage == _NowPlayingBottomBarPage.volumeBar
          ? const [NowPlayingBottomBar(), VolumeBar(), NowPlayingBottomBar()]
          : [
              const NowPlayingBottomBar(),
              NowPlayingBottomBar(
                showScrubber: true,
                scrubberController: _scrubber,
                scrubberActive:
                    _bottomBarPage == _NowPlayingBottomBarPage.scrubberBar,
                onScrubChanged: () {
                  setState(() {});
                  restartBarInactivityTimer();
                },
              ),
              RatingBar(
                currentRating: nowPlayingDetails.currentMetadata?.rating ?? 0,
                onRatingClicked: (val) async {
                  await ref
                      .read(nowPlayingDetailsProvider.notifier)
                      .setCurrentMetadataRating(val ?? 0);
                },
              ),
              ShuffleSegmentedControl(
                isShuffleEnabled: _isShuffleEnabled,
                onValueChanged: (value) {
                  setState(() {
                    _isShuffleEnabled = value ?? _isShuffleEnabled;
                  });
                },
              ),
              if (hasLyrics) const SizedBox(height: 10),
              const NowPlayingBottomBar(),
            ]),
    ];
    final returnPage = _progressReturnPage;
    if (returnPage != null) {
      while (bottomBarPages.length <= returnPage) {
        bottomBarPages.add(const NowPlayingBottomBar());
      }
      bottomBarPages[returnPage] = const NowPlayingBottomBar();
    }

    final ScreensaverType screensaverType =
        ref.watch(settingsPreferencesControllerProvider).screensaverType;
    final Widget contentBelowStatusBar = _visualizerActive
        ? (screensaverType == ScreensaverType.photoSlideshow
              ? const PhotoSlideshowView(
                  key: ValueKey('now-playing-slideshow'),
                )
              : const VisualizerView(
                  key: ValueKey('now-playing-visualizer'),
                ))
        : Column(
            key: const ValueKey('now-playing-content'),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (nowPlayingDetails.isShuffleEnabled)
                    Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: Icon(
                        CupertinoIcons.shuffle,
                        size: 20,
                        color: context.appPrimaryTextColor,
                      ),
                    ),
                  if (nowPlayingDetails.loopMode != LoopMode.off)
                    Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: Icon(
                        (nowPlayingDetails.loopMode == LoopMode.all)
                            ? CupertinoIcons.repeat
                            : CupertinoIcons.repeat_1,
                        size: 20,
                        color: context.appPrimaryTextColor,
                      ),
                    ),
                  if (!nowPlayingDetails.isShuffleEnabled &&
                      nowPlayingDetails.loopMode == LoopMode.off)
                    const SizedBox(height: 20),
                ],
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => unawaited(handleUserInput(onSelectPressed)),
                  onLongPress: () =>
                      unawaited(handleUserInput(onSelectLongPress)),
                  child: Padding(
                    padding: const EdgeInsets.only(left: 10),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child:
                          (_bottomBarPage == _NowPlayingBottomBarPage.lyrics &&
                              hasLyrics)
                          ? LyricsView(
                              key: ValueKey(
                                'lyrics-view-${nowPlayingDetails.currentMetadata?.originalSongIndex ?? 0}',
                              ),
                              lyrics: lyrics,
                              scrollController: _lyricsScrollController,
                            )
                          : NowPlayingWidget(
                              key: const ValueKey('now-playing-view'),
                              nowPlayingDetails: nowPlayingDetails,
                            ),
                    ),
                  ),
                ),
              ),
              SizedBox(
                height: 30,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: PageView(
                    controller: _bottomBarPageController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: bottomBarPages,
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
          );

    return Listener(
      onPointerDown: (_) => _onPointerActivity(),
      onPointerMove: (_) => _onPointerActivity(),
      onPointerUp: (_) => _onPointerActivity(),
      onPointerSignal: (_) => _onPointerActivity(),
      child: CupertinoPageScaffold(
        child: Column(
          children: [
            StatusBar(title: Routes.nowPlaying.title(context)),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: contentBelowStatusBar,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
