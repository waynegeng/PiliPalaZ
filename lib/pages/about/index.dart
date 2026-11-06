import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:pilipalaz/http/index.dart';
import 'package:pilipalaz/models/github/latest.dart';
import 'package:pilipalaz/pages/setting/controller.dart';
import 'package:pilipalaz/utils/storage.dart';
import 'package:pilipalaz/utils/utils.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../utils/cache_manage.dart';

class AboutPage extends StatefulWidget {
  const AboutPage({super.key, this.section = 'about', this.embedded = false});
  final String section;
  final bool embedded;

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  final AboutController _aboutController = Get.put(AboutController());
  String cacheSize = '';

  @override
  void initState() {
    super.initState();
    // 读取缓存占用
    getCacheSize();
  }

  Future<void> getCacheSize() async {
    final res = await CacheManage().loadApplicationCache();
    cacheSize = res;
    if (!mounted) return;
    setState(() => {});
  }

  @override
  Widget build(BuildContext context) {
    final Color outline = Theme.of(context).colorScheme.outline;
    TextStyle subTitleStyle =
        TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.outline);
    final items = <Widget>[
      if (widget.section == 'about')
        Column(children: [
          Image.asset(
            excludeFromSemantics: true,
            height: 150,
            'assets/images/logo/logo_android_2.png',
          ),
          Text('PiliPalaZ',
              textAlign: TextAlign.left,
              style: Theme.of(context).textTheme.titleMedium,
              semanticsLabel: 'PiliPalaZ 与你一起，发现不一样的世界'),
          Text(
            '使用Flutter开发的B站第三方客户端⁺',
            textAlign: TextAlign.left,
            style: TextStyle(
                color: Theme.of(context).colorScheme.outline, height: 3),
            semanticsLabel: '使用Flutter开发的B站第三方客户端（带无障碍适配）',
          ),
        ]),
      if (widget.section == 'about')
        Obx(
          () => ListTile(
            onTap: () => _aboutController.tapOnVersion(),
            title: const Text('当前版本'),
            leading: Icon(MdiIcons.sourceCommitLocal),
            trailing: Text(_aboutController.currentVersion.value,
                style: subTitleStyle),
          ),
        ),
      if (widget.section == 'about')
        Obx(
          () => ListTile(
            onTap: () => _aboutController.onUpdate(),
            title: const Text('最新版本'),
            leading: Icon(MdiIcons.newBox),
            trailing: Text(
              _aboutController.isLoading.value
                  ? '正在获取'
                  : _aboutController.isUpdate.value
                      ? '有新版本  ❤️${_aboutController.remoteVersion.value}'
                      : _aboutController.updateStatus.value,
              style: subTitleStyle,
            ),
          ),
        ),
      if (widget.section == 'about')
        Divider(
          thickness: 1,
          height: 30,
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
      if (widget.section == 'about')
        ListTile(
          onTap: () => _aboutController.githubUrl(),
          leading: Icon(MdiIcons.github),
          title: const Text('开源仓库⭐'),
          trailing: Text(
            'Github.com/waynegeng/PiliPalaZ',
            style: subTitleStyle,
          ),
        ),
      if (widget.section == 'other')
        ListTile(
          onTap: () => _aboutController.logs(),
          leading: const Icon(Icons.bug_report),
          title: const Text('错误日志'),
          trailing: Icon(Icons.arrow_forward_ios, size: 16, color: outline),
        ),
      if (widget.section == 'other')
        ListTile(
          onTap: () async {
            await CacheManage().clearCacheAll(context);
            getCacheSize();
          },
          leading: const Icon(Icons.delete),
          title: const Text('清除缓存'),
          trailing: Text('图片及网络缓存 $cacheSize', style: subTitleStyle),
        ),
      if (widget.section == 'other')
        ListTile(
            title: const Text('导入/导出设置'),
            dense: false,
            leading: const Icon(Icons.import_export),
            onTap: () async {
              await showDialog(
                context: context,
                builder: (context) {
                  return SimpleDialog(
                    title: const Text('导入/导出设置'),
                    children: [
                      ListTile(
                        title: const Text('导出设置至剪贴板'),
                        onTap: () async {
                          Get.back();
                          String data = await GStorage.exportAllSettings();
                          Clipboard.setData(ClipboardData(text: data));
                          SmartDialog.showToast('已复制到剪贴板');
                        },
                      ),
                      ListTile(
                        title: const Text('从剪贴板导入设置'),
                        onTap: () async {
                          Get.back();
                          ClipboardData? data =
                              await Clipboard.getData('text/plain');
                          if (data == null ||
                              data.text == null ||
                              data.text!.isEmpty) {
                            SmartDialog.showToast('剪贴板无数据');
                            return;
                          }
                          if (!context.mounted) return;
                          await showDialog(
                            context: context,
                            builder: (context) {
                              return AlertDialog(
                                title: const Text('是否导入如下设置？'),
                                content: Text(data.text!),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      Get.back();
                                    },
                                    child: const Text('取消'),
                                  ),
                                  TextButton(
                                    onPressed: () async {
                                      Get.back();
                                      try {
                                        await GStorage.importAllSettings(
                                            data.text!);
                                        SmartDialog.showToast('导入成功');
                                      } catch (e) {
                                        SmartDialog.showToast('导入失败：$e');
                                      }
                                    },
                                    child: const Text('确定'),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      ),
                    ],
                  );
                },
              );
            }),
      if (widget.section == 'other')
        ListTile(
          title: const Text('重置所有设置'),
          leading: const Icon(Icons.settings_backup_restore),
          onTap: () async {
            await showDialog(
              context: context,
              builder: (context) {
                return AlertDialog(
                  title: const Text('重置所有设置'),
                  content: const Text('是否重置所有设置？'),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Get.back();
                      },
                      child: const Text('取消'),
                    ),
                    TextButton(
                      onPressed: () {
                        Get.back();
                        GStorage.setting.clear();
                        GStorage.video.clear();
                        SmartDialog.showToast('重置成功');
                      },
                      child: const Text('重置可导出的设置'),
                    ),
                    TextButton(
                      onPressed: () {
                        Get.back();
                        GStorage.userInfo.clear();
                        GStorage.setting.clear();
                        GStorage.localCache.clear();
                        GStorage.video.clear();
                        GStorage.historyWord.clear();
                        GStorage.onlineCache.clear();
                        SmartDialog.showToast('重置成功');
                      },
                      child: const Text('重置所有数据（含登录信息）'),
                    ),
                  ],
                );
              },
            );
          },
        ),
    ];
    if (widget.embedded) return Column(children: items);
    return Scaffold(
      appBar: AppBar(
        title: Text('关于', style: Theme.of(context).textTheme.titleMedium),
      ),
      body: ListView(
        children: items,
      ),
    );
  }
}

