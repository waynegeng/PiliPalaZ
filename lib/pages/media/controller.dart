import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../http/user.dart';
import '../../http/video.dart';
import '../../http/msg.dart';
import '../../models/user/info.dart';
import '../../models/user/stat.dart';
import '../../models/msg/msgfeed_unread.dart';
import '../../models/user/fav_folder.dart';
import '../../models/user/fav_detail.dart';
import '../../utils/storage.dart';

typedef FolderRequest = Future<dynamic> Function(
    {required int pn, required int ps, required int mid});
typedef FavoriteRequest = Future<dynamic> Function(
    {required int mediaId, required int pn, required int ps});

class FavoriteFolderState {
  final List<FavDetailItemData> videos = [];
  int nextPage = 1;
  bool hasMore = true;
  bool loading = false;
  String? error;
  double scrollOffset = 0;
}

class MediaController extends GetxController {
  MediaController(
      {FolderRequest? folderRequest, FavoriteRequest? favoriteRequest})
      : folderRequest = folderRequest ?? UserHttp.userfavFolder,
        favoriteRequest = favoriteRequest ?? UserHttp.userFavFolderDetail;
  final FolderRequest folderRequest;
  final FavoriteRequest favoriteRequest;
  final RxBool userLogin = false.obs;
  final List<FavFolderItemData> folders = [];
  final Map<int, FavoriteFolderState> folderStates = {};
  final ScrollController scrollController = ScrollController();
  StreamSubscription? _accountSubscription;
  Worker? _loginWorker;
  int? mid;
  int? _accountMid;
  int? selectedFolderId;
  int _generation = 0;
  bool foldersLoading = false;
  bool _initialized = false;
  String? foldersError;
  FavoriteFolderState? get current => folderStates[selectedFolderId];
  UserInfoData? profile;
  UserStat? stats;
  MsgFeedUnread? feed;
  int? privateUnread;
  int _accountRequest = 0;

  int unreadCount(bool disableLikes) =>
      (feed?.reply ?? 0) +
      (feed?.at ?? 0) +
      (disableLikes ? 0 : feed?.like ?? 0) +
      (feed?.sys_msg ?? 0) +
      (privateUnread ?? 0);

  Future<void> onEnter() => Future.wait([ensureLoaded(), refreshAccount()]);
  Future<void> refreshPage() =>
      Future.wait([queryFavFolder(), refreshAccount()]);

  Future<void> refreshAccount() async {
    final account = _accountMid;
    if (account == null) return;
    final ticket = ++_accountRequest;
    bool current() =>
        !isClosed &&
        ticket == _accountRequest &&
        account == GStorage.userInfo.get('userInfoCache')?.mid;
    Future<void> fetch<T>(
        Future<T> Function() load, void Function(T) apply) async {
      try {
        final value = await load();
        if (current()) {
          apply(value);
          update();
        }
      } catch (error) {
        debugPrint('账号信息刷新失败: $error');
      }
    }

    await Future.wait([
      fetch(UserHttp.userInfo, (res) {
        if (res['status'] == true && res['data'].mid == account)
          profile = res['data'];
      }),
      fetch(UserHttp.userStatOwner, (res) {
        if (res['status'] == true) stats = res['data'];
      }),
      fetch(MsgHttp.msgFeedUnread, (res) {
        if (res['status'] == true) feed = MsgFeedUnread.fromJson(res['data']);
      }),
      fetch(MsgHttp.privateUnreadCount, (value) {
        if (value != null) privateUnread = value;
      }),
    ]);
  }

  Future<void> openMessages() async {
    if (_accountMid == null) {
      await Get.toNamed('/loginPage');
      return;
    }
    await Get.toNamed('/whisper');
    if (!isClosed) await refreshAccount();
  }

  void openSearch() {
    if (_accountMid == null) {
      Get.toNamed('/loginPage');
      return;
    }
    if (foldersLoading || folders.isEmpty) return;
    Get.toNamed('/favSearch',
        parameters: {'searchType': '1', 'mediaId': '${folders.first.id}'});
  }

  late final List list = [
    // {
    //   'icon': Icons.file_download_outlined,
    //   'title': '离线缓存',
    //   'onTap': () {
    //     SmartDialog.showToast('功能开发中');
    //   },
    // },
    {
      'icon': Icons.history,
      'title': '观看记录',
      'onTap': () => Get.toNamed('/history'),
    },
    {
      'icon': Icons.subscriptions_outlined,
      'title': '我的订阅',
      'onTap': () => Get.toNamed('/subscription'),
    },
    {
      'icon': Icons.watch_later_outlined,
      'title': '稍后再看',
      'onTap': () => Get.toNamed('/later'),
    },
    {
      'icon': Icons.notifications_none,
      'title': '消息通知',
      'onTap': openMessages,
    },
  ];

