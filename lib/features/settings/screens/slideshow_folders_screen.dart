import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:retropod/core/extensions/build_context_extensions.dart';
import 'package:retropod/core/extensions/go_router_extensions.dart';
import 'package:retropod/core/navigation/routes.dart';
import 'package:retropod/core/widgets/empty_state_widget.dart';
import 'package:retropod/features/custom_screen_elements/custom_screen.dart';
import 'package:retropod/features/device/models/device_action.dart';
import 'package:retropod/features/media/models/media_file_model.dart';
import 'package:retropod/features/media/services/media_files_service.dart';
import 'package:retropod/features/settings/controller/settings_preferences_controller.dart';
import 'package:retropod/features/settings/models/exclude_directory_model.dart';
import 'package:retropod/features/settings/widgets/exclude_directory_tile.dart';
import 'package:retropod/features/status_bar/widgets/status_bar.dart';

/// Every photo folder found by the media scan, with a toggle controlling
/// whether its photos are used by the slideshow screensaver. Enabled
/// folders show a checkmark; disabled ones show an xmark.
class SlideshowFolderModel {
  const SlideshowFolderModel({
    required this.directoryPath,
    required this.isEnabled,
  });

  final String directoryPath;
  final bool isEnabled;

  ExcludeDirectoryModel get asExcludeDirectoryModel {
    // The tile's isExcluded flag drives the trailing icon, so invert the
    // enabled flag to reuse the same folder row widget.
    return ExcludeDirectoryModel(
      directoryPath: directoryPath,
      isExcluded: !isEnabled,
    );
  }
}

class SlideshowFoldersScreen extends ConsumerStatefulWidget {
  const SlideshowFoldersScreen({super.key});

  @override
  ConsumerState createState() => _SlideshowFoldersScreenState();
}

class _SlideshowFoldersScreenState extends ConsumerState<SlideshowFoldersScreen>
    with CustomScreen {
  @override
  String get routeName => Routes.slideshowFolders.name;

  List<SlideshowFolderModel> get folders {
    final List<String> excludedFolders = ref
        .watch(settingsPreferencesControllerProvider)
        .excludedSlideshowFolders;
    final List<MediaFileModel> mediaFiles = ref
        .watch(mediaFilesServiceProvider)
        .value ?? const <MediaFileModel>[];
    final Set<String> folderPaths = <String>{};
    for (final MediaFileModel mediaFile in mediaFiles) {
      if (mediaFile.type == MediaFileType.photo) {
        folderPaths.add(p.dirname(mediaFile.path));
      }
    }
    final List<String> sortedPaths = folderPaths.toList()..sort();
    return sortedPaths
        .map(
          (folderPath) => SlideshowFolderModel(
            directoryPath: folderPath,
            isEnabled: !excludedFolders.contains(folderPath),
          ),
        )
        .toList();
  }

  @override
  List<SlideshowFolderModel> get displayItems => folders;

  @override
  void onSelectPressed() {
    if (displayItems.isEmpty || selectedDisplayItem >= displayItems.length) {
      return;
    }
    unawaited(
      _toggleFolder(
        folderPath: displayItems[selectedDisplayItem].directoryPath,
        folderIndex: selectedDisplayItem,
      ),
    );
  }

  Future<void> _toggleFolder({
    required String folderPath,
    required int folderIndex,
  }) async {
    setState(() => selectedDisplayItem = folderIndex);
    await ref
        .read(settingsPreferencesControllerProvider.notifier)
        .toggleSlideshowFolder(folderPath: folderPath);
  }

  @override
  Future<void> deviceControlHandler(
    dynamic inputSource,
    DeviceAction? newState,
  ) async {
    if (newState == null || context.router.locationNamed != routeName) {
      return;
    }
    if (displayItems.isNotEmpty &&
        selectedDisplayItem > displayItems.length - 1) {
      setState(() => selectedDisplayItem = displayItems.length - 1);
    }
    await super.deviceControlHandler(inputSource, newState);
  }

  @override
  Widget build(BuildContext context) {
    final List<SlideshowFolderModel> folders = displayItems;
    if (folders.isEmpty) {
      return CupertinoPageScaffold(
        child: Column(
          children: [
            StatusBar(title: Routes.slideshowFolders.title(context)),
            Expanded(
              child: EmptyStateWidget(
                emptyDescription: context.localization.noPhotosFound,
              ),
            ),
          ],
        ),
      );
    }
    return CupertinoPageScaffold(
      child: Column(
        children: [
          StatusBar(title: Routes.slideshowFolders.title(context)),
          Flexible(
            child: CupertinoScrollbar(
              controller: scrollController,
              child: ListView.builder(
                controller: scrollController,
                itemCount: folders.length,
                prototypeItem: ExcludeDirectoryTile(
                  excludeDirectoryModel: folders.first.asExcludeDirectoryModel,
                  isSelected: false,
                  onTap: () {},
                ),
                itemBuilder: (context, index) {
                  return ExcludeDirectoryTile(
                    excludeDirectoryModel:
                        folders[index].asExcludeDirectoryModel,
                    isSelected: selectedDisplayItem == index,
                    onTap: () => _toggleFolder(
                      folderPath: folders[index].directoryPath,
                      folderIndex: index,
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
