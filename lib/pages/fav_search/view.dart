import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../common/constants.dart';
import '../fav_detail/widget/fav_video_card.dart';
import 'controller.dart';

class FavSearchPage extends StatefulWidget {
  const FavSearchPage({super.key});
  @override
  State<FavSearchPage> createState() => _FavSearchPageState();
}

class _FavSearchPageState extends State<FavSearchPage> {
  final search = Get.put(FavSearchController());
  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(
          titleSpacing: 0,
          title: TextField(
              autofocus: true,
              focusNode: search.searchFocusNode,
              controller: search.controller,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => search.submit(),
              decoration: InputDecoration(
                  hintText: search.searchType == 1 ? '搜索全部收藏夹' : '搜索当前收藏夹',
                  border: InputBorder.none,
                  suffixIcon: IconButton(
                      tooltip: '清空',
                      icon: const Icon(Icons.clear, size: 22),
                      onPressed: () {
                        if (search.controller.text.isEmpty) {
                          Get.back();
                        } else {
                          search.clear();
                        }
                      }))),
          actions: [
            IconButton(
                tooltip: '搜索',
                icon: const Icon(Icons.search_outlined),
                onPressed: search.submit)
          ]),
      body: Obx(() {
        if (search.accountChanged.value)
          return const Center(child: Text('账号已切换，请返回后重新搜索'));
        if (!search.submitted.value) return const SizedBox.shrink();
        return CustomScrollView(controller: search.scrollController, slivers: [
          SliverPadding(
              padding:
                  const EdgeInsets.symmetric(horizontal: StyleString.safeSpace),
              sliver: SliverGrid(
                  gridDelegate: favoriteVideoGridDelegate(),
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final video = search.favList[index];
                    return FavVideoCardH(
                        videoItem: video,
                        searchType: search.searchType,
                        callFn: () => search.onCancelFav(video.id!));
                  }, childCount: search.favList.length))),
          SliverToBoxAdapter(
              child: Center(
                  child: search.loading.value
                      ? const CircularProgressIndicator()
                      : search.error.value
                          ? TextButton(
                              onPressed: search.load,
                              child: const Text('加载失败，点击重试'))
                          : search.favList.isEmpty
                              ? const Text('没有找到收藏视频')
                              : search.hasMore.value
                                  ? TextButton(
                                      onPressed: search.load,
                                      child: const Text('加载更多'))
                                  : const SizedBox.shrink())),
        ]);
      }));
}
