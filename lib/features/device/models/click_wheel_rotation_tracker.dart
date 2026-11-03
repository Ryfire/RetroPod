import 'dart:math' as math;
import 'dart:ui';

/// Tracks the angular position of a pointer around the click wheel center and
/// converts the accumulated rotation into discrete scroll steps.
///
/// The angle is computed with the screen coordinate system in mind (the y axis
/// points downwards) so a clockwise rotation of the pointer around the wheel
/// produces positive (forward) steps and a counter clockwise rotation produces
/// negative (backward) steps.
///
/// The step threshold adapts to the angular velocity of the pointer so fast
/// spins emit more steps per revolution, mimicking the acceleration of a
/// physical click wheel. The velocity is smoothed with an exponential moving
/// average and it resets whenever tracking restarts or the pointer re-enters
/// the wheel from the inner deadzone.
///
/// Rotation that has not crossed the step threshold yet survives a quick
/// finger lift: when the pointer drifts off the wheel and is placed back down
/// within [liftCarryOverWindow] the gesture continues where it stopped, like
/// a physical wheel. The carry is discarded when the next touch lands after
/// the window has passed or when the rotation direction changes.
class ClickWheelRotationTracker {
  ClickWheelRotationTracker({
    required this.thresholdDegrees,
    required this.minVelocityDegreesPerSecond,
    required this.maxVelocityDegreesPerSecond,
    required this.accelerationFactor,
    required this.maxStepsPerEvent,
  }) : assert(thresholdDegrees > 0),
       assert(minVelocityDegreesPerSecond >= 0),
       assert(maxVelocityDegreesPerSecond > minVelocityDegreesPerSecond),
       assert(accelerationFactor >= 1),
       assert(maxStepsPerEvent >= 1);

  /// How long the rotation of a lifted pointer stays pending. A new touch
  /// within this window continues the previous gesture, otherwise the
  /// accumulated rotation is discarded.
  static const Duration liftCarryOverWindow = Duration(milliseconds: 400);

  /// Opposing deltas smaller than the decisive reversal cutoff are treated
  /// as digitizer jitter that only erodes the pending rotation.
  static const double _minDecisiveReversalDegrees = 1.5;

  /// Degrees of rotation required to emit a single scroll step when the
  /// pointer moves slowly.
  double thresholdDegrees;

  /// Angular velocity in degrees per second at which the step threshold
  /// reaches its minimum value.
  final double maxVelocityDegreesPerSecond;

  /// Angular velocity in degrees per second below which no acceleration is
  /// applied.
  final double minVelocityDegreesPerSecond;

  /// Maximum ratio between the base step threshold and the accelerated step
  /// threshold.
  double accelerationFactor;

  /// Maximum number of scroll steps emitted per pointer move event. The
  /// rotation that exceeds the cap stays accumulated and is emitted by the
  /// following events.
  final int maxStepsPerEvent;

  static const double _velocitySmoothing = 0.6;

  /// Opposing deltas at least this large count as a deliberate reversal
  /// that discards the pending rotation. The cutoff scales with the step
  /// threshold but never drops below the jitter floor so quantization
  /// noise can never look like a reversal.
  double get _decisiveReversalDegrees =>
      math.max(_minDecisiveReversalDegrees, thresholdDegrees / 8);

  int? _activePointerId;
  Offset? _wheelCenter;
  double? _innerDeadzoneRadius;
  double? _lastAngleRadians;
  int? _lastEventMicros;
  int? _lastEndEventMicros;
  double _angularVelocity = 0;
  double _accumulatedDegrees = 0;

  /// The id of the pointer currently being tracked, null when idle.
  int? get activePointerId => _activePointerId;

  /// The smoothed angular velocity of the pointer in degrees per second.
  double get velocityDegreesPerSecond => _angularVelocity;

  /// Applies new settings between gestures so a reused tracker always scrolls
  /// with the preferences the user picked most recently.
  void configure({
    required double thresholdDegrees,
    required double accelerationFactor,
  }) {
    assert(thresholdDegrees > 0);
    assert(accelerationFactor >= 1);
    this.thresholdDegrees = thresholdDegrees;
    this.accelerationFactor = accelerationFactor;
  }

  /// Starts tracking [pointerId] around the wheel.
  ///
  /// [innerDeadzoneRadius] defines the radius around the center of the wheel
  /// where the pointer angle is considered unreliable.
  ///
  /// Rotation left over from a previous gesture is kept when [timeStamp] lies
  /// within [liftCarryOverWindow] of the last lift and discarded otherwise.
  ///
  /// Returns false when another pointer is already being tracked.
  bool begin({
    required int pointerId,
    required Offset wheelCenter,
    required double innerDeadzoneRadius,
    required Duration timeStamp,
  }) {
    if (_activePointerId != null) {
      return false;
    }
    final int? lastEndEventMicros = _lastEndEventMicros;
    final int eventMicros = timeStamp.inMicroseconds;
    final int carryOverMicros = lastEndEventMicros == null
        ? -1
        : eventMicros - lastEndEventMicros;
    final bool withinCarryOverWindow =
        carryOverMicros >= 0 &&
        carryOverMicros <= liftCarryOverWindow.inMicroseconds;
    _activePointerId = pointerId;
    _wheelCenter = wheelCenter;
    _innerDeadzoneRadius = innerDeadzoneRadius;
    _lastAngleRadians = null;
    _lastEventMicros = null;
    _angularVelocity = 0;
    if (!withinCarryOverWindow) {
      _accumulatedDegrees = 0;
    }
    return true;
  }

