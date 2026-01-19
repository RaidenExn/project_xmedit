import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class MeasureSize extends StatefulWidget {
  final Widget child;
  final ValueChanged<Size> onChange;

  const MeasureSize({
    super.key,
    required this.onChange,
    required this.child,
  });

  @override
  State<MeasureSize> createState() => _MeasureSizeState();
}

class _MeasureSizeState extends State<MeasureSize> {
  var _size = Size.zero;

  @override
  Widget build(BuildContext context) {
    SchedulerBinding.instance.addPostFrameCallback(_postFrameCallback);
    return Container(
      key: widget.key,
      child: widget.child,
    );
  }

  void _postFrameCallback(_) {
    final context = this.context;
    if (!context.mounted) return;

    final newSize = context.size;
    if (newSize != null && newSize != _size) {
      _size = newSize;
      widget.onChange(newSize);
    }
  }
}
