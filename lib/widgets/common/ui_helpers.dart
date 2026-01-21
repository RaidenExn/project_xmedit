import 'package:flutter/material.dart';

Color? getRowColor({
  required BuildContext context,
  required bool isZebra,
  bool isDeleted = false,
  bool isHighlighted = false,
}) {
  if (isDeleted) {
    return Theme.of(context).colorScheme.error.withAlpha((255 * 0.05).round());
  }
  if (isHighlighted) {
    return Theme.of(context)
        .colorScheme
        .primaryContainer
        .withAlpha((255 * 0.3).round());
  }
  if (isZebra) {
    return Theme.of(context)
        .colorScheme
        .surfaceContainerHighest
        .withAlpha((255 * 0.5).round());
  }
  return null;
}

class EntranceFader extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;
  final Offset offset;

  const EntranceFader({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 400),
    this.offset = const Offset(0.0, 0.1),
  });

  @override
  State<EntranceFader> createState() => _EntranceFaderState();
}

class _EntranceFaderState extends State<EntranceFader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: widget.offset,
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutQuad,
    ));

    Future.delayed(widget.delay, () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: widget.child,
      ),
    );
  }
}
