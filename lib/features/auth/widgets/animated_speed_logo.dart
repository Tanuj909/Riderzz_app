import 'package:flutter/material.dart';

class AnimatedSpeedLogo extends StatefulWidget {
  final double height;
  const AnimatedSpeedLogo({super.key, this.height = 130});

  @override
  State<AnimatedSpeedLogo> createState() => _AnimatedSpeedLogoState();
}

class _AnimatedSpeedLogoState extends State<AnimatedSpeedLogo> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3600), // 3.6s total loop time
    );

    _animation = TweenSequence<Offset>([
      // 1. Slide in from right (takes 800ms)
      TweenSequenceItem<Offset>(
        tween: Tween<Offset>(
          begin: const Offset(1.5, 0.0),
          end: Offset.zero,
        ).chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 22.0,
      ),
      // 2. Pause in center (stays 2000ms)
      TweenSequenceItem<Offset>(
        tween: ConstantTween<Offset>(Offset.zero),
        weight: 56.0,
      ),
      // 3. Slide out to left (takes 800ms)
      TweenSequenceItem<Offset>(
        tween: Tween<Offset>(
          begin: Offset.zero,
          end: const Offset(-1.5, 0.0),
        ).chain(CurveTween(curve: Curves.easeInCubic)),
        weight: 22.0,
      ),
    ]).animate(_controller);

    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        _controller.repeat();
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
    return Container(
      height: widget.height,
      width: double.infinity,
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
      ),
      child: SlideTransition(
        position: _animation,
        child: Image.asset(
          'assets/logo/logo.png',
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}

