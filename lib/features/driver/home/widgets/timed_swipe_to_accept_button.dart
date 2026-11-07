import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TimedSwipeToAcceptButton extends StatefulWidget {
  final int bookingId;
  final DateTime firstSeenTime;
  final Future<bool> Function() onAccept;

  const TimedSwipeToAcceptButton({
    super.key,
    required this.bookingId,
    required this.firstSeenTime,
    required this.onAccept,
  });

  @override
  State<TimedSwipeToAcceptButton> createState() => _TimedSwipeToAcceptButtonState();
}

class _TimedSwipeToAcceptButtonState extends State<TimedSwipeToAcceptButton>
    with TickerProviderStateMixin {
  late AnimationController _progressController;
  late AnimationController _arrowAnimationController;
  late AnimationController _arrowNudgeController;
  late Animation<double> _arrowNudgeAnimation;
  bool _isLocked = true;
  double _thumbPosition = 0;
  bool _isLoading = false;
  bool _isCompleted = false;

  @override
  void initState() {
    super.initState();

    // 5-second countdown controller
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    );

    // Looping chevron guide animation (>>>)
    _arrowAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();

    // Continuous nudge animation for the swipe arrow
    _arrowNudgeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);

    _arrowNudgeAnimation = Tween<double>(begin: -1.0, end: 5.0).animate(
      CurvedAnimation(
        parent: _arrowNudgeController,
        curve: Curves.easeInOut,
      ),
    );

    final elapsedMs = DateTime.now().difference(widget.firstSeenTime).inMilliseconds;
    if (elapsedMs >= 5000) {
      _isLocked = false;
      _progressController.value = 1.0;
    } else {
      _isLocked = true;
      _progressController.value = elapsedMs / 5000.0;
      _progressController.animateTo(
        1.0,
        duration: Duration(milliseconds: 5000 - elapsedMs),
        curve: Curves.linear,
      ).then((_) {
        if (mounted) {
          setState(() {
            _isLocked = false;
          });
        }
      });
    }

    _progressController.addListener(() {
      if (mounted && _isLocked) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _progressController.dispose();
    _arrowAnimationController.dispose();
    _arrowNudgeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double maxDistance = (constraints.maxWidth - 48).clamp(0.0, double.infinity);
        final double currentPosition = _isLoading ? maxDistance : _thumbPosition;
        final int secondsLeft = _isLocked
            ? ((1.0 - _progressController.value) * 5.0).ceil().clamp(1, 5)
            : 0;

        return Stack(
          children: [
            // Base Capsule Container
            ClipRRect(
              borderRadius: BorderRadius.circular(100),
              child: Container(
                width: double.infinity,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF16171B),
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(
                    color: _isLocked
                        ? const Color(0xFF282932)
                        : const Color(0xFF1C9A5B).withValues(alpha: 0.45),
                    width: 1.2,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x1A000000),
                      blurRadius: 8,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // 1. Green Track on Drag (after unlocked)
                    if (!_isLocked && currentPosition > 0)
                      Positioned(
                        left: 0,
                        top: 0,
                        bottom: 0,
                        child: Container(
                          width: currentPosition + 24,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFF1C9A5B), Color(0xFF15803D)],
                            ),
                          ),
                        ),
                      ),

                    // 2. Center Text ("Swipe to Accept" + 5s countdown badge during lock, >>> guide when unlocked)
                    Center(
                      child: _isLocked
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Swipe to Accept',
                                  style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13.5,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFC62E42).withValues(alpha: 0.25),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: const Color(0xFFE31C2E).withValues(alpha: 0.6),
                                      width: 0.8,
                                    ),
                                  ),
                                  child: Text(
                                    '${secondsLeft}s',
                                    style: GoogleFonts.outfit(
                                      color: const Color(0xFFFF5263),
                                      fontWeight: FontWeight.w800,
                                      fontSize: 11.5,
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Swipe to Accept',
                                  style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13.5,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                // Animated directional chevrons (>>>)
                                AnimatedBuilder(
                                  animation: _arrowAnimationController,
                                  builder: (context, child) {
                                    final value = _arrowAnimationController.value;
                                    return Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: List.generate(3, (index) {
                                        final double phase = (value - (index * 0.18)).clamp(0.0, 1.0);
                                        final double opacity =
                                            0.3 + 0.7 * (phase < 0.5 ? phase * 2 : (1.0 - phase) * 2);
                                        return Transform.translate(
                                          offset: Offset(value * 3, 0),
                                          child: Opacity(
                                            opacity: opacity.clamp(0.25, 1.0),
                                            child: const Icon(
                                              Icons.chevron_right_rounded,
                                              size: 16,
                                              color: Colors.white,
                                            ),
                                          ),
                                        );
                                      }),
                                    );
                                  },
                                ),
                              ],
                            ),
                    ),

                    // 3. Draggable Thumb
                    Positioned(
                      left: currentPosition + 3,
                      top: 3,
                      bottom: 3,
                      child: GestureDetector(
                        onHorizontalDragUpdate: (details) {
                          if (_isLocked || _isCompleted || _isLoading) return;
                          setState(() {
                            _thumbPosition += details.delta.dx;
                            if (_thumbPosition < 0) _thumbPosition = 0;
                            if (_thumbPosition > maxDistance) _thumbPosition = maxDistance;
                          });
                        },
                        onHorizontalDragEnd: (details) async {
                          if (_isLocked || _isCompleted || _isLoading) return;
                          if (_thumbPosition >= maxDistance * 0.75) {
                            setState(() {
                              _thumbPosition = maxDistance;
                              _isLoading = true;
                              _isCompleted = true;
                            });
                            try {
                              final success = await widget.onAccept();
                              if (success != true && mounted) {
                                setState(() {
                                  _thumbPosition = 0;
                                  _isLoading = false;
                                  _isCompleted = false;
                                });
                              }
                            } catch (_) {
                              if (mounted) {
                                setState(() {
                                  _thumbPosition = 0;
                                  _isLoading = false;
                                  _isCompleted = false;
                                });
                              }
                            }
                          } else {
                            setState(() {
                              _thumbPosition = 0;
                            });
                          }
                        },
                        child: Container(
                          width: 42,
                          height: 42,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Color(0x33000000),
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: _isLoading
                              ? const Center(
                                  child: SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Color(0xFF121214),
                                      ),
                                    ),
                                  ),
                                )
                              : AnimatedBuilder(
                                  animation: _arrowNudgeAnimation,
                                  builder: (context, child) {
                                    final double nudge = (_thumbPosition == 0 && !_isLoading)
                                        ? _arrowNudgeAnimation.value
                                        : 0.0;
                                    return Transform.translate(
                                      offset: Offset(nudge, 0),
                                      child: child,
                                    );
                                  },
                                  child: Icon(
                                    Icons.arrow_forward_rounded,
                                    size: 19,
                                    color: _isLocked
                                        ? const Color(0xFF7A0C18)
                                        : const Color(0xFF1C9A5B),
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Glowing Perimeter Border (All around the button, depleting during the 5s countdown)
            if (_isLocked)
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: GlowingBorderPainter(
                      progress: (1.0 - _progressController.value).clamp(0.0, 1.0),
                      glowColor: const Color(0xFFE31C2E),
                      coreColor: const Color(0xFFFF4D5E),
                      strokeWidth: 2.2,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class GlowingBorderPainter extends CustomPainter {
  final double progress; // 1.0 (full all-around) down to 0.0 (depleted)
  final Color glowColor;
  final Color coreColor;
  final double strokeWidth;

  GlowingBorderPainter({
    required this.progress,
    required this.glowColor,
    required this.coreColor,
    this.strokeWidth = 2.2,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0.0) return;

    final double halfStroke = strokeWidth / 2;
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        halfStroke,
        halfStroke,
        size.width - strokeWidth,
        size.height - strokeWidth,
      ),
      Radius.circular((size.height - strokeWidth) / 2),
    );

    final path = Path()..addRRect(rrect);
    final metrics = path.computeMetrics().toList();
    if (metrics.isEmpty) return;

    final metric = metrics.first;
    final double totalLength = metric.length;
    final double currentLength = (totalLength * progress).clamp(0.0, totalLength);

    final extractedPath = metric.extractPath(0, currentLength);

    // 1. Outer Glow Pass (neon bloom)
    final glowPaint = Paint()
      ..color = glowColor.withValues(alpha: 0.65)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth + 2.5
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.5);

    canvas.drawPath(extractedPath, glowPaint);

    // 2. Core Crisp Neon Stroke Pass
    final corePaint = Paint()
      ..color = coreColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(extractedPath, corePaint);
  }

  @override
  bool shouldRepaint(covariant GlowingBorderPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.glowColor != glowColor ||
        oldDelegate.coreColor != coreColor;
  }
}
