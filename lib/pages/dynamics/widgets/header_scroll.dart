import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class DynamicHeaderScroll extends StatelessWidget {
  const DynamicHeaderScroll(
      {super.key,
      required this.child,
      required this.enabled,
      required this.onVisibilityChanged});
  final Widget child;
  final bool Function() enabled;
  final ValueChanged<bool> onVisibilityChanged;
  @override
  Widget build(BuildContext context) =>
      NotificationListener<ScrollNotification>(
        onNotification: (event) {
          if (event.depth != 0 || event.metrics.axis != Axis.vertical)
            return false;
          if (!enabled() || event.metrics.pixels <= 0) {
            onVisibilityChanged(true);
          } else if (event is ScrollUpdateNotification &&
              event.dragDetails != null) {
            if ((event.scrollDelta ?? 0) > 0) onVisibilityChanged(false);
            if ((event.scrollDelta ?? 0) < 0) onVisibilityChanged(true);
          } else if (event is UserScrollNotification) {
            if (event.direction == ScrollDirection.forward)
              onVisibilityChanged(true);
            if (event.direction == ScrollDirection.reverse)
              onVisibilityChanged(false);
          }
          return false;
        },
        child: child,
      );
}
