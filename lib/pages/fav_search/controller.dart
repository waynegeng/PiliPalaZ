import 'dart:async';
import '../../utils/storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:pilipalaz/http/user.dart';
import 'package:pilipalaz/models/user/fav_detail.dart';

import '../../http/video.dart';

class FavSearchController extends GetxController {
  final scrollController = ScrollController();
  final controller = TextEditingController();
  final searchFocusNode = FocusNode();
  final favList = <FavDetailItemData>[].obs;
  final loading = false.obs;
  final error = false.obs;
  final hasMore = false.obs;
  final submitted = false.obs;
  late final int searchType;
  late final int mediaId;
  String keyword = '';
  int nextPage = 1;
  int _generation = 0;
  late final int? _account;
  StreamSubscription? _accountWatch;
  final accountChanged = false.obs;

  @override
  void onInit() {
    super.onInit();
    searchType = int.parse(Get.parameters['searchType']!);
    mediaId = int.parse(Get.parameters['mediaId']!);
    _account = GStorage.userInfo.get('userInfoCache')?.mid;
    _accountWatch =
        GStorage.userInfo.watch(key: 'userInfoCache').listen((event) {
      if (event.value?.mid != _account) {
        clear();
        accountChanged.value = true;
      }
    });
    scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (scrollController.position.extentAfter < 300 && !error.value) load();
  }

  void clear() {
    _generation++;
    controller.clear();
    keyword = '';
    submitted.value = loading.value = error.value = hasMore.value = false;
    favList.clear();
  }

  void submit() {
    final query = controller.text.trim();
    if (query.isEmpty || accountChanged.value) return;
    _generation++;
    keyword = query;
    searchFocusNode.unfocus();
    hasMore.value = false;
    if (scrollController.hasClients) scrollController.jumpTo(0);
    favList.clear();
    nextPage = 1;
    submitted.value = hasMore.value = true;
    loading.value = false;
    load();
  }

  Future<void> load() async {
    if (accountChanged.value || !hasMore.value || loading.value) return;
    final ticket = _generation;
    bool current() =>
        !isClosed &&
        ticket == _generation &&
        _account == GStorage.userInfo.get('userInfoCache')?.mid;
    loading.value = true;
    error.value = false;
    try {
      final res = await UserHttp.userFavFolderDetail(
          pn: nextPage,
          ps: 20,
          mediaId: mediaId,
          keyword: keyword,
          type: searchType);
      if (!current()) return;
      if (res['status'] != true) throw StateError('收藏搜索失败');
      final FavDetailData data = res['data'];
      final items = data.medias ?? [];
      favList.addAll(items);
      hasMore.value = data.hasMore == true && items.isNotEmpty;
      nextPage++;
    } catch (_) {
      if (current()) error.value = true;
    } finally {
      if (current()) loading.value = false;
    }
  }

  @override
  void onClose() {
    _generation++;
    _accountWatch?.cancel();
    scrollController.removeListener(_onScroll);
    scrollController.dispose();
    searchFocusNode.dispose();
    controller.dispose();
    super.onClose();
  }

  onCancelFav(int id) async {
    var result = await VideoHttp.favVideo(
        aid: id, addIds: '', delIds: mediaId.toString());
    if (result['status']) {
      List dataList = favList;
      for (var i in dataList) {
        if (i.id == id) {
          dataList.remove(i);
          break;
        }
      }
      SmartDialog.showToast('取消收藏');
    }
  }
}
