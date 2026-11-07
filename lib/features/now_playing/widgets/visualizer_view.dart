import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retropod/core/extensions/build_context_extensions.dart';
import 'package:retropod/features/now_playing/services/visualizer_service.dart';

/// Full-screen EQ visualizer for the Now Playing screensaver. On Android it
/// streams real FFT frames from the audio session and renders log-scaled
/// bars (with a waveform-derived approximation when the device returns no
/// usable FFT energy); on platforms without native capture it falls back
/// to a purely cosmetic animated EQ. Real capture never fakes motion:
/// silence and missing frames decay the bars to a flat line.
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
  static const Duration _fftAliveWindow = Duration(seconds: 2);
  static const double _fftAliveThreshold = 0.04;
  static const int _maxAttachAttempts = 5;
  static const Duration _attachRetryDelay = Duration(seconds: 2);
  static const double _waveGain = 2.5;
  static const double _fftDbFloor = -45.0;

  late final Ticker _ticker;
  StreamSubscription<VisualizerFrame>? _framesSubscription;
  final List<double> _fftLevels = List<double>.filled(_barCount, 0.0);
  final List<double> _waveLevels = List<double>.filled(_barCount, 0.0);
  final List<double> _targetLevels = List<double>.filled(_barCount, 0.0);
  final List<double> _displayLevels = List<double>.filled(_barCount, 0.0);
  final List<double> _peakLevels = List<double>.filled(_barCount, 0.0);
  late final bool _platformSupportsCapture;
  bool _captureAttached = false;
  DateTime? _lastFrameAt;
  DateTime? _fftLastAliveAt;
  int _attachAttempts = 0;

  @override
  void initState() {
    super.initState();
    _platformSupportsCapture =
        !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
    _ticker = createTicker(_onTick);
    _ticker.start();
    if (_platformSupportsCapture) {
      unawaited(_attachRealFft());
    }
  }

  @override
  void dispose() {
    unawaited(_framesSubscription?.cancel());
    unawaited(ref.read(visualizerServiceProvider).detach());
    _ticker.dispose();
    super.dispose();
  }

  /// Tries to attach the native capture, retrying a few times in case the
  /// first attempt raced ahead of the audio session. If every attempt
  /// fails, the bars stay at an honest flat line instead of animating.
  Future<void> _attachRealFft() async {
    final bool attached = await ref.read(visualizerServiceProvider).attach();
    if (!mounted) {
      return;
    }
    if (!attached) {
      _attachAttempts++;
      if (_attachAttempts < _maxAttachAttempts) {
        await Future<void>.delayed(_attachRetryDelay);
        if (mounted) {
          unawaited(_attachRealFft());
        }
      }
      return;
    }
    _captureAttached = true;
    _framesSubscription = ref
        .read(visualizerServiceProvider)
        .framesStream
        .listen(
          _onFrame,
          onDone: () {
            _captureAttached = false;
          },
          onError: (Object error) {
            _captureAttached = false;
          },
        );
  }

  /// Routes incoming native frames: FFT frames feed the spectrum bars, and
  /// waveform frames provide an audio-reactive fallback when the device
  /// returns no usable FFT energy.
  void _onFrame(VisualizerFrame frame) {
    _lastFrameAt = DateTime.now();
    if (frame.isFft) {
      if (_updateFftLevels(frame.data)) {
        _fftLastAliveAt = _lastFrameAt;
      }
    } else {
      _updateWaveLevels(frame.data);
    }
  }

  /// Converts raw FFT bytes (signed pairs: real, imaginary) into log-scaled
  /// per-bar magnitudes so bass does not dominate the display. Returns
  /// whether the frame contained audible energy.
  bool _updateFftLevels(Uint8List fft) {
    final int pairs = math.min(fft.length ~/ 2, _fftBinCount);
    if (pairs < 4) {
      return false;
    }
    bool hasEnergy = false;
    for (int bar = 0; bar < _barCount; bar++) {
      final int startBin = _barStartBin(bar, pairs);
      final int endBin = math.max(startBin + 1, _barStartBin(bar + 1, pairs));
      double maxMagnitude = 0;
      for (int bin = startBin; bin < endBin && bin < pairs; bin++) {
        final int re = _fftSignedByte(fft[2 * bin]);
        final int im = _fftSignedByte(fft[2 * bin + 1]);
        final double magnitude = math.sqrt(
          (re * re + im * im).toDouble(),
        );
        if (magnitude > maxMagnitude) {
          maxMagnitude = magnitude;
        }
      }
      // dB-scale the magnitudes (0 dB = full scale at 128): raw linear
      // levels saturate on loud passages, while a -45 dB floor keeps the
      // bars spread across the range like a classic EQ.
      final double db =
          20 * math.log(math.max(maxMagnitude, 1.0) / 128) / math.ln10;
      _fftLevels[bar] = ((db - _fftDbFloor) / -_fftDbFloor).clamp(0.0, 1.0);
      if (_fftLevels[bar] > _fftAliveThreshold) {
        hasEnergy = true;
      }
    }
    return hasEnergy;
  }

  /// Converts an Android FFT byte to its signed value. Unlike the waveform
  /// capture (unsigned, zero at 128), FFT bytes are 8-bit signed; decoding
  /// them as centered-at-128 inflates every near-zero bin to magnitude ~128
  /// and pins all bars to the top.
  static int _fftSignedByte(int byte) => ((byte & 0xFF) ^ 0x80) - 128;

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

  /// Derives per-bar levels from waveform samples when the FFT stream
  /// carries no usable energy: splits the buffer into segments, estimates
  /// each segment's dominant frequency from its zero-crossing rate, and
  /// deposits its RMS energy on the bars nearest that frequency.
  void _updateWaveLevels(Uint8List wave) {
    const int segmentCount = 8;
    final int segmentLength = wave.length ~/ segmentCount;
    if (segmentLength < 16) {
      return;
    }
    _waveLevels.fillRange(0, _barCount, 0.0);
    for (int segment = 0; segment < segmentCount; segment++) {
      final int offset = segment * segmentLength;
      double sumSquares = 0;
      int crossings = 0;
      int previous = wave[offset] - 128;
      for (int i = 1; i < segmentLength; i++) {
        final int sample = wave[offset + i] - 128;
        sumSquares += sample * sample;
        if ((sample >= 0) != (previous >= 0)) {
          crossings++;
        }
        previous = sample;
      }
      final double rms = math.sqrt(sumSquares / segmentLength) / 128;
      // Crossings per sample -> cycles per sample -> fraction of the
      // Nyquist rate.
      final double normalizedFrequency =
          (crossings / (segmentLength - 1)).clamp(0.0, 1.0);
      final double position = normalizedFrequency * (_barCount - 1);
      final int center = position.round().clamp(0, _barCount - 1);
      for (int bar = math.max(0, center - 1);
          bar <= math.min(_barCount - 1, center + 1);
          bar++) {
        final double contribution =
            (rms * _waveGain * (1.0 - (bar - position).abs() * 0.5))
                .clamp(0.0, 1.0);
        if (contribution > _waveLevels[bar]) {
          _waveLevels[bar] = contribution;
        }
      }
    }
  }

  /// Synthetic animation used only on platforms without native capture
  /// (web, desktop): a purely cosmetic layered sine wave.
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
    final DateTime now = DateTime.now();
    final bool framesStale =
        _lastFrameAt != null &&
        now.difference(_lastFrameAt!) > _fftStaleAfter;
    if (!_platformSupportsCapture) {
      _updateTargetsSynthetic(elapsed);
    } else if (!_captureAttached || framesStale) {
      // Real capture is expected but no frames are flowing (attached yet
      // the engine holds silence, the stream died, or attaching is still
      // in flight): decay to an honest flat line instead of faking
      // motion.
      for (int bar = 0; bar < _barCount; bar++) {
        _targetLevels[bar] = 0;
      }
    } else {
      // Prefer the real FFT spectrum while it is producing energy; the
      // waveform approximation takes over when the device's FFT output
      // stays dead.
      final bool fftAlive =
          _fftLastAliveAt != null &&
          now.difference(_fftLastAliveAt!) <= _fftAliveWindow;
      for (int bar = 0; bar < _barCount; bar++) {
        _targetLevels[bar] = fftAlive ? _fftLevels[bar] : _waveLevels[bar];
      }
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
