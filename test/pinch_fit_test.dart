import 'package:PiliPalaX/plugin/pl_player/utils/pinch_fit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('outward pinch crops, inward pinch restores auto, once per gesture', () {
    final gesture = PinchFitGesture();
    BoxFit? update(double scale) => gesture.update(
        pointerCount: 2, scale: scale, fullScreen: true, locked: false);
    expect(update(1.03), isNull);
    expect(update(1.2), BoxFit.cover);
    expect(update(0.7), isNull);
    gesture.reset();
    expect(update(0.8), BoxFit.contain);
    expect(update(0.6), isNull);
  });

  test(
      'single fingers, locked controls and windowed playback do not change fit',
      () {
    for (final pointerCount in [1, 2, 3]) {
      for (final fullScreen in [true, false]) {
        for (final locked in [true, false]) {
          if (pointerCount == 2 && fullScreen && !locked) continue;
          expect(
              PinchFitGesture().update(
                  pointerCount: pointerCount,
                  scale: 1.5,
                  fullScreen: fullScreen,
                  locked: locked),
              isNull);
        }
      }
    }
  });

  test('lifting one finger does not turn a pinch into a seek', () {
    final gesture = PinchFitGesture();
    gesture.update(pointerCount: 2, scale: 1, fullScreen: true, locked: false);
    gesture.update(pointerCount: 1, scale: 1, fullScreen: true, locked: false);
    expect(gesture.active, isTrue);
    gesture.reset();
    expect(gesture.active, isFalse);
  });

  testWidgets(
      'real two-finger gestures change fit with viewer scaling disabled',
      (tester) async {
    final gesture = PinchFitGesture();
    final fits = <BoxFit>[];
    final transform = TransformationController();
    addTearDown(transform.dispose);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Listener(
          onPointerDown: (event) => gesture.pointerDown(event.pointer),
          onPointerUp: (event) => gesture.pointerUp(event.pointer),
          onPointerCancel: (event) => gesture.pointerUp(event.pointer),
          child: InteractiveViewer(
            transformationController: transform,
            panEnabled: false,
            scaleEnabled: false,
            onInteractionUpdate: (details) {
              final fit = gesture.update(
                  pointerCount: details.pointerCount,
                  scale: details.scale,
                  fullScreen: true,
                  locked: false);
              if (fit != null) fits.add(fit);
            },
            child: const SizedBox.expand(),
          ),
        ),
      ),
    ));
    final first = await tester.startGesture(const Offset(250, 300), pointer: 1);
    final second =
        await tester.startGesture(const Offset(450, 300), pointer: 2);
    await first.moveTo(const Offset(200, 300));
    await second.moveTo(const Offset(500, 300));
    expect(fits, [BoxFit.cover]);
    await first.up();
    await second.up();
    // No movement between lifting fingers: Flutter may omit the final scale-end.
    final third = await tester.startGesture(const Offset(200, 300), pointer: 3);
    final fourth =
        await tester.startGesture(const Offset(500, 300), pointer: 4);
    await third.moveTo(const Offset(250, 300));
    await fourth.moveTo(const Offset(450, 300));
    expect(fits, [BoxFit.cover, BoxFit.contain]);
    expect(transform.value.getMaxScaleOnAxis(), 1);
    await third.up();
    await fourth.up();
  });
}
