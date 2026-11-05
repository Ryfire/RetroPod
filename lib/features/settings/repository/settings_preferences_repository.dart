import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retropod/core/constants/constants.dart';
import 'package:retropod/core/models/shared_preference_keys.dart';
import 'package:retropod/core/providers/shared_preferences_with_cache_provider.dart';
import 'package:retropod/core/utils/rating_snapshot.dart';
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
import 'package:retropod/features/settings/models/sleep_timer_action.dart';
import 'package:retropod/features/settings/models/status_bar_clock_format.dart';
import 'package:retropod/features/settings/models/volume_mode.dart';
import 'package:shared_preferences/shared_preferences.dart';

final settingsPreferencesRepositoryProvider =
    Provider.autoDispose<SettingsPreferencesRepository>((ref) {
      return SettingsPreferencesRepository(
        ref.read(sharedPreferencesWithCacheProvider).requireValue,
      );
    });

class SettingsPreferencesRepository {
  final SharedPreferencesWithCache _sharedPreferencesWithCache;

  SettingsPreferencesRepository(this._sharedPreferencesWithCache);

  String getLanguageLocaleCode() {
    return _sharedPreferencesWithCache.getString(
          SharedPreferencesKeys.languageLocaleCode.name,
        ) ??
        Constants.defaultLanguageLocaleCode;
  }

  String getDeviceColor() {
    return _sharedPreferencesWithCache.getString(
          SharedPreferencesKeys.deviceColor.name,
        ) ??
        DeviceColor.silver.name;
  }

  String getClickWheelSize() {
    return _sharedPreferencesWithCache.getString(
          SharedPreferencesKeys.clickWheelSize.name,
        ) ??
        ClickWheelSize.medium.name;
  }

  String getClickWheelSpeed() {
    final String? storedSpeedName = _sharedPreferencesWithCache.getString(
      SharedPreferencesKeys.clickWheelSpeed.name,
    );
    if (storedSpeedName != null) {
      return ClickWheelSpeed.fromName(storedSpeedName).name;
    }
    // One-time migration from the retired sensitivity and step settings:
    // their combined effect is preserved as the nearest speed value. The
    // legacy keys stay readable until every installation has migrated.
    return ClickWheelSpeed.fromLegacyNames(
      sensitivityName: _sharedPreferencesWithCache.getString(
        SharedPreferencesKeys.clickWheelSensitivity.name,
      ),
      stepName: _sharedPreferencesWithCache.getString(
        SharedPreferencesKeys.clickWheelStep.name,
      ),
    ).name;
  }

  String getClickWheelAcceleration() {
    return _sharedPreferencesWithCache.getString(
          SharedPreferencesKeys.clickWheelAcceleration.name,
        ) ??
        ClickWheelAcceleration.normal.name;
  }

  bool getTouchScreenEnabled() {
    return _sharedPreferencesWithCache.getBool(
          SharedPreferencesKeys.isTouchScreenEnabled.name,
        ) ??
        true;
  }

  String getRepeatMode() {
    return _sharedPreferencesWithCache.getString(
          SharedPreferencesKeys.repeatMode.name,
        ) ??
        RepeatMode.off.name;
  }

  bool getVibrate() {
    return _sharedPreferencesWithCache.getBool(
          SharedPreferencesKeys.vibrate.name,
        ) ??
        true;
  }

  bool getSplitScreenEnabled() {
    return _sharedPreferencesWithCache.getBool(
          SharedPreferencesKeys.splitScreenEnabled.name,
        ) ??
        true;
  }

  bool getClickWheelSound() {
    return _sharedPreferencesWithCache.getBool(
          SharedPreferencesKeys.clickWheelSound.name,
        ) ??
        false;
  }

  String getClickWheelSoundChoice() {
    return _sharedPreferencesWithCache.getString(
          SharedPreferencesKeys.clickWheelSoundChoice.name,
        ) ??
        ClickWheelSoundChoice.classic.name;
  }

  String getClickWheelVolumeLevel() {
    return _sharedPreferencesWithCache.getString(
          SharedPreferencesKeys.clickWheelVolume.name,
        ) ??
        ClickWheelVolumeLevel.max.name;
  }

  String getVolumeMode() {
    return _sharedPreferencesWithCache.getString(
          SharedPreferencesKeys.volumeMode.name,
        ) ??
        VolumeMode.app.name;
  }

  String getAppTheme() {
    return _sharedPreferencesWithCache.getString(
          SharedPreferencesKeys.appTheme.name,
        ) ??
        AppTheme.light.name;
  }

  bool getImmersiveMode() {
    return _sharedPreferencesWithCache.getBool(
          SharedPreferencesKeys.immersiveMode.name,
        ) ??
        false;
  }

  String getDeviceSkin() {
    return _sharedPreferencesWithCache.getString(
          SharedPreferencesKeys.deviceSkin.name,
        ) ??
        DeviceSkin.classic.name;
  }

