import 'dart:io';

import 'package:pilipalaz/pages/home/controller.dart';
import 'package:pilipalaz/pages/home/view.dart';
import 'package:pilipalaz/pages/home/widgets/pure_home_search.dart';
import 'package:pilipalaz/pages/rcmd/controller.dart';
import 'package:pilipalaz/utils/storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;

  setUpAll(() async {
    directory = await Directory.systemTemp.createTemp('pure_home_test');
    Hive.init(directory.path);
    GStorage.setting = await Hive.openBox('setting');
    GStorage.userInfo = await Hive.openBox('userInfo');
  });

  setUp(() async {
    await GStorage.setting.clear();
    await GStorage.setting.put(SettingBoxKey.pureHome, true);
  });

  tearDown(() async => Get.reset());
  tearDownAll(() async {
    await Hive.close();
    await directory.delete(recursive: true);
  });

  Widget app(Widget home) => GetMaterialApp(
        home: home,
        getPages: [
          GetPage(name: '/search', page: () => const Text('history page')),
          GetPage(
            name: '/searchResult',
            page: () =>
                Scaffold(body: Text('result: ${Get.parameters['keyword']}')),
          ),
        ],
      );

  testWidgets('pure home mounts no recommendations and refresh is safe',
      (tester) async {
    await tester.pumpWidget(app(const HomePage()));
    await tester.pumpAndSettle();
    expect(find.byType(PureHomeSearch), findsOneWidget);
    expect(find.byType(TabBarView), findsNothing);
    expect(Get.isRegistered<RcmdController>(), isFalse);
    final controller = Get.find<HomeController>();
    controller.onRefresh();
    controller.animateToTop();
    expect(tester.takeException(), isNull);

    // Stand in for feed bodies so toggling the real Hive setting needs no API.
    controller.tabsPageList = List.generate(
        controller.tabs.length, (index) => Center(child: Text('feed $index')));
    await tester
        .runAsync(() => GStorage.setting.put(SettingBoxKey.pureHome, false));
    await tester.pumpAndSettle();
    expect(find.byType(PureHomeSearch), findsNothing);
    expect(find.byType(TabBarView), findsOneWidget);
    await tester
        .runAsync(() => GStorage.setting.put(SettingBoxKey.pureHome, true));
    await tester.pumpAndSettle();
    expect(find.byType(PureHomeSearch), findsOneWidget);
    expect(find.byType(TabBarView), findsNothing);
  });

  testWidgets(
      'focus stays home; empty search does nothing; Enter opens results',
      (tester) async {
    await tester.pumpWidget(app(const Scaffold(body: PureHomeSearch())));
    final field = find.byType(TextField);
    expect(tester.getCenter(field).dy, closeTo(300, 1));
    await tester.tap(field);
    await tester.pumpAndSettle();
    expect(find.text('history page'), findsNothing);
    expect(find.byType(PureHomeSearch), findsOneWidget);
    await tester.enterText(field, '   ');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
    expect(find.byType(PureHomeSearch), findsOneWidget);
    await tester.enterText(field, '  Flutter 中文 & 测试  ');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
    expect(find.text('result: Flutter 中文 & 测试'), findsOneWidget);
    expect(find.text('history page'), findsNothing);
    Get.back();
    await tester.pumpAndSettle();
    expect(find.byType(PureHomeSearch), findsOneWidget);
    expect(find.text('  Flutter 中文 & 测试  '), findsOneWidget);
  });

  testWidgets('search button submits and narrow landscape fits',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(568, 280));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(app(const Scaffold(body: PureHomeSearch())));
    await tester.enterText(find.byType(TextField), 'bilibili');
    await tester.tap(find.byTooltip('搜索'));
    await tester.pumpAndSettle();
    expect(find.text('result: bilibili'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
