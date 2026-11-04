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
