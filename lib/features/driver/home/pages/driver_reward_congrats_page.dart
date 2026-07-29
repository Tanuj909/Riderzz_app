import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DriverRewardCongratsPage extends StatefulWidget {
  const DriverRewardCongratsPage({super.key});

  @override
  State<DriverRewardCongratsPage> createState() => _DriverRewardCongratsPageState();
}

class _DriverRewardCongratsPageState extends State<DriverRewardCongratsPage>
    with TickerProviderStateMixin {
  late AnimationController _confettiController;
  late AnimationController _cardController;
  late Animation<double> _cardScaleAnimation;
  late Animation<double> _cardFadeAnimation;
  late List<ConfettiParticle> _particles;

  @override
  void initState() {
    super.initState();
    // Confetti continuous falling animation
    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    // Dialog card popping scale & fade animation
    _cardController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _cardScaleAnimation = CurvedAnimation(
      parent: _cardController,
      curve: Curves.elasticOut,
    );

    _cardFadeAnimation = CurvedAnimation(
      parent: _cardController,
      curve: Curves.easeIn,
    );

    _cardController.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Generate particles based on screen size
    final size = MediaQuery.of(context).size;
    _particles = ConfettiParticle.generate(60, size.width, size.height);
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _cardController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F11),
      body: Stack(
        children: [
          // Background Glows
          Positioned(
            top: -100,
            left: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFCC2D3B).withOpacity(0.15),
                    blurRadius: 100,
                    spreadRadius: 50,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            right: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFF59E0B).withOpacity(0.1),
                    blurRadius: 100,
                    spreadRadius: 50,
                  ),
                ],
              ),
            ),
          ),

          // Custom Confetti Animation Overlay
          Positioned.fill(
            child: CustomPaint(
              painter: ConfettiPainter(
                animation: _confettiController,
                particles: _particles,
              ),
            ),
          ),

          // Main Content
          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: ScaleTransition(
                  scale: _cardScaleAnimation,
                  child: FadeTransition(
                    opacity: _cardFadeAnimation,
                    child: Container(
                      padding: const EdgeInsets.all(32.0),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E24).withOpacity(0.9),
                        borderRadius: BorderRadius.circular(32),
                        border: Border.all(
                          color: const Color(0xFFCC2D3B).withOpacity(0.3),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFCC2D3B).withOpacity(0.2),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Animated Gift/Trophy Icon
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [Color(0xFFE31C2E), Color(0xFFFF5252)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFE31C2E).withOpacity(0.4),
                                  blurRadius: 20,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0.8, end: 1.2),
                              duration: const Duration(seconds: 1),
                              builder: (context, val, child) {
                                return Transform.scale(
                                  scale: val,
                                  child: child,
                                );
                              },
                              curve: Curves.easeInOut,
                              child: const Icon(
                                Icons.card_giftcard_rounded,
                                color: Colors.white,
                                size: 56,
                              ),
                            ),
                          ),
                          const SizedBox(height: 28),

                          // Congratulations Title
                          Text(
                            'Congratulations!',
                            style: GoogleFonts.plusJakartaSans(
                              color: const Color(0xFFF59E0B),
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),

                          // Enjoy Bonus Subtitle
                          Text(
                            'Enjoy bonus!',
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),

                          // Description
                          Text(
                            'Your sign-in reward has been claimed successfully and credited directly to your wallet balance. Welcome aboard!',
                            style: GoogleFonts.outfit(
                              color: const Color(0xFF9CA3AF),
                              fontSize: 14.5,
                              height: 1.5,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 32),

                          // Claim Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFCC2D3B),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(100),
                                ),
                                elevation: 0,
                              ),
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              child: Text(
                                'Thanks! Go to Wallet',
                                style: GoogleFonts.outfit(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Confetti Particle & Painter Definitions
class ConfettiPainter extends CustomPainter {
  final Animation<double> animation;
  final List<ConfettiParticle> particles;

  ConfettiPainter({required this.animation, required this.particles}) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    for (var particle in particles) {
      final double progress = animation.value;
      final double y = (particle.y + progress * size.height * particle.speed) % size.height;
      final double x = particle.x + sin(progress * 2 * pi + particle.randomOffset) * 20;
      paint.color = particle.color.withOpacity(0.8);
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(progress * particle.rotationSpeed * pi);
      if (particle.isCircle) {
        canvas.drawCircle(Offset.zero, particle.size, paint);
      } else {
        canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: particle.size * 2, height: particle.size), paint);
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class ConfettiParticle {
  final double x;
  final double y;
  final double size;
  final Color color;
  final double speed;
  final double rotationSpeed;
  final double randomOffset;
  final bool isCircle;

  ConfettiParticle({
    required this.x,
    required this.y,
    required this.size,
    required this.color,
    required this.speed,
    required this.rotationSpeed,
    required this.randomOffset,
    required this.isCircle,
  });

  static List<ConfettiParticle> generate(int count, double width, double height) {
    final random = Random();
    final colors = [
      const Color(0xFFCC2D3B),
      const Color(0xFFF59E0B),
      const Color(0xFF10B981),
      const Color(0xFF3B82F6),
      const Color(0xFFEC4899),
    ];
    return List.generate(count, (index) {
      return ConfettiParticle(
        x: random.nextDouble() * width,
        y: random.nextDouble() * height,
        size: random.nextDouble() * 6 + 4,
        color: colors[random.nextInt(colors.length)],
        speed: random.nextDouble() * 0.5 + 0.3,
        rotationSpeed: random.nextDouble() * 4 + 2,
        randomOffset: random.nextDouble() * 2 * pi,
        isCircle: random.nextBool(),
      );
    });
  }
}
