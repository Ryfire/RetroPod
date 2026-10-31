import 'package:flutter/cupertino.dart';
import 'package:retropod/core/constants/app_palette.dart';
import 'package:retropod/core/extensions/build_context_extensions.dart';
import 'package:retropod/core/widgets/marquee_text.dart';

class NameFilterTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final bool isSelected;
  final VoidCallback onTap;

  const NameFilterTile({
    super.key,
    required this.title,
    required this.icon,
    required this.iconColor,
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
                Expanded(
                  child: MarqueeText(
                    title,
                    mode: TextScrollMode.bouncing,
                    intervalSpaces: null,
                    delayBefore: const Duration(seconds: 2),
                    pauseBetween: const Duration(seconds: 2),
                    pauseOnBounce: const Duration(seconds: 2),
                    style: CupertinoTheme.of(context).textTheme.textStyle
                        .copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? context.appInverseTextColor
                              : context.appPrimaryTextColor,
                          overflow: TextOverflow.ellipsis,
                        ),
                  ),
                ),
                const SizedBox(width: 5),
                Icon(icon, color: iconColor),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
