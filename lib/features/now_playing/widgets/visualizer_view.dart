import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retropod/core/extensions/build_context_extensions.dart';
import 'package:retropod/features/now_playing/services/visualizer_service.dart';

/// Full-screen EQ visualizer for the Now Playing screensaver. Streams real
/// FFT frames from the Android audio session and renders log-scaled bars;
/// falls back to an animated synthetic EQ when FFT capture is unavailable
/// or the frames go stale (e.g. playback paused).
class VisualizerView extends ConsumerStatefulWidget {
  const VisualizerView({super.key});

  @override
  ConsumerState<VisualizerView> createState() => _VisualizerViewState();
}

class _VisualizerViewState extends ConsumerState<VisualizerView>
    with SingleTickerProviderStateMixin {
  static const int _barCount = 24;
  static const int _fftBinCount = 128;
  static const Duration _fftStaleAfter = Duration(milliseconds: 250);

  late final Ticker _ticker;
  StreamSubscription<Uint8List>? _fftSubscription;
  final List<double> _targetLevels = List<double>.filled(_barCount, 0.0);
  final List<double> _displayLevels = List<double>.filled(_barCount, 0.0);
  final List<double> _peakLevels = List<double>.filled(_barCount, 0.0);
  bool _useRealFft = false;
  DateTime? _lastFftAt;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
    _ticker.start();
    unawaited(_attachRealFft());
  }

  @override
  void dispose() {
    unawaited(_fftSubscription?.cancel());
    unawaited(ref.read(visualizerServiceProvider).detach());
    _ticker.dispose();
    super.dispose();
  }

  /// Tries to attach the native FFT capture; falls back to the synthetic
  /// animation when the platform does not support it.
  Future<void> _attachRealFft() async {
    final bool attached = await ref.read(visualizerServiceProvider).attach();
    if (!mounted || !attached) {
      return;
    }
    _fftSubscription = ref
        .read(visualizerServiceProvider)
        .fftStream
        .listen(
          (Uint8List fft) {
            _lastFftAt = DateTime.now();
            _useRealFft = true;
            _updateTargetsFromFft(fft);
          },
          onDone: () {
            _useRealFft = false;
          },
          onError: (Object error) {
            _useRealFft = false;
          },
        );
  }

  /// Converts raw FFT bytes (signed pairs: real, imaginary) into log-scaled
  /// per-bar magnitudes so bass does not dominate the display.
  void _updateTargetsFromFft(Uint8List fft) {
    final int pairs = math.min(fft.length ~/ 2, _fftBinCount);
    if (pairs < 4) {
      return;
    }
    for (int bar = 0; bar < _barCount; bar++) {
      final int startBin = _barStartBin(bar, pairs);
      final int endBin = math.max(startBin + 1, _barStartBin(bar + 1, pairs));
      double maxMagnitude = 0;
      for (int bin = startBin; bin < endBin && bin < pairs; bin++) {
        final int re = fft[2 * bin] - 128;
        final int im = fft[2 * bin + 1] - 128;
        final double magnitude = math.sqrt(
          (re * re + im * im).toDouble(),
        );
        if (magnitude > maxMagnitude) {
          maxMagnitude = magnitude;
        }
      }
      _targetLevels[bar] = (maxMagnitude / 128).clamp(0.0, 1.0);
    }
  }

  /// Logarithmic frequency mapping across the FFT bins for each bar.
  int _barStartBin(int bar, int totalBins) {
    if (bar <= 0) {
      return 1;
    }
    if (bar >= _barCount) {
      return totalBins;
    }
    const double minBin = 2.0;
    final double maxBin = totalBins.toDouble();
    final double ratio = bar / _barCount;
    final double scaled = minBin * math.pow(maxBin / minBin, ratio);
    return scaled.floor().clamp(1, totalBins);
  }

  /// Synthetic animation used when real FFT frames are not flowing.
  void _updateTargetsSynthetic(Duration elapsed) {
    final double seconds = elapsed.inMicroseconds / 1e6;
    for (int bar = 0; bar < _barCount; bar++) {
      final double phase = seconds * (0.8 + bar * 0.23);
      final double wave =
          math.sin(phase) * 0.5 +
          math.sin(phase * 1.7 + bar * 1.3) * 0.3 +
          math.sin(phase * 0.6 + bar * 2.1) * 0.2;
      _targetLevels[bar] = ((wave + 0.5) / 1.5).clamp(0.0, 1.0);
    }
  }

  void _onTick(Duration elapsed) {
    final bool fftStale =
        _lastFftAt != null &&
        DateTime.now().difference(_lastFftAt!) > _fftStaleAfter;
    if (!_useRealFft || fftStale) {
      _updateTargetsSynthetic(elapsed);
    }
    const double attack = 0.45;
    const double decay = 0.1;
    for (int bar = 0; bar < _barCount; bar++) {
      final double target = _targetLevels[bar];
      final double current = _displayLevels[bar];
      final double smoothed =
          current + (target - current) * (target > current ? attack : decay);
      _displayLevels[bar] = smoothed.clamp(0.0, 1.0);
      if (_displayLevels[bar] > _peakLevels[bar]) {
        _peakLevels[bar] = _displayLevels[bar];
      } else {
        _peakLevels[bar] = math.max(0.0, _peakLevels[bar] - 0.008);
      }
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: context.appBackgroundColor,
      child: CustomPaint(
        painter: _VisualizerPainter(
          levels: _displayLevels,
          peaks: _peakLevels,
          barColor: context.appPrimaryTextColor,
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _VisualizerPainter extends CustomPainter {
  _VisualizerPainter({
    required this.levels,
    required this.peaks,
    required this.barColor,
  });

  final List<double> levels;
  final List<double> peaks;
  final Color barColor;

  @override
  void paint(Canvas canvas, Size size) {
    const double gapRatio = 0.28;
    final double barWidth = size.width / levels.length;
    final double barInnerWidth = barWidth * (1 - gapRatio);
    final double maxBarHeight = size.height * 0.92;
    final double baseline = size.height * 0.96;
    final double minBarHeight = size.height * 0.02;

    final Paint barPaint = Paint()..color = barColor;
    final Paint peakPaint = Paint()
      ..color = barColor.withValues(alpha: 0.45);

    for (int bar = 0; bar < levels.length; bar++) {
      final double left = bar * barWidth + (barWidth - barInnerWidth) / 2;
      final double barHeight =
          minBarHeight + levels[bar] * (maxBarHeight - minBarHeight);
      final Rect barRect = Rect.fromLTWH(
        left,
        baseline - barHeight,
        barInnerWidth,
        barHeight,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          barRect,
          Radius.circular(barInnerWidth / 3),
        ),
        barPaint,
      );
      final double peakY =
          baseline - minBarHeight - peaks[bar] * (maxBarHeight - minBarHeight);
      final Rect peakRect = Rect.fromLTWH(
        left,
        peakY,
        barInnerWidth,
        size.height * 0.006,
      );
      canvas.drawRect(peakRect, peakPaint);
    }
  }

  @override
  bool shouldRepaint(_VisualizerPainter oldDelegate) => true;
}
