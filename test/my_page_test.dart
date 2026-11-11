import 'package:pilipalaz/pages/about/index.dart';
import 'package:dio/dio.dart' as dio;
import 'package:pilipalaz/models/model_owner.dart';
import 'package:pilipalaz/http/init.dart';
import 'package:pilipalaz/http/api.dart';
import 'package:pilipalaz/pages/fav_search/view.dart';
import 'package:pilipalaz/pages/dynamics/view.dart';
import 'package:pilipalaz/pages/fav_detail/widget/fav_video_card.dart';
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

class _TestAboutController extends AboutController {
  @override
  Future<void> getCurrentApp() async {
    currentVersion.value = '1.2.4+114519';
  }

  @override
  Future<void> getRemoteApp() async {
    isLoading.value = false;
  }
}

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
  bool messagesRead = false;
  setUp(() async {
    messagesRead = false;
    await GStorage.setting.clear();
    await GStorage.userInfo.clear();
    Request();
    Request.dio.interceptors.clear();
    Request.dio.interceptors
        .add(dio.InterceptorsWrapper(onRequest: (options, handler) {
      final mid = GStorage.userInfo.get('userInfoCache')?.mid;
      final responses = {
        Api.userInfo: {
          'mid': mid,
          'uname': '测试用户',
          'level_info': {
            'current_level': 6,
            'current_exp': 30000,
            'next_exp': '--'
          },
          'money': 12.5
        },
        Api.userStatOwner: {'following': 2, 'follower': 3, 'dynamic_count': 4},
        Api.msgFeedUnread: messagesRead
            ? <String, dynamic>{}
            : {'at': 2, 'like': 96, 'reply': 1, 'sys_msg': 1},
        Api.privateUnread: {
          'follow_unread': messagesRead ? 0 : 2,
          'unfollow_unread': messagesRead ? 0 : 1
        },
        Api.userFavFolderDetail: {
          'has_more': false,
          'medias': [
            if (options.queryParameters['type'] == 1 &&
                options.queryParameters['media_id'] == 1 &&
                options.queryParameters['keyword'] == '默认')
              {
                'id': 170001,
                'title': '只在默认收藏夹',
                'cover': 'https://example.test/video.jpg',
                'page': 1,
                'bvid': 'BV17x411w7KC',
                'ugc': {'first_cid': 123}
              }
          ]
        },
      };
      handler.resolve(dio.Response(
          requestOptions: options,
          data: {'code': 0, 'data': responses[options.path] ?? {}}));
    }));
  });
  tearDown(() async {
    await Get.deleteAll(force: true);
    Get.reset();
  });
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
            body: Align(
                alignment: Alignment.topCenter,
                child: SizedBox(
                    height: 120,
                    width: 390,
                    child:
                        FavVideoCardH(videoItem: video, callFn: () async {})))),
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
            FavDetailItemData(
                id: 1,
                title: '收藏视频示例',
                duration: 186,
                pubdate: 1700000000,
                owner: Owner(name: '视频作者'),
                cntInfo: {'play': 12345, 'danmaku': 76}),
            FavDetailItemData(id: 2, title: '已失效视频')
          ])
        },
      ));
      await controller.ensureLoaded();
    });
    final key = GlobalKey();
    await tester.pumpWidget(GetMaterialApp(
        home: RepaintBoundary(key: key, child: const MediaPage()),
        getPages: [
          GetPage(name: '/favSearch', page: () => const FavSearchPage()),
          for (final name in ['follow', 'fan', 'member'])
            GetPage(
                name: '/$name', page: () => Scaffold(body: Text('列表 $name'))),
          GetPage(
              name: '/video', page: () => const Scaffold(body: Text('播放器'))),
          GetPage(
              name: '/whisper', page: () => const Scaffold(body: Text('消息页'))),
        ]));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.text('观看记录')).dy,
        tester.getTopLeft(find.text('我的订阅')).dy);
    expect(tester.getTopLeft(find.text('稍后再看')).dy,
        tester.getTopLeft(find.text('消息通知')).dy);
    expect(find.text('收藏视频示例'), findsOneWidget);
    expect(find.byType(FavVideoCardH), findsWidgets);
    expect(find.text('管理'), findsNothing);
    expect(find.text('我的'), findsNothing);
    expect(find.bySemanticsLabel('PiliPalaZ'), findsNothing);
    expect(find.text('测试用户'), findsOneWidget);
    expect(find.textContaining('已满级'), findsOneWidget);
    expect(find.text('99+'), findsOneWidget);
    expect(controller.unreadCount(true), 7);
    await tester.tap(find.text('测试用户'));
    await tester.pumpAndSettle();
    expect(find.byType(MediaPage), findsOneWidget);
    for (final entry in {'关注': 'follow', '粉丝': 'fan', '动态': 'member'}.entries) {
      await tester.tap(find.text(entry.key));
      await tester.pumpAndSettle();
      expect(find.text('列表 ${entry.value}'), findsOneWidget);
      expect(Get.parameters['mid'], '1');
      Get.back();
      await tester.pumpAndSettle();
    }
    await tester.runAsync(
        () => GStorage.setting.put(SettingBoxKey.dynamicBadgeMode, 0));
    await tester.pumpAndSettle();
    expect(find.text('99+'), findsOneWidget);
    for (final mode in [1, 0, 2]) {
      await tester.runAsync(
          () => GStorage.setting.put(SettingBoxKey.messageBadgeMode, mode));
      await tester.pumpAndSettle();
      final badge = tester.widget<Badge>(find.byType(Badge));
      expect(badge.isLabelVisible, mode != 0);
      expect(badge.label != null, mode == 2);
    }
    await tester.tap(find.text('消息通知'));
    await tester.pumpAndSettle();
    expect(find.text('消息页'), findsOneWidget);
    messagesRead = true;
    Get.back();
    await tester.pumpAndSettle();
    expect(tester.widget<Badge>(find.byType(Badge)).isLabelVisible, isFalse);
    await screenshot(tester, key, 'my-light');
    await tester.tap(find.byKey(const ValueKey('folder-2')));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();
    expect(controller.selectedFolderId, 2);
    await tester.tap(find.byTooltip('搜索全部收藏夹'));
    await tester.pumpAndSettle();
    expect(Get.parameters['searchType'], '1');
    expect(Get.parameters['mediaId'], '1');
    await tester.enterText(find.byType(TextField), '默认');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
    await tester.tap(find.text('只在默认收藏夹'));
    await tester.pumpAndSettle();
    expect(find.text('播放器'), findsOneWidget);
    Get.back();
    await tester.pumpAndSettle();
    Get.back();
    await tester.pumpAndSettle();
    expect(controller.selectedFolderId, 2);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
      'global favorite search discards late replies and retries the same page',
      (tester) async {
    await tester.runAsync(() => login(1));
    final oldReply = Completer<void>();
    final requests = <String>[];
    bool fail = true;
    Request.dio.interceptors.clear();
    Request.dio.interceptors
        .add(dio.InterceptorsWrapper(onRequest: (options, handler) async {
      if (options.path != Api.userFavFolderDetail) {
        handler
            .resolve(dio.Response(requestOptions: options, data: {'code': -1}));
        return;
      }
      final args = options.queryParameters;
      final query = args['keyword'];
      final page = args['pn'];
      requests.add('$query/$page');
      expect(args['type'], 1);
      expect(args['media_id'], 42);
      expect(args['ps'], 20);
      if (query == 'old') await oldReply.future;
      final code = (page == 2 && fail) ? -1 : 0;
      handler.resolve(dio.Response(requestOptions: options, data: {
        'code': code,
        'data': {
          'has_more': page == 1,
          'medias': [
            {'id': page, 'title': '$query result $page'}
          ]
        }
      }));
    }));
    await tester.pumpWidget(GetMaterialApp(home: const Scaffold(), getPages: [
      GetPage(name: '/favSearch', page: () => const FavSearchPage())
    ]));
    Get.toNamed('/favSearch', parameters: {'searchType': '1', 'mediaId': '42'});
    await tester.pumpAndSettle();
    final field = find.byType(TextField);
    await tester.enterText(field, 'old');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pump();
    await tester.enterText(field, 'new');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
    oldReply.complete();
    await tester.pumpAndSettle();
    expect(find.text('old result 1'), findsNothing);
    expect(find.text('new result 1'), findsOneWidget);
    await tester.tap(find.text('加载更多'));
    await tester.pumpAndSettle();
    fail = false;
    await tester.tap(find.text('加载失败，点击重试'));
    await tester.pumpAndSettle();
    expect(find.text('new result 2'), findsOneWidget);
    expect(requests, ['old/1', 'new/1', 'new/2', 'new/2']);
    await tester.runAsync(() => login(2));
    await tester.pumpAndSettle();
    expect(find.text('new result 1'), findsNothing);
    expect(find.textContaining('账号已切换'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('narrow dark My page supports large type without overflow',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final key = GlobalKey();
    await tester.pumpWidget(GetMaterialApp(
        theme: ThemeData.dark(),
        getPages: [
          GetPage(
              name: '/loginPage',
              page: () => const Scaffold(body: Text('账号登录')))
        ],
        builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(2)),
            child: child!),
        home: RepaintBoundary(key: key, child: const MediaPage())));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('登录'), findsOneWidget);
    await screenshot(tester, key, 'my-dark-large');
    await tester.ensureVisible(find.byTooltip('搜索全部收藏夹'));
    await tester.tap(find.byTooltip('搜索全部收藏夹'));
    await tester.pumpAndSettle();
    expect(find.text('账号登录'), findsOneWidget);
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
  testWidgets('general settings directly contain former About information',
      (tester) async {
    const channel = MethodChannel('plugins.flutter.io/path_provider');
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(channel, (_) async => temp.path);
    addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
    Get.put<AboutController>(_TestAboutController());
    await tester.pumpWidget(
        const GetMaterialApp(home: SettingsCategoryPage(category: 'general')));
    await tester
        .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('当前版本'), 400);
    expect(find.text('1.2.4+114519'), findsOneWidget);
    expect(find.text('关于'), findsNothing);
    expect(find.byType(Image), findsNothing);
    expect(find.text('最新版本'), findsOneWidget);
    expect(find.text('开源仓库⭐'), findsOneWidget);
    expect(find.text('错误日志'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
