import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:retropod/core/extensions/build_context_extensions.dart';
import 'package:retropod/core/navigation/routes.dart';
import 'package:retropod/core/services/audio_player_service.dart';
import 'package:retropod/features/custom_screen_elements/custom_screen.dart';
import 'package:retropod/features/menu/controller/split_screen_controller.dart';
import 'package:retropod/features/menu/models/split_screen_type.dart';
import 'package:retropod/features/now_playing/provider/now_playing_details_provider.dart';
import 'package:retropod/features/settings/controller/prevent_duplicate_tracks_controller.dart';
import 'package:retropod/features/settings/controller/settings_preferences_controller.dart';
import 'package:retropod/features/settings/models/screen_color.dart';
import 'package:retropod/features/settings/models/settings_preferences_model.dart';
import 'package:retropod/features/settings/widgets/settings_list_tile.dart';
import 'package:retropod/features/sleep_timer/models/sleep_timer_model.dart';
import 'package:retropod/features/sleep_timer/provider/sleep_timer_provider.dart';
import 'package:retropod/features/status_bar/widgets/status_bar.dart';

enum _SettingsDisplayItems {
  about,
  shuffle,
  repeat,
  language,
  appTheme,
  deviceColor,
  deviceSkin,
  noteFontSize,
  autoSaveNoteReadingPosition,
  noteReaderHideStatusBar,
  screenColors,
  noteFontColor,
  clickWheelSize,
  clickWheelSpeed,
  clickWheelAcceleration,
  isTouchScreenEnabled,
  vibrate,
  clickWheelSound,
  clickWheelSoundChoice,
  clickWheelVolume,
  volumeMode,
  seekInterval,
  sleepTimerAction,
  menuHoldAction,
  screensaverType,
  visualizerIdleTime,
  slideshowDuration,
  slideshowFolders,
  keepScreenAwake,
  sleepTimer,
  showStatusBarClock,
  statusBarClockFormat,
  splitScreenEnabled,
  immersiveMode,
  showAppTutorial,
  rescanMusicFiles,
  excludeDirectories,
  preventDuplicateTracks,
  resetSettings;

