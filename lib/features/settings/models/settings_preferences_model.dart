import 'package:flutter/foundation.dart';
import 'package:retropod/core/constants/constants.dart';
import 'package:retropod/features/settings/models/app_theme.dart';
import 'package:retropod/features/settings/models/click_wheel_acceleration.dart';
import 'package:retropod/features/settings/models/click_wheel_size.dart';
import 'package:retropod/features/settings/models/click_wheel_sound_choice.dart';
import 'package:retropod/features/settings/models/click_wheel_speed.dart';
import 'package:retropod/features/settings/models/click_wheel_volume_level.dart';
import 'package:retropod/features/settings/models/device_color.dart';
import 'package:retropod/features/settings/models/device_skin.dart';
import 'package:retropod/features/settings/models/menu_hold_action.dart';
import 'package:retropod/features/settings/models/note_font_color.dart';
import 'package:retropod/features/settings/models/repeat_mode.dart';
import 'package:retropod/features/settings/models/screen_color.dart';
import 'package:retropod/features/settings/models/screensaver_type.dart';
import 'package:retropod/features/settings/models/seek_interval.dart';
import 'package:retropod/features/settings/models/sleep_timer_action.dart';
import 'package:retropod/features/settings/models/slideshow_duration.dart';
import 'package:retropod/features/settings/models/status_bar_clock_format.dart';
import 'package:retropod/features/settings/models/visualizer_idle_time.dart';
import 'package:retropod/features/settings/models/volume_mode.dart';

class SettingsPreferencesModel {
  final String languageLocaleCode;
  final DeviceColor deviceColor;
  final ClickWheelSize clickWheelSize;
  final ClickWheelSpeed clickWheelSpeed;
  final ClickWheelAcceleration clickWheelAcceleration;
  final bool isTouchScreenEnabled;
  final RepeatMode repeatMode;
  final bool vibrate;
  final bool clickWheelSound;
  final ClickWheelSoundChoice clickWheelSoundChoice;
  final ClickWheelVolumeLevel clickWheelVolumeLevel;
  final VolumeMode volumeMode;
  final bool splitScreenEnabled;
  final bool immersiveMode;
  final bool fetchOnlineMusic;
  final AppTheme appTheme;
  final DeviceSkin deviceSkin;
  final NoteFontColor noteFontColor;
  final int noteFontSize;
  final bool autoSaveNoteReadingPosition;
  final bool noteReaderHideStatusBar;
  final SeekInterval seekInterval;
  final SleepTimerAction sleepTimerAction;
  final MenuHoldAction menuHoldAction;
  final bool showStatusBarClock;
  final StatusBarClockFormat statusBarClockFormat;
  final ScreenColor screenBackgroundColor;
  final ScreenColor fontColor;
  final ScreenColor highlightColor;
  final VisualizerIdleTime visualizerIdleTime;
  final bool keepScreenAwake;
  final ScreensaverType screensaverType;
  final SlideshowDuration slideshowDuration;
  final List<String> excludedSlideshowFolders;

  SettingsPreferencesModel({
    required this.languageLocaleCode,
    required this.deviceColor,
    required this.clickWheelSize,
    required this.clickWheelSpeed,
    required this.clickWheelAcceleration,
    required this.isTouchScreenEnabled,
    required this.repeatMode,
    required this.vibrate,
    required this.clickWheelSound,
    this.clickWheelSoundChoice = ClickWheelSoundChoice.classic,
    this.clickWheelVolumeLevel = ClickWheelVolumeLevel.max,
    required this.volumeMode,
    required this.splitScreenEnabled,
    required this.immersiveMode,
    required this.appTheme,
    this.fetchOnlineMusic = false,
    this.deviceSkin = DeviceSkin.classic,
    this.noteFontColor = NoteFontColor.theme,
    this.noteFontSize = Constants.defaultNoteFontSize,
    this.autoSaveNoteReadingPosition = false,
    this.noteReaderHideStatusBar = false,
    this.seekInterval = SeekInterval.five,
    this.sleepTimerAction = SleepTimerAction.stopMusic,
    this.menuHoldAction = MenuHoldAction.none,
    this.showStatusBarClock = false,
    this.statusBarClockFormat = StatusBarClockFormat.twentyFourHour,
    this.screenBackgroundColor = ScreenColor.theme,
    this.fontColor = ScreenColor.theme,
    this.highlightColor = ScreenColor.theme,
    this.visualizerIdleTime = VisualizerIdleTime.off,
    this.keepScreenAwake = false,
    this.screensaverType = ScreensaverType.visualizer,
    this.slideshowDuration = SlideshowDuration.s5,
    this.excludedSlideshowFolders = const [],
  });

