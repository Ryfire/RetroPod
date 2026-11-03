import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:retropod/core/constants/constants.dart';
import 'package:retropod/core/extensions/build_context_extensions.dart';
import 'package:retropod/core/navigation/routes.dart';
import 'package:retropod/core/services/audio_player_service.dart';
import 'package:retropod/core/widgets/empty_state_widget.dart';
import 'package:retropod/features/custom_screen_elements/custom_page_screen.dart';
import 'package:retropod/features/notes/models/note_file_model.dart';
import 'package:retropod/features/notes/services/notes_service.dart';
import 'package:retropod/features/settings/controller/settings_preferences_controller.dart';
import 'package:retropod/features/status_bar/widgets/status_bar.dart';

const int _kMaxReadChars = 1000000;
const double _kLineHeight = 1.35;
const EdgeInsets _kPagePadding = EdgeInsets.symmetric(
  horizontal: 8,
  vertical: 6,
);
const double _kFooterHeight = 20.0;
const double _kNoticeHeight = 14.0;
const int _kMaxSafetyReserve = 4;
const int _kPaginationSliceMs = 14;

class NoteReaderScreen extends ConsumerStatefulWidget {
  final NoteFileModel? note;

  const NoteReaderScreen({super.key, required this.note});

  @override
  ConsumerState<NoteReaderScreen> createState() => _NoteReaderScreenState();
}

