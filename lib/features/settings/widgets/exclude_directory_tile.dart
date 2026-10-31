import 'package:flutter/cupertino.dart';
import 'package:retropod/core/constants/app_palette.dart';
import 'package:retropod/core/extensions/build_context_extensions.dart';
import 'package:retropod/core/widgets/marquee_text.dart';
import 'package:retropod/features/settings/models/exclude_directory_model.dart';

class ExcludeDirectoryTile extends StatelessWidget {
  final ExcludeDirectoryModel excludeDirectoryModel;
  final bool isSelected;
  final VoidCallback onTap;
  final List<String> nameFilters;

  const ExcludeDirectoryTile({
    super.key,
    required this.excludeDirectoryModel,
    required this.isSelected,
    required this.onTap,
    this.nameFilters = const [],
  });

  bool get _isExcludedByNameFilter {
    if (excludeDirectoryModel.isExcluded) {
      return false;
    }
    final String path = excludeDirectoryModel.directoryPath.toLowerCase();
    return nameFilters.any((filter) => path.contains(filter.toLowerCase()));
  }

  @override
  Widget build(BuildContext context) {
    final bool isExcludedByNameFilter = _isExcludedByNameFilter;
    final Color textColor = isSelected
        ? context.appInverseTextColor
        : isExcludedByNameFilter
        ? context.appSecondaryTextColor
        : context.appPrimaryTextColor;
    final Widget trailingIcon;
    if (excludeDirectoryModel.isExcluded) {
      trailingIcon = const Icon(
        CupertinoIcons.xmark_square_fill,
        color: AppPalette.lowBatteryBarGradientColor2,
      );
    } else if (isExcludedByNameFilter) {
      trailingIcon = const Icon(
        CupertinoIcons.minus_circle,
        color: AppPalette.lowBatteryBarGradientColor2,
      );
    } else {
      trailingIcon = const Icon(
        CupertinoIcons.checkmark_alt_circle_fill,
        color: AppPalette.batteryBarGradientColor6,
      );
    }
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
                    excludeDirectoryModel.directoryPath,
                    mode: TextScrollMode.bouncing,
                    intervalSpaces: null,
                    delayBefore: const Duration(seconds: 2),
                    pauseBetween: const Duration(seconds: 2),
                    pauseOnBounce: const Duration(seconds: 2),
                    style: CupertinoTheme.of(context).textTheme.textStyle
                        .copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                          overflow: TextOverflow.ellipsis,
                        ),
                  ),
                ),
                const SizedBox(width: 5),
                trailingIcon,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
