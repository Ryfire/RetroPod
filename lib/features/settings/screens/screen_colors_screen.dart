import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:retropod/core/extensions/build_context_extensions.dart';
import 'package:retropod/core/navigation/routes.dart';
import 'package:retropod/features/custom_screen_elements/custom_screen.dart';
import 'package:retropod/features/settings/controller/settings_preferences_controller.dart';
import 'package:retropod/features/settings/models/settings_preferences_model.dart';
import 'package:retropod/features/status_bar/widgets/status_bar.dart';

/// The rows of the consolidated Screen Colors screen.
enum _ScreenColorsItem { background, font, highlight, reset }

/// Consolidated screen listing the Screen Background, Font Color and
/// Highlight Color settings in one place, each with a live preview swatch
/// of its effective color, plus a row that clears all three pins and
/// returns every color to the theme defaults.
class ScreenColorsScreen extends ConsumerStatefulWidget {
  const ScreenColorsScreen({super.key});

  @override
  ConsumerState createState() => _ScreenColorsScreenState();
}

class _ScreenColorsScreenState extends ConsumerState<ScreenColorsScreen>
    with CustomScreen {
  @override
  String get routeName => Routes.screenColors.name;

  @override
  List<_ScreenColorsItem> get displayItems => _ScreenColorsItem.values;

  @override
  Future<void> onSelectPressed() async {
    switch (displayItems[selectedDisplayItem]) {
      case _ScreenColorsItem.background:
        context.goNamed(Routes.screenBackgroundColor.name);
        break;
      case _ScreenColorsItem.font:
        context.goNamed(Routes.fontColor.name);
        break;
      case _ScreenColorsItem.highlight:
        context.goNamed(Routes.highlightColor.name);
        break;
      case _ScreenColorsItem.reset:
        await ref
            .read(settingsPreferencesControllerProvider.notifier)
            .resetScreenColors();
        break;
    }
  }

  String _itemTitle(_ScreenColorsItem item) {
    switch (item) {
      case _ScreenColorsItem.background:
        return context.localization.screenBackgroundColorSettingTitle;
      case _ScreenColorsItem.font:
        return context.localization.fontColorSettingTitle;
      case _ScreenColorsItem.highlight:
        return context.localization.highlightColorSettingTitle;
      case _ScreenColorsItem.reset:
        return context.localization.resetScreenColorsTitle;
    }
  }

  /// The live effective color for each row, so the swatches always show
  /// how the pinned settings combine with the current theme.
  Color? _itemSwatch(_ScreenColorsItem item) {
    switch (item) {
      case _ScreenColorsItem.background:
        return context.appBackgroundColor;
      case _ScreenColorsItem.font:
        return context.appPrimaryTextColor;
      case _ScreenColorsItem.highlight:
        return context.appHighlightColor;
      case _ScreenColorsItem.reset:
        return null;
    }
  }

  String? _itemValue(
    SettingsPreferencesModel settingsState,
    _ScreenColorsItem item,
  ) {
    switch (item) {
      case _ScreenColorsItem.background:
        return settingsState.screenBackgroundColor.backgroundTitle(context);
      case _ScreenColorsItem.font:
        return settingsState.fontColor.fontTitle(context);
      case _ScreenColorsItem.highlight:
        return settingsState.highlightColor.highlightTitle(context);
      case _ScreenColorsItem.reset:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsState = ref.watch(settingsPreferencesControllerProvider);

    return CupertinoPageScaffold(
      child: Column(
        children: [
          StatusBar(title: Routes.screenColors.title(context)),
          Flexible(
            child: CupertinoScrollbar(
              controller: scrollController,
              child: ListView.builder(
                controller: scrollController,
                itemCount: displayItems.length,
                prototypeItem: _ScreenColorsTile(
                  item: _ScreenColorsItem.background,
                  title: '',
                  swatch: null,
                  value: null,
                  isSelected: false,
                  onTap: () {},
                ),
                itemBuilder: (context, index) {
                  final item = displayItems[index];
                  return _ScreenColorsTile(
                    item: item,
                    title: _itemTitle(item),
                    swatch: _itemSwatch(item),
                    value: _itemValue(settingsState, item),
                    isSelected: selectedDisplayItem == index,
                    onTap: onSelectPressed,
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

class _ScreenColorsTile extends StatelessWidget {
  final _ScreenColorsItem item;
  final String title;
  final Color? swatch;
  final String? value;
  final bool isSelected;
  final VoidCallback onTap;

  const _ScreenColorsTile({
    required this.item,
    required this.title,
    required this.swatch,
    required this.value,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        height: 30,
        width: double.infinity,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: context.appHighlightGradient,
                  )
                : null,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              spacing: 5,
              children: [
                if (item == _ScreenColorsItem.reset)
                  Icon(
                    CupertinoIcons.refresh_circled,
                    size: 18,
                    color: isSelected
                        ? context.appHighlightTextColor
                        : context.appPrimaryTextColor,
                  )
                else
                  DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: swatch,
                      border: Border.all(
                        color: context.appOutlineColor,
                        width: 1.5,
                      ),
                    ),
                    child: const SizedBox(height: 18, width: 18),
                  ),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? context.appHighlightTextColor
                          : context.appPrimaryTextColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (value != null)
                  Text(
                    value!,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? context.appHighlightTextColor
                          : context.appSecondaryTextColor,
                    ),
                  ),
                if (value == null && isSelected)
                  Icon(
                    CupertinoIcons.right_chevron,
                    color: context.appHighlightTextColor,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
