import 'dart:async';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:auto_orientation/auto_orientation.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../../utils/storage.dart';

Timer? screenTimer;
int _screenRevision = 0;
void stopScreenTimer() {
  _screenRevision++;
  screenTimer?.cancel();
  screenTimer = null;
}

//横屏
Future<void> landScape() async {
  stopScreenTimer();
  dynamic document;
  try {
    if (kIsWeb) {
      await document.documentElement?.requestFullscreen();
    } else if (Platform.isAndroid || Platform.isIOS) {
      await AutoOrientation.landscapeAutoMode(forceSensor: true);
    } else if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
      await const MethodChannel('com.alexmercerind/media_kit_video')
          .invokeMethod(
        'Utils.EnterNativeFullscreen',
      );
    }
  } catch (exception, stacktrace) {
    debugPrint(exception.toString());
    debugPrint(stacktrace.toString());
  }
}

//竖屏
Future<void> verticalScreenForTwoSeconds() async {
  stopScreenTimer();
  final revision = _screenRevision;
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  // A page may have closed (or entered full screen) during the platform call.
  if (revision != _screenRevision) return;
  screenTimer = Timer(const Duration(seconds: 2), () {
    screenTimer = null;
    autoScreen();
  });
}

//竖屏
Future<void> verticalScreen() async {
  stopScreenTimer();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
}

//全向
Future<void> autoScreen() async {
  stopScreenTimer();
  if (!GStorage.setting
      .get(SettingBoxKey.allowRotateScreen, defaultValue: true)) {
    // Explicitly clear any sensor-landscape lock left by full-screen playback.
    await verticalScreen();
    return;
  }
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    // DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
}

/// Restore the app layout policy when leaving a video/live page.
Future<void> restoreAppOrientation() async {
  stopScreenTimer();
  final horizontal =
      GStorage.setting.get(SettingBoxKey.horizontalScreen, defaultValue: false);
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    if (horizontal) ...[
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ],
  ]);
}

Future<void> fullAutoModeForceSensor() async {
  stopScreenTimer();
  await AutoOrientation.fullAutoMode(forceSensor: true);
}

Future<void> hideStatusBar() async {
  await SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.immersiveSticky,
  );
}

//退出全屏显示
Future<void> showStatusBar() async {
  dynamic document;
  late SystemUiMode mode = SystemUiMode.edgeToEdge;
  try {
    if (kIsWeb) {
      document.exitFullscreen();
    } else if (Platform.isAndroid || Platform.isIOS) {
      if (Platform.isAndroid &&
          (await DeviceInfoPlugin().androidInfo).version.sdkInt < 29) {
        mode = SystemUiMode.manual;
      }
      await SystemChrome.setEnabledSystemUIMode(
        mode,
        overlays: SystemUiOverlay.values,
      );
    } else if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
      await const MethodChannel('com.alexmercerind/media_kit_video')
          .invokeMethod(
        'Utils.ExitNativeFullscreen',
      );
    }
  } catch (exception, stacktrace) {
    debugPrint(exception.toString());
    debugPrint(stacktrace.toString());
  }
}