  String getNoteFontColor() {
    return _sharedPreferencesWithCache.getString(
          SharedPreferencesKeys.noteFontColor.name,
        ) ??
        NoteFontColor.theme.name;
  }

  int getNoteFontSize() {
    final size = _sharedPreferencesWithCache.getInt(
      SharedPreferencesKeys.noteFontSize.name,
    );
    if (size == null || size < Constants.minNoteFontSize) {
      return Constants.defaultNoteFontSize;
    }
    return size.clamp(Constants.minNoteFontSize, Constants.maxNoteFontSize);
  }

  bool getAutoSaveNoteReadingPosition() {
    return _sharedPreferencesWithCache.getBool(
          SharedPreferencesKeys.autoSaveNoteReadingPosition.name,
        ) ??
        false;
  }

  bool getNoteReaderHideStatusBar() {
    return _sharedPreferencesWithCache.getBool(
          SharedPreferencesKeys.noteReaderHideStatusBar.name,
        ) ??
        false;
  }

  String getSeekInterval() {
    return _sharedPreferencesWithCache.getString(
          SharedPreferencesKeys.seekInterval.name,
        ) ??
        SeekInterval.five.name;
  }

  String getSleepTimerAction() {
    return _sharedPreferencesWithCache.getString(
          SharedPreferencesKeys.sleepTimerAction.name,
        ) ??
        SleepTimerAction.stopMusic.name;
  }

  bool getShowStatusBarClock() {
    return _sharedPreferencesWithCache.getBool(
          SharedPreferencesKeys.showStatusBarClock.name,
        ) ??
        false;
  }

  String getStatusBarClockFormat() {
    return _sharedPreferencesWithCache.getString(
          SharedPreferencesKeys.statusBarClockFormat.name,
        ) ??
        StatusBarClockFormat.twentyFourHour.name;
  }

  String getScreenBackgroundColor() {
    return _sharedPreferencesWithCache.getString(
          SharedPreferencesKeys.screenBackgroundColor.name,
        ) ??
        ScreenColor.theme.name;
  }

  String getFontColor() {
    return _sharedPreferencesWithCache.getString(
          SharedPreferencesKeys.fontColor.name,
        ) ??
        ScreenColor.theme.name;
  }

  String getHighlightColor() {
    return _sharedPreferencesWithCache.getString(
          SharedPreferencesKeys.highlightColor.name,
        ) ??
        ScreenColor.theme.name;
  }

  Future<void> setLanguageLocaleCode({
    required String languageLocaleCode,
  }) async {
    return _sharedPreferencesWithCache.setString(
      SharedPreferencesKeys.languageLocaleCode.name,
      languageLocaleCode,
    );
  }

  Future<void> setDeviceColor({required String deviceColorName}) async {
    return _sharedPreferencesWithCache.setString(
      SharedPreferencesKeys.deviceColor.name,
      deviceColorName,
    );
  }

  Future<void> setClickWheelSize({required String clickWheelSizeName}) async {
    return _sharedPreferencesWithCache.setString(
      SharedPreferencesKeys.clickWheelSize.name,
      clickWheelSizeName,
    );
  }

  Future<void> setClickWheelSpeed({required String clickWheelSpeedName}) async {
    return _sharedPreferencesWithCache.setString(
      SharedPreferencesKeys.clickWheelSpeed.name,
      clickWheelSpeedName,
    );
  }

  Future<void> setClickWheelAcceleration({
    required String clickWheelAccelerationName,
  }) async {
    return _sharedPreferencesWithCache.setString(
      SharedPreferencesKeys.clickWheelAcceleration.name,
      clickWheelAccelerationName,
    );
  }

  Future<void> setTouchScreenEnabled({
    required bool isTouchScreenEnabled,
  }) async {
    return _sharedPreferencesWithCache.setBool(
      SharedPreferencesKeys.isTouchScreenEnabled.name,
      isTouchScreenEnabled,
    );
  }

  Future<void> setRepeatMode({required String repeatModeName}) async {
    return _sharedPreferencesWithCache.setString(
      SharedPreferencesKeys.repeatMode.name,
      repeatModeName,
    );
  }

  Future<void> setVibrate({required bool isVibrateEnabled}) async {
    return _sharedPreferencesWithCache.setBool(
      SharedPreferencesKeys.vibrate.name,
      isVibrateEnabled,
    );
  }

  Future<void> setClickWheelSound({
    required bool isClickWheelSoundEnabled,
  }) async {
    return _sharedPreferencesWithCache.setBool(
      SharedPreferencesKeys.clickWheelSound.name,
      isClickWheelSoundEnabled,
    );
  }

  Future<void> setClickWheelSoundChoice({
    required String clickWheelSoundChoiceName,
  }) async {
    return _sharedPreferencesWithCache.setString(
      SharedPreferencesKeys.clickWheelSoundChoice.name,
      clickWheelSoundChoiceName,
    );
  }

  Future<void> setClickWheelVolumeLevel({
    required String clickWheelVolumeLevelName,
  }) async {
    return _sharedPreferencesWithCache.setString(
      SharedPreferencesKeys.clickWheelVolume.name,
      clickWheelVolumeLevelName,
    );
  }

