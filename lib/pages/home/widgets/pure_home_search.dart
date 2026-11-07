import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Search in place: focusing the field never opens history or recommendations.
class PureHomeSearch extends StatefulWidget {
  const PureHomeSearch({super.key});

  @override
  State<PureHomeSearch> createState() => _PureHomeSearchState();
}

class _PureHomeSearchState extends State<PureHomeSearch> {
  final _controller = TextEditingController();

  void _submit(String value) {
    final keyword = value.trim();
    if (keyword.isEmpty) return;
    FocusScope.of(context).unfocus();
    Get.toNamed('/searchResult', parameters: {'keyword': keyword});
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    // The viewport stays stable when ancestor Scaffolds resize for the keyboard.
    final viewport = MediaQuery.sizeOf(context);
    final top = math.max(64.0,
        viewport.height * .38 - 28 - MediaQuery.viewPaddingOf(context).top);
    return Stack(
      children: [
        Positioned(
          top: top,
          left: 0,
          right: 0,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: TextField(
                  controller: _controller,
                  textInputAction: TextInputAction.search,
                  maxLines: 1,
                  onSubmitted: _submit,
                  decoration: InputDecoration(
                    hintText: '搜索',
                    filled: true,
                    fillColor: colors.onSecondaryContainer.withOpacity(0.05),
                    prefixIcon: const Icon(Icons.search_outlined),
                    suffixIcon: IconButton(
                      tooltip: '搜索',
                      onPressed: () => _submit(_controller.text),
                      icon: const Icon(Icons.arrow_forward),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
            ),
          ),
        )
      ],
    );
  }
}
