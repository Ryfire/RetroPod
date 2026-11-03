import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retropod/core/constants/constants.dart';
import 'package:retropod/core/models/shared_preference_keys.dart';
import 'package:retropod/core/providers/shared_preferences_with_cache_provider.dart';
import 'package:retropod/core/utils/rating_snapshot.dart';
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

  String getClickWheelSensitivity() {
    return _sharedPreferencesWithCache.getString(
          SharedPreferencesKeys.clickWheelSensitivity.name,
        ) ??
        ClickWheelSensitivity.medium.name;
  }

  String getClickWheelStep() {
    return _sharedPreferencesWithCache.getString(
          SharedPreferencesKeys.clickWheelStep.name,
        ) ??
        ClickWheelStep.normal.name;
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

  Future<void> setClickWheelSensitivity({
    required String clickWheelSensitivityName,
  }) async {
    return _sharedPreferencesWithCache.setString(
      SharedPreferencesKeys.clickWheelSensitivity.name,
      clickWheelSensitivityName,
    );
  }

  Future<void> setClickWheelStep({required String clickWheelStepName}) async {
    return _sharedPreferencesWithCache.setString(
      SharedPreferencesKeys.clickWheelStep.name,
      clickWheelStepName,
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
