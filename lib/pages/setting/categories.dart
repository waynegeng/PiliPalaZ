import 'play_setting.dart';
import 'video_setting.dart';
import 'privacy_setting.dart';
import 'recommend_setting.dart';
import '../dynamics/controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'controller.dart';
import 'style_setting.dart';
import 'extra_setting.dart';
import '../about/index.dart';
import '../../utils/storage.dart';
import 'widgets/switch_item.dart';

class SettingsCategoryPage extends StatelessWidget {
  const SettingsCategoryPage({super.key, required this.category});
  final String category;
  Widget link(String title, String route, IconData icon) => ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => Get.toNamed(route));
  @override
  Widget build(BuildContext context) {
    final controller = Get.put(SettingController());
    final titles = {
      'general': '一般设置',
      'playback': '播放设置',
      'home': '首页设置',
      'dynamic': '动态设置',
      'account': '账号设置'
    };
    return Scaffold(
        appBar: AppBar(
            centerTitle: false,
            titleSpacing: 0,
            title: Text(titles[category]!,
                style: Theme.of(context).textTheme.titleMedium)),
        body: ListTileTheme.merge(
            titleTextStyle: Theme.of(context).textTheme.titleMedium,
            subtitleTextStyle: Theme.of(context)
                .textTheme
                .labelMedium
                ?.copyWith(color: Theme.of(context).colorScheme.outline),
            child: ListView(children: [
              if (category == 'general') ...[
                const StyleSetting(embedded: true),
                const StyleSetting(section: 'other', embedded: true),
                const ExtraSetting(embedded: true),
                const AboutPage(section: 'other', embedded: true),
                Obx(() => controller.hiddenSettingUnlocked.value
                    ? link('开发人员选项', '/hiddenSetting',
                        Icons.developer_board_outlined)
                    : const SizedBox.shrink()),
                link('关于', '/about', Icons.info_outline),
              ],
              if (category == 'playback') ...[
                const PlaySetting(embedded: true),
                const Divider(),
                const VideoSetting(embedded: true),
              ],
              if (category == 'home') ...[
                const StyleSetting(section: 'home', embedded: true),
                const ExtraSetting(section: 'home', embedded: true),
                const Divider(),
                const RecommendSetting(embedded: true),
              ],
              if (category == 'dynamic') ...[
                link('动态标签页', '/dynamicTabbarSetting', Icons.tab_outlined),
                SetSwitchItem(
                    callFn: (_) {
                      if (Get.isRegistered<DynamicsController>()) {
                        Get.find<DynamicsController>().headerVisible.value =
                            true;
                      }
                    },
                    leading: const Icon(Icons.vertical_align_top),
                    title: '动态页顶栏收起',
                    subTitle: '上滑收起标签栏，下滑恢复',
                    setKey: SettingBoxKey.hideDynamicHeader,
                    defaultVal: true),
                const StyleSetting(section: 'dynamic', embedded: true),
              ],
              if (category == 'account') ...[
                const PrivacySetting(embedded: true),
                Obx(() => controller.userLogin.value
                    ? ListTile(
                        title: const Text('退出登录'),
                        leading: const Icon(Icons.logout),
                        onTap: () => controller.loginOut(context))
                    : const SizedBox.shrink()),
              ],
            ])));
  }
}
