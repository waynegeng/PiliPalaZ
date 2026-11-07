import 'package:flutter/material.dart';
import '../../common/widgets/network_img_layer.dart';
import '../../models/user/fav_detail.dart';
import '../../utils/utils.dart';
import '../fav_detail/widget/favorite_actions.dart';

class FavoriteVideoTile extends StatelessWidget {
  const FavoriteVideoTile(
      {super.key, required this.video, required this.onRemove});
  final FavDetailItemData video;
  final Future<void> Function() onRemove;
  @override
  Widget build(BuildContext context) {
    final title = video.title ?? '视频暂不可用';
    final playable = (video.id ?? 0) > 0 &&
        video.pic?.isNotEmpty == true &&
        !['已失效视频', '视频已失效', '视频已删除'].contains(title);
    final heroTag = Utils.makeHeroTag(video.id);
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      child: Card(
        margin: EdgeInsets.zero,
        elevation: 0,
        color: theme.colorScheme.surfaceContainerLow,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: playable ? () => openFavoriteVideo(video, heroTag) : null,
          child: Padding(
              padding: const EdgeInsets.all(10),
              child: LayoutBuilder(builder: (context, constraints) {
                final coverWidth =
                    (constraints.maxWidth * .36).clamp(72.0, 200.0);
                return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                          width: coverWidth,
                          child: AspectRatio(
                            aspectRatio: 16 / 9,
                            child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Stack(fit: StackFit.expand, children: [
                                  if (video.pic?.isNotEmpty == true)
                                    Hero(
                                        tag: heroTag,
                                        child: NetworkImgLayer(
                                            src: video.pic,
                                            width: coverWidth,
                                            height: coverWidth * 9 / 16))
                                  else
                                    ColoredBox(
                                        color: theme.colorScheme
                                            .surfaceContainerHighest,
                                        child: const Icon(
                                            Icons.videocam_off_outlined)),
                                  if ((video.duration ?? 0) > 0)
                                    Positioned(
                                        right: 4,
                                        bottom: 4,
                                        child: DecoratedBox(
                                            decoration: BoxDecoration(
                                                color: Colors.black54,
                                                borderRadius:
                                                    BorderRadius.circular(4)),
                                            child: Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 4),
                                                child: Text(
                                                    Utils.timeFormat(
                                                        video.duration!),
                                                    style: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 10))))),
                                ])),
                          )),
                      const SizedBox(width: 12),
                      Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Text(title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.titleSmall),
                            const SizedBox(height: 6),
                            if (video.owner?.name != null)
                              Text(video.owner!.name!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.labelMedium?.copyWith(
                                      color: theme.colorScheme.outline)),
                            if (!playable)
                              Text('暂不可播放', style: theme.textTheme.labelSmall),
                            Wrap(spacing: 10, children: [
                              if (video.stat?.view != null)
                                Text('${Utils.numFormat(video.stat!.view)}播放',
                                    style: theme.textTheme.labelSmall),
                              if (video.stat?.danmu != null)
                                Text('${Utils.numFormat(video.stat!.danmu)}弹幕',
                                    style: theme.textTheme.labelSmall),
                            ]),
                            if (video.id != null)
                              Align(
                                  alignment: Alignment.centerRight,
                                  child: IconButton(
                                    tooltip: '取消收藏',
                                    visualDensity: VisualDensity.compact,
                                    iconSize: 18,
                                    icon: const Icon(
                                        Icons.bookmark_remove_outlined),
                                    onPressed: () => confirmRemoveFavorite(
                                        context, onRemove),
                                  )),
                          ])),
                    ]);
              })),
        ),
      ),
    );
  }
}
