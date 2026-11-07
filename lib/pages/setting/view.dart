import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SettingPage extends StatelessWidget {
  const SettingPage({super.key});
  @override
  Widget build(BuildContext context) {
    final entries = [
      ['一般设置', '主题、外观、启动、缓存与关于', Icons.settings_outlined, '/generalSetting'],
      [
        '播放设置',
        '播放器、手势、弹幕、画质与音频',
        Icons.play_circle_outline,
        '/playbackSetting'
      ],
      ['首页设置', '纯净首页、首页布局、搜索与推荐', Icons.home_outlined, '/homeSetting'],
      [
        '动态设置',
        '动态标签、顶栏、UP主与未读标记',
        Icons.motion_photos_on_outlined,
        '/dynamicSetting'
      ],
      ['账号设置', '隐私、黑名单与退出登录', Icons.person_outline, '/accountSetting'],
    ];
    return Scaffold(
      appBar: AppBar(
          centerTitle: false,
          titleSpacing: 0,
          title: Text('设置', style: Theme.of(context).textTheme.titleMedium)),
      body: ListView(children: [
        for (final entry in entries)
          ListTile(
            dense: false,
            leading: Icon(entry[2] as IconData),
            title: Text(entry[0] as String,
                style: Theme.of(context).textTheme.titleMedium),
            subtitle: Text(entry[1] as String,
                style: Theme.of(context)
                    .textTheme
                    .labelMedium!
                    .copyWith(color: Theme.of(context).colorScheme.outline)),
            onTap: () => Get.toNamed(entry[3] as String),
          ),
      ]),
    );
  }
}
