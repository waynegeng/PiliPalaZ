import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../common/widgets/network_img_layer.dart';
import 'controller.dart';

class AccountHeader extends StatelessWidget {
  const AccountHeader({super.key, required this.controller});
  final MediaController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final info = controller.profile;
    final level = info?.levelInfo;
    final avatar = info?.face?.isNotEmpty == true
        ? ClipOval(
            child: NetworkImgLayer(
                type: 'avatar', src: info!.face, width: 56, height: 56))
        : const CircleAvatar(radius: 28, child: Icon(Icons.person_outline));
    if (!controller.userLogin.value) {
      return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(children: [
            avatar,
            const SizedBox(width: 16),
            FilledButton.tonal(
                onPressed: () => Get.toNamed('/loginPage'),
                child: const Text('登录'))
          ]));
    }
    final exp = level?.currentExp ?? '—';
    final next = level?.currentLevel == 6 ? '已满级' : '${level?.nextExp ?? '—'}';
    final money = info?.money;
    final coins = money == null
        ? '—'
        : money == money.truncate()
            ? money.toInt().toString()
            : money.toString();
    final mid = controller.mid;
    Widget stat(String label, int? count, String route) => Expanded(
        child: TextButton(
            onPressed: () => Get.toNamed('/$route?mid=$mid'),
            child: Column(children: [
              Text('${count ?? '—'}', style: theme.textTheme.titleMedium),
              Text(label, style: theme.textTheme.labelMedium)
            ])));
    return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(children: [
          Row(children: [
            avatar,
            const SizedBox(width: 14),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Wrap(
                      spacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(info?.uname ?? '—',
                            style: theme.textTheme.titleLarge),
                        Text('Lv.${level?.currentLevel ?? '—'}',
                            style: theme.textTheme.labelLarge
                                ?.copyWith(color: theme.colorScheme.primary))
                      ]),
                  const SizedBox(height: 4),
                  Wrap(
                      spacing: 12,
                      children: [Text('经验 $exp / $next'), Text('硬币 $coins')]),
                ]))
          ]),
          const SizedBox(height: 8),
          Row(children: [
            stat('动态', controller.stats?.dynamicCount, 'member'),
            stat('关注', controller.stats?.following, 'follow'),
            stat('粉丝', controller.stats?.follower, 'fan')
          ]),
        ]));
  }
}