  @override
  void onInit() {
    super.onInit();
    profile = GStorage.userInfo.get('userInfoCache');
    _accountMid = mid = profile?.mid;
    userLogin.value = _accountMid != null;
    _accountSubscription = GStorage.userInfo
        .watch(key: 'userInfoCache')
        .listen((_) => syncAccount());
    _loginWorker = ever(userLogin, (_) => syncAccount());
  }

  void syncAccount() {
    final int? next = GStorage.userInfo.get('userInfoCache')?.mid;
    if (next == _accountMid) return;
    _accountRequest++;
    profile = GStorage.userInfo.get('userInfoCache');
    stats = null;
    feed = null;
    privateUnread = null;
    _accountMid = next;
    mid = next;
    userLogin.value = next != null;
    _generation++;
    folders.clear();
    folderStates.clear();
    selectedFolderId = null;
    foldersError = null;
    foldersLoading = false;
    _initialized = false;
    if (scrollController.hasClients) scrollController.jumpTo(0);
    update();
    if (next != null) onEnter();
  }

  Future<void> ensureLoaded() async {
    syncAccount();
    if (!_initialized && !foldersLoading && _accountMid != null)
      await queryFavFolder();
  }

  Future<void> queryFavFolder() async {
    final account = _accountMid;
    final generation = ++_generation;
    final selected = selectedFolderId;
    folders.clear();
    folderStates.clear();
    selectedFolderId = null;
    foldersError = null;
    _initialized = true;
    foldersLoading = account != null;
    update();
    if (account == null) return;
    try {
      int page = 1;
      bool more = true;
      while (more) {
        final res = await folderRequest(pn: page, ps: 10, mid: account);
        if (isClosed || generation != _generation) return;
        if (res == null || res['status'] != true)
          throw StateError(res?['msg'] ?? '获取收藏夹失败');
        final FavFolderData data = res['data'];
        final entries = data.list ?? <FavFolderItemData>[];
        final ids = folders.map((e) => e.id).toSet();
        final fresh =
            entries.where((e) => (e.id ?? 0) > 0 && ids.add(e.id)).toList();
        folders.addAll(fresh);
        more = data.hasMore == true && fresh.isNotEmpty;
        page++;
      }
    } catch (_) {
      if (isClosed || generation != _generation) return;
      foldersError = '收藏夹加载失败，点击重试';
    }
    if (isClosed || generation != _generation) return;
    foldersLoading = false;
    if (folders.isNotEmpty) {
      selectedFolderId =
          folders.any((e) => e.id == selected) ? selected : folders.first.id;
      folderStates[selectedFolderId!] = FavoriteFolderState();
    }
    update();
    if (selectedFolderId != null) await loadVideos(selectedFolderId!);
  }

  void selectFolder(int id) {
    if (!folders.any((e) => e.id == id)) return;
    if (scrollController.hasClients && current != null)
      current!.scrollOffset = scrollController.offset;
    selectedFolderId = id;
    final state = folderStates.putIfAbsent(id, () => FavoriteFolderState());
    update();
    if (state.nextPage == 1 && !state.loading && state.hasMore) loadVideos(id);
  }

  Future<void> loadVideos(int id) async {
    final state = folderStates[id];
    if (state == null || state.loading || !state.hasMore || _accountMid == null)
      return;
    final generation = _generation;
    state.loading = true;
    state.error = null;
    update();
    try {
      final res =
          await favoriteRequest(mediaId: id, pn: state.nextPage, ps: 20);
      if (isClosed || generation != _generation || folderStates[id] != state)
        return;
      if (res == null || res['status'] != true)
        throw StateError(res?['msg'] ?? '加载失败');
      final FavDetailData data = res['data'];
      final items = data.medias ?? <FavDetailItemData>[];
      final known = state.videos.map((e) => e.id).whereType<int>().toSet();
      final fresh =
          items.where((e) => e.id == null || known.add(e.id!)).toList();
      state.videos.addAll(fresh);
      state.nextPage++;
      state.hasMore = data.hasMore == true && fresh.isNotEmpty;
    } catch (error) {
      debugPrint('收藏视频加载失败: $error');
      if (isClosed || generation != _generation) return;
      state.error = '视频加载失败，点击重试';
    } finally {
      if (!isClosed && generation == _generation && folderStates[id] == state) {
        state.loading = false;
        update();
      }
    }
  }

  Future<void> cancelFavorite(int folderId, int videoId) async {
    final generation = _generation;
    final res =
        await VideoHttp.favVideo(aid: videoId, addIds: '', delIds: '$folderId');
    if (isClosed || generation != _generation) return;
    if (res['status'] != true) throw StateError(res['msg'] ?? '取消收藏失败');
    folderStates[folderId]?.videos.removeWhere((e) => e.id == videoId);
    update();
  }

  @override
  void onClose() {
    _generation++;
    _accountSubscription?.cancel();
    _loginWorker?.dispose();
    scrollController.dispose();
    super.onClose();
  }
}
