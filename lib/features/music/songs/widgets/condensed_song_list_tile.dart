import 'package:flutter/cupertino.dart';
import 'package:retropod/core/extensions/build_context_extensions.dart';

class CondensedSongListTile extends StatelessWidget {
  final String songName;
  final bool isSelected;
  final bool isCurrentlyPlaying;
  final VoidCallback? onTap;

  const CondensedSongListTile({
    super.key,
    required this.songName,
    required this.isSelected,
    required this.isCurrentlyPlaying,
    this.onTap,
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
                ? Border(
                    top: BorderSide(color: context.appHighlightGradient.first),
                    bottom: BorderSide(
                      color: context.appHighlightGradient.last,
                    ),
                  )
                : null,
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
              children: [
                Flexible(
                  child: Text(
                    songName,
                    style: CupertinoTheme.of(context).textTheme.textStyle
                        .copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? context.appHighlightTextColor
                              : context.appPrimaryTextColor,
                        ),
                    maxLines: 1,
                  ),
                ),
                if (isCurrentlyPlaying)
                  Icon(
                    CupertinoIcons.volume_up,
                    color: isSelected
                        ? context.appHighlightTextColor
                        : context.appPrimaryTextColor,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
