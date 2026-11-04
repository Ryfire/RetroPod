import 'package:flutter/cupertino.dart';
import 'package:retropod/core/constants/app_palette.dart';
import 'package:retropod/core/extensions/build_context_extensions.dart';
import 'package:retropod/features/music/playlist/models/playlist_model.dart';

class PlaylistListTile extends StatelessWidget {
  final PlaylistModel playlistModel;
  final bool isSelected;
  final VoidCallback onTap;

  const PlaylistListTile({
    super.key,
    required this.playlistModel,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkTheme =
        CupertinoTheme.of(context).brightness == Brightness.dark;
    final borderColor = isDarkTheme
        ? AppPalette.darkListTileBorderColor
        : AppPalette.lightListTileBorderColor;
    final Border? tileBorder = isSelected
        ? null
        : Border(bottom: BorderSide(color: borderColor));

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        height: 54,
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
            border: tileBorder,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        playlistModel.name,
                        style: CupertinoTheme.of(context).textTheme.textStyle
                            .copyWith(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isSelected
                                  ? context.appHighlightTextColor
                                  : context.appPrimaryTextColor,
                            ),
                        maxLines: 1,
                      ),
                      Text(
                        context.localization.nSongs(playlistModel.songs.length),
                        style: CupertinoTheme.of(context).textTheme.textStyle
                            .copyWith(
                              color: isSelected
                                  ? context.appHighlightTextColor
                                  : context.appSecondaryTextColor,
                            ),
                        maxLines: 1,
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Icon(
                    CupertinoIcons.chevron_right,
                    size: 18,
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
