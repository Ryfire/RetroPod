import 'package:retropod/core/constants/constants.dart';
import 'package:retropod/features/settings/models/app_theme.dart';
import 'package:retropod/features/settings/models/click_wheel_acceleration.dart';
import 'package:retropod/features/settings/models/click_wheel_sensitivity.dart';
import 'package:retropod/features/settings/models/click_wheel_size.dart';
import 'package:retropod/features/settings/models/click_wheel_step.dart';
import 'package:retropod/features/settings/models/device_color.dart';
import 'package:retropod/features/settings/models/device_skin.dart';
import 'package:retropod/features/settings/models/note_font_color.dart';
import 'package:retropod/features/settings/models/repeat_mode.dart';
import 'package:retropod/features/settings/models/volume_mode.dart';

class SettingsPreferencesModel {
  final String languageLocaleCode;
  final DeviceColor deviceColor;
  final ClickWheelSize clickWheelSize;
  final ClickWheelSensitivity clickWheelSensitivity;
  final ClickWheelStep clickWheelStep;
  final ClickWheelAcceleration clickWheelAcceleration;
  final bool isTouchScreenEnabled;
  final RepeatMode repeatMode;
  final bool vibrate;
  final bool clickWheelSound;
  final VolumeMode volumeMode;
  final bool splitScreenEnabled;
  final bool immersiveMode;
  final bool fetchOnlineMusic;
  final AppTheme appTheme;
  final DeviceSkin deviceSkin;
  final NoteFontColor noteFontColor;
  final int noteFontSize;

  SettingsPreferencesModel({
    required this.languageLocaleCode,
    required this.deviceColor,
    required this.clickWheelSize,
    required this.clickWheelSensitivity,
    required this.clickWheelStep,
    required this.clickWheelAcceleration,
    required this.isTouchScreenEnabled,
    required this.repeatMode,
    required this.vibrate,
    required this.clickWheelSound,
    required this.volumeMode,
    required this.splitScreenEnabled,
    required this.immersiveMode,
    required this.appTheme,
    this.fetchOnlineMusic = false,
    this.deviceSkin = DeviceSkin.classic,
    this.noteFontColor = NoteFontColor.theme,
    this.noteFontSize = Constants.defaultNoteFontSize,
  });

  SettingsPreferencesModel copyWith({
    String? languageLocaleCode,
    DeviceColor? deviceColor,
    ClickWheelSize? clickWheelSize,
    ClickWheelSensitivity? clickWheelSensitivity,
    ClickWheelStep? clickWheelStep,
    ClickWheelAcceleration? clickWheelAcceleration,
    bool? isTouchScreenEnabled,
    RepeatMode? repeatMode,
    bool? vibrate,
    bool? clickWheelSound,
    VolumeMode? volumeMode,
    bool? splitScreenEnabled,
    bool? immersiveMode,
    bool? fetchOnlineMusic,
    AppTheme? appTheme,
    DeviceSkin? deviceSkin,
    NoteFontColor? noteFontColor,
    int? noteFontSize,
  }) {
    return SettingsPreferencesModel(
      languageLocaleCode: languageLocaleCode ?? this.languageLocaleCode,
      deviceColor: deviceColor ?? this.deviceColor,
      clickWheelSize: clickWheelSize ?? this.clickWheelSize,
      clickWheelSensitivity:
          clickWheelSensitivity ?? this.clickWheelSensitivity,
      clickWheelStep: clickWheelStep ?? this.clickWheelStep,
      clickWheelAcceleration:
          clickWheelAcceleration ?? this.clickWheelAcceleration,
      isTouchScreenEnabled: isTouchScreenEnabled ?? this.isTouchScreenEnabled,
      repeatMode: repeatMode ?? this.repeatMode,
      vibrate: vibrate ?? this.vibrate,
      clickWheelSound: clickWheelSound ?? this.clickWheelSound,
      volumeMode: volumeMode ?? this.volumeMode,
      splitScreenEnabled: splitScreenEnabled ?? this.splitScreenEnabled,
      immersiveMode: immersiveMode ?? this.immersiveMode,
      appTheme: appTheme ?? this.appTheme,
      fetchOnlineMusic: fetchOnlineMusic ?? this.fetchOnlineMusic,
      deviceSkin: deviceSkin ?? this.deviceSkin,
      noteFontColor: noteFontColor ?? this.noteFontColor,
      noteFontSize: noteFontSize ?? this.noteFontSize,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is SettingsPreferencesModel &&
        other.languageLocaleCode == languageLocaleCode &&
        other.deviceColor == deviceColor &&
        other.clickWheelSize == clickWheelSize &&
        other.clickWheelSensitivity == clickWheelSensitivity &&
        other.clickWheelStep == clickWheelStep &&
        other.clickWheelAcceleration == clickWheelAcceleration &&
        other.isTouchScreenEnabled == isTouchScreenEnabled &&
        other.repeatMode == repeatMode &&
        other.vibrate == vibrate &&
        other.clickWheelSound == clickWheelSound &&
        other.volumeMode == volumeMode &&
        other.splitScreenEnabled == splitScreenEnabled &&
        other.immersiveMode == immersiveMode &&
        other.fetchOnlineMusic == fetchOnlineMusic &&
        other.deviceSkin == deviceSkin &&
        other.appTheme == appTheme &&
        other.noteFontColor == noteFontColor &&
        other.noteFontSize == noteFontSize;
  }

  @override
  int get hashCode => Object.hash(
    languageLocaleCode,
    deviceColor,
    clickWheelSize,
    clickWheelSensitivity,
    clickWheelStep,
    clickWheelAcceleration,
    isTouchScreenEnabled,
    repeatMode,
    vibrate,
    clickWheelSound,
    volumeMode,
    splitScreenEnabled,
    immersiveMode,
    appTheme,
    fetchOnlineMusic,
    deviceSkin,
    noteFontColor,
    noteFontSize,
  );
}
