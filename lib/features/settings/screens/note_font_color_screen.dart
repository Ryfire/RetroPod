import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retropod/core/constants/app_palette.dart';
import 'package:retropod/core/extensions/build_context_extensions.dart';
import 'package:retropod/core/navigation/routes.dart';
import 'package:retropod/features/custom_screen_elements/custom_screen.dart';
import 'package:retropod/features/settings/controller/settings_preferences_controller.dart';
import 'package:retropod/features/settings/models/note_font_color.dart';
import 'package:retropod/features/status_bar/widgets/status_bar.dart';

class NoteFontColorScreen extends ConsumerStatefulWidget {
  const NoteFontColorScreen({super.key});

  @override
  ConsumerState<NoteFontColorScreen> createState() =>
      _NoteFontColorScreenState();
}

class _NoteFontColorScreenState extends ConsumerState<NoteFontColorScreen>
    with CustomScreen {
  @override
  String get routeName => Routes.noteFontColor.name;

  @override
  List<NoteFontColor> get displayItems => NoteFontColor.values;

  @override
  Future<void> onSelectPressed() => _selectColor(selectedDisplayItem);

  Future<void> _selectColor(int index) async {
    setState(() => selectedDisplayItem = index);
    await ref
        .read(settingsPreferencesControllerProvider.notifier)
        .setNoteFontColor(displayItems[index]);
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: Column(
        children: [
          StatusBar(title: Routes.noteFontColor.title(context)),
          Flexible(
            child: CupertinoScrollbar(
              controller: scrollController,
              child: ListView.builder(
                controller: scrollController,
                itemCount: displayItems.length,
                prototypeItem: _NoteFontColorOptionTile(
                  noteFontColor: displayItems.first,
                  isSelected: false,
                  onTap: () {},
                ),
                itemBuilder: (context, index) {
                  final noteFontColor = displayItems[index];
                  final isSelected = selectedDisplayItem == index;
                  return _NoteFontColorOptionTile(
                    noteFontColor: noteFontColor,
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

class _NoteFontColorOptionTile extends StatelessWidget {
  final NoteFontColor noteFontColor;
  final bool isSelected;
  final VoidCallback onTap;

  const _NoteFontColorOptionTile({
    required this.noteFontColor,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color? textColor = noteFontColor.textColor;
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
                    color: textColor,
                    gradient: textColor == null
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
                    noteFontColor.title(context),
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
