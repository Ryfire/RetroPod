import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:retropod/core/extensions/build_context_extensions.dart';
import 'package:retropod/core/extensions/go_router_extensions.dart';
import 'package:retropod/features/device/models/device_action.dart';
import 'package:retropod/features/device/services/device_buttons_service_provider.dart';

mixin CustomPageScreen<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  abstract final String routeName;
  abstract final List displayItems;
  late final PageController pageController;
  final double viewPortFraction = 1;
  final int initialPage = 0;
  double currentPage = 0;
  int selectedDisplayItem = 0;
  int _pendingPageScrolls = 0;
  bool _isDrainingPageScrolls = false;

  /// Number of wheel steps required to advance one page. Subclasses can
  /// override this to make page turns feel less jumpy; the default of 1
  /// preserves the original one-page-per-step behavior.
  int get wheelStepsPerPageTurn => 1;

  int _wheelStepAccumulator = 0;

  void onSelectPressed();

  void onSelectLongPress() {}

  Future<void> scrollForward() async {
    if (selectedDisplayItem < displayItems.length - 1) {
      await pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.ease,
      );
    }
  }

  Future<void> scrollBackward() async {
    if (selectedDisplayItem > 0) {
      await pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.ease,
      );
    }
  }

  void onMenuButtonPressed() {
    context.pop();
  }

  Future<void> seekForward() async {
    await scrollForward();
  }

  Future<void> seekBackward() async {
    await scrollBackward();
  }

  void _queuePageScrolls(int steps) {
    _pendingPageScrolls += steps;
    unawaited(_drainPageScrolls());
  }

  Future<void> _drainPageScrolls() async {
    if (_isDrainingPageScrolls) {
      return;
    }
    if (displayItems.isEmpty) {
      _pendingPageScrolls = 0;
      return;
    }
    _isDrainingPageScrolls = true;
    try {
      while (mounted && pageController.hasClients && _pendingPageScrolls != 0) {
        final int step = _pendingPageScrolls > 0 ? 1 : -1;
        final double? current = pageController.page;
        if (current == null) {
          break;
        }
        final int target = (current.round() + step).clamp(
          0,
          displayItems.length - 1,
        );
        if (target == current.round()) {
          if (step > 0 && _pendingPageScrolls > 0) {
            _pendingPageScrolls = 0;
          } else if (step < 0 && _pendingPageScrolls < 0) {
            _pendingPageScrolls = 0;
          }
          break;
        }
        _pendingPageScrolls -= step;
        await pageController.animateToPage(
          target,
          duration: _pendingPageScrolls == 0
              ? const Duration(milliseconds: 300)
              : const Duration(milliseconds: 100),
          curve: Curves.ease,
        );
      }
    } finally {
      _isDrainingPageScrolls = false;
    }
    if (_pendingPageScrolls != 0) {
      await _drainPageScrolls();
    }
  }

  Future<void> rotateForward() async {
    if (_wheelStepAccumulator.isNegative) {
      // The wheel reversed direction; abandon the pending page credit so
      // the first page in the new direction does not lag behind.
      _wheelStepAccumulator = 0;
    }
    if (++_wheelStepAccumulator >= wheelStepsPerPageTurn) {
      _wheelStepAccumulator = 0;
      _queuePageScrolls(1);
    }
  }

  Future<void> rotateBackward() async {
    if (_wheelStepAccumulator > 0) {
      _wheelStepAccumulator = 0;
    }
    if (--_wheelStepAccumulator <= -wheelStepsPerPageTurn) {
      _wheelStepAccumulator = 0;
      _queuePageScrolls(-1);
    }
  }

  void seekForwardLongPress() {}

  void seekBackwardLongPress() {}

  void onLongPressEnd() {}

  Future<void> deviceControlHandler(_, DeviceAction? newState) async {
    if (newState == null || context.router.locationNamed != routeName) {
      return;
    }
    switch (newState) {
      case DeviceAction.menu:
        onMenuButtonPressed();
        break;
      case DeviceAction.select:
        onSelectPressed();
        break;
      case DeviceAction.selectLongPress:
        onSelectLongPress();
        break;
      case DeviceAction.rotateForward:
        await rotateForward();
        break;
      case DeviceAction.rotateBackward:
        await rotateBackward();
        break;
      case DeviceAction.seekForward:
        await seekForward();
        break;
      case DeviceAction.seekBackward:
        await seekBackward();
        break;
      case DeviceAction.seekForwardLongPress:
        seekForwardLongPress();
        break;
      case DeviceAction.seekBackwardLongPress:
        seekBackwardLongPress();
        break;
      case DeviceAction.playPause:
        break;
      case DeviceAction.longPressEnd:
        onLongPressEnd();
        break;
    }
  }

  void _updatePage() {
    setState(() {
      currentPage = pageController.page ?? currentPage;
      selectedDisplayItem = currentPage.toInt();
    });
  }

  @override
  void initState() {
    pageController = PageController(
      initialPage: initialPage,
      viewportFraction: viewPortFraction,
      keepPage: false,
    );
    pageController.addListener(_updatePage);
    super.initState();
    ref.listenManual(deviceButtonsServiceProvider, deviceControlHandler);
  }

  @override
  void dispose() {
    pageController.removeListener(_updatePage);
    pageController.dispose();
    super.dispose();
  }
}
