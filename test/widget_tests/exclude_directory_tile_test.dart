import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retropod/features/settings/models/exclude_directory_model.dart';
import 'package:retropod/features/settings/widgets/exclude_directory_tile.dart';

ExcludeDirectoryModel _model(String path, {required bool isExcluded}) {
  return ExcludeDirectoryModel(
    directoryPath: path,
    isExcluded: isExcluded,
  );
}

Widget _wrap(Widget child) {
  return CupertinoApp(
    home: CupertinoPageScaffold(child: child),
  );
}

/// Lets the marquee text delay timer and the periodic scroll timer
/// (which self-cancels when the text fits) fire, then unmounts the tree.
Future<void> _disposeTree(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 2));
  await tester.pump(const Duration(milliseconds: 60));
  await tester.pumpWidget(const SizedBox());
  await tester.pump();
}

void main() {
  group('ExcludeDirectoryTile states', () {
    const String path = '/storage/emulated/0/Music/Albums';

    testWidgets('included directory shows green checkmark', (tester) async {
      await tester.pumpWidget(
        _wrap(
          ExcludeDirectoryTile(
            excludeDirectoryModel: _model(path, isExcluded: false),
            isSelected: false,
            onTap: () {},
          ),
        ),
      );
      expect(
        find.byIcon(CupertinoIcons.checkmark_alt_circle_fill),
        findsOneWidget,
      );
      expect(find.byIcon(CupertinoIcons.xmark_square_fill), findsNothing);
      expect(find.byIcon(CupertinoIcons.minus_circle), findsNothing);
      await _disposeTree(tester);
    });

    testWidgets('toggled-off directory shows xmark', (tester) async {
      await tester.pumpWidget(
        _wrap(
          ExcludeDirectoryTile(
            excludeDirectoryModel: _model(path, isExcluded: true),
            isSelected: false,
            onTap: () {},
          ),
        ),
      );
      expect(find.byIcon(CupertinoIcons.xmark_square_fill), findsOneWidget);
      expect(find.byIcon(CupertinoIcons.minus_circle), findsNothing);
      await _disposeTree(tester);
    });

    testWidgets('name-filtered directory shows minus circle', (tester) async {
      await tester.pumpWidget(
        _wrap(
          ExcludeDirectoryTile(
            excludeDirectoryModel: _model(path, isExcluded: false),
            isSelected: false,
            nameFilters: const ['albums'],
            onTap: () {},
          ),
        ),
      );
      expect(find.byIcon(CupertinoIcons.minus_circle), findsOneWidget);
      expect(
        find.byIcon(CupertinoIcons.checkmark_alt_circle_fill),
        findsNothing,
      );
      await _disposeTree(tester);
    });

    testWidgets('toggled-off wins over name filter', (tester) async {
      await tester.pumpWidget(
        _wrap(
          ExcludeDirectoryTile(
            excludeDirectoryModel: _model(path, isExcluded: true),
            isSelected: false,
            nameFilters: const ['albums'],
            onTap: () {},
          ),
        ),
      );
      expect(find.byIcon(CupertinoIcons.xmark_square_fill), findsOneWidget);
      expect(find.byIcon(CupertinoIcons.minus_circle), findsNothing);
      await _disposeTree(tester);
    });
  });
}
