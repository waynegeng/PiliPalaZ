import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:get/get.dart';
import '../main/controller.dart';
import 'controller.dart';
import 'favorite_video_tile.dart';

class MediaPage extends StatefulWidget {
  const MediaPage({super.key});
  @override
  State<MediaPage> createState() => _MediaPageState();
}

class _MediaPageState extends State<MediaPage>
    with AutomaticKeepAliveClientMixin {
  late final MediaController controller;
  bool _restoring = false;
  @override
  bool get wantKeepAlive => true;
  @override
  void initState() {
    super.initState();
    controller = Get.isRegistered<MediaController>()
        ? Get.find<MediaController>()
        : Get.put(MediaController());
    controller.scrollController.addListener(_onScroll);
    controller.ensureLoaded();
  }

  void _onScroll() {
    final scroll = controller.scrollController;
    if (!scroll.hasClients || _restoring) return;
    controller.current?.scrollOffset = scroll.offset;
    if (scroll.position.extentAfter < 350 &&
        controller.selectedFolderId != null &&
        controller.current?.error == null) {
      controller.loadVideos(controller.selectedFolderId!);
    }
    if (Get.isRegistered<MainController>()) {
      final direction = scroll.position.userScrollDirection;
      if (direction != ScrollDirection.idle) {
        Get.find<MainController>()
            .bottomBarStream
            .add(direction == ScrollDirection.forward);
      }
    }
  }

  void _select(int id, double headerExtent) {
    if (id == controller.selectedFolderId) return;
    final scroll = controller.scrollController;
    final previous = scroll.hasClients ? scroll.offset : 0.0;
    final cached = controller.folderStates.containsKey(id);
    _restoring = true;
    controller.selectFolder(id);
    if (!cached)
      controller.current?.scrollOffset = math.min(previous, headerExtent);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (scroll.hasClients) {
        scroll.jumpTo((controller.current?.scrollOffset ?? 0)
            .clamp(0.0, scroll.position.maxScrollExtent));
      }
      _restoring = false;
    });
  }

  @override
  void dispose() {
    controller.scrollController.removeListener(_onScroll);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return LayoutBuilder(builder: (context, viewport) {
      final theme = Theme.of(context);
      final scale = MediaQuery.textScalerOf(context);
      final available = math.min(
          1000.0, viewport.maxWidth - MediaQuery.paddingOf(context).horizontal);
      final textWidth = math.max(1.0, (available - 44) / 2 - 24);
      double buttonHeight = 88;
      for (final entry in controller.list) {
        final painter = TextPainter(
            text: TextSpan(
                text: entry['title'], style: theme.textTheme.titleMedium),
            textDirection: Directionality.of(context),
            textScaler: scale)
          ..layout(maxWidth: textWidth);
        buttonHeight = math.max(buttonHeight, painter.height + 60);
        painter.dispose();
      }
      final headerExtent = buttonHeight * 2 + 100;
      return Scaffold(
        appBar: AppBar(title: const Text('我的'), centerTitle: false, actions: [
          IconButton(
              tooltip: '设置',
              icon: const Icon(Icons.settings_outlined),
              onPressed: () => Get.toNamed('/setting')),
          const SizedBox(width: 8),
        ]),
        body: SafeArea(
            top: false,
            child: Center(
                child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1000),
              child: GetBuilder<MediaController>(builder: (controller) {
                final state = controller.current;
                return RefreshIndicator(
                  onRefresh: controller.queryFavFolder,
                  child: CustomScrollView(
                    controller: controller.scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverPadding(
                          padding: const EdgeInsets.all(16),
                          sliver: SliverGrid(
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    crossAxisSpacing: 12,
                                    mainAxisSpacing: 12,
                                    mainAxisExtent: buttonHeight),
                            delegate:
                                SliverChildBuilderDelegate((context, index) {
                              final entry = controller.list[index];
                              return Material(
                                color: theme.colorScheme.secondaryContainer
                                    .withOpacity(.5),
                                borderRadius: BorderRadius.circular(16),
                                clipBehavior: Clip.antiAlias,
                                child: InkWell(
                                    onTap: entry['onTap'],
                                    child: Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(entry['icon'],
                                                size: 28,
                                                color:
                                                    theme.colorScheme.primary),
                                            const SizedBox(height: 8),
                                            Text(entry['title'],
                                                style:
                                                    theme.textTheme.titleMedium,
                                                textAlign: TextAlign.center),
                                          ]),
                                    )),
                              );
                            }, childCount: 4),
                          )),
                      SliverToBoxAdapter(
                          child: ListTile(
                        title: Text('我的收藏', style: theme.textTheme.titleMedium),
                        leading: Icon(Icons.bookmarks_outlined,
                            color: theme.colorScheme.primary),
                        trailing: TextButton(
                            onPressed: () => Get.toNamed('/fav'),
                            child: const Text('管理')),
                      )),
                      if (!controller.userLogin.value)
                        SliverToBoxAdapter(
                            child: _message('登录后查看收藏视频',
                                action: '登录',
                                onTap: () => Get.toNamed('/login')))
                      else if (controller.foldersLoading)
                        const SliverToBoxAdapter(
                            child: Padding(
                                padding: EdgeInsets.all(32),
                                child:
                                    Center(child: CircularProgressIndicator())))
                      else ...[
                        if (controller.foldersError != null)
                          SliverToBoxAdapter(
                              child: _message(controller.foldersError!,
                                  action: '重试',
                                  onTap: controller.queryFavFolder)),
                        if (controller.folders.isEmpty &&
                            controller.foldersError == null)
                          SliverToBoxAdapter(child: _message('还没有收藏夹')),
                        if (controller.folders.isNotEmpty)
                          SliverPersistentHeader(
                              pinned: true,
                              delegate: _FolderHeader(
                                  height: math.max(56, scale.scale(20) + 28),
                                  child: Material(
                                    color: theme.colorScheme.surface,
                                    child: SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16),
                                      child: Row(children: [
                                        for (final folder in controller.folders)
                                          Padding(
                                              padding: const EdgeInsets.only(
                                                  right: 8),
                                              child: ChoiceChip(
                                                key: ValueKey(
                                                    'folder-${folder.id}'),
                                                label: Text(
                                                    folder.title ?? '未命名收藏夹'),
                                                selected: folder.id ==
                                                    controller.selectedFolderId,
                                                onSelected: (_) => _select(
                                                    folder.id!, headerExtent),
                                              )),
                                      ]),
                                    ),
                                  ))),
                        if (state != null) ...[
                          SliverList(
                              delegate:
                                  SliverChildBuilderDelegate((context, index) {
                            final video = state.videos[index];
                            final id = controller.selectedFolderId!;
                            return FavoriteVideoTile(
                                key: ValueKey('$id-${video.id}-$index'),
                                video: video,
                                onRemove: () =>
                                    controller.cancelFavorite(id, video.id!));
                          }, childCount: state.videos.length)),
                          if (state.loading)
                            const SliverToBoxAdapter(
                                child: Padding(
                                    padding: EdgeInsets.all(24),
                                    child: Center(
                                        child: CircularProgressIndicator())))
                          else if (state.error != null)
                            SliverToBoxAdapter(
                                child: _message(state.error!,
                                    action: '重试',
                                    onTap: () => controller.loadVideos(
                                        controller.selectedFolderId!)))
                          else if (state.videos.isEmpty)
                            SliverToBoxAdapter(child: _message('这个收藏夹还没有视频'))
                          else if (state.hasMore)
                            SliverToBoxAdapter(
                                child: _message('继续向下浏览',
                                    action: '加载更多',
                                    onTap: () => controller.loadVideos(
                                        controller.selectedFolderId!)))
                          else
                            SliverToBoxAdapter(child: _message('已显示全部视频')),
                        ],
                      ],
                      const SliverToBoxAdapter(child: SizedBox(height: 24)),
                    ],
                  ),
                );
              }),
            ))),
      );
    });
  }

  Widget _message(String text, {String? action, VoidCallback? onTap}) =>
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
        child: Column(children: [
          Text(text, textAlign: TextAlign.center),
          if (action != null) TextButton(onPressed: onTap, child: Text(action)),
        ]),
      );
}

class _FolderHeader extends SliverPersistentHeaderDelegate {
  _FolderHeader({required this.height, required this.child});
  final double height;
  final Widget child;
  @override
  double get minExtent => height;
  @override
  double get maxExtent => height;
  @override
  Widget build(
          BuildContext context, double shrinkOffset, bool overlapsContent) =>
      SizedBox.expand(child: child);
  @override
  bool shouldRebuild(covariant _FolderHeader old) =>
      old.height != height || old.child != child;
}
