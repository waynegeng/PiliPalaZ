import '../../../utils/grid.dart';
import 'favorite_actions.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:pilipalaz/common/constants.dart';
import 'package:pilipalaz/common/widgets/stat/danmu.dart';
import 'package:pilipalaz/common/widgets/stat/view.dart';
import 'package:pilipalaz/utils/utils.dart';
import 'package:pilipalaz/common/widgets/network_img_layer.dart';
import '../../../common/widgets/badge.dart';

// Keep the folder detail and My page density and columns identical.
SliverGridDelegate favoriteVideoGridDelegate() =>
    SliverGridDelegateWithExtentAndRatio(
        mainAxisSpacing: StyleString.cardSpace,
        crossAxisSpacing: StyleString.safeSpace,
        maxCrossAxisExtent: Grid.maxRowWidth * 2,
        childAspectRatio: StyleString.aspectRatio * 2.4,
        mainAxisExtent: 0);

// 收藏视频卡片 - 水平布局
class FavVideoCardH extends StatelessWidget {
  final dynamic videoItem;
  final Function? callFn;
  final int? searchType;

  const FavVideoCardH({
    super.key,
    required this.videoItem,
    this.callFn,
    this.searchType,
  });

  @override
  Widget build(BuildContext context) {
    int id = videoItem.id ?? 0;
    final playable = id > 0 &&
        videoItem.pic?.isNotEmpty == true &&
        !['已失效视频', '视频已失效', '视频已删除'].contains(videoItem.title);
    String heroTag = Utils.makeHeroTag(id);
    return InkWell(
      onTap: playable ? () => openFavoriteVideo(videoItem, heroTag) : null,
      child: LayoutBuilder(
        builder: (context, boxConstraints) {
          double width =
              (boxConstraints.maxWidth - StyleString.cardSpace * 6) / 2;
          return SizedBox(
            height: width / StyleString.aspectRatio,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AspectRatio(
                  aspectRatio: StyleString.aspectRatio,
                  child: LayoutBuilder(
                    builder: (context, boxConstraints) {
                      double maxWidth = boxConstraints.maxWidth;
                      double maxHeight = boxConstraints.maxHeight;
                      return Stack(
                        children: [
                          Hero(
                            tag: heroTag,
                            child: NetworkImgLayer(
                              src: videoItem.pic ?? '',
                              width: maxWidth,
                              height: maxHeight,
                            ),
                          ),
                          if (videoItem.duration != null)
                            PBadge(
                              text: Utils.timeFormat(videoItem.duration!),
                              right: 6.0,
                              bottom: 6.0,
                              type: 'gray',
                            ),
                          if (videoItem.ogv != null) ...[
                            PBadge(
                              text: videoItem.ogv['type_name'],
                              top: 6.0,
                              right: 6.0,
                              bottom: null,
                              left: null,
                            ),
                          ],
                        ],
                      );
                    },
                  ),
                ),
                VideoContent(
                  videoItem: videoItem,
                  callFn: callFn,
                  searchType: searchType,
                )
              ],
            ),
          );
        },
      ),
    );
  }
}

class VideoContent extends StatelessWidget {
  final dynamic videoItem;
  final Function? callFn;
  final int? searchType;
  const VideoContent({
    super.key,
    required this.videoItem,
    this.callFn,
    this.searchType,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 2, 6, 0),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  videoItem.title ?? '视频暂不可用',
                  textAlign: TextAlign.start,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (videoItem.ogv != null) ...[
                  Text(
                    videoItem.intro ?? '',
                    style: TextStyle(
                      fontSize:
                          Theme.of(context).textTheme.labelMedium!.fontSize,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                ],
                const Spacer(),
                Text(
                  "${videoItem.pubdate == null ? '' : Utils.dateFormat(videoItem.pubdate!, formatType: 'day')} ${videoItem.owner?.name ?? ''}",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize:
                          Theme.of(context).textTheme.labelMedium!.fontSize,
                      color: Theme.of(context).colorScheme.outline),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Row(
                    children: [
                      if (videoItem.cntInfo?['play'] != null)
                        StatView(
                          theme: 'gray',
                          view: videoItem.cntInfo['play'],
                        ),
                      const SizedBox(width: 8),
                      if (videoItem.cntInfo?['danmaku'] != null)
                        StatDanMu(
                            theme: 'gray', danmu: videoItem.cntInfo['danmaku']),
                      const Spacer(),
                    ],
                  ),
                ),
              ],
            ),
            if (searchType != 1)
              Positioned(
                right: 0,
                bottom: -6,
                width: 28,
                height: 28,
                child: IconButton(
                  tooltip: '取消收藏',
                  style: ButtonStyle(
                    padding: WidgetStateProperty.all(EdgeInsets.zero),
                  ),
                  onPressed: () {
                    showDialog(
                      context: Get.context!,
                      builder: (context) {
                        return AlertDialog(
                          title: const Text('提示'),
                          content: const Text('要取消收藏吗?'),
                          actions: [
                            TextButton(
                                onPressed: () => Get.back(),
                                child: Text(
                                  '取消',
                                  style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .outline),
                                )),
                            TextButton(
                              onPressed: () async {
                                await callFn!();
                                Get.back();
                              },
                              child: const Text('确定取消'),
                            )
                          ],
                        );
                      },
                    );
                  },
                  icon: Icon(
                    Icons.clear_outlined,
                    color: Theme.of(context).colorScheme.outline,
                    size: 18,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
