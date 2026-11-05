import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retropod/core/constants/app_palette.dart';
import 'package:retropod/core/extensions/build_context_extensions.dart';
import 'package:retropod/features/now_playing/provider/now_playing_details_provider.dart';
import 'package:retropod/features/settings/controller/settings_preferences_controller.dart';
import 'package:retropod/features/settings/models/settings_preferences_model.dart';
import 'package:retropod/features/settings/models/status_bar_clock_format.dart';
import 'package:retropod/features/status_bar/widgets/battery_indicator.dart';

class StatusBarClockState {
  final bool visible;
  final StatusBarClockFormat format;

  const StatusBarClockState({
    required this.visible,
    required this.format,
  });

  const StatusBarClockState.hidden()
    : visible = false,
      format = StatusBarClockFormat.twentyFourHour;
}

/// The status bar clock state derived from the settings. Falls back to
/// hidden when the preferences are unavailable, e.g. widget tests that
/// pump screens directly without initializing SharedPreferences.
final statusBarClockStateProvider = Provider<StatusBarClockState>((ref) {
  try {
    final SettingsPreferencesModel settings = ref.watch(
      settingsPreferencesControllerProvider,
    );
    return StatusBarClockState(
      visible: settings.showStatusBarClock,
      format: settings.statusBarClockFormat,
    );
  } catch (_) {
    return const StatusBarClockState.hidden();
  }
});

class StatusBar extends StatelessWidget {
  final String title;

  const StatusBar({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    final isDarkTheme =
        CupertinoTheme.of(context).brightness == Brightness.dark;
    final gradientColors = isDarkTheme
        ? const [
            AppPalette.darkStatusBarGradientColor1,
            AppPalette.darkStatusBarGradientColor2,
          ]
        : const [
            AppPalette.statusBarGradientColor1,
            AppPalette.statusBarGradientColor2,
          ];
    final borderColor = isDarkTheme
        ? AppPalette.darkStatusBarBorderColor
        : AppPalette.statusBarBorderColor;

    return SizedBox(
      height: 30,
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: gradientColors,
          ),
          border: Border(bottom: BorderSide(color: borderColor)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: CupertinoColors.black,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                ),
              ),
              Consumer(
                builder: (context, ref, child) {
                  final StatusBarClockState clock = ref.watch(
                    statusBarClockStateProvider,
                  );
                  if (!clock.visible) {
                    return child!;
                  }
                  return _StatusBarClock(format: clock.format);
                },
                child: const SizedBox.shrink(),
              ),
              Consumer(
                builder: (context, ref, child) {
                  final isPlaying = ref.watch(
                    nowPlayingDetailsProvider.select((e) => e.isPlaying),
                  );
                  return Icon(
                    isPlaying
                        ? CupertinoIcons.play_fill
                        : CupertinoIcons.pause_fill,
                    color: context.appHighlightColor,
                  );
                },
              ),
              const SizedBox(width: 2),
              const RepaintBoundary(child: BatteryIndicator()),
            ],
          ),
        ),
      ),
    );
  }
}

/// Live wall-clock text for the status bar, refreshed on the minute so the
/// home screen does not rebuild every frame.
class _StatusBarClock extends StatefulWidget {
  final StatusBarClockFormat format;

  const _StatusBarClock({required this.format});

  @override
  State<_StatusBarClock> createState() => _StatusBarClockState();
}

class _StatusBarClockState extends State<_StatusBarClock> {
  Timer? _timer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _scheduleNextMinuteTick();
  }

  @override
  void didUpdateWidget(_StatusBarClock oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.format != widget.format) {
      setState(() => _now = DateTime.now());
    }
  }

  void _scheduleNextMinuteTick() {
    final DateTime now = DateTime.now();
    final Duration untilNextMinute = Duration(
      seconds: 60 - now.second,
      milliseconds: 1000 - now.millisecond,
    );
    _timer = Timer(untilNextMinute, () {
      if (!mounted) {
        return;
      }
      setState(() => _now = DateTime.now());
      _scheduleNextMinuteTick();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      widget.format.format(_now),
      style: const TextStyle(
        color: CupertinoColors.black,
        fontSize: 12,
        fontWeight: FontWeight.bold,
      ),
      maxLines: 1,
    );
  }
}
