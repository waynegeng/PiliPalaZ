import '../widgets/header_scroll.dart';
import '../../../models/dynamics/video_card_adapter.dart';
import '../../../common/widgets/video_card_v.dart';
import '../../../common/skeleton/video_card_v.dart';
import 'dart:async';

import 'package:pilipalaz/utils/storage.dart';
import 'package:easy_debounce/easy_throttle.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pilipalaz/common/constants.dart';
import 'package:pilipalaz/common/widgets/http_error.dart';
import 'package:pilipalaz/common/widgets/no_data.dart';
import 'package:waterfall_flow/waterfall_flow.dart';

import '../../../common/skeleton/dynamic_card.dart';
import '../../../models/dynamics/result.dart';
import '../../../utils/grid.dart';

import '../index.dart';
import '../widgets/dynamic_panel.dart';
import 'controller.dart';

class DynamicsTabPage extends StatefulWidget {
  const DynamicsTabPage({super.key, required this.dynamicsType});

  final String dynamicsType;

  @override
  State<DynamicsTabPage> createState() => _DynamicsTabPageState();
}

class _DynamicsTabPageState extends State<DynamicsTabPage>
    with AutomaticKeepAliveClientMixin {
  late DynamicsTabController _dynamicsTabController;
  late Future _futureBuilderFuture;
  late ScrollController scrollController;
  late bool dynamicsWaterfallFlow;
  late VoidCallback _scrollListener;
  late Worker _midWorker;
  late final DynamicsController dynamicsController;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _dynamicsTabController =
        Get.put(DynamicsTabController(), tag: widget.dynamicsType);
    dynamicsController = Get.find<DynamicsController>();

    _futureBuilderFuture = _dynamicsTabController.queryFollowDynamic(
        'init', widget.dynamicsType, dynamicsController.mid.value);
    scrollController = _dynamicsTabController.scrollController
      ..addListener(_scrollListener = () {
        if (scrollController.position.pixels >=
            scrollController.position.maxScrollExtent - 200) {
          if (!_dynamicsTabController.isLoadingMore.value) {
            EasyThrottle.throttle('dynamic_load_${widget.dynamicsType}',
                const Duration(milliseconds: 500), () async {
              _dynamicsTabController.isLoadingMore.value = true;
              await _dynamicsTabController.onLoad();
              if (mounted) _dynamicsTabController.isLoadingMore.value = false;
            });
          }
        }
      });
    _midWorker = ever(dynamicsController.mid, (mid) {
      if (widget.dynamicsType != 'up' || !mounted) return;
      print('midListen: $mid');
      if (scrollController.hasClients) scrollController.jumpTo(0);
      setState(() {
        _futureBuilderFuture = _dynamicsTabController.queryFollowDynamic(
            'init', widget.dynamicsType, mid);
      });
    });
    dynamicsWaterfallFlow = GStorage.setting
        .get(SettingBoxKey.dynamicsWaterfallFlow, defaultValue: true);
  }

  @override
  void dispose() {
    scrollController.removeListener(_scrollListener);
    _midWorker.dispose();
    EasyThrottle.cancel('dynamic_load_${widget.dynamicsType}');
    Get.delete<DynamicsTabController>(tag: widget.dynamicsType);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    // print(widget.dynamicsType + widget.mid.value.toString());
    return DynamicHeaderScroll(
        enabled: () => GStorage.setting
            .get(SettingBoxKey.hideDynamicHeader, defaultValue: true),
        onVisibilityChanged: (visible) =>
            dynamicsController.headerVisible.value = visible,
        child: RefreshIndicator(
            displacement: 10.0,
            edgeOffset: 10.0,
            // key:
            //     ValueKey<String>(widget.dynamicsType + widget.mid.value.toString()),
            onRefresh: () async {
              dynamicsWaterfallFlow = GStorage.setting
                  .get(SettingBoxKey.dynamicsWaterfallFlow, defaultValue: true);
              await Future.wait(<Future>[
                _dynamicsTabController.onRefresh(),
                dynamicsController.queryFollowUp()
              ]);
            },
            child: CustomScrollView(
              cacheExtent: 3500,
              physics: const AlwaysScrollableScrollPhysics(),
              controller: _dynamicsTabController.scrollController,
              slivers: [
                FutureBuilder(
                  future: _futureBuilderFuture,
                  builder: (context, snapshot) {
                    // print(snapshot);
                    // print(widget.dynamicsType + "${widget.mid?.value}");
                    if (snapshot.connectionState == ConnectionState.done) {
                      if (snapshot.data == null) {
                        return const NoData();
                      }
                      Map data = snapshot.data;
                      // print('data: $data');
                      if (data['status']) {
                        List<DynamicItemModel> list =
                            _dynamicsTabController.dynamicsList;
                        // print('list: $list');
                        return Obx(
                          () {
                            if (list.isEmpty) {
                              if (_dynamicsTabController.isLoadingMore.value) {
                                return skeleton();
                              }
                              return const NoData();
                            }
                            if (widget.dynamicsType == 'video') {
                              final visible = list
                                  .where((item) => !dynamicsController
                                      .tempBannedList
                                      .contains(
                                          item.modules?.moduleAuthor?.mid))
                                  .toList();
                              return videoGrid(visible);
                            }
                            if (!dynamicsWaterfallFlow) {
                              return SliverCrossAxisGroup(
                                slivers: [
                                  const SliverFillRemaining(),
                                  SliverConstrainedCrossAxis(
                                      maxExtent: Grid.maxRowWidth * 2,
                                      sliver: SliverList(
                                        delegate: SliverChildBuilderDelegate(
                                          (context, index) {
                                            if ((widget.dynamicsType == 'up' &&
                                                    dynamicsController
                                                            .mid.value !=
                                                        -1) ||
                                                !dynamicsController
                                                    .tempBannedList
                                                    .contains(list[index]
                                                        .modules
                                                        ?.moduleAuthor
                                                        ?.mid)) {
                                              return DynamicPanel(
                                                  item: list[index]);
                                            }
                                            return const SizedBox();
                                          },
                                          childCount: list.length,
                                        ),
                                      )),
                                  const SliverFillRemaining(),
                                ],
                              );
                            }
                            return SliverWaterfallFlow.extent(
                              maxCrossAxisExtent: Grid.maxRowWidth * 2,
                              //cacheExtent: 0.0,
                              crossAxisSpacing: StyleString.cardSpace / 2,
                              mainAxisSpacing: StyleString.cardSpace / 2,

                              lastChildLayoutTypeBuilder: (index) =>
                                  index == list.length
                                      ? LastChildLayoutType.foot
                                      : LastChildLayoutType.none,
                              children: [
                                if (widget.dynamicsType == 'up' &&
                                    dynamicsController.mid.value != -1) ...[
                                  for (var i in list) DynamicPanel(item: i),
                                ] else ...[
                                  for (var i in list)
                                    if (!dynamicsController.tempBannedList
                                        .contains(i.modules?.moduleAuthor?.mid))
                                      DynamicPanel(item: i),
                                ]
                              ],
                            );
                          },
                        );
                      } else {
                        return HttpError(
                          errMsg: data['msg'],
                          fn: () {
                            setState(() {
                              _futureBuilderFuture =
                                  _dynamicsTabController.queryFollowDynamic(
                                      'init',
                                      widget.dynamicsType,
                                      dynamicsController.mid.value);
                            });
                            dynamicsController.onRefresh();
                          },
                        );
                      }
                    } else {
                      // 骨架屏
                      return skeleton();
                    }
                  },
                )
              ],
            )));
  }

  Widget videoGrid(List<DynamicItemModel>? items) {
    if (items == null) return videoCardGrid(null);
    final slivers = <Widget>[];
    final group = <DynamicItemModel>[];
    void flushGroup() {
      if (group.isEmpty) return;
      slivers.add(videoCardGrid(List.of(group)));
      group.clear();
    }

    for (final item in items) {
      if (dynamicVideoCard(item) != null) {
        group.add(item);
      } else {
        flushGroup();
        slivers.add(SliverToBoxAdapter(
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: StyleString.safeSpace),
            child: Card(
                child: ListTile(
              dense: true,
              leading: const Icon(Icons.videocam_off_outlined),
              title: const Text('视频暂不可用'),
              subtitle: item.modules?.moduleDynamic?.major?.archive?.title ==
                      null
                  ? null
                  : Text(item.modules!.moduleDynamic!.major!.archive!.title!),
            )),
          ),
        ));
      }
    }
    flushGroup();
    return slivers.isEmpty
        ? const NoData()
        : SliverMainAxisGroup(slivers: slivers);
  }

  Widget videoCardGrid(List<DynamicItemModel>? items) => SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: StyleString.safeSpace),
        sliver: SliverGrid(
          gridDelegate: SliverGridDelegateWithExtentAndRatio(
            maxCrossAxisExtent: Grid.maxRowWidth,
            mainAxisSpacing: StyleString.cardSpace,
            crossAxisSpacing: StyleString.cardSpace,
            childAspectRatio: StyleString.aspectRatio,
            mainAxisExtent: MediaQuery.textScalerOf(context).scale(90),
          ),
          delegate: SliverChildBuilderDelegate((context, index) {
            if (items == null) return const VideoCardVSkeleton();
            final video = dynamicVideoCard(items[index]);
            return VideoCardV(videoItem: video);
          }, childCount: items?.length ?? 10),
        ),
      );

  Widget skeleton() {
    if (widget.dynamicsType == 'video') return videoGrid(null);
    if (!dynamicsWaterfallFlow) {
      return SliverCrossAxisGroup(slivers: [
        const SliverFillRemaining(),
        SliverConstrainedCrossAxis(
          maxExtent: Grid.maxRowWidth * 2,
          sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
            return const DynamicCardSkeleton();
          }, childCount: 10)),
        ),
        const SliverFillRemaining()
      ]);
    }
    return SliverGrid(
      gridDelegate: SliverGridDelegateWithExtentAndRatio(
          crossAxisSpacing: StyleString.cardSpace / 2,
          mainAxisSpacing: StyleString.cardSpace / 2,
          maxCrossAxisExtent: Grid.maxRowWidth * 2,
          childAspectRatio: StyleString.aspectRatio,
          mainAxisExtent: 50),
      delegate: SliverChildBuilderDelegate((context, index) {
        return const DynamicCardSkeleton();
      }, childCount: 10),
    );
  }
}
