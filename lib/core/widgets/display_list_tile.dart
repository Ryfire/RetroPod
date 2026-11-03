import 'package:flutter/cupertino.dart';
import 'package:retropod/core/extensions/build_context_extensions.dart';

class DisplayListTile extends StatelessWidget {
  final String text;
  final bool isSelected;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const DisplayListTile({
    super.key,
    required this.text,
    required this.isSelected,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: SizedBox(
        height: 30,
        width: double.infinity,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: isSelected
                ? Border(
                    top: BorderSide(
                      color: context.appHighlightGradient.first,
                    ),
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
                    text,
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
                if (isSelected)
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
