import 'package:flutter/material.dart';

/// Wraps [child] with a fade+slide-in animation, delayed by `index * 50ms`.
/// Set [animate] to false to render [child] immediately with no effect —
/// used for anything built outside the initial screen load (pagination,
/// items revealed by scrolling later).
class StaggeredListItem extends StatefulWidget {
  final int index;
  final bool animate;
  final Widget child;

  const StaggeredListItem({
    super.key,
    required this.index,
    required this.child,
    this.animate = true,
  });

  @override
  State<StaggeredListItem> createState() => _StaggeredListItemState();
}

class _StaggeredListItemState extends State<StaggeredListItem> {
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    if (!widget.animate) {
      _visible = true;
      return;
    }
    final delay = Duration(milliseconds: 50 * widget.index.clamp(0, 12));
    Future.delayed(delay, () {
      if (mounted) setState(() => _visible = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.animate) return widget.child;
    return AnimatedOpacity(
      opacity: _visible ? 1 : 0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      child: AnimatedSlide(
        offset: _visible ? Offset.zero : const Offset(0, 0.08),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}
