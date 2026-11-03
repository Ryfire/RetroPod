import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retropod/core/constants/app_palette.dart';
import 'package:retropod/core/extensions/build_context_extensions.dart';
import 'package:retropod/core/navigation/routes.dart';
import 'package:retropod/features/custom_screen_elements/custom_screen.dart';
import 'package:retropod/features/settings/controller/settings_preferences_controller.dart';
import 'package:retropod/features/settings/models/screen_color.dart';
import 'package:retropod/features/status_bar/widgets/status_bar.dart';

/// Which preference a [ScreenColorScreen] instance edits.
enum ScreenColorRole { background, font, highlight }

/// Picker screen shared by the Screen Background and Font Color settings.
/// Rows show the swatch of each [ScreenColor]; the theme option is drawn as
/// a black-to-white gradient circle.
class ScreenColorScreen extends ConsumerStatefulWidget {
  final Routes route;
  final ScreenColorRole role;

  const ScreenColorScreen({super.key, required this.route, required this.role});

  @override
  ConsumerState<ScreenColorScreen> createState() => _ScreenColorScreenState();
}

class _ScreenColorScreenState extends ConsumerState<ScreenColorScreen>
    with CustomScreen {
  @override
  String get routeName => widget.route.name;

  @override
  List<ScreenColor> get displayItems => ScreenColor.values;

  @override
  Future<void> onSelectPressed() => _selectColor(selectedDisplayItem);

  Future<void> _selectColor(int index) async {
    setState(() => selectedDisplayItem = index);
    final ScreenColor screenColor = displayItems[index];
    switch (widget.role) {
      case ScreenColorRole.background:
        await ref
            .read(settingsPreferencesControllerProvider.notifier)
            .setScreenBackgroundColor(screenColor);
        break;
      case ScreenColorRole.font:
        await ref
            .read(settingsPreferencesControllerProvider.notifier)
            .setFontColor(screenColor);
        break;
      case ScreenColorRole.highlight:
        await ref
            .read(settingsPreferencesControllerProvider.notifier)
            .setHighlightColor(screenColor);
        break;
    }
  }

  String _screenTitle(BuildContext context) {
    switch (widget.role) {
      case ScreenColorRole.background:
        return context.localization.screenBackgroundColorSettingTitle;
      case ScreenColorRole.font:
        return context.localization.fontColorSettingTitle;
      case ScreenColorRole.highlight:
        return context.localization.highlightColorSettingTitle;
    }
  }

  String _optionTitle(BuildContext context, ScreenColor screenColor) {
    switch (widget.role) {
      case ScreenColorRole.background:
        return screenColor.backgroundTitle(context);
      case ScreenColorRole.font:
        return screenColor.fontTitle(context);
      case ScreenColorRole.highlight:
        return screenColor.highlightTitle(context);
    }
  }

  /// Background rows show the light gradient end, font rows the darker end
  /// so the font palette reads as saturated text colors.
  Color? _swatchOf(ScreenColor screenColor) {
    switch (widget.role) {
      case ScreenColorRole.background:
        return screenColor.backgroundColor;
      case ScreenColorRole.font:
        return screenColor.fontSwatchColor;
      case ScreenColorRole.highlight:
        return screenColor.highlightSwatchColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: Column(
        children: [
          StatusBar(title: _screenTitle(context)),
          Flexible(
            child: CupertinoScrollbar(
              controller: scrollController,
              child: ListView.builder(
                controller: scrollController,
                itemCount: displayItems.length,
                prototypeItem: _ScreenColorOptionTile(
                  screenColor: displayItems.first,
                  swatchOf: _swatchOf,
                  optionTitle: _optionTitle,
                  isSelected: false,
                  onTap: () {},
                ),
                itemBuilder: (context, index) {
                  final screenColor = displayItems[index];
                  final isSelected = selectedDisplayItem == index;
                  return _ScreenColorOptionTile(
                    screenColor: screenColor,
                    swatchOf: _swatchOf,
                    optionTitle: _optionTitle,
                    isSelected: isSelected,
                    onTap: () async => _selectColor(index),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScreenColorOptionTile extends StatelessWidget {
  final ScreenColor screenColor;
  final Color? Function(ScreenColor) swatchOf;
  final String Function(BuildContext, ScreenColor) optionTitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _ScreenColorOptionTile({
    required this.screenColor,
    required this.swatchOf,
    required this.optionTitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color? color = swatchOf(screenColor);
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        height: 30,
        width: double.infinity,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: isSelected
                ? const Border(
                    top: BorderSide(
                      color: AppPalette.selectedTileTopBorderColor,
                    ),
                    bottom: BorderSide(
                      color: AppPalette.selectedTileBottomBorderColor,
                    ),
                  )
                : null,
            gradient: isSelected
                ? const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppPalette.selectedTileGradientColor1,
                      AppPalette.selectedTileGradientColor2,
                    ],
                  )
                : null,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color,
                    gradient: color == null
                        ? const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              CupertinoColors.black,
                              CupertinoColors.white,
                            ],
                          )
                        : null,
                    border: Border.all(
                      color: context.appOutlineColor,
                      width: 1.5,
                    ),
                  ),
                  child: const SizedBox(height: 18, width: 18),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    optionTitle(context, screenColor),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? context.appInverseTextColor
                          : context.appPrimaryTextColor,
                    ),
                    maxLines: 1,
                  ),
                ),
                if (isSelected)
                  Icon(
                    CupertinoIcons.right_chevron,
                    color: context.appInverseTextColor,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
