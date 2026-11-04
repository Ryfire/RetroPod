import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retropod/core/constants/constants.dart';
import 'package:retropod/core/extensions/build_context_extensions.dart';
import 'package:retropod/core/navigation/routes.dart';
import 'package:retropod/features/custom_screen_elements/custom_screen.dart';
import 'package:retropod/features/settings/controller/settings_preferences_controller.dart';
import 'package:retropod/features/status_bar/widgets/status_bar.dart';

class NoteFontSizeScreen extends ConsumerStatefulWidget {
  const NoteFontSizeScreen({super.key});

  @override
  ConsumerState<NoteFontSizeScreen> createState() => _NoteFontSizeScreenState();
}

class _NoteFontSizeScreenState extends ConsumerState<NoteFontSizeScreen>
    with CustomScreen {
  List<int> get _sizes => List<int>.generate(
    Constants.maxNoteFontSize - Constants.minNoteFontSize + 1,
    (index) => Constants.minNoteFontSize + index,
  );

  @override
  String get routeName => Routes.noteFontSize.name;

  @override
  List<int> get displayItems => _sizes;

  @override
  Future<void> onSelectPressed() => _selectSize(selectedDisplayItem);

  Future<void> _selectSize(int index) async {
    setState(() => selectedDisplayItem = index);
    await ref
        .read(settingsPreferencesControllerProvider.notifier)
        .setNoteFontSize(displayItems[index]);
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: Column(
        children: [
          StatusBar(title: Routes.noteFontSize.title(context)),
          Flexible(
            child: CupertinoScrollbar(
              controller: scrollController,
              child: ListView.builder(
                controller: scrollController,
                itemCount: displayItems.length,
                prototypeItem: _NoteFontSizeOptionTile(
                  fontSize: displayItems.first,
                  isSelected: false,
                  onTap: () {},
                ),
                itemBuilder: (context, index) {
                  final fontSize = displayItems[index];
                  final isSelected = selectedDisplayItem == index;
                  return _NoteFontSizeOptionTile(
                    fontSize: fontSize,
                    isSelected: isSelected,
                    onTap: () async => _selectSize(index),
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

class _NoteFontSizeOptionTile extends StatelessWidget {
  final int fontSize;
  final bool isSelected;
  final VoidCallback onTap;

  const _NoteFontSizeOptionTile({
    required this.fontSize,
    required this.isSelected,
    required this.onTap,
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
              children: [
                Text(
                  'Aa',
                  style: TextStyle(
                    fontSize: fontSize.toDouble(),
                    fontWeight: FontWeight.bold,
                    color: isSelected
                        ? context.appHighlightTextColor
                        : context.appPrimaryTextColor,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '$fontSize',
                    style: TextStyle(
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
