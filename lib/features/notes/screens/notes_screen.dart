import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:retropod/core/extensions/build_context_extensions.dart';
import 'package:retropod/core/navigation/routes.dart';
import 'package:retropod/core/widgets/display_list_tile.dart';
import 'package:retropod/core/widgets/empty_state_widget.dart';
import 'package:retropod/core/widgets/fast_scroll_indicator.dart';
import 'package:retropod/features/custom_screen_elements/custom_screen.dart';
import 'package:retropod/features/notes/models/note_file_model.dart';
import 'package:retropod/features/notes/services/notes_service.dart';
import 'package:retropod/features/status_bar/widgets/status_bar.dart';

class NotesScreen extends ConsumerStatefulWidget {
  const NotesScreen({super.key});

  @override
  ConsumerState<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends ConsumerState<NotesScreen>
    with CustomScreen, WidgetsBindingObserver {
  @override
  String get routeName => Routes.notes.name;

  @override
  int get extraDisplayItems => 3;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_requestStoragePermission());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(ref.read(notesServiceProvider.notifier).refreshSilently());
    }
  }

  List<NoteFileModel> get _notes => ref.watch(notesServiceProvider).value ?? [];

  @override
  List<String> get displayItems => _notes.map((note) => note.name).toList();

  @override
  void onSelectPressed() {
    final notes = _notes;
    final index = selectedDisplayItem;
    if (index == 0) {
      unawaited(context.pushNamed(Routes.notesSearch.name));
    } else if (index == 1) {
      unawaited(context.pushNamed(Routes.notesBookmarks.name));
    } else if (index <= notes.length + 1) {
      unawaited(_openNote(notes[index - 2]));
    } else {
      unawaited(ref.read(notesServiceProvider.notifier).rescan());
    }
  }

  Future<void> _openNote(NoteFileModel note) async {
    await context.pushNamed(Routes.noteViewer.name, extra: note);
  }

  Future<void> _requestStoragePermission() async {
    if (!Platform.isAndroid ||
        await Permission.manageExternalStorage.isGranted) {
      return;
    }
    final status = await Permission.manageExternalStorage.request();
    if (status.isGranted && mounted) {
      await ref.read(notesServiceProvider.notifier).rescan();
    }
  }

  @override
  Widget build(BuildContext context) {
    final notesAsync = ref.watch(notesServiceProvider);
    final notes = notesAsync.value ?? [];

    return CupertinoPageScaffold(
      child: Column(
        children: [
          StatusBar(title: Routes.notes.title(context)),
          Expanded(
            child: notesAsync.when(
              loading: () => const Center(child: CupertinoActivityIndicator()),
              error: (_, _) => _buildBody(context, notes),
              data: (_) => _buildBody(context, notes),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, List<NoteFileModel> notes) {
    if (notes.isEmpty) {
      return Column(
        children: [
          Expanded(
            child: EmptyStateWidget(
              emptyDescription: context.localization.notesEmpty,
              emptySubtitle: context.localization.notesEmptyHint,
            ),
          ),
          _buildSearchTile(isSelected: selectedDisplayItem == 0),
          _buildBookmarksTile(isSelected: selectedDisplayItem == 1),
          _buildRefreshTile(isSelected: selectedDisplayItem == 2),
        ],
      );
    }
    return FastScrollIndicator(
      wheelScrollIndex: wheelScrollIndex,
      itemCount: notes.length + 3,
      itemExtent: displayTileHeight,
      labelAt: (index) =>
          index < 2 || index > notes.length + 1 ? '' : notes[index - 2].name,
      child: CupertinoScrollbar(
        controller: scrollController,
        child: ListView.builder(
          controller: scrollController,
          itemCount: notes.length + 3,
          prototypeItem: const DisplayListTile(text: '', isSelected: false),
          itemBuilder: (context, index) {
            if (index == 0) {
              return _buildSearchTile(isSelected: selectedDisplayItem == 0);
            }
            if (index == 1) {
              return _buildBookmarksTile(isSelected: selectedDisplayItem == 1);
            }
            if (index == notes.length + 2) {
              return _buildRefreshTile(
                isSelected: selectedDisplayItem == index,
              );
            }
            final note = notes[index - 2];
            return DisplayListTile(
              text: note.name,
              isSelected: selectedDisplayItem == index,
              onTap: () {
                setState(() => selectedDisplayItem = index);
                unawaited(_openNote(note));
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildSearchTile({required bool isSelected}) {
    return GestureDetector(
      onTap: () => unawaited(context.pushNamed(Routes.notesSearch.name)),
      child: Container(
        height: displayTileHeight,
        color: isSelected
            ? context.appHighlightColor
            : context.appSurfaceColor,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            Icon(
              CupertinoIcons.search,
              size: 14,
              color: isSelected
                  ? context.appHighlightTextColor
                  : context.appPrimaryTextColor,
            ),
            const SizedBox(width: 6),
            Text(
              context.localization.notesSearchTitle,
              style: TextStyle(
                fontSize: 11,
                color: isSelected
                    ? context.appHighlightTextColor
                    : context.appPrimaryTextColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookmarksTile({required bool isSelected}) {
    return GestureDetector(
      onTap: () => unawaited(context.pushNamed(Routes.notesBookmarks.name)),
      child: Container(
        height: displayTileHeight,
        color: isSelected
            ? context.appHighlightColor
            : context.appSurfaceColor,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            Icon(
              CupertinoIcons.bookmark,
              size: 14,
              color: isSelected
                  ? context.appHighlightTextColor
                  : context.appPrimaryTextColor,
            ),
            const SizedBox(width: 6),
            Text(
              context.localization.notesBookmarksTitle,
              style: TextStyle(
                fontSize: 11,
                color: isSelected
                    ? context.appHighlightTextColor
                    : context.appPrimaryTextColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRefreshTile({required bool isSelected}) {
    return GestureDetector(
      onTap: () => unawaited(ref.read(notesServiceProvider.notifier).rescan()),
      child: Container(
        height: displayTileHeight,
        color: isSelected
            ? context.appHighlightColor
            : context.appSurfaceColor,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            Icon(
              CupertinoIcons.refresh,
              size: 14,
              color: isSelected
                  ? context.appHighlightTextColor
                  : context.appPrimaryTextColor,
            ),
            const SizedBox(width: 6),
            Text(
              context.localization.notesRefreshTitle,
              style: TextStyle(
                fontSize: 11,
                color: isSelected
                    ? context.appHighlightTextColor
                    : context.appPrimaryTextColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