class AboutController extends GetxController {
  Box setting = GStorage.setting;
  final SettingController settingController = Get.put(SettingController());
  RxString currentVersion = ''.obs;
  RxString remoteVersion = ''.obs;
  late LatestDataModel remoteAppInfo;
  RxBool isUpdate = false.obs;
  RxString updateStatus = '暂无发布版本'.obs;
  RxBool isLoading = true.obs;
  LatestDataModel? data;
  RxInt count = 0.obs;

  @override
  void onInit() {
    super.onInit();
    // init();
    // 获取当前版本
    getCurrentApp().then((_) => getRemoteApp());
  }

  // 获取设备信息
  // Future init() async {
  //   DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
  //   if (Platform.isAndroid) {
  //     AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
  //     print(androidInfo.supportedAbis);
  //   } else if (Platform.isIOS) {
  //     IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
  //     print(iosInfo);
  //   }
  // }

  // 获取当前版本
  Future getCurrentApp() async {
    var currentInfo = await PackageInfo.fromPlatform();
    String buildNumber = currentInfo.buildNumber;
    //if is android

    currentVersion.value = "${currentInfo.version}+$buildNumber";
  }

  // 获取远程版本
  Future getRemoteApp() async {
    isLoading.value = true;
    try {
      final result = await Request().get(Api.latestApp, extra: {'ua': 'pc'});
      if (result.data is! List) throw StateError('Invalid release response');
      if (result.data.isEmpty) {
        data = null;
        isUpdate.value = false;
        updateStatus.value = '暂无发布版本';
        return false;
      }
      data = LatestDataModel.fromJson(result.data[0]);
      remoteAppInfo = data!;
      remoteVersion.value = data!.tagName!;
      isUpdate.value =
          Utils.needUpdate(currentVersion.value, remoteVersion.value);
      updateStatus.value = '当前已是最新版';
      return true;
    } catch (_) {
      updateStatus.value = '检查更新失败，点击重试';
      isUpdate.value = false;
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // 跳转下载/本地更新
  Future onUpdate() async {
    if (data == null) {
      SmartDialog.showLoading(msg: '正在尝试从Github获取最新版本');
      await getRemoteApp();
      SmartDialog.dismiss();
      return;
    }
    Utils.matchVersion(data);
  }

  // 跳转github
  githubUrl() {
    launchUrl(
      Uri.parse('https://github.com/waynegeng/PiliPalaZ'),
      mode: LaunchMode.externalApplication,
    );
  }

  githubRelease() {
    launchUrl(
      Uri.parse('https://github.com/waynegeng/PiliPalaZ/releases'),
      mode: LaunchMode.externalApplication,
    );
  }

  aPay() {
    SmartDialog.showToast('感谢你的喜欢，给个Star就行~');
  }

  // 日志
  logs() {
    Get.toNamed('/logs');
  }

  tapOnVersion() {
    if (settingController.hiddenSettingUnlocked.value) {
      SmartDialog.showToast('您已解锁开发人员选项, 无需再次操作');
      return;
    }
    count.value++;
    if (count.value == 5) {
      setting.put(SettingBoxKey.hiddenSettingUnlocked, true);
      SmartDialog.showToast('恭喜您发现了开发人员选项!');
    }
  }
}
