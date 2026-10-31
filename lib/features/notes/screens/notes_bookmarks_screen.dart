import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:retropod/core/extensions/build_context_extensions.dart';
import 'package:retropod/core/navigation/routes.dart';
import 'package:retropod/core/widgets/display_list_tile.dart';
import 'package:retropod/core/widgets/empty_state_widget.dart';
import 'package:retropod/core/widgets/fast_scroll_indicator.dart';
import 'package:retropod/features/custom_screen_elements/custom_screen.dart';
import 'package:retropod/features/notes/models/note_file_model.dart';
import 'package:retropod/features/notes/services/notes_service.dart';
import 'package:retropod/features/status_bar/widgets/status_bar.dart';

class NotesBookmarksScreen extends ConsumerStatefulWidget {
  const NotesBookmarksScreen({super.key});

  @override
  ConsumerState<NotesBookmarksScreen> createState() =>
      _NotesBookmarksScreenState();
}

class _NotesBookmarksScreenState extends ConsumerState<NotesBookmarksScreen>
    with CustomScreen {
  Set<String> _bookmarkedPaths = const <String>{};

  @override
  String get routeName => Routes.notesBookmarks.name;

  @override
  int get extraDisplayItems => 0;

  @override
  void initState() {
    super.initState();
    unawaited(_loadBookmarkedPaths());
  }

  Future<void> _loadBookmarkedPaths() async {
    final paths = await ref
        .read(notesServiceProvider.notifier)
        .getBookmarkedPaths();
    if (!mounted) {
      return;
    }
    setState(() => _bookmarkedPaths = paths);
  }

  List<NoteFileModel> get _bookmarkedNotes => filterBookmarkedNotes(
    ref.watch(notesServiceProvider).value ?? const [],
    _bookmarkedPaths,
  );

  @override
  List<String> get displayItems =>
      _bookmarkedNotes.map((note) => note.name).toList();

  @override
  void onSelectPressed() {
    final notes = _bookmarkedNotes;
    final index = selectedDisplayItem;
    if (index < notes.length) {
      unawaited(_openNote(notes[index]));
    }
  }

  @override
  void onSelectLongPress() {
    final notes = _bookmarkedNotes;
    final index = selectedDisplayItem;
    if (index < notes.length) {
      unawaited(_removeBookmark(notes[index]));
    }
  }

  Future<void> _openNote(NoteFileModel note) async {
    await context.pushNamed(Routes.noteViewer.name, extra: note);
    await _loadBookmarkedPaths();
  }

  Future<void> _removeBookmark(NoteFileModel note) async {
    await ref.read(notesServiceProvider.notifier).removeBookmark(note.path);
    await _loadBookmarkedPaths();
  }

  @override
  Widget build(BuildContext context) {
    final notesAsync = ref.watch(notesServiceProvider);
    return CupertinoPageScaffold(
      child: Column(
        children: [
          StatusBar(title: Routes.notesBookmarks.title(context)),
          Expanded(
            child: notesAsync.when(
              loading: () => const Center(child: CupertinoActivityIndicator()),
              error: (_, _) => _buildBody(_bookmarkedNotes),
              data: (_) => _buildBody(_bookmarkedNotes),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(List<NoteFileModel> notes) {
    if (notes.isEmpty) {
      return EmptyStateWidget(
        emptyDescription: context.localization.notesBookmarksEmpty,
      );
    }
    return FastScrollIndicator(
      wheelScrollIndex: wheelScrollIndex,
      itemCount: notes.length,
      itemExtent: displayTileHeight,
      labelAt: (index) => notes[index].name,
      child: CupertinoScrollbar(
        controller: scrollController,
        child: ListView.builder(
          controller: scrollController,
          itemCount: notes.length,
          prototypeItem: const DisplayListTile(text: '', isSelected: false),
          itemBuilder: (context, index) {
            final note = notes[index];
            return DisplayListTile(
              text: note.name,
              isSelected: selectedDisplayItem == index,
              onTap: () {
                setState(() => selectedDisplayItem = index);
                unawaited(_openNote(note));
              },
              onLongPress: () => unawaited(_removeBookmark(note)),
            );
          },
        ),
      ),
    );
  }
}