  /// Converts the rotation of [pointerId] since the previous update into the
  /// number of scroll steps taken this event (forward is positive, backward is
  /// negative).
  int update({
    required int pointerId,
    required Offset localPosition,
    required Duration timeStamp,
  }) {
    if (_activePointerId != pointerId) {
      return 0;
    }
    final Offset? wheelCenter = _wheelCenter;
    final double? innerDeadzoneRadius = _innerDeadzoneRadius;
    if (wheelCenter == null || innerDeadzoneRadius == null) {
      return 0;
    }
    final Offset pointerOffset = localPosition - wheelCenter;
    if (pointerOffset.distance < innerDeadzoneRadius) {
      // The angle is unstable near the center of the wheel so forget the
      // previous angle and wait for the pointer to leave the deadzone.
      _lastAngleRadians = null;
      _lastEventMicros = null;
      _angularVelocity = 0;
      return 0;
    }
    final double angleRadians = math.atan2(pointerOffset.dy, pointerOffset.dx);
    final double? lastAngleRadians = _lastAngleRadians;
    final int eventMicros = timeStamp.inMicroseconds;
    if (lastAngleRadians == null) {
      // The first sample only anchors the angle so no step can be emitted.
      _lastAngleRadians = angleRadians;
      _lastEventMicros = eventMicros;
      return 0;
    }
    _lastAngleRadians = angleRadians;
    // The shortest signed difference between two angles (handles the ±180
    // degrees wraparound).
    final double deltaRadians = math.atan2(
      math.sin(angleRadians - lastAngleRadians),
      math.cos(angleRadians - lastAngleRadians),
    );
    final double deltaDegrees = deltaRadians * 180 / math.pi;
    _updateVelocity(deltaDegrees, eventMicros);
    // Tiny deltas that oppose the accumulated rotation are digitizer
    // jitter: the reported position oscillates between adjacent pixels
    // while the finger creeps forward. Erode the pending rotation by the
    // jitter instead of discarding it, otherwise slow movement loses its
    // progress and whole arcs of the wheel feel skipped. A large opposing
    // delta is a decisive reversal: drop the pending rotation so the first
    // step in the new direction fires promptly instead of waiting for the
    // old arc to unwind.
    if (_accumulatedDegrees != 0 &&
        deltaDegrees.isNegative != _accumulatedDegrees.isNegative &&
        deltaDegrees.abs() >= _decisiveReversalDegrees) {
      _accumulatedDegrees = 0;
    }
    _accumulatedDegrees += deltaDegrees;
    final double effectiveThreshold = _effectiveThresholdDegrees;
    int steps = 0;
    while (steps.abs() < maxStepsPerEvent &&
        _accumulatedDegrees.abs() >= effectiveThreshold) {
      if (_accumulatedDegrees.isNegative) {
        steps--;
        _accumulatedDegrees += effectiveThreshold;
      } else {
        steps++;
        _accumulatedDegrees -= effectiveThreshold;
      }
    }
    return steps;
  }

  /// Stops tracking [pointerId] and remembers the rotation that has not
  /// crossed the step threshold yet so a quick follow-up touch can continue
  /// the gesture.
  void end({required int pointerId, required Duration timeStamp}) {
    if (_activePointerId != pointerId) {
      return;
    }
    _lastEndEventMicros = timeStamp.inMicroseconds;
    _activePointerId = null;
    _wheelCenter = null;
    _innerDeadzoneRadius = null;
    _lastAngleRadians = null;
    _lastEventMicros = null;
    _angularVelocity = 0;
  }

  void _updateVelocity(double deltaDegrees, int eventMicros) {
    final int? lastEventMicros = _lastEventMicros;
    _lastEventMicros = eventMicros;
    if (lastEventMicros == null) {
      return;
    }
    final int deltaMicros = eventMicros - lastEventMicros;
    if (deltaMicros <= 0) {
      // The timestamps did not advance so the velocity is unknown.
      return;
    }
    final double instantaneous =
        deltaDegrees.abs() * Duration.microsecondsPerSecond / deltaMicros;
    if (_angularVelocity == 0) {
      _angularVelocity = instantaneous;
    } else {
      _angularVelocity =
          _velocitySmoothing * instantaneous +
          (1 - _velocitySmoothing) * _angularVelocity;
    }
  }

  double get _effectiveThresholdDegrees {
    final double speed = _angularVelocity.abs();
    if (speed <= minVelocityDegreesPerSecond) {
      return thresholdDegrees;
    }
    final double ramp =
        ((speed - minVelocityDegreesPerSecond) /
                (maxVelocityDegreesPerSecond - minVelocityDegreesPerSecond))
            .clamp(0.0, 1.0);
    final double minThreshold = thresholdDegrees / accelerationFactor;
    return thresholdDegrees + (minThreshold - thresholdDegrees) * ramp;
  }
}
