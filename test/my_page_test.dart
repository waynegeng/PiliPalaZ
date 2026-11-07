import 'package:dio/dio.dart' as dio;
import 'package:pilipalaz/http/init.dart';
import 'package:pilipalaz/pages/dynamics/view.dart';
import 'package:pilipalaz/pages/media/favorite_video_tile.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:pilipalaz/models/user/info.dart';
import 'package:pilipalaz/models/user/fav_folder.dart';
import 'package:pilipalaz/models/user/fav_detail.dart';
import 'package:pilipalaz/pages/media/controller.dart';
import 'package:pilipalaz/pages/media/view.dart';
import 'package:pilipalaz/pages/dynamics/controller.dart';
import 'package:pilipalaz/pages/setting/view.dart';
import 'package:pilipalaz/pages/setting/categories.dart';
import 'package:pilipalaz/utils/storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory temp;
  setUpAll(() async {
    if (Platform.environment['PILIPALAZ_PREVIEW_DIR'] != null) {
      final chinese = FontLoader('Roboto')
        ..addFont(File('C:/Windows/Fonts/msyh.ttc')
            .readAsBytes()
            .then((b) => ByteData.sublistView(b)));
      final icons = FontLoader('MaterialIcons')
        ..addFont(File(
                '../flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf')
            .readAsBytes()
            .then((b) => ByteData.sublistView(b)));
      await chinese.load();
      await icons.load();
    }
    temp = await Directory.systemTemp.createTemp('pilipalaz_my');
    Hive.init(temp.path);
    Hive.registerAdapter(UserInfoDataAdapter());
    GStorage.setting = await Hive.openBox('setting');
    GStorage.userInfo = await Hive.openBox('user');
    GStorage.localCache = await Hive.openBox('local');
  });
  setUp(() async {
    await GStorage.setting.clear();
    await GStorage.userInfo.clear();
  });
  tearDown(() => Get.reset());
  tearDownAll(() async {
    await Hive.close();
    await temp.delete(recursive: true);
  });
  Future<void> login(int? id) => GStorage.userInfo
      .put('userInfoCache', id == null ? null : UserInfoData(mid: id));
  Map<String, dynamic> folderResponse(int page) => {
        'status': true,
        'data': FavFolderData(hasMore: page < 3, list: [
          for (int i = (page - 1) * 10; i < (page == 3 ? 23 : page * 10); i++)
            FavFolderItemData(id: i + 1, title: '收藏夹 ${i + 1}')
        ])
      };
  Map<String, dynamic> videos(int page) => {
        'status': true,
        'data': FavDetailData(hasMore: page < 2, medias: [
          for (int i = 0; i < 20; i++)
            FavDetailItemData(id: page * 100 + i, title: '收藏视频 $page-$i')
        ])
      };

  test('all folder pages load; video pages are lazy and isolated', () async {
    await login(1);
    final folderPages = <int>[];
    final videoCalls = <String>[];
    final controller = Get.put(MediaController(
      folderRequest: ({required pn, required ps, required mid}) async {
        folderPages.add(pn);
        return folderResponse(pn);
      },
      favoriteRequest: ({required mediaId, required pn, required ps}) async {
        expect(ps, 20);
        videoCalls.add('$mediaId/$pn');
        return videos(pn);
      },
    ));
    await controller.ensureLoaded();
    expect(folderPages, [1, 2, 3]);
    expect(controller.folders.length, 23);
    expect(videoCalls, ['1/1']);
    await controller.loadVideos(1);
    expect(controller.current!.videos.length, 40);
    expect(controller.current!.hasMore, isFalse);
    controller.current!.scrollOffset = 321;
    controller.selectFolder(2);
    await Future<void>.delayed(Duration.zero);
    expect(controller.current!.videos.length, 20);
    controller.selectFolder(1);
    expect(controller.current!.scrollOffset, 321);
    expect(controller.current!.videos.length, 40);
    await controller.ensureLoaded();
    expect(folderPages, [1, 2, 3]);
  });

  test('failed page retries the same page and duplicate requests are ignored',
      () async {
    await login(1);
    int calls = 0;
    final pending = Completer<dynamic>();
    final controller = Get.put(MediaController(
      folderRequest: ({required pn, required ps, required mid}) async => {
        'status': true,
        'data': FavFolderData(list: [FavFolderItemData(id: 1)], hasMore: false)
      },
      favoriteRequest: ({required mediaId, required pn, required ps}) async {
        calls++;
        expect(pn, 1);
        if (calls == 1) return {'status': false};
        return await pending.future;
      },
    ));
    await controller.ensureLoaded();
    expect(controller.current!.error, isNotNull);
    final retry = controller.loadVideos(1);
    await controller.loadVideos(1);
    expect(calls, 2);
    pending.complete(videos(1));
    await retry;
    expect(controller.current!.error, isNull);
    expect(controller.current!.nextPage, 2);
  });

  test('logout discards late video responses and clears cached data', () async {
    await login(1);
    final pending = Completer<dynamic>();
    final controller = Get.put(MediaController(
      folderRequest: ({required pn, required ps, required mid}) async => {
        'status': true,
        'data': FavFolderData(list: [FavFolderItemData(id: 1)], hasMore: false)
      },
      favoriteRequest: ({required mediaId, required pn, required ps}) =>
          pending.future,
    ));
    final loading = controller.ensureLoaded();
    await Future<void>.delayed(Duration.zero);
    await login(null);
    controller.syncAccount();
    pending.complete(videos(1));
    await loading;
    expect(controller.folders, isEmpty);
    expect(controller.folderStates, isEmpty);
    expect(controller.userLogin.value, isFalse);
  });

  testWidgets(
      'hidden tabs use default content and retain Up selector only for Up',
      (tester) async {
    late DynamicsController controller;
    await tester.runAsync(() async {
      await GStorage.setting.putAll({
        SettingBoxKey.dynamicTabs: <String>[],
        SettingBoxKey.defaultDynamicTab: 'up'
      });
      controller = Get.put(DynamicsController());
    });
    expect(controller.tabsHidden, isTrue);
    expect(controller.visibleTabs, ['up']);
    expect(controller.showUpPanel, isTrue);
    controller.mid.value = 42;
    await tester.runAsync(() async {
      await GStorage.setting.put(SettingBoxKey.defaultDynamicTab, 'video');
      controller.applyTabConfig();
    });
    await tester.pump();
    expect(controller.currentTab, 'video');
    expect(controller.showUpPanel, isFalse);
    expect(controller.mid.value, -1);
    await tester.runAsync(() async {
      await GStorage.setting.put(SettingBoxKey.dynamicTabs, ['all', 'article']);
      controller.applyTabConfig();
    });
    await tester.pump();
    expect(controller.tabsHidden, isFalse);
    expect(controller.currentTab, 'all');
  });

  testWidgets(
      'hidden dynamic header stays absent after scrolling and return to top',
      (tester) async {
    Request();
    Request.dio.interceptors.clear();
    Request.dio.interceptors
        .add(dio.InterceptorsWrapper(onRequest: (options, handler) {
      handler.resolve(dio.Response(requestOptions: options, data: {
        'code': 0,
        'data': {'items': [], 'offset': ''}
      }));
    }));
    late DynamicsController controller;
    await tester.runAsync(() async {
      await GStorage.setting.putAll({
        SettingBoxKey.dynamicTabs: <String>[],
        SettingBoxKey.defaultDynamicTab: 'video'
      });
      controller = Get.put(DynamicsController());
    });
    await tester.pumpWidget(const GetMaterialApp(home: DynamicsPage()));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();
    expect(find.byType(TabBar), findsNothing);
    expect(tester.widget<AppBar>(find.byType(AppBar)).toolbarHeight, 0);
    controller.animateToTop();
    controller.headerVisible.value = true;
    await tester.pumpAndSettle();
    expect(find.byType(TabBar), findsNothing);
    expect(tester.widget<AppBar>(find.byType(AppBar)).toolbarHeight, 0);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('favorite video tap opens player with its identifiers',
      (tester) async {
    final video = FavDetailItemData(
        id: 170001,
        title: '点击播放测试',
        pic: 'https://example.test/cover.jpg',
        bvid: 'BV17x411w7KC',
        cid: 123,
        page: 1);
    await tester.pumpWidget(GetMaterialApp(
        home: Scaffold(
            body: FavoriteVideoTile(video: video, onRemove: () async {})),
        getPages: [
          GetPage(name: '/video', page: () => const Scaffold(body: Text('播放器')))
        ]));
    await tester.tap(find.text('点击播放测试'));
    await tester.pumpAndSettle();
    expect(find.text('播放器'), findsOneWidget);
    expect(Get.parameters['bvid'], 'BV17x411w7KC');
    expect(Get.parameters['cid'], '123');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  Future<void> screenshot(
      WidgetTester tester, GlobalKey key, String name) async {
    final dir = Platform.environment['PILIPALAZ_PREVIEW_DIR'];
    if (dir == null) return;
    await tester.runAsync(() async {
      final image = await (key.currentContext!.findRenderObject()
              as RenderRepaintBoundary)
          .toImage();
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      Directory(dir).createSync(recursive: true);
      File('$dir/$name.png').writeAsBytesSync(data!.buffer.asUint8List());
      image.dispose();
    });
  }

  testWidgets('My page has 2x2 buttons, inline videos and cached tab selection',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    late MediaController controller;
    await tester.runAsync(() async {
      await login(1);
      controller = Get.put(MediaController(
        folderRequest: ({required pn, required ps, required mid}) async => {
          'status': true,
          'data': FavFolderData(hasMore: false, list: [
            FavFolderItemData(id: 1, title: '默认收藏夹'),
            FavFolderItemData(id: 2, title: '学习')
          ])
        },
        favoriteRequest: ({required mediaId, required pn, required ps}) async =>
            {
          'status': true,
          'data': FavDetailData(hasMore: false, medias: [
            FavDetailItemData(id: 1, title: '收藏视频示例'),
            FavDetailItemData(id: 2, title: '已失效视频')
          ])
        },
      ));
      await controller.ensureLoaded();
    });
    final key = GlobalKey();
    await tester.pumpWidget(GetMaterialApp(
        home: RepaintBoundary(key: key, child: const MediaPage())));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.text('观看记录')).dy,
        tester.getTopLeft(find.text('我的订阅')).dy);
    expect(tester.getTopLeft(find.text('稍后再看')).dy,
        tester.getTopLeft(find.text('创作中心')).dy);
    expect(find.text('收藏视频示例'), findsOneWidget);
    await screenshot(tester, key, 'my-light');
    await tester.tap(find.byKey(const ValueKey('folder-2')));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();
    expect(controller.selectedFolderId, 2);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('narrow dark My page supports large type without overflow',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final key = GlobalKey();
    await tester.pumpWidget(GetMaterialApp(
        theme: ThemeData.dark(),
        builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(2)),
            child: child!),
        home: RepaintBoundary(key: key, child: const MediaPage())));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await screenshot(tester, key, 'my-dark-large');
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
      'settings restore icons and home category contains direct controls',
      (tester) async {
    final key = GlobalKey();
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(GetMaterialApp(
        home: RepaintBoundary(key: key, child: const SettingPage())));
    expect(find.byType(ListTile), findsNWidgets(5));
    expect(find.byType(Icon), findsNWidgets(5));
    await tester.pumpAndSettle();
    await screenshot(tester, key, 'settings');
    await tester.pumpWidget(
        const GetMaterialApp(home: SettingsCategoryPage(category: 'home')));
    await tester.pumpAndSettle();
    expect(find.text('纯净首页'), findsOneWidget);
    expect(find.text('首页推荐类型'), findsOneWidget);
    expect(find.text('推荐'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