  Future<void> setVolumeMode({required String volumeModeName}) async {
    return _sharedPreferencesWithCache.setString(
      SharedPreferencesKeys.volumeMode.name,
      volumeModeName,
    );
  }

  Future<void> setAppTheme({required String appThemeName}) async {
    return _sharedPreferencesWithCache.setString(
      SharedPreferencesKeys.appTheme.name,
      appThemeName,
    );
  }

  Future<void> setSplitScreenEnabled({
    required bool isSplitScreenEnabled,
  }) async {
    return _sharedPreferencesWithCache.setBool(
      SharedPreferencesKeys.splitScreenEnabled.name,
      isSplitScreenEnabled,
    );
  }

  Future<void> setImmersiveMode({required bool isImmersiveModeEnabled}) async {
    return _sharedPreferencesWithCache.setBool(
      SharedPreferencesKeys.immersiveMode.name,
      isImmersiveModeEnabled,
    );
  }

  Future<void> setDeviceSkin({required String deviceSkinName}) async {
    return _sharedPreferencesWithCache.setString(
      SharedPreferencesKeys.deviceSkin.name,
      deviceSkinName,
    );
  }

  Future<void> setNoteFontColor({required String noteFontColorName}) async {
    return _sharedPreferencesWithCache.setString(
      SharedPreferencesKeys.noteFontColor.name,
      noteFontColorName,
    );
  }

  Future<void> setNoteFontSize({required int noteFontSize}) async {
    return _sharedPreferencesWithCache.setInt(
      SharedPreferencesKeys.noteFontSize.name,
      noteFontSize.clamp(Constants.minNoteFontSize, Constants.maxNoteFontSize),
    );
  }

  Future<void> setAutoSaveNoteReadingPosition({
    required bool isAutoSaveNoteReadingPositionEnabled,
  }) async {
    return _sharedPreferencesWithCache.setBool(
      SharedPreferencesKeys.autoSaveNoteReadingPosition.name,
      isAutoSaveNoteReadingPositionEnabled,
    );
  }

  Future<void> setNoteReaderHideStatusBar({
    required bool isNoteReaderHideStatusBarEnabled,
  }) async {
    return _sharedPreferencesWithCache.setBool(
      SharedPreferencesKeys.noteReaderHideStatusBar.name,
      isNoteReaderHideStatusBarEnabled,
    );
  }

  Future<void> setSeekInterval({required String seekIntervalName}) async {
    return _sharedPreferencesWithCache.setString(
      SharedPreferencesKeys.seekInterval.name,
      seekIntervalName,
    );
  }

  Future<void> setSleepTimerAction({
    required String sleepTimerActionName,
  }) async {
    return _sharedPreferencesWithCache.setString(
      SharedPreferencesKeys.sleepTimerAction.name,
      sleepTimerActionName,
    );
  }

  Future<void> setShowStatusBarClock({
    required bool isShowStatusBarClockEnabled,
  }) async {
    return _sharedPreferencesWithCache.setBool(
      SharedPreferencesKeys.showStatusBarClock.name,
      isShowStatusBarClockEnabled,
    );
  }

  Future<void> setStatusBarClockFormat({
    required String statusBarClockFormatName,
  }) async {
    return _sharedPreferencesWithCache.setString(
      SharedPreferencesKeys.statusBarClockFormat.name,
      statusBarClockFormatName,
    );
  }

  Future<void> setScreenBackgroundColor({
    required String screenBackgroundColorName,
  }) async {
    return _sharedPreferencesWithCache.setString(
      SharedPreferencesKeys.screenBackgroundColor.name,
      screenBackgroundColorName,
    );
  }

  Future<void> setFontColor({required String fontColorName}) async {
    return _sharedPreferencesWithCache.setString(
      SharedPreferencesKeys.fontColor.name,
      fontColorName,
    );
  }

  Future<void> setHighlightColor({required String highlightColorName}) async {
    return _sharedPreferencesWithCache.setString(
      SharedPreferencesKeys.highlightColor.name,
      highlightColorName,
    );
  }

  /// Returns the `filePath -> rating` snapshot saved before a library rescan
  /// so star ratings (the Starred playlist) can be restored afterwards.
  Map<String, int> getRatingSnapshot() {
    return decodeRatingSnapshot(
      _sharedPreferencesWithCache.getString(
        SharedPreferencesKeys.ratingSnapshot.name,
      ),
    );
  }

  Future<void> setRatingSnapshot({required Map<String, int> ratingSnapshot}) {
    return _sharedPreferencesWithCache.setString(
      SharedPreferencesKeys.ratingSnapshot.name,
      encodeRatingSnapshot(ratingSnapshot),
    );
  }

  Future<void> clearRatingSnapshot() {
    return _sharedPreferencesWithCache.remove(
      SharedPreferencesKeys.ratingSnapshot.name,
    );
  }
}