  String title(BuildContext context) {
    switch (this) {
      case about:
        return context.localization.aboutScreenTitle;
      case shuffle:
        return context.localization.shuffleSettingTitle;
      case repeat:
        return context.localization.repeatModeSettingTitle;
      case language:
        return context.localization.languageScreenTitle;
      case appTheme:
        return context.localization.themeSettingTitle;
      case isTouchScreenEnabled:
        return context.localization.touchScreenSettingTitle;
      case deviceColor:
        return context.localization.deviceColorSettingTitle;
      case deviceSkin:
        return 'Skins';
      case noteFontColor:
        return context.localization.noteFontColorSettingTitle;
      case noteFontSize:
        return context.localization.noteFontSizeSettingTitle;
      case autoSaveNoteReadingPosition:
        return context.localization.autoSaveNoteReadingPositionSettingTitle;
      case noteReaderHideStatusBar:
        return context.localization.noteReaderHideStatusBarSettingTitle;
      case screenColors:
        return context.localization.screenColorsSettingTitle;
      case clickWheelSize:
        return context.localization.clickWheelSizeSettingTitle;
      case clickWheelSpeed:
        return context.localization.clickWheelSpeedSettingTitle;
      case clickWheelAcceleration:
        return context.localization.clickWheelAccelerationSettingTitle;
      case volumeMode:
        return context.localization.volumeModeSettingTitle;
      case seekInterval:
        return context.localization.seekIntervalSettingTitle;
      case sleepTimerAction:
        return context.localization.sleepTimerActionSettingTitle;
      case menuHoldAction:
        return context.localization.menuHoldActionSettingTitle;
      case screensaverType:
        return context.localization.screensaverTypeSettingTitle;
      case visualizerIdleTime:
        return context.localization.visualizerIdleTimeSettingTitle;
      case slideshowDuration:
        return context.localization.slideshowDurationSettingTitle;
      case slideshowFolders:
        return context.localization.slideshowFoldersSettingTitle;
      case keepScreenAwake:
        return context.localization.keepScreenAwakeSettingTitle;
      case sleepTimer:
        return context.localization.sleepTimerTitle;
      case showStatusBarClock:
        return context.localization.showStatusBarClockSettingTitle;
      case statusBarClockFormat:
        return context.localization.statusBarClockFormatSettingTitle;
      case vibrate:
        return context.localization.vibrateSettingTitle;
      case clickWheelSound:
        return context.localization.clickWheelSettingTitle;
      case clickWheelSoundChoice:
        return context.localization.clickWheelSoundSettingTitle;
      case clickWheelVolume:
        return context.localization.clickWheelVolumeSettingTitle;
      case splitScreenEnabled:
        return context.localization.splitScreenSettingTitle;
      case immersiveMode:
        return context.localization.immersiveModeSettingTitle;
      case showAppTutorial:
        return context.localization.showAppTutorialSettingTitle;
      case rescanMusicFiles:
        return context.localization.rescanMusicFilesSettingTitle;
      case resetSettings:
        return context.localization.resetSettingsTitle;
      case excludeDirectories:
        return context.localization.excludeDirectoriesScreenTitle;
      case preventDuplicateTracks:
        return context.localization.preventDuplicateTracksTitle;
    }
  }
}

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen>
    with CustomScreen {
  @override
  String get routeName => Routes.settings.name;

  @override
  List<_SettingsDisplayItems> get displayItems => _SettingsDisplayItems.values;

  @override
  Future<void> onSelectPressed() =>
      _settingAction(displayItems[selectedDisplayItem]);

  Future<void> _settingAction(_SettingsDisplayItems settingItem) async {
    setState(() => selectedDisplayItem = displayItems.indexOf(settingItem));
    switch (settingItem) {
      case _SettingsDisplayItems.about:
        context.goNamed(Routes.about.name);
        break;
      case _SettingsDisplayItems.language:
        context.goNamed(Routes.language.name);
        break;
      case _SettingsDisplayItems.shuffle:
        await ref.read(audioPlayerServiceProvider.notifier).toggleShuffleMode();
        break;
      case _SettingsDisplayItems.repeat:
        await ref
            .read(settingsPreferencesControllerProvider.notifier)
            .toggleRepeatMode();
        break;
      case _SettingsDisplayItems.appTheme:
        await ref
            .read(settingsPreferencesControllerProvider.notifier)
            .toggleAppTheme();
        break;
      case _SettingsDisplayItems.deviceColor:
        context.goNamed(Routes.deviceColor.name);
        break;
      case _SettingsDisplayItems.deviceSkin:
        context.goNamed(Routes.deviceSkin.name);
        break;
      case _SettingsDisplayItems.noteFontColor:
        context.goNamed(Routes.noteFontColor.name);
        break;
      case _SettingsDisplayItems.noteFontSize:
        context.goNamed(Routes.noteFontSize.name);
        break;
      case _SettingsDisplayItems.autoSaveNoteReadingPosition:
        await ref
            .read(settingsPreferencesControllerProvider.notifier)
            .toggleAutoSaveNoteReadingPosition();
        break;
      case _SettingsDisplayItems.noteReaderHideStatusBar:
        await ref
            .read(settingsPreferencesControllerProvider.notifier)
            .toggleNoteReaderHideStatusBar();
        break;
      case _SettingsDisplayItems.screenColors:
        context.goNamed(Routes.screenColors.name);
        break;
      case _SettingsDisplayItems.clickWheelSize:
        await ref
            .read(settingsPreferencesControllerProvider.notifier)
            .toggleClickWheelSize();
        break;
      case _SettingsDisplayItems.clickWheelSpeed:
        await ref
            .read(settingsPreferencesControllerProvider.notifier)
            .toggleClickWheelSpeed();
        break;
      case _SettingsDisplayItems.clickWheelAcceleration:
        await ref
            .read(settingsPreferencesControllerProvider.notifier)
            .toggleClickWheelAcceleration();
        break;
      case _SettingsDisplayItems.isTouchScreenEnabled:
        await ref
            .read(settingsPreferencesControllerProvider.notifier)
            .toggleTouchScreen();
        break;
      case _SettingsDisplayItems.vibrate:
        await ref
            .read(settingsPreferencesControllerProvider.notifier)
            .toggleVibrate();
        break;
      case _SettingsDisplayItems.clickWheelSound:
        await ref
            .read(settingsPreferencesControllerProvider.notifier)
            .toggleClickWheelSound();
        break;
      case _SettingsDisplayItems.clickWheelSoundChoice:
        await ref
            .read(settingsPreferencesControllerProvider.notifier)
            .cycleClickWheelSoundChoice();
        break;
      case _SettingsDisplayItems.clickWheelVolume:
        await ref
            .read(settingsPreferencesControllerProvider.notifier)
            .cycleClickWheelVolumeLevel();
        break;
      case _SettingsDisplayItems.volumeMode:
        await ref
            .read(settingsPreferencesControllerProvider.notifier)
            .toggleVolumeMode();
        break;
      case _SettingsDisplayItems.seekInterval:
        await ref
            .read(settingsPreferencesControllerProvider.notifier)
            .cycleSeekInterval();
        break;
      case _SettingsDisplayItems.sleepTimerAction:
        await ref
            .read(settingsPreferencesControllerProvider.notifier)
            .cycleSleepTimerAction();
        break;
      case _SettingsDisplayItems.menuHoldAction:
        await ref
            .read(settingsPreferencesControllerProvider.notifier)
            .cycleMenuHoldAction();
        break;
      case _SettingsDisplayItems.screensaverType:
        await ref
            .read(settingsPreferencesControllerProvider.notifier)
            .cycleScreensaverType();
        break;
      case _SettingsDisplayItems.visualizerIdleTime:
        await ref
            .read(settingsPreferencesControllerProvider.notifier)
            .cycleVisualizerIdleTime();
        break;
      case _SettingsDisplayItems.slideshowDuration:
        await ref
            .read(settingsPreferencesControllerProvider.notifier)
            .cycleSlideshowDuration();
        break;
      case _SettingsDisplayItems.slideshowFolders:
        context.goNamed(Routes.slideshowFolders.name);
        break;
      case _SettingsDisplayItems.keepScreenAwake:
        await ref
            .read(settingsPreferencesControllerProvider.notifier)
            .toggleKeepScreenAwake();
        break;
      case _SettingsDisplayItems.sleepTimer:
        _cycleSleepTimer();
        break;
      case _SettingsDisplayItems.showStatusBarClock:
        await ref
            .read(settingsPreferencesControllerProvider.notifier)
            .toggleShowStatusBarClock();
        break;
      case _SettingsDisplayItems.statusBarClockFormat:
        await ref
            .read(settingsPreferencesControllerProvider.notifier)
            .cycleStatusBarClockFormat();
        break;
      case _SettingsDisplayItems.splitScreenEnabled:
        await ref
            .read(settingsPreferencesControllerProvider.notifier)
            .toggleSplitScreen();
        break;
      case _SettingsDisplayItems.immersiveMode:
        await ref
            .read(settingsPreferencesControllerProvider.notifier)
            .toggleImmersiveMode();
        break;
      case _SettingsDisplayItems.showAppTutorial:
        await ref
            .read(settingsPreferencesControllerProvider.notifier)
            .showAppTutorial();
        break;
      case _SettingsDisplayItems.rescanMusicFiles:
        await ref
            .read(settingsPreferencesControllerProvider.notifier)
            .rescanMusicFiles();
        break;
      case _SettingsDisplayItems.excludeDirectories:
        context.goNamed(Routes.excludeDirectories.name);
        break;
      case _SettingsDisplayItems.preventDuplicateTracks:
        await ref
            .read(preventDuplicateTracksProvider.notifier)
            .setEnabled(!ref.read(preventDuplicateTracksProvider));
        break;
      case _SettingsDisplayItems.resetSettings:
        await ref
            .read(settingsPreferencesControllerProvider.notifier)
            .resetSettings();
        break;
    }
  }

  /// Cycles the sleep timer through Off, 15/30/45/60 minutes and End of
  /// Current Song, applying each choice immediately. This tile and the
  /// Sleep Timer screen drive the same controller, so they always agree;
  /// starting a timer from here replaces any timer that is already
  /// running. Session-scoped like the real iPod: the timer resets to Off
  /// when the app restarts and is never persisted.
  void _cycleSleepTimer() {
    final SleepTimerState timerState = ref.read(sleepTimerControllerProvider);
    final int currentIndex = switch (timerState.mode) {
      SleepTimerMode.off => 0,
      SleepTimerMode.fixedDuration => switch (timerState.duration?.inMinutes) {
        15 => 1,
        30 => 2,
        45 => 3,
        60 => 4,
        _ => 0,
      },
      SleepTimerMode.endOfCurrentSong => 5,
    };
    // End of Current Song is only offered while something is playing,
    // mirroring the Sleep Timer screen.
    final bool endOfSongAvailable =
        ref.read(nowPlayingDetailsProvider).currentMetadata != null;
    final List<int> cycle = endOfSongAvailable
        ? const [0, 1, 2, 3, 4, 5]
        : const [0, 1, 2, 3, 4];
    final int next = cycle[(currentIndex + 1) % cycle.length];
    final SleepTimerController controller = ref.read(
      sleepTimerControllerProvider.notifier,
    );
    switch (next) {
      case 0:
        controller.cancel();
      case 1:
        controller.start(const Duration(minutes: 15));
      case 2:
        controller.start(const Duration(minutes: 30));
      case 3:
        controller.start(const Duration(minutes: 45));
      case 4:
        controller.start(const Duration(minutes: 60));
      case 5:
        controller.stopAtEndOfCurrentSong();
    }
  }

  String? _sleepTimerValue() {
    final SleepTimerState timerState = ref.watch(sleepTimerControllerProvider);
    return switch (timerState.mode) {
      SleepTimerMode.off => context.localization.tileValueOff,
      SleepTimerMode.endOfCurrentSong =>
        context.localization.sleepTimerEndOfCurrentSong,
      SleepTimerMode.fixedDuration => context.localization.sleepTimerMinutes(
        timerState.duration?.inMinutes ?? 0,
      ),
    };
  }

  bool? _isOn(
    SettingsPreferencesModel settingsState,
    _SettingsDisplayItems settingsItem,
  ) {
    switch (settingsItem) {
      case _SettingsDisplayItems.shuffle:
        return ref.watch(nowPlayingDetailsProvider).isShuffleEnabled;
      case _SettingsDisplayItems.isTouchScreenEnabled:
        return settingsState.isTouchScreenEnabled;
      case _SettingsDisplayItems.vibrate:
        return settingsState.vibrate;
      case _SettingsDisplayItems.clickWheelSound:
        return settingsState.clickWheelSound;
      case _SettingsDisplayItems.splitScreenEnabled:
        return settingsState.splitScreenEnabled;
      case _SettingsDisplayItems.autoSaveNoteReadingPosition:
        return settingsState.autoSaveNoteReadingPosition;
      case _SettingsDisplayItems.noteReaderHideStatusBar:
        return settingsState.noteReaderHideStatusBar;
      case _SettingsDisplayItems.immersiveMode:
        return settingsState.immersiveMode;
      case _SettingsDisplayItems.preventDuplicateTracks:
        return ref.watch(preventDuplicateTracksProvider);
      default:
        return null;
    }
  }

  String? _getValue(
    SettingsPreferencesModel settingsState,
    _SettingsDisplayItems settingsItem,
  ) {
    switch (settingsItem) {
      case _SettingsDisplayItems.deviceColor:
        return settingsState.deviceColor.title(context);
      case _SettingsDisplayItems.deviceSkin:
        return settingsState.deviceSkin.title(context);
      case _SettingsDisplayItems.noteFontColor:
        return settingsState.noteFontColor.title(context);
      case _SettingsDisplayItems.noteFontSize:
        return '${settingsState.noteFontSize}';
      case _SettingsDisplayItems.screenColors:
        return settingsState.screenBackgroundColor == ScreenColor.theme &&
                settingsState.fontColor == ScreenColor.theme &&
                settingsState.highlightColor == ScreenColor.theme
            ? context.localization.themeDefaultColorOption
            : context.localization.customColorsValue;
      case _SettingsDisplayItems.clickWheelSize:
        return settingsState.clickWheelSize.title(context);
      case _SettingsDisplayItems.clickWheelSpeed:
        return settingsState.clickWheelSpeed.title(context);
      case _SettingsDisplayItems.clickWheelAcceleration:
        return settingsState.clickWheelAcceleration.title(context);
      case _SettingsDisplayItems.clickWheelSoundChoice:
        return settingsState.clickWheelSoundChoice.title(context);
      case _SettingsDisplayItems.clickWheelVolume:
        return settingsState.clickWheelVolumeLevel.title(context);
      case _SettingsDisplayItems.appTheme:
        return settingsState.appTheme.title(context);
      case _SettingsDisplayItems.repeat:
        return settingsState.repeatMode.title(context);
      case _SettingsDisplayItems.volumeMode:
        return settingsState.volumeMode.title(context);
      case _SettingsDisplayItems.seekInterval:
        return settingsState.seekInterval.title(context);
      case _SettingsDisplayItems.sleepTimerAction:
        return settingsState.sleepTimerAction.title(context);
      case _SettingsDisplayItems.menuHoldAction:
        return settingsState.menuHoldAction.title(context);
      case _SettingsDisplayItems.screensaverType:
        return settingsState.screensaverType.title(context);
      case _SettingsDisplayItems.visualizerIdleTime:
        return settingsState.visualizerIdleTime.title(context);
      case _SettingsDisplayItems.slideshowDuration:
        return settingsState.slideshowDuration.title(context);
      case _SettingsDisplayItems.keepScreenAwake:
        return settingsState.keepScreenAwake
            ? context.localization.tileValueOn
            : context.localization.tileValueOff;
      case _SettingsDisplayItems.sleepTimer:
        return _sleepTimerValue();
      case _SettingsDisplayItems.showStatusBarClock:
        return settingsState.showStatusBarClock
            ? context.localization.tileValueOn
            : context.localization.tileValueOff;
      case _SettingsDisplayItems.statusBarClockFormat:
        return settingsState.statusBarClockFormat.title(context);
      default:
        final bool? isOn = _isOn(settingsState, settingsItem);
        if (isOn != null) {
          if (isOn) {
            return context.localization.tileValueOn;
          } else {
            return context.localization.tileValueOff;
          }
        }
        return null;
    }
  }

  Future<void> _changeSplitScreenType() async {
    await Future.delayed(const Duration(milliseconds: 150));
    switch (displayItems[selectedDisplayItem]) {
      case _SettingsDisplayItems.language:
        ref.read(splitScreenControllerProvider.notifier).changeSplitScreenType =
            SplitScreenType.language;
        break;

      case _SettingsDisplayItems.deviceColor:
        ref.read(splitScreenControllerProvider.notifier).changeSplitScreenType =
            SplitScreenType.deviceColor;
        break;
      case _SettingsDisplayItems.deviceSkin:
        ref.read(splitScreenControllerProvider.notifier).changeSplitScreenType =
            SplitScreenType.deviceSkin;
        break;
      case _SettingsDisplayItems.noteFontColor:
        ref.read(splitScreenControllerProvider.notifier).changeSplitScreenType =
            SplitScreenType.noteFontColor;
        break;
      case _SettingsDisplayItems.noteFontSize:
        ref.read(splitScreenControllerProvider.notifier).changeSplitScreenType =
            SplitScreenType.noteFontSize;
        break;
      case _SettingsDisplayItems.screenColors:
        ref.read(splitScreenControllerProvider.notifier).changeSplitScreenType =
            SplitScreenType.screenColors;
        break;
      case _SettingsDisplayItems.appTheme:
        ref.read(splitScreenControllerProvider.notifier).changeSplitScreenType =
            SplitScreenType.appTheme;
        break;
      case _SettingsDisplayItems.clickWheelSize:
        ref.read(splitScreenControllerProvider.notifier).changeSplitScreenType =
            SplitScreenType.clickWheelSize;
        break;
      case _SettingsDisplayItems.clickWheelSpeed:
        ref.read(splitScreenControllerProvider.notifier).changeSplitScreenType =
            SplitScreenType.clickWheelSpeed;
        break;
      case _SettingsDisplayItems.clickWheelAcceleration:
        ref.read(splitScreenControllerProvider.notifier).changeSplitScreenType =
            SplitScreenType.clickWheelAcceleration;
        break;
      case _SettingsDisplayItems.isTouchScreenEnabled:
        ref.read(splitScreenControllerProvider.notifier).changeSplitScreenType =
            SplitScreenType.touchScreen;
        break;
      case _SettingsDisplayItems.shuffle:
        ref.read(splitScreenControllerProvider.notifier).changeSplitScreenType =
            SplitScreenType.shuffle;
        break;
      case _SettingsDisplayItems.repeat:
        ref.read(splitScreenControllerProvider.notifier).changeSplitScreenType =
            SplitScreenType.repeat;
        break;
      case _SettingsDisplayItems.vibrate:
        ref.read(splitScreenControllerProvider.notifier).changeSplitScreenType =
            SplitScreenType.vibrate;
        break;
      case _SettingsDisplayItems.clickWheelSound:
        ref.read(splitScreenControllerProvider.notifier).changeSplitScreenType =
            SplitScreenType.clickWheelSound;
        break;
      case _SettingsDisplayItems.clickWheelSoundChoice:
        ref.read(splitScreenControllerProvider.notifier).changeSplitScreenType =
            SplitScreenType.clickWheelSoundChoice;
        break;
      case _SettingsDisplayItems.clickWheelVolume:
        ref.read(splitScreenControllerProvider.notifier).changeSplitScreenType =
            SplitScreenType.clickWheelVolume;
        break;
      case _SettingsDisplayItems.volumeMode:
        ref.read(splitScreenControllerProvider.notifier).changeSplitScreenType =
            SplitScreenType.volumeMode;
        break;
      case _SettingsDisplayItems.splitScreenEnabled:
        ref.read(splitScreenControllerProvider.notifier).changeSplitScreenType =
            SplitScreenType.splitScreenMode;
        break;
      case _SettingsDisplayItems.immersiveMode:
        ref.read(splitScreenControllerProvider.notifier).changeSplitScreenType =
            SplitScreenType.immersiveMode;
        break;
      case _SettingsDisplayItems.showAppTutorial:
        ref.read(splitScreenControllerProvider.notifier).changeSplitScreenType =
            SplitScreenType.showTutorialScreen;
        break;
      case _SettingsDisplayItems.rescanMusicFiles:
        ref.read(splitScreenControllerProvider.notifier).changeSplitScreenType =
            SplitScreenType.rescanMusicFiles;
        break;
      case _SettingsDisplayItems.excludeDirectories:
        ref.read(splitScreenControllerProvider.notifier).changeSplitScreenType =
            SplitScreenType.excludeDirectories;
        break;
      case _SettingsDisplayItems.resetSettings:
        ref.read(splitScreenControllerProvider.notifier).changeSplitScreenType =
            SplitScreenType.resetSettings;
        break;
      default:
        ref.read(splitScreenControllerProvider.notifier).changeSplitScreenType =
            SplitScreenType.settings;
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsState = ref.watch(settingsPreferencesControllerProvider);

    unawaited(_changeSplitScreenType());

    return CupertinoPageScaffold(
      child: Column(
        children: [
          StatusBar(title: Routes.settings.title(context)),
          Flexible(
            child: CupertinoScrollbar(
              controller: scrollController,
              child: ListView.builder(
                controller: scrollController,
                itemCount: displayItems.length,
                prototypeItem: SettingsListTile(
                  text: '',
                  isSelected: false,
                  onTap: () {},
                ),
                itemBuilder: (context, index) => SettingsListTile(
                  text: displayItems[index].title(context),
                  value: _getValue(settingsState, displayItems[index]),
                  isSelected: selectedDisplayItem == index,
                  onTap: () async => _settingAction(displayItems[index]),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
