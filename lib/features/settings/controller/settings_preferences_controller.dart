import 'dart:async';
import 'dart:io' as io;

import 'package:flutter/cupertino.dart' hide RepeatMode;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:just_audio/just_audio.dart';
import 'package:retropod/core/constants/constants.dart';
import 'package:retropod/core/models/music_metadata.dart';
import 'package:retropod/core/navigation/routes.dart';
import 'package:retropod/core/services/audio_files_service.dart';
import 'package:retropod/core/services/audio_player_service.dart';
import 'package:retropod/core/utils/rating_snapshot.dart';
import 'package:retropod/features/app_startup/controllers/splash_controller.dart';
import 'package:retropod/features/music/playlist/models/playlist_model.dart';
import 'package:retropod/features/notes/services/notes_service.dart';
import 'package:retropod/features/settings/models/app_theme.dart';
import 'package:retropod/features/settings/models/click_wheel_acceleration.dart';
import 'package:retropod/features/settings/models/click_wheel_size.dart';
import 'package:retropod/features/settings/models/click_wheel_sound_choice.dart';
import 'package:retropod/features/settings/models/click_wheel_speed.dart';
import 'package:retropod/features/settings/models/click_wheel_volume_level.dart';
import 'package:retropod/features/settings/models/device_color.dart';
import 'package:retropod/features/settings/models/device_skin.dart';
import 'package:retropod/features/settings/models/note_font_color.dart';
import 'package:retropod/features/settings/models/repeat_mode.dart';
import 'package:retropod/features/settings/models/screen_color.dart';
import 'package:retropod/features/settings/models/seek_interval.dart';
import 'package:retropod/features/settings/models/settings_preferences_model.dart';
import 'package:retropod/features/settings/models/sleep_timer_action.dart';
import 'package:retropod/features/settings/models/status_bar_clock_format.dart';
import 'package:retropod/features/settings/models/volume_mode.dart';
import 'package:retropod/features/settings/repository/settings_preferences_repository.dart';
import 'package:retropod/features/tutorial/controller/tutorial_controller.dart';
import 'package:universal_html/html.dart';
import 'package:volume_controller/volume_controller.dart';

final settingsPreferencesControllerProvider =
    NotifierProvider<
      SettingsPreferencesControllerNotifier,
      SettingsPreferencesModel
    >(SettingsPreferencesControllerNotifier.new);

