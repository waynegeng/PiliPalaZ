import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import '../../../http/search.dart';
import '../../../http/video.dart';
import '../../../models/common/search_type.dart';
import '../../../utils/id_utils.dart';

Future<void> openFavoriteVideo(dynamic video, String heroTag) async {
  try {
    final String bvid = video.bvid ?? video.bvId ?? IdUtils.av2bv(video.id);
    String? epId = video.epId;
    if (video.ogv != null &&
        (video.ogv['type_name'] == '番剧' || video.ogv['type_name'] == '国创')) {
      video.cid ??= await SearchHttp.ab2c(bvid: bvid);
    } else if (video.page == 0 || (video.page ?? 0) > 1) {
      final result = await VideoHttp.videoIntro(bvid: bvid);
      if (result['status']) epId = result['data'].epId;
    }
    video.cid ??= await SearchHttp.ab2c(bvid: bvid);
    Get.toNamed('/video', parameters: {
      'bvid': bvid,
      'cid': '${video.cid}',
      'epId': epId ?? '',
    }, arguments: {
      'videoItem': video,
      'heroTag': heroTag,
      'videoType': epId != null ? SearchType.media_bangumi : SearchType.video,
    });
  } catch (_) {
    SmartDialog.showToast('视频暂不可播放，请稍后重试');
  }
}

Future<void> confirmRemoveFavorite(
    BuildContext context, Future<void> Function() remove) async {
  final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
            title: const Text('取消收藏'),
            content: const Text('要从当前收藏夹移除此视频吗？'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('取消')),
              TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('确定')),
            ],
          ));
  if (confirmed != true) return;
  try {
    await remove();
    SmartDialog.showToast('已取消收藏');
  } catch (_) {
    SmartDialog.showToast('取消收藏失败，请重试');
  }
}
