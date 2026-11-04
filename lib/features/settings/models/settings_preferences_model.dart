import 'package:retropod/core/constants/constants.dart';
import 'package:retropod/features/settings/models/app_theme.dart';
import 'package:retropod/features/settings/models/click_wheel_acceleration.dart';
import 'package:retropod/features/settings/models/click_wheel_size.dart';
import 'package:retropod/features/settings/models/click_wheel_sound_choice.dart';
import 'package:retropod/features/settings/models/click_wheel_speed.dart';
import 'package:retropod/features/settings/models/device_color.dart';
import 'package:retropod/features/settings/models/device_skin.dart';
import 'package:retropod/features/settings/models/note_font_color.dart';
import 'package:retropod/features/settings/models/repeat_mode.dart';
import 'package:retropod/features/settings/models/screen_color.dart';
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
  final VolumeMode volumeMode;
  final bool splitScreenEnabled;
  final bool immersiveMode;
  final bool fetchOnlineMusic;
  final AppTheme appTheme;
  final DeviceSkin deviceSkin;
  final NoteFontColor noteFontColor;
  final int noteFontSize;
  final ScreenColor screenBackgroundColor;
  final ScreenColor fontColor;
  final ScreenColor highlightColor;

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
    required this.volumeMode,
    required this.splitScreenEnabled,
    required this.immersiveMode,
    required this.appTheme,
    this.fetchOnlineMusic = false,
    this.deviceSkin = DeviceSkin.classic,
    this.noteFontColor = NoteFontColor.theme,
    this.noteFontSize = Constants.defaultNoteFontSize,
    this.screenBackgroundColor = ScreenColor.theme,
    this.fontColor = ScreenColor.theme,
    this.highlightColor = ScreenColor.theme,
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
    VolumeMode? volumeMode,
    bool? splitScreenEnabled,
    bool? immersiveMode,
    bool? fetchOnlineMusic,
    AppTheme? appTheme,
    DeviceSkin? deviceSkin,
    NoteFontColor? noteFontColor,
    int? noteFontSize,
    ScreenColor? screenBackgroundColor,
    ScreenColor? fontColor,
    ScreenColor? highlightColor,
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
      volumeMode: volumeMode ?? this.volumeMode,
      splitScreenEnabled: splitScreenEnabled ?? this.splitScreenEnabled,
      immersiveMode: immersiveMode ?? this.immersiveMode,
      appTheme: appTheme ?? this.appTheme,
      fetchOnlineMusic: fetchOnlineMusic ?? this.fetchOnlineMusic,
      deviceSkin: deviceSkin ?? this.deviceSkin,
      noteFontColor: noteFontColor ?? this.noteFontColor,
      noteFontSize: noteFontSize ?? this.noteFontSize,
      screenBackgroundColor:
          screenBackgroundColor ?? this.screenBackgroundColor,
      fontColor: fontColor ?? this.fontColor,
      highlightColor: highlightColor ?? this.highlightColor,
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
        other.volumeMode == volumeMode &&
        other.splitScreenEnabled == splitScreenEnabled &&
        other.immersiveMode == immersiveMode &&
        other.fetchOnlineMusic == fetchOnlineMusic &&
        other.deviceSkin == deviceSkin &&
        other.appTheme == appTheme &&
        other.noteFontColor == noteFontColor &&
        other.noteFontSize == noteFontSize &&
        other.screenBackgroundColor == screenBackgroundColor &&
        other.fontColor == fontColor &&
        other.highlightColor == highlightColor;
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
    volumeMode,
    splitScreenEnabled,
    immersiveMode,
    appTheme,
    fetchOnlineMusic,
    deviceSkin,
    noteFontColor,
    noteFontSize,
    screenBackgroundColor,
    fontColor,
    highlightColor,
  ]);
}