class SettingsPreferencesControllerNotifier
    extends Notifier<SettingsPreferencesModel> {
  SettingsPreferencesControllerNotifier() : super();

  @override
  SettingsPreferencesModel build() {
    final settingsPreferencesRepository = ref.read(
      settingsPreferencesRepositoryProvider,
    );
    return SettingsPreferencesModel(
      languageLocaleCode: settingsPreferencesRepository.getLanguageLocaleCode(),
      deviceColor: DeviceColor.fromName(
        settingsPreferencesRepository.getDeviceColor(),
      ),
      clickWheelSize: ClickWheelSize.values.byName(
        settingsPreferencesRepository.getClickWheelSize(),
      ),
      clickWheelSpeed: ClickWheelSpeed.fromName(
        settingsPreferencesRepository.getClickWheelSpeed(),
      ),
      clickWheelAcceleration: ClickWheelAcceleration.fromName(
        settingsPreferencesRepository.getClickWheelAcceleration(),
      ),
      isTouchScreenEnabled: settingsPreferencesRepository
          .getTouchScreenEnabled(),
      repeatMode: RepeatMode.values.byName(
        settingsPreferencesRepository.getRepeatMode(),
      ),
      vibrate: settingsPreferencesRepository.getVibrate(),
      clickWheelSound: settingsPreferencesRepository.getClickWheelSound(),
      clickWheelSoundChoice: ClickWheelSoundChoice.fromName(
        settingsPreferencesRepository.getClickWheelSoundChoice(),
      ),
      clickWheelVolumeLevel: ClickWheelVolumeLevel.fromName(
        settingsPreferencesRepository.getClickWheelVolumeLevel(),
      ),
      volumeMode: VolumeMode.values.byName(
        settingsPreferencesRepository.getVolumeMode(),
      ),
      splitScreenEnabled: settingsPreferencesRepository.getSplitScreenEnabled(),
      immersiveMode: settingsPreferencesRepository.getImmersiveMode(),
      appTheme: AppTheme.fromName(settingsPreferencesRepository.getAppTheme()),
      deviceSkin: DeviceSkin.fromName(
        settingsPreferencesRepository.getDeviceSkin(),
      ),
      noteFontColor: NoteFontColor.fromName(
        settingsPreferencesRepository.getNoteFontColor(),
      ),
      noteFontSize: settingsPreferencesRepository.getNoteFontSize(),
      autoSaveNoteReadingPosition: settingsPreferencesRepository
          .getAutoSaveNoteReadingPosition(),
      noteReaderHideStatusBar: settingsPreferencesRepository
          .getNoteReaderHideStatusBar(),
      seekInterval: SeekInterval.fromName(
        settingsPreferencesRepository.getSeekInterval(),
      ),
      sleepTimerAction: SleepTimerAction.fromName(
        settingsPreferencesRepository.getSleepTimerAction(),
      ),
      showStatusBarClock: settingsPreferencesRepository.getShowStatusBarClock(),
      statusBarClockFormat: StatusBarClockFormat.fromName(
        settingsPreferencesRepository.getStatusBarClockFormat(),
      ),
      screenBackgroundColor: ScreenColor.fromName(
        settingsPreferencesRepository.getScreenBackgroundColor(),
      ),
      fontColor: ScreenColor.fromName(
        settingsPreferencesRepository.getFontColor(),
      ),
      highlightColor: ScreenColor.fromName(
        settingsPreferencesRepository.getHighlightColor(),
      ),
    );
  }

  Future<void> setSystemUiMode() async {
    if (kIsWeb) {
      if (state.immersiveMode) {
        // ignore: unawaited_futures
        document.documentElement?.requestFullscreen();
      } else {
        document.exitFullscreen();
      }
    } else if (io.Platform.isAndroid || io.Platform.isIOS) {
      if (state.immersiveMode) {
        await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      } else {
        await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      }
    }
  }

  void setAudioSource({required bool isOnlineAudioSource}) {
    if (isOnlineAudioSource) {
      state = state.copyWith(fetchOnlineMusic: true);
    } else {
      state = state.copyWith(fetchOnlineMusic: false);
    }
  }

  Future<void> showAppTutorial() async {
    await ref.read(tutorialControllerProvider.notifier).resetTutorials();
    ref.read(routerProvider).goNamed(Routes.menu.name);
    Future.delayed(const Duration(milliseconds: 500), () {
      ref.read(tutorialControllerProvider.notifier).playMenuTutorial();
    });
  }

  Future<void> setInitialRepeatMode() async {
    switch (state.repeatMode) {
      case RepeatMode.off:
        await ref
            .read(audioPlayerServiceProvider.notifier)
            .setLoopMode(LoopMode.off);
        break;
      case RepeatMode.one:
        // in case app starts with repeat mode one, set the loop mode to all
        await ref
            .read(settingsPreferencesRepositoryProvider)
            .setRepeatMode(repeatModeName: RepeatMode.all.name);
        state = state.copyWith(repeatMode: RepeatMode.all);
      case RepeatMode.all:
        await ref
            .read(audioPlayerServiceProvider.notifier)
            .setLoopMode(LoopMode.all);
        break;
    }
  }

  Future<void> setLanguage(Locale locale) async {
    state = state.copyWith(languageLocaleCode: locale.languageCode);
    await ref
        .read(settingsPreferencesRepositoryProvider)
        .setLanguageLocaleCode(languageLocaleCode: locale.languageCode);
  }

  Future<void> setDeviceColor(DeviceColor deviceColor) async {
    if (state.deviceColor == deviceColor) {
      return;
    }
    state = state.copyWith(deviceColor: deviceColor);
    await ref
        .read(settingsPreferencesRepositoryProvider)
        .setDeviceColor(deviceColorName: deviceColor.name);
  }

  Future<void> setSkin(DeviceSkin skin) async {
    if (state.deviceSkin == skin) return;
    state = state.copyWith(deviceSkin: skin);
    await ref
        .read(settingsPreferencesRepositoryProvider)
        .setDeviceSkin(deviceSkinName: skin.name);
  }

  Future<void> setNoteFontColor(NoteFontColor noteFontColor) async {
    if (state.noteFontColor == noteFontColor) {
      return;
    }
    state = state.copyWith(noteFontColor: noteFontColor);
    await ref
        .read(settingsPreferencesRepositoryProvider)
        .setNoteFontColor(noteFontColorName: noteFontColor.name);
  }

  /// Changing the global note font size resets every note back to it by
  /// clearing all saved per-note font sizes.
  Future<void> setNoteFontSize(int noteFontSize) async {
    final int clamped = noteFontSize.clamp(
      Constants.minNoteFontSize,
      Constants.maxNoteFontSize,
    );
    if (state.noteFontSize == clamped) {
      return;
    }
    state = state.copyWith(noteFontSize: clamped);
    await ref
        .read(settingsPreferencesRepositoryProvider)
        .setNoteFontSize(noteFontSize: clamped);
    await ref.read(notesServiceProvider.notifier).clearAllFontSizes();
  }

  Future<void> toggleAutoSaveNoteReadingPosition() async {
    state = state.copyWith(
      autoSaveNoteReadingPosition: !state.autoSaveNoteReadingPosition,
    );
    await ref
        .read(settingsPreferencesRepositoryProvider)
        .setAutoSaveNoteReadingPosition(
          isAutoSaveNoteReadingPositionEnabled:
              state.autoSaveNoteReadingPosition,
        );
  }

  Future<void> toggleNoteReaderHideStatusBar() async {
    state = state.copyWith(
      noteReaderHideStatusBar: !state.noteReaderHideStatusBar,
    );
    await ref
        .read(settingsPreferencesRepositoryProvider)
        .setNoteReaderHideStatusBar(
          isNoteReaderHideStatusBarEnabled: state.noteReaderHideStatusBar,
        );
  }

  Future<void> cycleSeekInterval() async {
    final int nextIndex =
        (state.seekInterval.index + 1) % SeekInterval.values.length;
    final SeekInterval nextInterval = SeekInterval.values[nextIndex];
    state = state.copyWith(seekInterval: nextInterval);
    await ref
        .read(settingsPreferencesRepositoryProvider)
        .setSeekInterval(seekIntervalName: nextInterval.name);
  }

  Future<void> cycleSleepTimerAction() async {
    final int nextIndex =
        (state.sleepTimerAction.index + 1) % SleepTimerAction.values.length;
    final SleepTimerAction nextAction = SleepTimerAction.values[nextIndex];
    state = state.copyWith(sleepTimerAction: nextAction);
    await ref
        .read(settingsPreferencesRepositoryProvider)
        .setSleepTimerAction(sleepTimerActionName: nextAction.name);
  }

  Future<void> toggleShowStatusBarClock() async {
    state = state.copyWith(showStatusBarClock: !state.showStatusBarClock);
    await ref
        .read(settingsPreferencesRepositoryProvider)
        .setShowStatusBarClock(
          isShowStatusBarClockEnabled: state.showStatusBarClock,
        );
  }

  Future<void> cycleStatusBarClockFormat() async {
    final int nextIndex =
        (state.statusBarClockFormat.index + 1) %
        StatusBarClockFormat.values.length;
    final StatusBarClockFormat nextFormat =
        StatusBarClockFormat.values[nextIndex];
    state = state.copyWith(statusBarClockFormat: nextFormat);
    await ref
        .read(settingsPreferencesRepositoryProvider)
        .setStatusBarClockFormat(statusBarClockFormatName: nextFormat.name);
  }

  Future<void> setScreenBackgroundColor(ScreenColor screenColor) async {
    if (state.screenBackgroundColor == screenColor) {
      return;
    }
    state = state.copyWith(screenBackgroundColor: screenColor);
    await ref
        .read(settingsPreferencesRepositoryProvider)
        .setScreenBackgroundColor(screenBackgroundColorName: screenColor.name);
  }

  Future<void> setFontColor(ScreenColor fontColor) async {
    if (state.fontColor == fontColor) {
      return;
    }
    state = state.copyWith(fontColor: fontColor);
    await ref
        .read(settingsPreferencesRepositoryProvider)
        .setFontColor(fontColorName: fontColor.name);
  }

  Future<void> setHighlightColor(ScreenColor highlightColor) async {
    if (state.highlightColor == highlightColor) {
      return;
    }
    state = state.copyWith(highlightColor: highlightColor);
    await ref
        .read(settingsPreferencesRepositoryProvider)
        .setHighlightColor(highlightColorName: highlightColor.name);
  }

  /// Clears the Screen Background, Font Color and Highlight Color pins in
  /// one tap, returning all three to the theme defaults without touching
  /// any other preference such as the click wheel settings.
  Future<void> resetScreenColors() async {
    await ref
        .read(settingsPreferencesRepositoryProvider)
        .setScreenBackgroundColor(
          screenBackgroundColorName: ScreenColor.theme.name,
        );
    await ref
        .read(settingsPreferencesRepositoryProvider)
        .setFontColor(fontColorName: ScreenColor.theme.name);
    await ref
        .read(settingsPreferencesRepositoryProvider)
        .setHighlightColor(highlightColorName: ScreenColor.theme.name);
    state = state.copyWith(
      screenBackgroundColor: ScreenColor.theme,
      fontColor: ScreenColor.theme,
      highlightColor: ScreenColor.theme,
    );
  }

  Future<void> toggleClickWheelSize() async {
    switch (state.clickWheelSize) {
      case ClickWheelSize.small:
        await ref
            .read(settingsPreferencesRepositoryProvider)
            .setClickWheelSize(clickWheelSizeName: ClickWheelSize.medium.name);
        state = state.copyWith(clickWheelSize: ClickWheelSize.medium);
        break;
      case ClickWheelSize.medium:
        await ref
            .read(settingsPreferencesRepositoryProvider)
            .setClickWheelSize(clickWheelSizeName: ClickWheelSize.large.name);
        state = state.copyWith(clickWheelSize: ClickWheelSize.large);
        break;
      case ClickWheelSize.large:
        await ref
            .read(settingsPreferencesRepositoryProvider)
            .setClickWheelSize(clickWheelSizeName: ClickWheelSize.small.name);
        state = state.copyWith(clickWheelSize: ClickWheelSize.small);
        break;
    }
  }

  Future<void> toggleClickWheelSpeed() async {
    final int nextIndex =
        (state.clickWheelSpeed.index + 1) % ClickWheelSpeed.values.length;
    final ClickWheelSpeed nextSpeed = ClickWheelSpeed.values[nextIndex];
    await ref
        .read(settingsPreferencesRepositoryProvider)
        .setClickWheelSpeed(clickWheelSpeedName: nextSpeed.name);
    state = state.copyWith(clickWheelSpeed: nextSpeed);
  }

  Future<void> toggleClickWheelAcceleration() async {
    final int nextIndex =
        (state.clickWheelAcceleration.index + 1) %
        ClickWheelAcceleration.values.length;
    final ClickWheelAcceleration nextAcceleration =
        ClickWheelAcceleration.values[nextIndex];
    await ref
        .read(settingsPreferencesRepositoryProvider)
        .setClickWheelAcceleration(
          clickWheelAccelerationName: nextAcceleration.name,
        );
    state = state.copyWith(clickWheelAcceleration: nextAcceleration);
  }

  Future<void> toggleTouchScreen() async {
    state = state.copyWith(isTouchScreenEnabled: !state.isTouchScreenEnabled);

    await ref
        .read(settingsPreferencesRepositoryProvider)
        .setTouchScreenEnabled(
          isTouchScreenEnabled: state.isTouchScreenEnabled,
        );
  }

  Future<void> toggleRepeatMode() async {
    switch (state.repeatMode) {
      case RepeatMode.off:
        state = state.copyWith(repeatMode: RepeatMode.one);
        await ref
            .read(settingsPreferencesRepositoryProvider)
            .setRepeatMode(repeatModeName: RepeatMode.one.name);
        break;
      case RepeatMode.one:
        state = state.copyWith(repeatMode: RepeatMode.all);
        await ref
            .read(settingsPreferencesRepositoryProvider)
            .setRepeatMode(repeatModeName: RepeatMode.all.name);
        break;
      case RepeatMode.all:
        state = state.copyWith(repeatMode: RepeatMode.off);
        await ref
            .read(settingsPreferencesRepositoryProvider)
            .setRepeatMode(repeatModeName: RepeatMode.off.name);
        break;
    }
    await ref
        .read(audioPlayerServiceProvider.notifier)
        .setLoopMode(state.repeatMode.toLoopMode());
  }

  Future<void> toggleVibrate() async {
    state = state.copyWith(vibrate: !state.vibrate);
    await ref
        .read(settingsPreferencesRepositoryProvider)
        .setVibrate(isVibrateEnabled: state.vibrate);
  }

  Future<void> toggleClickWheelSound() async {
    state = state.copyWith(clickWheelSound: !state.clickWheelSound);

    await ref
        .read(settingsPreferencesRepositoryProvider)
        .setClickWheelSound(isClickWheelSoundEnabled: state.clickWheelSound);
  }

  Future<void> cycleClickWheelSoundChoice() async {
    final int nextIndex =
        (state.clickWheelSoundChoice.index + 1) %
        ClickWheelSoundChoice.values.length;
    final ClickWheelSoundChoice nextChoice =
        ClickWheelSoundChoice.values[nextIndex];
    state = state.copyWith(clickWheelSoundChoice: nextChoice);

    await ref
        .read(settingsPreferencesRepositoryProvider)
        .setClickWheelSoundChoice(clickWheelSoundChoiceName: nextChoice.name);
  }

  Future<void> cycleClickWheelVolumeLevel() async {
    final int nextIndex =
        (state.clickWheelVolumeLevel.index + 1) %
        ClickWheelVolumeLevel.values.length;
    final ClickWheelVolumeLevel nextLevel =
        ClickWheelVolumeLevel.values[nextIndex];
    state = state.copyWith(clickWheelVolumeLevel: nextLevel);

    await ref
        .read(settingsPreferencesRepositoryProvider)
        .setClickWheelVolumeLevel(clickWheelVolumeLevelName: nextLevel.name);
  }

  Future<void> toggleVolumeMode() async {
    switch (state.volumeMode) {
      case VolumeMode.app:
        await ref
            .read(settingsPreferencesRepositoryProvider)
            .setVolumeMode(volumeModeName: VolumeMode.system.name);
        state = state.copyWith(volumeMode: VolumeMode.system);
        break;
      case VolumeMode.system:
        await ref
            .read(settingsPreferencesRepositoryProvider)
            .setVolumeMode(volumeModeName: VolumeMode.app.name);
        state = state.copyWith(volumeMode: VolumeMode.app);
        break;
    }
  }

  Future<void> toggleSplitScreen() async {
    state = state.copyWith(splitScreenEnabled: !state.splitScreenEnabled);
    await ref
        .read(settingsPreferencesRepositoryProvider)
        .setSplitScreenEnabled(isSplitScreenEnabled: state.splitScreenEnabled);
  }

  Future<void> toggleAppTheme() async {
    final AppTheme updatedTheme = state.appTheme == AppTheme.light
        ? AppTheme.dark
        : AppTheme.light;
    state = state.copyWith(appTheme: updatedTheme);
    await ref
        .read(settingsPreferencesRepositoryProvider)
        .setAppTheme(appThemeName: updatedTheme.name);
  }

  Future<void> toggleImmersiveMode() async {
    state = state.copyWith(immersiveMode: !state.immersiveMode);
    await ref
        .read(settingsPreferencesRepositoryProvider)
        .setImmersiveMode(isImmersiveModeEnabled: state.immersiveMode);
    await setSystemUiMode();
  }

  Future<void> rescanMusicFiles({bool clearPlaylists = false}) async {
    final Box<MusicMetadata> metadataBox = Hive.box<MusicMetadata>(
      Constants.metadataBoxName,
    );
    // Snapshot ratings before the cache is wiped so the Starred playlist can
    // be restored after the rescan rebuilds the metadata from file tags.
    await ref
        .read(settingsPreferencesRepositoryProvider)
        .setRatingSnapshot(
          ratingSnapshot: extractRatingSnapshot(metadataBox.values.toList()),
        );
    await metadataBox.clear();
    if (clearPlaylists) {
      await Hive.box<PlaylistModel>(Constants.playlistBoxName).clear();
    }
    ref.invalidate(audioFilesServiceProvider);
    ref.invalidate(splashControllerProvider);
    ref.read(routerProvider).goNamed(Routes.splash.name);
  }

  Future<void> resetSettings() async {
    await ref
        .read(settingsPreferencesRepositoryProvider)
        .setLanguageLocaleCode(languageLocaleCode: 'en');
    await ref
        .read(settingsPreferencesRepositoryProvider)
        .setDeviceColor(deviceColorName: DeviceColor.silver.name);
    await ref
        .read(settingsPreferencesRepositoryProvider)
        .setTouchScreenEnabled(isTouchScreenEnabled: true);
    await ref
        .read(settingsPreferencesRepositoryProvider)
        .setRepeatMode(repeatModeName: RepeatMode.off.name);
    await ref
        .read(settingsPreferencesRepositoryProvider)
        .setVibrate(isVibrateEnabled: true);
    await ref
        .read(settingsPreferencesRepositoryProvider)
        .setClickWheelSound(isClickWheelSoundEnabled: false);
    await ref
        .read(settingsPreferencesRepositoryProvider)
        .setSplitScreenEnabled(isSplitScreenEnabled: true);
    await ref
        .read(settingsPreferencesRepositoryProvider)
        .setImmersiveMode(isImmersiveModeEnabled: false);
    await ref
        .read(settingsPreferencesRepositoryProvider)
        .setAppTheme(appThemeName: AppTheme.light.name);
    await ref
        .read(settingsPreferencesRepositoryProvider)
        .setDeviceSkin(deviceSkinName: DeviceSkin.classic.name);
    await ref
        .read(settingsPreferencesRepositoryProvider)
        .setNoteFontColor(noteFontColorName: NoteFontColor.theme.name);
    await ref
        .read(settingsPreferencesRepositoryProvider)
        .setNoteFontSize(noteFontSize: Constants.defaultNoteFontSize);
    await ref.read(notesServiceProvider.notifier).clearAllFontSizes();
    await ref
        .read(settingsPreferencesRepositoryProvider)
        .setAutoSaveNoteReadingPosition(
          isAutoSaveNoteReadingPositionEnabled: false,
        );
    await ref
        .read(settingsPreferencesRepositoryProvider)
        .setNoteReaderHideStatusBar(isNoteReaderHideStatusBarEnabled: false);
    await ref
        .read(settingsPreferencesRepositoryProvider)
        .setSeekInterval(seekIntervalName: SeekInterval.five.name);
    await ref
        .read(settingsPreferencesRepositoryProvider)
        .setSleepTimerAction(
          sleepTimerActionName: SleepTimerAction.stopMusic.name,
        );
    await ref
        .read(settingsPreferencesRepositoryProvider)
        .setShowStatusBarClock(isShowStatusBarClockEnabled: false);
    await ref
        .read(settingsPreferencesRepositoryProvider)
        .setStatusBarClockFormat(
          statusBarClockFormatName: StatusBarClockFormat.twentyFourHour.name,
        );
    await ref
        .read(settingsPreferencesRepositoryProvider)
        .setScreenBackgroundColor(
          screenBackgroundColorName: ScreenColor.theme.name,
        );
    await ref
        .read(settingsPreferencesRepositoryProvider)
        .setFontColor(fontColorName: ScreenColor.theme.name);
    await ref
        .read(settingsPreferencesRepositoryProvider)
        .setHighlightColor(highlightColorName: ScreenColor.theme.name);
    ref.invalidateSelf();
  }

  Future<void> increaseVolume() async {
    if (state.volumeMode == VolumeMode.app) {
      final double currentVolume = ref.read(audioPlayerProvider).volume;
      if (currentVolume < 1) {
        await ref.read(audioPlayerProvider).setVolume(currentVolume + 0.05);
      }
    } else {
      final double currentVolume = await VolumeController.instance.getVolume();
      if (currentVolume < 1) {
        await VolumeController.instance.setVolume(
          (currentVolume + 0.05).clamp(0, 1),
        );
      }
    }
  }

  Future<void> decreaseVolume() async {
    if (state.volumeMode == VolumeMode.app) {
      final double currentVolume = ref.read(audioPlayerProvider).volume;
      if (currentVolume > 0) {
        if (currentVolume <= 0.05) {
          await ref.read(audioPlayerProvider).setVolume(0);
        } else {
          await ref.read(audioPlayerProvider).setVolume(currentVolume - 0.05);
        }
      }
    } else {
      final double currentVolume = await VolumeController.instance.getVolume();
      if (currentVolume > 0) {
        await VolumeController.instance.setVolume(
          (currentVolume - 0.05).clamp(0, 1),
        );
      }
    }
  }
}
