import 'dart:async';
import 'dart:io';

import 'package:pilipalaz/plugin/pl_player/utils/fullscreen.dart';
import 'package:pilipalaz/utils/storage.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  final calls = <MethodCall>[];
  late Directory directory;
  const portrait = ['DeviceOrientation.portraitUp'];
  const rotating = [
    ...portrait,
    'DeviceOrientation.landscapeLeft',
    'DeviceOrientation.landscapeRight'
  ];

  setUpAll(() async {
    directory = await Directory.systemTemp.createTemp('orientation_test');
    Hive.init(directory.path);
    GStorage.setting = await Hive.openBox('setting');
  });
  setUp(() async {
    await GStorage.setting.clear();
    calls.clear();
    binding.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
      calls.add(call);
      return null;
    });
  });
  tearDown(() {
    stopScreenTimer();
    binding.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });
  tearDownAll(() async {
    await Hive.close();
    await directory.delete(recursive: true);
  });

  test('disabled auto rotation explicitly clears a landscape lock', () async {
    await GStorage.setting.put(SettingBoxKey.allowRotateScreen, false);
    await autoScreen();
    expect(calls.last.method, 'SystemChrome.setPreferredOrientations');
    expect(calls.last.arguments, portrait);
  });

  test('enabled auto rotation restores all supported directions', () async {
    await autoScreen();
    expect(calls.last.arguments, rotating);
  });

  testWidgets(
      'closing during a pending portrait call does not arm a stale timer',
      (tester) async {
    final pending = Completer<void>();
    binding.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
      calls.add(call);
      if (calls.length == 1) await pending.future;
      return null;
    });
    final portraitRequest = verticalScreenForTwoSeconds();
    await tester.pump();
    await restoreAppOrientation();
    pending.complete();
    await portraitRequest;
    expect(screenTimer, isNull);
    await tester.pump(const Duration(seconds: 3));
    expect(calls.length, 2);
  });

  testWidgets('closing a page cancels the delayed auto-rotation reset',
      (tester) async {
    await verticalScreenForTwoSeconds();
    await restoreAppOrientation();
    final count = calls.length;
    await tester.pump(const Duration(seconds: 3));
    expect(calls.length, count);
    expect(calls.last.arguments, portrait);
    expect(screenTimer, isNull);
  });

  testWidgets('repeated portrait requests replace the previous timer',
      (tester) async {
    await verticalScreenForTwoSeconds();
    await tester.pump(const Duration(seconds: 1));
    await verticalScreenForTwoSeconds();
    await tester.pump(const Duration(seconds: 1));
    expect(calls.last.arguments, portrait);
    expect(calls.length, 2);
    await tester.pump(const Duration(seconds: 1));
    expect(calls.last.arguments, rotating);
    expect(screenTimer, isNull);
  });

  test(
      'leaving playback restores tablet app policy independently of player setting',
      () async {
    await GStorage.setting.put(SettingBoxKey.horizontalScreen, true);
    await GStorage.setting.put(SettingBoxKey.allowRotateScreen, false);
    await restoreAppOrientation();
    expect(calls.last.arguments, rotating);
  });
}