class _NoteReaderScreenState extends ConsumerState<NoteReaderScreen>
    with CustomPageScreen {
  String? _content;
  bool _isLoading = true;
  bool _truncated = false;
  List<String> _pages = const <String>[''];
  List<int> _pageOffsets = const <int>[0];
  Size? _lastPageSize;
  TextScaler? _lastTextScaler;
  double? _lastPaginatedFontSize;
  double _fontSize = Constants.defaultNoteFontSize.toDouble();
  bool _isShowingFontIndicator = false;
  Timer? _fontIndicatorTimer;
  int? _pendingBookmarkOffset;
  bool _isShowingBookmarkIndicator = false;
  Timer? _bookmarkIndicatorTimer;
  int _bookmarkIndicatorPage = 0;
  int _bookmarkIndicatorTotal = 0;
  final Map<int, GlobalKey> _pageTextKeys = <int, GlobalKey>{};
  int _safetyReserve = 0;
  bool _verifyQueued = false;
  bool _paginationPending = false;
  int _paginationGeneration = 0;

  @override
  String get routeName => Routes.noteViewer.name;

  /// Requires four wheel steps per page turn so scanning a note feels less
  /// jumpy; the queued page turns still drain smoothly when spinning fast.
  @override
  int get wheelStepsPerPageTurn => 4;

  @override
  List<String> get displayItems => _pages;

  @override
  void onSelectPressed() {
    unawaited(_cycleFontSize());
  }

  @override
  void onSelectLongPress() {
    unawaited(_openMoreOptions());
  }

  Future<void> _openMoreOptions() async {
    final note = widget.note;
    if (note == null || _isLoading) {
      return;
    }
    final int currentPage = pageController.hasClients
        ? (pageController.page ?? 0).round()
        : selectedDisplayItem;
    final int pageOffset =
        (currentPage >= 0 && currentPage < _pageOffsets.length)
        ? _pageOffsets[currentPage]
        : 0;
    await context.pushNamed(
      Routes.noteMoreOptions.name,
      extra: (note, pageOffset),
    );
  }

  @override
  Future<void> seekForward() async {
    await ref.read(audioPlayerServiceProvider.notifier).nextSong();
  }

  @override
  Future<void> seekBackward() async {
    await ref.read(audioPlayerServiceProvider.notifier).seekBackwards();
  }

  @override
  void initState() {
    super.initState();
    pageController.addListener(_scheduleVerify);
    unawaited(_loadContent());
  }

  Future<void> _cycleFontSize() async {
    final note = widget.note;
    if (note == null || _isLoading) {
      return;
    }
    final double nextSize = _fontSize >= Constants.maxNoteFontSize
        ? Constants.minNoteFontSize.toDouble()
        : _fontSize + 1;
    if (note.path.isNotEmpty) {
      try {
        await ref
            .read(notesServiceProvider.notifier)
            .setFontSize(note.path, nextSize.round());
      } catch (_) {
        // Keep the in-session font change even if persisting fails
      }
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _fontSize = nextSize;
      _isShowingFontIndicator = true;
      _safetyReserve = 0;
      _lastPageSize = null;
      _paginationPending = true;
    });
    _fontIndicatorTimer?.cancel();
    _fontIndicatorTimer = Timer(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() => _isShowingFontIndicator = false);
      }
    });
  }

  @override
  void dispose() {
    _fontIndicatorTimer?.cancel();
    _bookmarkIndicatorTimer?.cancel();
    super.dispose();
  }

  void _showBookmarkIndicator(int page, int total) {
    _bookmarkIndicatorTimer?.cancel();
    setState(() {
      _isShowingBookmarkIndicator = true;
      _bookmarkIndicatorPage = page;
      _bookmarkIndicatorTotal = total;
    });
    _bookmarkIndicatorTimer = Timer(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() => _isShowingBookmarkIndicator = false);
      }
    });
  }

  double _fractionOfCurrentPage() {
    if (_pages.length <= 1) {
      return 0;
    }
    final int current = pageController.hasClients
        ? (pageController.page ?? 0).round()
        : 0;
    return current / (_pages.length - 1);
  }

  void _scheduleVerify() {
    if (!mounted || _isLoading || _content == null || _verifyQueued) {
      return;
    }
    _verifyQueued = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _verifyQueued = false;
      if (!mounted) return;
      _verifyActivePage();
    });
  }

  void _verifyActivePage() {
    if (!mounted || _isLoading || _content == null || _paginationPending) {
      return;
    }
    final Size? size = _lastPageSize;
    if (size == null) {
      return;
    }
    final double available = size.height - _kPagePadding.vertical;
    if (available <= 0) {
      return;
    }
    final int index = pageController.hasClients
        ? (pageController.page ?? 0).round()
        : 0;
    if (index < 0 || index >= _pages.length) {
      return;
    }
    final GlobalKey? key = _pageTextKeys[index];
    final BuildContext? textContext = key?.currentContext;
    if (textContext == null) {
      return;
    }
    final RenderObject? renderObject = textContext.findRenderObject();
    if (renderObject is! RenderParagraph) {
      return;
    }
    if (renderObject.size.width <= 0) {
      return;
    }
    final double actual = renderObject.computeMaxIntrinsicHeight(
      renderObject.size.width,
    );
    if (actual <= available) {
      return;
    }
    if (_safetyReserve >= _kMaxSafetyReserve) {
      return;
    }
    setState(() {
      _safetyReserve += 1;
      _lastPageSize = null;
    });
  }

  Future<void> _loadContent() async {
    final note = widget.note;
    if (note == null) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      return;
    }
    try {
      final file = File(note.path);
      String content = await file.readAsString();
      if (content.length > _kMaxReadChars) {
        content = content.substring(0, _kMaxReadChars);
        _truncated = true;
      }
      final int? perNoteSize = await ref
          .read(notesServiceProvider.notifier)
          .getFontSize(note.path);
      final int globalSize = ref
          .read(settingsPreferencesControllerProvider)
          .noteFontSize;
      final int? bookmarkOffset = await ref
          .read(notesServiceProvider.notifier)
          .getBookmarkOffset(note.path);
      if (!mounted) return;
      setState(() {
        _content = content;
        _fontSize = (perNoteSize ?? globalSize).toDouble();
        _pendingBookmarkOffset = bookmarkOffset;
        _isLoading = false;
        _paginationPending = true;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _content = null;
        _isLoading = false;
      });
    }
  }

  bool _fits(
    String text,
    int start,
    int end,
    double maxWidth,
    double maxHeight,
    TextScaler textScaler,
    TextStyle style,
  ) {
    final painter = TextPainter(
      text: TextSpan(text: text.substring(start, end), style: style),
      textDirection: TextDirection.ltr,
      textScaler: textScaler,
    )..layout(maxWidth: maxWidth);
    final double lineHeight = painter.preferredLineHeight > 0
        ? painter.preferredLineHeight
        : 1;
    final bool fits =
        painter.height + lineHeight * (1 + _safetyReserve) <= maxHeight;
    painter.dispose();
    return fits;
  }

  int _estimatePageWindow(
    double maxWidth,
    double maxHeight,
    TextScaler textScaler,
    TextStyle style,
  ) {
    final painter = TextPainter(
      text: TextSpan(text: 'Xg', style: style),
      textDirection: TextDirection.ltr,
      textScaler: textScaler,
    )..layout();
    final double lineHeight = painter.height;
    painter.dispose();
    final double safeLineHeight = lineHeight <= 0 ? 1 : lineHeight;
    final int lines = (maxHeight / safeLineHeight).floor() + 1;
    final double fontSize =
        style.fontSize ?? Constants.defaultNoteFontSize.toDouble();
    final double scaledFontSize = textScaler.scale(fontSize);
    final double avgCharWidth = scaledFontSize * 0.6;
    final double safeCharWidth = avgCharWidth <= 0 ? 1 : avgCharWidth;
    final int charsPerLine = (maxWidth / safeCharWidth).ceil();
    return (charsPerLine * lines).clamp(16, 4096);
  }

  int _findPageEnd(
    String text,
    int start,
    int window,
    double maxWidth,
    double maxHeight,
    TextScaler textScaler,
    TextStyle style,
  ) {
    final int maxLen = text.length - start;
    bool fits(int len) =>
        _fits(text, start, start + len, maxWidth, maxHeight, textScaler, style);
    int lo = 0;
    int hi = maxLen;
    final int initial = window.clamp(1, maxLen);
    if (fits(initial)) {
      lo = initial;
      if (initial == maxLen) {
        return start + maxLen;
      }
      int probe = (initial + window).clamp(1, maxLen);
      while (probe > lo) {
        if (fits(probe)) {
          lo = probe;
          if (probe == maxLen) {
            return start + maxLen;
          }
          probe = (probe + window).clamp(1, maxLen);
        } else {
          hi = probe;
          break;
        }
      }
    } else {
      hi = initial;
    }
    while (hi - lo > 1) {
      final int mid = lo + ((hi - lo) >> 1);
      if (fits(mid)) {
        lo = mid;
      } else {
        hi = mid;
      }
    }
    return start + (lo > 0 ? lo : 1);
  }

  int _snapBack(String text, int start, int end) {
    bool isBreak(int codeUnit) =>
        codeUnit == 0x20 ||
        codeUnit == 0x09 ||
        codeUnit == 0x0A ||
        codeUnit == 0x0D;
    int adjusted = end;
    if (adjusted < text.length &&
        adjusted > start &&
        text.codeUnitAt(adjusted) >= 0xDC00 &&
        text.codeUnitAt(adjusted) <= 0xDFFF &&
        text.codeUnitAt(adjusted - 1) >= 0xD800 &&
        text.codeUnitAt(adjusted - 1) <= 0xDBFF) {
      adjusted--;
    }
    while (adjusted > start + 1 &&
        adjusted < text.length &&
        !isBreak(text.codeUnitAt(adjusted - 1)) &&
        !isBreak(text.codeUnitAt(adjusted))) {
      adjusted--;
    }
    return adjusted;
  }

  /// Finds the page whose [start, nextStart) character range contains
  /// [offset] by binary searching the strictly increasing page start offsets.
  int _pageForOffset(List<int> pageOffsets, int offset) {
    if (pageOffsets.isEmpty) {
      return 0;
    }
    int lo = 0;
    int hi = pageOffsets.length - 1;
    while (lo < hi) {
      final int mid = (lo + hi + 1) >> 1;
      if (pageOffsets[mid] <= offset) {
        lo = mid;
      } else {
        hi = mid - 1;
      }
    }
    return lo;
  }

  void _finishPagination(
    List<String> pages,
    List<int> pageOffsets,
    bool restorePosition,
    bool Function() stale,
  ) {
    if (stale()) {
      return;
    }
    final double fraction = restorePosition ? _fractionOfCurrentPage() : 0;
    setState(() {
      _pages = pages;
      _pageOffsets = pageOffsets;
      _paginationPending = false;
    });
    _pageTextKeys.removeWhere((key, _) => key >= pages.length);
    final int? bookmarkOffset = pages.length > 1
        ? _pendingBookmarkOffset
        : null;
    if (bookmarkOffset != null) {
      _pendingBookmarkOffset = null;
      final int target = _pageForOffset(
        pageOffsets,
        bookmarkOffset,
      ).clamp(0, pages.length - 1);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || stale()) {
          return;
        }
        if (pageController.hasClients) {
          pageController.jumpToPage(target);
          _showBookmarkIndicator(target + 1, pages.length);
        }
        _scheduleVerify();
      });
      return;
    }
    if (restorePosition && pages.length > 1 && pageController.hasClients) {
      final int target = (fraction * (pages.length - 1)).round().clamp(
        0,
        pages.length - 1,
      );
      if ((pageController.page ?? 0).round() != target) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted || stale()) {
            return;
          }
          if (pageController.hasClients &&
              (pageController.page ?? 0).round() != target) {
            pageController.jumpToPage(target);
          }
          _scheduleVerify();
        });
        return;
      }
    }
    _scheduleVerify();
  }

  Future<void> _runPagination(
    String text,
    Size size,
    TextScaler textScaler,
    TextStyle style,
    int generation,
  ) async {
    final double paginationFontSize = _fontSize;
    bool stale() =>
        !mounted ||
        generation != _paginationGeneration ||
        _fontSize != paginationFontSize;
    final bool progressive = _pages.length <= 1;
    final bool restorePosition = !progressive;
    if (text.isEmpty) {
      _finishPagination(
        const <String>[''],
        const <int>[0],
        restorePosition,
        stale,
      );
      return;
    }
    final double maxWidth = size.width - _kPagePadding.horizontal;
    final double maxHeight = size.height - _kPagePadding.vertical;
    if (maxWidth <= 0 || maxHeight <= 0) {
      _finishPagination(<String>[text], const <int>[0], restorePosition, stale);
      return;
    }
    final int window = _estimatePageWindow(
      maxWidth,
      maxHeight,
      textScaler,
      style,
    );
    final List<String> pages = <String>[];
    final List<int> pageOffsets = <int>[];
    final Stopwatch budget = Stopwatch()..start();
    int start = 0;
    try {
      while (start < text.length) {
        if (stale()) {
          return;
        }
        if (budget.elapsedMilliseconds >= _kPaginationSliceMs) {
          if (progressive && pages.isNotEmpty) {
            if (stale()) {
              return;
            }
            setState(() {
              _pages = List<String>.of(pages);
              _pageOffsets = List<int>.of(pageOffsets);
            });
          }
          await WidgetsBinding.instance.endOfFrame;
          if (stale()) {
            return;
          }
          budget.reset();
          continue;
        }
        while (start < text.length) {
          final int codeUnit = text.codeUnitAt(start);
          if (codeUnit == 0x0A ||
              codeUnit == 0x0D ||
              codeUnit == 0x20 ||
              codeUnit == 0x09) {
            start++;
          } else {
            break;
          }
        }
        if (start >= text.length) {
          break;
        }
        int end = _findPageEnd(
          text,
          start,
          window,
          maxWidth,
          maxHeight,
          textScaler,
          style,
        );
        end = _snapBack(text, start, end);
        pageOffsets.add(start);
        pages.add(text.substring(start, end));
        start = end;
      }
    } catch (error) {
      debugPrint('Note pagination failed: $error');
      if (stale()) {
        return;
      }
      setState(() => _paginationPending = false);
      return;
    }
    if (stale()) {
      return;
    }
    _finishPagination(
      pages.isEmpty ? <String>[text] : pages,
      pageOffsets.isEmpty ? <int>[0] : pageOffsets,
      restorePosition,
      stale,
    );
  }

  TextStyle _pageStyle(BuildContext context, Color textColor) {
    return DefaultTextStyle.of(context).style.merge(
      TextStyle(fontSize: _fontSize, height: _kLineHeight, color: textColor),
    );
  }

  @override
  Widget build(BuildContext context) {
    final note = widget.note;
    if (note == null) {
      return CupertinoPageScaffold(
        child: Column(
          children: [
            StatusBar(title: Routes.noteViewer.title(context)),
            const Expanded(
              child: EmptyStateWidget(emptyDescription: 'No note selected'),
            ),
          ],
        ),
      );
    }

    final Color textColor =
        ref
            .watch(settingsPreferencesControllerProvider)
            .noteFontColor
            .textColor ??
        context.appPrimaryTextColor;

    return CupertinoPageScaffold(
      child: Stack(
        children: [
          Column(
            children: [
              StatusBar(title: note.name),
              Expanded(
                child: !_isLoading && _content == null
                    ? EmptyStateWidget(
                        emptyDescription: context.localization.noteLoadError,
                      )
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          final size = Size(
                            constraints.maxWidth,
                            constraints.maxHeight,
                          );
                          final footerHeight = _truncated
                              ? _kFooterHeight + _kNoticeHeight
                              : _kFooterHeight;
                          final pageSize = Size(
                            size.width,
                            (size.height - footerHeight).clamp(
                              0.0,
                              double.infinity,
                            ),
                          );
                          final textScaler = MediaQuery.textScalerOf(context);
                          if (_content != null &&
                              (_lastPageSize != pageSize ||
                                  _lastTextScaler != textScaler ||
                                  _lastPaginatedFontSize != _fontSize)) {
                            _lastPageSize = pageSize;
                            _lastTextScaler = textScaler;
                            _lastPaginatedFontSize = _fontSize;
                            _paginationPending = true;
                            _paginationGeneration += 1;
                            final int generation = _paginationGeneration;
                            final content = _content!;
                            final style = _pageStyle(context, textColor);
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (!mounted ||
                                  generation != _paginationGeneration) {
                                return;
                              }
                              unawaited(
                                _runPagination(
                                  content,
                                  pageSize,
                                  textScaler,
                                  style,
                                  generation,
                                ),
                              );
                            });
                          }
                          return Column(
                            children: [
                              Expanded(
                                child: PageView.builder(
                                  controller: pageController,
                                  itemCount: _pages.length,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemBuilder: (context, index) {
                                    if (_isLoading) {
                                      return const Center(
                                        child: CupertinoActivityIndicator(),
                                      );
                                    }
                                    return Padding(
                                      padding: _kPagePadding,
                                      child: Text(
                                        _pages[index],
                                        key: _pageTextKeys.putIfAbsent(
                                          index,
                                          GlobalKey.new,
                                        ),
                                        style: _pageStyle(context, textColor),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              Container(
                                height: _kFooterHeight,
                                alignment: Alignment.center,
                                child: Text(
                                  context.localization.notePageIndicator(
                                    (pageController.hasClients
                                                ? pageController.page ?? 0
                                                : 0)
                                            .round() +
                                        1,
                                    _pages.length,
                                  ),
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: context.appSecondaryTextColor,
                                  ),
                                ),
                              ),
                              if (_truncated)
                                Container(
                                  height: _kNoticeHeight,
                                  alignment: Alignment.center,
                                  child: Text(
                                    context.localization.noteTooLarge,
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontStyle: FontStyle.italic,
                                      color: context.appSecondaryTextColor,
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
              ),
            ],
          ),
          if (_paginationPending && !_isLoading && _content != null)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 24,
                alignment: Alignment.center,
                color: CupertinoColors.systemGrey,
                child: const Text(
                  'Paginating...',
                  style: TextStyle(fontSize: 11, color: CupertinoColors.white),
                ),
              ),
            ),
          if (_isShowingBookmarkIndicator)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 24,
                alignment: Alignment.center,
                color: CupertinoColors.systemBlue,
                child: Text(
                  context.localization.noteBookmarkIndicator(
                    _bookmarkIndicatorPage,
                    _bookmarkIndicatorTotal,
                  ),
                  style: const TextStyle(
                    fontSize: 11,
                    color: CupertinoColors.white,
                  ),
                ),
              ),
            ),
          if (_isShowingFontIndicator)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 24,
                alignment: Alignment.center,
                color: CupertinoColors.systemBlue,
                child: Text(
                  context.localization.noteFontIndicator(
                    '${_fontSize.round()}',
                  ),
                  style: const TextStyle(
                    fontSize: 11,
                    color: CupertinoColors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
