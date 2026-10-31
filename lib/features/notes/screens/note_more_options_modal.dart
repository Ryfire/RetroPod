import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:retropod/core/extensions/build_context_extensions.dart';
import 'package:retropod/core/navigation/routes.dart';
import 'package:retropod/core/widgets/options_list_tile.dart';
import 'package:retropod/features/custom_screen_elements/custom_screen.dart';
import 'package:retropod/features/notes/models/note_file_model.dart';
import 'package:retropod/features/notes/services/notes_service.dart';

enum _NoteMoreOptions {
  bookmark,
  cancel;

  String title(BuildContext context, {required bool hasBookmark}) {
    switch (this) {
      case bookmark:
        return hasBookmark
            ? context.localization.noteMenuRemoveBookmark
            : context.localization.noteMenuBookmark;
      case cancel:
        return context.localization.cancelText;
    }
  }
}

class NoteMoreOptionsModal extends ConsumerStatefulWidget {
  const NoteMoreOptionsModal({
    super.key,
    required this.note,
    required this.pageOffset,
  });

  final NoteFileModel note;
  final int pageOffset;

  @override
  ConsumerState createState() => _NoteMoreOptionsModalState();
}

class _NoteMoreOptionsModalState extends ConsumerState<NoteMoreOptionsModal>
    with CustomScreen {
  bool _hasBookmark = false;

  @override
  String get routeName => Routes.noteMoreOptions.name;

  @override
  List<_NoteMoreOptions> get displayItems => _NoteMoreOptions.values;

  @override
  Future<void> onSelectPressed() =>
      _handleOption(_NoteMoreOptions.values[selectedDisplayItem]);

  @override
  void initState() {
    super.initState();
    unawaited(_loadBookmarkState());
  }

  Future<void> _loadBookmarkState() async {
    final bookmark = await ref
        .read(notesServiceProvider.notifier)
        .getBookmarkOffset(widget.note.path);
    if (!mounted) {
      return;
    }
    setState(() => _hasBookmark = bookmark != null);
  }

  Future<void> _handleOption(_NoteMoreOptions optionItem) async {
    setState(() => selectedDisplayItem = displayItems.indexOf(optionItem));
    switch (optionItem) {
      case _NoteMoreOptions.bookmark:
        if (widget.note.path.isNotEmpty) {
          if (_hasBookmark) {
            await ref
                .read(notesServiceProvider.notifier)
                .removeBookmark(widget.note.path);
          } else {
            await ref
                .read(notesServiceProvider.notifier)
                .setBookmarkOffset(widget.note.path, widget.pageOffset);
          }
        }
        if (mounted) {
          context.pop();
        }
        break;
      case _NoteMoreOptions.cancel:
        context.pop();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.appSurfaceColor,
        border: Border.all(color: context.appOutlineColor),
      ),
      child: ListView.builder(
        shrinkWrap: true,
        controller: scrollController,
        itemCount: displayItems.length,
        prototypeItem: const OptionsListTile(text: '', isSelected: false),
        itemBuilder: (context, index) {
          return OptionsListTile(
            text: displayItems[index].title(context, hasBookmark: _hasBookmark),
            isSelected: index == selectedDisplayItem,
            onTap: () => unawaited(_handleOption(displayItems[index])),
          );
        },
      ),
    );
  }
}
