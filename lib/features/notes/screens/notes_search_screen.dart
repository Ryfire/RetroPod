import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:retropod/core/extensions/build_context_extensions.dart';
import 'package:retropod/core/navigation/routes.dart';
import 'package:retropod/core/widgets/display_list_tile.dart';
import 'package:retropod/core/widgets/input_text_bar.dart';
import 'package:retropod/features/custom_screen_elements/custom_input_text_screen.dart';
import 'package:retropod/features/notes/models/note_file_model.dart';
import 'package:retropod/features/notes/services/notes_service.dart';
import 'package:retropod/features/status_bar/widgets/status_bar.dart';

class NotesSearchScreen extends ConsumerStatefulWidget {
  const NotesSearchScreen({super.key});

  @override
  ConsumerState<NotesSearchScreen> createState() => _NotesSearchScreenState();
}

class _NotesSearchScreenState extends ConsumerState<NotesSearchScreen>
    with CustomInputTextScreen {
  @override
  int get extraDisplayItems => 1;

  @override
  String get routeName => Routes.notesSearch.name;

  List<NoteFileModel> get _matchedNotes {
    final query = inputText.trim().toLowerCase();
    final notes = ref.watch(notesServiceProvider).value ?? [];
    if (query.isEmpty) {
      return notes;
    }
    return notes
        .where((note) => note.name.toLowerCase().contains(query))
        .toList();
  }

  @override
  List<NoteFileModel> get displayItems => _matchedNotes;

  @override
  Future<void> onSelectAction() async {
    final notes = _matchedNotes;
    final index = selectedDisplayItem;
    if (index == 0) {
      setState(() => isInputTextBarActive = true);
      return;
    }
    if (index - 1 < notes.length) {
      setState(() => selectedDisplayItem = index);
      await context.pushNamed(Routes.noteViewer.name, extra: notes[index - 1]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final notes = _matchedNotes;
    final String statusBarTitle;
    if (inputText.trim().isEmpty) {
      statusBarTitle = Routes.notesSearch.title(context);
    } else {
      statusBarTitle =
          "${context.localization.notesSearchResultsText} ${notes.length}";
    }

    return CupertinoPageScaffold(
      resizeToAvoidBottomInset: false,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Column(
            children: [
              StatusBar(title: statusBarTitle),
              Flexible(
                child: CupertinoScrollbar(
                  controller: scrollController,
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: notes.length + 1,
                    prototypeItem: const DisplayListTile(
                      text: '',
                      isSelected: false,
                    ),
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return DisplayListTile(
                          text: inputText.isEmpty
                              ? context.localization.notesSearchPrompt
                              : inputText,
                          isSelected: selectedDisplayItem == 0,
                          onTap: () =>
                              setState(() => isInputTextBarActive = true),
                        );
                      }
                      final note = notes[index - 1];
                      return DisplayListTile(
                        text: note.name,
                        isSelected: selectedDisplayItem == index,
                        onTap: () async {
                          setState(() => selectedDisplayItem = index);
                          await context.pushNamed(
                            Routes.noteViewer.name,
                            extra: note,
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
          if (isInputTextBarActive)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: InputTextBar(
                inputTextBarController: inputTextBarController,
                onSearchTextChanged: (value) {
                  setState(() {
                    inputText = value;
                    selectedDisplayItem = 0;
                  });
                },
              ),
            ),
        ],
      ),
    );
  }
}
