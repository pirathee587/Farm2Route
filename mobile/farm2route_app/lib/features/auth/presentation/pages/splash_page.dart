import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../shared/widgets/farm2route_logo.dart';
import '../providers/auth_provider.dart';

class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage> with TickerProviderStateMixin {
  // 1. Entrance Controller (Logo drop & staggered text reveal)
  late AnimationController _entryController;
  late Animation<double> _logoScale;
  late Animation<double> _logoFade;
  late Animation<Offset> _textSlide;
  late Animation<double> _textFade;

  // 2. Idle Pulse / Float Controller (GPS ripple wave & subtle float)
  late AnimationController _pulseController;

  // 3. Exit Controller (Uber Camera Zoom-Through into Home Screen)
  late AnimationController _exitController;
  late Animation<double> _exitZoom;
  late Animation<double> _exitFade;

  @override
  void initState() {
    super.initState();

    // 1. Setup Entrance Animation (950ms)
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 950),
    );

    _logoScale = Tween<double>(begin: 0.75, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.0, 0.75, curve: Curves.easeOutBack),
      ),
    );

    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.0, 0.45, curve: Curves.easeIn),
      ),
    );

    _textSlide = Tween<Offset>(begin: const Offset(0.0, 0.35), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.30, 0.85, curve: Curves.easeOutCubic),
      ),
    );

    _textFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.30, 0.75, curve: Curves.easeIn),
      ),
    );

    // 2. Setup Idle Pulse & Float Animation (1800ms looping)
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();

    // 3. Setup Signature Uber Zoom-Through Exit Animation (420ms)
    _exitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );

    _exitZoom = Tween<double>(begin: 1.0, end: 2.6).animate(
      CurvedAnimation(
        parent: _exitController,
        curve: Curves.easeInOutCubic,
      ),
    );

    _exitFade = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _exitController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeIn),
      ),
    );

    // Start Entrance
    _entryController.forward();

    // Wait and trigger Uber Zoom-Through into the app
    Future.delayed(const Duration(milliseconds: 1700), () async {
      if (mounted) {
        await _exitController.forward();
        if (mounted) {
          ref.read(authNotifierProvider.notifier).checkSession();
        }
      }
    });
  }

  @override
  void dispose() {
    _entryController.dispose();
    _pulseController.dispose();
    _exitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0EB258), // Vibrant rich green matching image exactly
      body: SafeArea(
        child: Center(
          child: AnimatedBuilder(
            animation: Listenable.merge([_entryController, _pulseController, _exitController]),
            builder: (context, child) {
              final exitScale = _exitZoom.value;
              final exitOpacity = _exitFade.value.clamp(0.0, 1.0);

              // Subtle floating hover motion (2-3px)
              final floatOffset = math.sin(_pulseController.value * 2 * math.pi) * 3.0;

              return Transform.scale(
                scale: exitScale,
                child: Opacity(
                  opacity: exitOpacity,
                  child: Transform.translate(
                    offset: Offset(0, floatOffset),
                    child: child,
                  ),
                ),
              );
            },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 1. Concentric Circular Badge with Eco-Truck
                FadeTransition(
                  opacity: _logoFade,
                  child: ScaleTransition(
                    scale: _logoScale,
                    child: Farm2RouteLogo(
                      size: 130,
                      showWordmark: false,
                      wheelRotation: _pulseController.value * 2 * math.pi,
                    ),
                  ),
                ),

                const SizedBox(height: 36),

                // 2. Wordmark: "Farm" (Black) + "2" (White), followed by "Route" (Black)
                SlideTransition(
                  position: _textSlide,
                  child: FadeTransition(
                    opacity: _textFade,
                    child: Column(
                      children: [
                        RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: 'Farm',
                                style: GoogleFonts.outfit(
                                  fontSize: 54,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF141414), // Deep bold black
                                  letterSpacing: -1.2,
                                  height: 0.95,
                                ),
                              ),
                              TextSpan(
                                text: '2',
                                style: GoogleFonts.outfit(
                                  fontSize: 54,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white, // Pure white '2'
                                  letterSpacing: -1.2,
                                  height: 0.95,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          'Route',
                          style: GoogleFonts.outfit(
                            fontSize: 54,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF141414), // Deep bold black
                            letterSpacing: -1.2,
                            height: 0.95,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
