import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import '../../../models/common/dynamic_tab_config.dart';
import '../../../utils/storage.dart';
import '../../dynamics/controller.dart';

class DynamicTabbarSetPage extends StatefulWidget {
  const DynamicTabbarSetPage({super.key});
  @override
  State<DynamicTabbarSetPage> createState() => _DynamicTabbarSetPageState();
}

class _DynamicTabbarSetPageState extends State<DynamicTabbarSetPage> {
  late List<String> visible;
  late List<String> order;
  late String defaultId;
  @override
  void initState() {
    super.initState();
    final box = GStorage.setting;
    visible = DynamicTabConfig.normalize(box.get(SettingBoxKey.dynamicTabs));
    order = [
      ...visible,
      ...DynamicTabConfig.ids.where((id) => !visible.contains(id))
    ];
    defaultId = DynamicTabConfig.defaultId(
        box.get(SettingBoxKey.defaultDynamicTab),
        box.get(SettingBoxKey.defaultDynamicType),
        visible);
  }

  Future<void> save() async {
    final ids = order.where(visible.contains).toList();
    await GStorage.setting.putAll({
      SettingBoxKey.dynamicTabs: ids,
      SettingBoxKey.defaultDynamicTab: defaultId
    });
    if (Get.isRegistered<DynamicsController>())
      Get.find<DynamicsController>().applyTabConfig();
    SmartDialog.showToast('已保存并生效');
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
            title: const Text('动态标签页'),
            actions: [TextButton(onPressed: save, child: const Text('保存'))]),
        body: ReorderableListView(
          header: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(children: [
                DropdownButtonFormField<String>(
                    value: defaultId,
                    decoration: const InputDecoration(labelText: '默认标签'),
                    items: order
                        .where((id) => visible.isEmpty || visible.contains(id))
                        .map((id) => DropdownMenuItem(
                            value: id,
                            child: Text(DynamicTabConfig.labels[id]!)))
                        .toList(),
                    onChanged: (id) => setState(() => defaultId = id!)),
                const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text('全部取消勾选后隐藏顶栏，仅显示默认标签的内容。')),
                TextButton(
                    onPressed: () => setState(() {
                          visible = List.of(DynamicTabConfig.ids);
                          order = List.of(visible);
                          defaultId = 'all';
                        }),
                    child: const Text('恢复默认')),
              ])),
          onReorder: (oldIndex, newIndex) => setState(() {
            if (newIndex > oldIndex) newIndex--;
            order.insert(newIndex, order.removeAt(oldIndex));
          }),
          children: [
            for (final id in order)
              CheckboxListTile(
                  key: ValueKey(id),
                  title: Text(DynamicTabConfig.labels[id]!),
                  secondary: const Icon(Icons.drag_indicator),
                  value: visible.contains(id),
                  onChanged: (enabled) {
                    setState(() {
                      if (enabled == true) {
                        visible.add(id);
                      } else {
                        visible.remove(id);
                      }
                      if (visible.isNotEmpty && !visible.contains(defaultId))
                        defaultId = order.firstWhere(visible.contains);
                    });
                  })
          ],
        ),
      );
}
