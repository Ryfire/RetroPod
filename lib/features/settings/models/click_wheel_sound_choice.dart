import 'package:flutter/cupertino.dart';
import 'package:retropod/core/extensions/build_context_extensions.dart';
import 'package:retropod/core/utils/enum_from_name.dart';

/// The built-in click wheel sound played for every wheel step and device
/// button press.
///
/// All sounds are short bundled assets (15-45 ms, 44.1 kHz, mono) so the
/// low latency audio pool can replay them instantly and overlap ticks
/// when the wheel is spun quickly.
enum ClickWheelSoundChoice {
  classic('sounds/click_classic.wav'),
  soft('sounds/click_soft.wav'),
  sharp('sounds/click_sharp.wav'),
  deep('sounds/click_deep.wav'),
  mechanical('sounds/click_mechanical.wav');

  const ClickWheelSoundChoice(this.assetPath);

  static ClickWheelSoundChoice fromName(String? raw) =>
      enumFromName(values, raw, classic);

  /// The bundled asset path handed to [AssetSource], which prepends the
  /// default `assets/` prefix.
  final String assetPath;

  String title(BuildContext context) {
    switch (this) {
      case classic:
        return context.localization.clickSoundClassic;
      case soft:
        return context.localization.clickSoundSoft;
      case sharp:
        return context.localization.clickSoundSharp;
      case deep:
        return context.localization.clickSoundDeep;
      case mechanical:
        return context.localization.clickSoundMechanical;
    }
  }
}
