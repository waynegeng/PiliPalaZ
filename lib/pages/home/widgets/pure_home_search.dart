import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Search in place: focusing the field never opens history or recommendations.
class PureHomeSearch extends StatefulWidget {
  const PureHomeSearch({super.key});

  static final routeObserver = RouteObserver<ModalRoute<dynamic>>();

  @override
  State<PureHomeSearch> createState() => _PureHomeSearchState();
}

class _PureHomeSearchState extends State<PureHomeSearch> with RouteAware {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  ModalRoute<dynamic>? _route;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (_route == route) return;
    PureHomeSearch.routeObserver.unsubscribe(this);
    _route = route;
    if (route != null) PureHomeSearch.routeObserver.subscribe(this, route);
  }

  @override
  void didPushNext() {
    // Clear the route's focus history before another page takes focus, so
    // popping that page cannot restore the search field and reopen the IME.
    _focusNode.unfocus();
  }

  void _submit(String value) {
    final keyword = value.trim();
    if (keyword.isEmpty) return;
    _focusNode.unfocus();
    Get.toNamed('/searchResult', parameters: {'keyword': keyword});
  }

  @override
  void dispose() {
    PureHomeSearch.routeObserver.unsubscribe(this);
    _focusNode.dispose();
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
    final logoSize = math.min(150.0, top - 16);
    return Stack(
      children: [
        Positioned(
            top: top - logoSize - 12,
            left: 0,
            right: 0,
            child: Center(
                child: Image.asset('assets/images/logo/logo_android_2.png',
                    height: logoSize,
                    width: logoSize,
                    semanticLabel: 'PiliPalaZ'))),
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
                  focusNode: _focusNode,
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
