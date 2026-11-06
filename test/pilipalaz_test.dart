import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:pilipalaz/pages/setting/pages/dynamic_tabbar_set.dart';
import 'package:dio/dio.dart';
import 'package:pilipalaz/http/init.dart';
import 'package:pilipalaz/pages/about/index.dart';
import 'package:pilipalaz/pages/dynamics/tab/controller.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart' hide Response;
import 'package:hive/hive.dart';
import 'package:pilipalaz/models/common/dynamic_tab_config.dart';
import 'package:pilipalaz/models/dynamics/result.dart';
import 'package:pilipalaz/models/dynamics/video_card_adapter.dart';
import 'package:pilipalaz/pages/dynamics/controller.dart';
import 'package:pilipalaz/pages/dynamics/widgets/header_scroll.dart';
import 'package:pilipalaz/pages/setting/view.dart';
import 'package:pilipalaz/common/widgets/video_card_v.dart';
import 'package:pilipalaz/utils/storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory temp;
  setUpAll(() async {
    temp = await Directory.systemTemp.createTemp('pilipalaz_test');
    Hive.init(temp.path);
    GStorage.setting = await Hive.openBox('setting');
    GStorage.userInfo = await Hive.openBox('user');
    GStorage.localCache = await Hive.openBox('local');
  });
  setUp(() async {
    await GStorage.setting.clear();
  });
  tearDown(() async {
    Get.reset();
  });
  tearDownAll(() async {
    await Hive.close();
    await temp.delete(recursive: true);
  });

  test('tab configuration removes unknown/duplicate IDs and never empties', () {
    expect(DynamicTabConfig.normalize(['video', 'up', 'video', 'bad']),
        ['video', 'up']);
    expect(DynamicTabConfig.normalize([]), ['all']);
    expect(DynamicTabConfig.normalize(null), DynamicTabConfig.ids);
  });
  test('legacy default maps to stable ID regardless of visible order', () {
    expect(DynamicTabConfig.defaultId(null, 1, ['up', 'video']), 'video');
    expect(DynamicTabConfig.defaultId('article', 1, ['up', 'video']), 'up');
    expect(DynamicTabConfig.defaultId(null, 999, ['video']), 'video');
  });
  testWidgets('reordering preserves selected tab; hiding Up clears selection',
      (tester) async {
    late DynamicsController controller;
    await tester.runAsync(() async {
      controller = Get.put(DynamicsController());
    });
    controller.tabController.index = 4;
    controller.mid.value = 123;
    await tester.runAsync(
        () => GStorage.setting.put(SettingBoxKey.dynamicTabs, ['video', 'up']));
    await tester.runAsync(() async {
      controller.applyTabConfig();
    });
    await tester.pump();
    expect(controller.currentTab, 'up');
    await tester.runAsync(
        () => GStorage.setting.put(SettingBoxKey.dynamicTabs, ['video']));
    await tester.runAsync(() async {
      controller.applyTabConfig();
    });
    await tester.pump();
    expect(controller.currentTab, 'video');
    expect(controller.showUpPanel, isFalse);
    expect(controller.mid.value, -1);
    controller.onSelectUp(456);
    expect(controller.mid.value, -1);
    controller.animateToTop();
    expect(tester.takeException(), isNull);
  });
  DynamicItemModel sample({bool statistics = true}) =>
      DynamicItemModel.fromJson({
        'id_str': '123',
        'type': 'DYNAMIC_TYPE_AV',
        'modules': {
          'module_author': {'mid': 123, 'name': '示例作者'},
          'module_dynamic': {
            'major': {
              'type': 'MAJOR_TYPE_ARCHIVE',
              'archive': {
                'aid': 170001,
                'bvid': 'BV17x411w7KC',
                'cover': 'https://example.com/cover.jpg',
                'title': '投稿示例',
                'duration_text': '01:02:03',
                if (statistics) 'stat': {'play': '1.2万', 'danmaku': '25'},
              }
            }
          },
        },
      });
  test('video adapter retains API display statistics and author', () {
    final video = dynamicVideoCard(sample())!;
    expect(video.title, '投稿示例');
    expect(video.owner!.mid, 123);
    expect(video.stat!.view, '1.2万');
    expect(video.stat!.danmu, '25');
    expect(video.duration, 3723);
    expect(video.cid, isNull);
  });
  test('absent statistics stay absent and malformed videos are rejected', () {
    expect(dynamicVideoCard(sample(statistics: false))!.stat!.view, isNull);
    expect(dynamicVideoCard(DynamicItemModel()), isNull);
    final invalid = sample();
    invalid.modules!.moduleDynamic!.major!.archive!.bvid = ' ';
    expect(dynamicVideoCard(invalid), isNull);
  });
  test('empty releases and failed checks never report latest', () async {
    Request();
    Request.dio.interceptors.clear();
    dynamic response = [];
    Request.dio.interceptors
        .add(InterceptorsWrapper(onRequest: (options, handler) {
      expect(options.path, contains('waynegeng/PiliPalaZ/releases'));
      handler.resolve(Response(requestOptions: options, data: response));
    }));
    final about = AboutController();
    about.currentVersion.value = '1.2.0+114515';
    await about.getRemoteApp();
    expect(about.updateStatus.value, '暂无发布版本');
    expect(about.isUpdate.value, isFalse);
    response = {'message': 'rate limited'};
    await about.getRemoteApp();
    expect(about.updateStatus.value, contains('失败'));
    expect(about.isLoading.value, isFalse);
    about.onClose();
  });
  test('video pagination keeps type and offset; refresh replaces content',
      () async {
    Request();
    Request.dio.interceptors.clear();
    final offsets = <String>[];
    Request.dio.interceptors
        .add(InterceptorsWrapper(onRequest: (options, handler) {
      expect(options.queryParameters['type'], 'video');
      expect(options.queryParameters.containsKey('host_mid'), isFalse);
      offsets.add(options.queryParameters['offset']);
      handler.resolve(Response(requestOptions: options, data: {
        'code': 0,
        'data': {
          'items': [
            {'id_str': '${offsets.length}'}
          ],
          'offset': 'next'
        }
      }));
    }));
    final controller = DynamicsTabController();
    await controller.queryFollowDynamic('init', 'video', -1);
    await controller.onLoad();
    expect(controller.dynamicsList.length, 2);
    await controller.onRefresh();
    expect(controller.dynamicsList.length, 1);
    expect(offsets, ['', 'next', '']);
    controller.onClose();
  });
  testWidgets('shared card content renders missing statistics safely',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: SizedBox(
                width: 240,
                height: 100,
                child: Column(children: [
                  VideoContent(
                      videoItem: dynamicVideoCard(sample(statistics: false))!)
                ])))));
    expect(find.text('示例作者'), findsOneWidget);
    expect(find.text('0'), findsNothing);
    expect(tester.takeException(), isNull);
  });
  testWidgets('tab editor keeps one visible tab and persists across reopen',
      (tester) async {
    Widget editor() => GetMaterialApp(
        builder: FlutterSmartDialog.init(), home: const DynamicTabbarSetPage());
    await tester.pumpWidget(editor());
    for (final id in ['all', 'pgc', 'article', 'up']) {
      await tester.tap(find.byKey(ValueKey(id)));
      await tester.pump();
    }
    await tester.tap(find.byKey(const ValueKey('video')));
    await tester.pump();
    expect(
        tester
            .widget<CheckboxListTile>(find.byKey(const ValueKey('video')))
            .value,
        isTrue);
    await tester.runAsync(() async {
      await tester.tap(find.text('保存'));
      await GStorage.setting.flush();
    });
    await tester.pump();
    expect(GStorage.setting.get(SettingBoxKey.dynamicTabs), ['video']);
    expect(GStorage.setting.get(SettingBoxKey.defaultDynamicTab), 'video');
    SmartDialog.dismiss(status: SmartStatus.allToast);
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(editor());
    expect(
        tester
            .widget<CheckboxListTile>(find.byKey(const ValueKey('all')))
            .value,
        isFalse);
    expect(
        tester
            .widget<CheckboxListTile>(find.byKey(const ValueKey('video')))
            .value,
        isTrue);
    expect(tester.takeException(), isNull);
  });
  testWidgets('settings contains exactly five primary categories',
      (tester) async {
    await tester.pumpWidget(const GetMaterialApp(home: SettingPage()));
    for (final title in ['一般设置', '播放设置', '首页设置', '动态设置', '账号设置']) {
      expect(find.text(title), findsOneWidget);
    }
    expect(find.byType(ListTile), findsNWidgets(5));
    expect(find.text('关于'), findsNothing);
  });
  testWidgets(
      'header hides on upward content scroll and restores downward or at top',
      (tester) async {
    bool visible = true;
    bool enabled = true;
    final scroll = ScrollController();
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: DynamicHeaderScroll(
      enabled: () => enabled,
      onVisibilityChanged: (value) => visible = value,
      child: ListView.builder(
          controller: scroll,
          itemExtent: 60,
          itemCount: 100,
          itemBuilder: (_, i) => Text('$i')),
    ))));
    scroll.jumpTo(300);
    await tester.pump();
    expect(visible, isTrue);
    await tester.drag(find.byType(ListView), const Offset(0, -180));
    await tester.pumpAndSettle();
    expect(visible, isFalse);
    await tester.drag(find.byType(ListView), const Offset(0, 100));
    await tester.pumpAndSettle();
    expect(visible, isTrue);
    await tester.drag(find.byType(ListView), const Offset(0, -180));
    await tester.pumpAndSettle();
    scroll.jumpTo(0);
    await tester.pump();
    expect(visible, isTrue);
    await tester.drag(find.byType(ListView), const Offset(0, -180));
    await tester.pumpAndSettle();
    expect(visible, isFalse,
        reason: 'a gesture starting at the top must hide the header');
    enabled = false;
    await tester.drag(find.byType(ListView), const Offset(0, -180));
    await tester.pumpAndSettle();
    expect(visible, isTrue);
    await tester.pumpWidget(const SizedBox());
    scroll.dispose();
  });
}
