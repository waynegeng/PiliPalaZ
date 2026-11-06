import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SettingPage extends StatelessWidget {
  const SettingPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('设置')),
        body: ListView(children: [
          for (final entry in const {
            '一般设置': '/generalSetting',
            '播放设置': '/playbackSetting',
            '首页设置': '/homeSetting',
            '动态设置': '/dynamicSetting',
            '账号设置': '/accountSetting'
          }.entries)
            ListTile(
                title: Text(entry.key),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Get.toNamed(entry.value)),
        ]),
      );
}
