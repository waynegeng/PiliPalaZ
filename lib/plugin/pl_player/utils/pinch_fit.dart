import 'package:flutter/painting.dart';

/// Claim multi-touch until all fingers lift, and change fit once per pinch.
class PinchFitGesture {
  bool active = false;
  bool _handled = false;
  final Set<int> _pointers = {};

  void pointerDown(int pointer) {
    if (_pointers.isEmpty) reset();
    _pointers.add(pointer);
  }

  void pointerUp(int pointer) => _pointers.remove(pointer);

  void reset() {
    active = false;
    _handled = false;
  }

  BoxFit? update({
    required int pointerCount,
    required double scale,
    required bool fullScreen,
    required bool locked,
  }) {
    if (pointerCount >= 2) active = true;
    if (pointerCount != 2 || !fullScreen || locked || _handled) return null;
    // Ignore small changes while the second finger lands.
    if (scale > 1.08) {
      _handled = true;
      return BoxFit.cover;
    }
    if (scale < 0.92) {
      _handled = true;
      return BoxFit.contain;
    }
    return null;
  }
}