  SettingsPreferencesModel copyWith({
    String? languageLocaleCode,
    DeviceColor? deviceColor,
    ClickWheelSize? clickWheelSize,
    ClickWheelSpeed? clickWheelSpeed,
    ClickWheelAcceleration? clickWheelAcceleration,
    bool? isTouchScreenEnabled,
    RepeatMode? repeatMode,
    bool? vibrate,
    bool? clickWheelSound,
    ClickWheelSoundChoice? clickWheelSoundChoice,
    ClickWheelVolumeLevel? clickWheelVolumeLevel,
    VolumeMode? volumeMode,
    bool? splitScreenEnabled,
    bool? immersiveMode,
    bool? fetchOnlineMusic,
    AppTheme? appTheme,
    DeviceSkin? deviceSkin,
    NoteFontColor? noteFontColor,
    int? noteFontSize,
    bool? autoSaveNoteReadingPosition,
    bool? noteReaderHideStatusBar,
    SeekInterval? seekInterval,
    SleepTimerAction? sleepTimerAction,
    MenuHoldAction? menuHoldAction,
    bool? showStatusBarClock,
    StatusBarClockFormat? statusBarClockFormat,
    ScreenColor? screenBackgroundColor,
    ScreenColor? fontColor,
    ScreenColor? highlightColor,
    VisualizerIdleTime? visualizerIdleTime,
    bool? keepScreenAwake,
    ScreensaverType? screensaverType,
    SlideshowDuration? slideshowDuration,
    List<String>? excludedSlideshowFolders,
  }) {
    return SettingsPreferencesModel(
      languageLocaleCode: languageLocaleCode ?? this.languageLocaleCode,
      deviceColor: deviceColor ?? this.deviceColor,
      clickWheelSize: clickWheelSize ?? this.clickWheelSize,
      clickWheelSpeed: clickWheelSpeed ?? this.clickWheelSpeed,
      clickWheelAcceleration:
          clickWheelAcceleration ?? this.clickWheelAcceleration,
      isTouchScreenEnabled: isTouchScreenEnabled ?? this.isTouchScreenEnabled,
      repeatMode: repeatMode ?? this.repeatMode,
      vibrate: vibrate ?? this.vibrate,
      clickWheelSound: clickWheelSound ?? this.clickWheelSound,
      clickWheelSoundChoice:
          clickWheelSoundChoice ?? this.clickWheelSoundChoice,
      clickWheelVolumeLevel:
          clickWheelVolumeLevel ?? this.clickWheelVolumeLevel,
      volumeMode: volumeMode ?? this.volumeMode,
      splitScreenEnabled: splitScreenEnabled ?? this.splitScreenEnabled,
      immersiveMode: immersiveMode ?? this.immersiveMode,
      appTheme: appTheme ?? this.appTheme,
      fetchOnlineMusic: fetchOnlineMusic ?? this.fetchOnlineMusic,
      deviceSkin: deviceSkin ?? this.deviceSkin,
      noteFontColor: noteFontColor ?? this.noteFontColor,
      noteFontSize: noteFontSize ?? this.noteFontSize,
      autoSaveNoteReadingPosition:
          autoSaveNoteReadingPosition ?? this.autoSaveNoteReadingPosition,
      noteReaderHideStatusBar:
          noteReaderHideStatusBar ?? this.noteReaderHideStatusBar,
      seekInterval: seekInterval ?? this.seekInterval,
      sleepTimerAction: sleepTimerAction ?? this.sleepTimerAction,
      menuHoldAction: menuHoldAction ?? this.menuHoldAction,
      showStatusBarClock: showStatusBarClock ?? this.showStatusBarClock,
      statusBarClockFormat: statusBarClockFormat ?? this.statusBarClockFormat,
      screenBackgroundColor:
          screenBackgroundColor ?? this.screenBackgroundColor,
      fontColor: fontColor ?? this.fontColor,
      highlightColor: highlightColor ?? this.highlightColor,
      visualizerIdleTime: visualizerIdleTime ?? this.visualizerIdleTime,
      keepScreenAwake: keepScreenAwake ?? this.keepScreenAwake,
      screensaverType: screensaverType ?? this.screensaverType,
      slideshowDuration: slideshowDuration ?? this.slideshowDuration,
      excludedSlideshowFolders:
          excludedSlideshowFolders ?? this.excludedSlideshowFolders,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is SettingsPreferencesModel &&
        other.languageLocaleCode == languageLocaleCode &&
        other.deviceColor == deviceColor &&
        other.clickWheelSize == clickWheelSize &&
        other.clickWheelSpeed == clickWheelSpeed &&
        other.clickWheelAcceleration == clickWheelAcceleration &&
        other.isTouchScreenEnabled == isTouchScreenEnabled &&
        other.repeatMode == repeatMode &&
        other.vibrate == vibrate &&
        other.clickWheelSound == clickWheelSound &&
        other.clickWheelSoundChoice == clickWheelSoundChoice &&
        other.clickWheelVolumeLevel == clickWheelVolumeLevel &&
        other.volumeMode == volumeMode &&
        other.splitScreenEnabled == splitScreenEnabled &&
        other.immersiveMode == immersiveMode &&
        other.fetchOnlineMusic == fetchOnlineMusic &&
        other.deviceSkin == deviceSkin &&
        other.appTheme == appTheme &&
        other.noteFontColor == noteFontColor &&
        other.noteFontSize == noteFontSize &&
        other.autoSaveNoteReadingPosition == autoSaveNoteReadingPosition &&
        other.noteReaderHideStatusBar == noteReaderHideStatusBar &&
        other.seekInterval == seekInterval &&
        other.sleepTimerAction == sleepTimerAction &&
        other.menuHoldAction == menuHoldAction &&
        other.showStatusBarClock == showStatusBarClock &&
        other.statusBarClockFormat == statusBarClockFormat &&
        other.screenBackgroundColor == screenBackgroundColor &&
        other.fontColor == fontColor &&
        other.highlightColor == highlightColor &&
        other.visualizerIdleTime == visualizerIdleTime &&
        other.keepScreenAwake == keepScreenAwake &&
        other.screensaverType == screensaverType &&
        other.slideshowDuration == slideshowDuration &&
        listEquals(other.excludedSlideshowFolders, excludedSlideshowFolders);
  }

  @override
  int get hashCode => Object.hashAll(<Object?>[
    languageLocaleCode,
    deviceColor,
    clickWheelSize,
    clickWheelSpeed,
    clickWheelAcceleration,
    isTouchScreenEnabled,
    repeatMode,
    vibrate,
    clickWheelSound,
    clickWheelSoundChoice,
    clickWheelVolumeLevel,
    volumeMode,
    splitScreenEnabled,
    immersiveMode,
    appTheme,
    fetchOnlineMusic,
    deviceSkin,
    noteFontColor,
    noteFontSize,
    autoSaveNoteReadingPosition,
    noteReaderHideStatusBar,
    seekInterval,
    sleepTimerAction,
    menuHoldAction,
    showStatusBarClock,
    statusBarClockFormat,
    screenBackgroundColor,
    fontColor,
    highlightColor,
    visualizerIdleTime,
    keepScreenAwake,
    screensaverType,
    slideshowDuration,
    Object.hashAll(excludedSlideshowFolders),
  ]);
}
