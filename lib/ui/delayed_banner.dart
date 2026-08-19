import 'dart:async';

import 'package:flutter/material.dart';

/// Shows the built child only after [visible] has stayed `true` for
/// [delay]. Transient conditions (a reconnect that heals in <5s, e.g. on
/// unlock from a locked screen) never surface; sustained ones do.
class DelayedVisibility extends StatefulWidget {
  final bool visible;
  final Duration delay;
  final WidgetBuilder builder;

  const DelayedVisibility({
    super.key,
    required this.visible,
    required this.delay,
    required this.builder,
  });

  @override
  State<DelayedVisibility> createState() => _DelayedVisibilityState();
}

class _DelayedVisibilityState extends State<DelayedVisibility> {
  Timer? _timer;
  bool _armed = false;

  @override
  void initState() {
    super.initState();
    _update(widget.visible);
  }

  @override
  void didUpdateWidget(covariant DelayedVisibility oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.visible != widget.visible) _update(widget.visible);
  }

  void _update(bool visible) {
    if (visible) {
      _timer ??= Timer(widget.delay, () {
        _timer = null;
        if (mounted) setState(() => _armed = true);
      });
    } else {
      _timer?.cancel();
      _timer = null;
      if (_armed) setState(() => _armed = false);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _armed ? widget.builder(context) : const SizedBox.shrink();
  }
}
