import 'package:flutter/cupertino.dart';
import 'package:retropod/core/constants/app_palette.dart';

class EmptyStateWidget extends StatelessWidget {
  final String emptyDescription;

  /// Optional second line shown under the description in smaller, lighter
  /// text, e.g. guidance on how to add items. When set the icon switches
  /// from the music note to a document icon to match the guidance context.
  final String? emptySubtitle;

  const EmptyStateWidget({
    super.key,
    required this.emptyDescription,
    this.emptySubtitle,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppPalette.darkScreenBackgroundGradient1,
              AppPalette.darkScreenBackgroundGradient2,
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              emptySubtitle == null
                  ? CupertinoIcons.music_note_2
                  : CupertinoIcons.doc_text,
              size: 65,
              color: CupertinoColors.white,
            ),
            const SizedBox(height: 20),
            Text(
              emptyDescription,
              style: const TextStyle(
                fontSize: 20,
                color: CupertinoColors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (emptySubtitle != null) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  emptySubtitle!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    color: CupertinoColors.systemGrey,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
