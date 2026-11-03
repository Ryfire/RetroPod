import 'package:flutter/cupertino.dart';
import 'package:retropod/core/extensions/build_context_extensions.dart';
import 'package:retropod/core/widgets/display_list_tile.dart';

/// Live preview of how the Screen Background, Font Color and Highlight
/// Color settings combine, shown in the split screen pane while browsing
/// the Screen Colors screen and its color pickers.
class ScreenColorsPreviewWidget extends StatelessWidget {
  const ScreenColorsPreviewWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(color: context.appBackgroundColor),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                context.localization.screenColorsSettingTitle,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: context.appPrimaryTextColor,
                ),
              ),
            ),
            const DisplayListTile(text: 'Music', isSelected: false),
            const DisplayListTile(text: 'Videos', isSelected: true),
            const DisplayListTile(text: 'Extras', isSelected: false),
            const DisplayListTile(text: 'Photos', isSelected: false),
            const DisplayListTile(text: 'Settings', isSelected: false),
          ],
        ),
      ),
    );
  }
}
