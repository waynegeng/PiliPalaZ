import '../home/rcmd/result.dart';
import 'result.dart';

RecVideoItemAppModel? dynamicVideoCard(DynamicItemModel item) {
  final archive = item.modules?.moduleDynamic?.major?.archive;
  final author = item.modules?.moduleAuthor;
  if (archive == null ||
      archive.bvid?.trim().startsWith('BV') != true ||
      archive.title?.trim().isNotEmpty != true ||
      archive.cover?.isNotEmpty != true) return null;
  final parts = archive.durationText?.split(':').map(int.tryParse).toList();
  int duration = 0;
  if (parts != null && parts.every((part) => part != null)) {
    for (final part in parts) {
      duration = duration * 60 + part!;
    }
  }
  return RecVideoItemAppModel(
    id: archive.aid,
    aid: archive.aid,
    bvid: archive.bvid!.trim(),
    goto: 'av',
    pic: archive.cover,
    title: archive.title,
    duration: duration,
    owner: RcmdOwner(name: author?.name ?? '未知UP主', mid: author?.mid),
    stat: RcmdStat(view: archive.stat?.play, danmu: archive.stat?.danmu),
  );
}
