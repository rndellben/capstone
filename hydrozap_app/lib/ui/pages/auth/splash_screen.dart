import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/notification_provider.dart';
import '../../../core/services/push_notification_service.dart';
import '../../../routes/app_routes.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import 'dart:math' as math;

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _floatController;
  late AnimationController _pulseController;
  late AnimationController _particleController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _floatAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _particleAnimation;

  @override
  void initState() {
    super.initState();

    // Fade animation
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: Curves.easeIn,
      ),
    );

    // Floating animation (subtle up and down movement)
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _floatAnimation = Tween<double>(begin: 0.0, end: 10.0).animate(
      CurvedAnimation(
        parent: _floatController,
        curve: Curves.easeInOut,
      ),
    );

    // Pulse animation for subtle size change
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );

    // Particle animation for background effects
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    _particleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _particleController,
        curve: Curves.linear,
      ),
    );

    // Start the animations
    _fadeController.forward();

    // Navigate to the appropriate screen after animation completes
    _fadeController.addStatusListener((status) async {
      if (status == AnimationStatus.completed) {
        // Wait a short time to let animations play
        await Future.delayed(const Duration(seconds: 1));
        
        // Check if user is logged in and there are any pending notification intents
        if (mounted) {
          _checkAuthAndNavigate();
        }
      }
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _floatController.dispose();
    _pulseController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  void _initializePushNotifications() {
    // Get push notification service
    final pushService = Provider.of<PushNotificationService>(context, listen: false);
    
    // Initialize the service if not already done
    pushService.initialize();
  }

  // Check authentication status and notification intents
  Future<void> _checkAuthAndNavigate() async {
    try {
      final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);
      
      // First check if there are any pending notification navigation intents
      final navigationIntent = await notificationProvider.getNavigationIntent();
      
      try {
        // Try to check login status
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final bool isLoggedIn = await authProvider.isUserLoggedIn();
        
        if (isLoggedIn) {
          // If logged in, initialize push notifications
          _initializePushNotifications();
          
          // Get the current user ID
          final userId = await authProvider.getCurrentUserId();
          
          if (userId != null && navigationIntent != null) {
            _handleNavigationWithIntent(navigationIntent, userId);
          } else {
            // No navigation intent, go to dashboard
            Navigator.of(context).pushReplacementNamed(
              AppRoutes.dashboard,
              arguments: userId,
            );
          }
        } else {
          // Not logged in, navigate to welcome page
          Navigator.of(context).pushReplacementNamed(AppRoutes.welcome);
        }
      } catch (authError) {
        // Firebase auth error fallback
        debugPrint('Auth error during splash navigation: $authError');
        
        // If we have a navigation intent, try to honor it anyway
        if (navigationIntent != null) {
          _handleNavigationWithIntent(navigationIntent, 'default_user');
        } else {
          // On auth error, default to welcome page
          Navigator.of(context).pushReplacementNamed(AppRoutes.welcome);
        }
      }
    } catch (e) {
      debugPrint('Error during splash navigation: $e');
      // Final fallback
      Navigator.of(context).pushReplacementNamed(AppRoutes.welcome);
    }
  }
  
  // Helper method to handle navigation with intent
  void _handleNavigationWithIntent(Map<String, dynamic> navigationIntent, String userId) {
    final route = navigationIntent['route'] as String;
    final arguments = navigationIntent['arguments'] as Map<String, dynamic>?;
    
    if (route == '/alerts' && arguments != null) {
      // Add userId to arguments if not present
      if (!arguments.containsKey('user_id')) {
        arguments['user_id'] = userId;
      }
      
      // Navigate to alerts page first, then it will handle the alert details navigation
      Navigator.of(context).pushReplacementNamed(
        AppRoutes.alerts,
        arguments: userId,
      );
    } else {
      // For other routes, navigate directly
      Navigator.of(context).pushReplacementNamed(
        route,
        arguments: arguments,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.forest.withAlpha((0.9 * 255).round()),
                  AppColors.forest,
                  AppColors.forest.withAlpha((0.8 * 255).round()),
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),

          // Animated particles
          AnimatedBuilder(
            animation: _particleAnimation,
            builder: (context, child) {
              return CustomPaint(
                size: Size(size.width, size.height),
                painter: ParticlesPainter(
                  progress: _particleAnimation.value,
                  particleColor: AppColors.leaf.withAlpha((0.2 * 255).round()),
                ),
              );
            },
          ),

          // Radial light effect behind logo
          Center(
            child: Container(
              width: 340,
              height: 340,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.sunlight.withAlpha((0.3 * 255).round()),
                    AppColors.forest.withAlpha((0.0 * 255).round()),
                  ],
                  stops: const [0.2, 1.0],
                ),
              ),
            ),
          ),

          // Main content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animated logo
                AnimatedBuilder(
                  animation: Listenable.merge([_floatAnimation, _pulseAnimation]),
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(0, -_floatAnimation.value),
                      child: Transform.scale(
                        scale: _pulseAnimation.value,
                        child: FadeTransition(
                          opacity: _fadeAnimation,
                          child: Container(
                            decoration: BoxDecoration(
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.transparent,
                                  blurRadius: 20,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: Image.asset(
                              'assets/images/logo.png',
                              height: 240,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 40),

                // App name with stylized appearance
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: ShaderMask(
                    shaderCallback: (bounds) => LinearGradient(
                      colors: [
                        AppColors.textOnDark,
                        AppColors.water,
                        AppColors.textOnDark,
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ).createShader(bounds),
                    child: const Text(
                      AppStrings.appName,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 38,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2.0,
                        shadows: [
                          Shadow(
                            color: AppColors.forest,
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Animated divider
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Container(
                    width: 80,
                    height: 3,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Colors.transparent,
                          AppColors.sunlight,
                          Colors.transparent,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Tagline with fade-in effect
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: const Text(
                    'Smart Hydroponic Solutions',
                    style: TextStyle(
                      color: AppColors.sand,
                      fontSize: 16,
                      letterSpacing: 1.0,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),

                const SizedBox(height: 60),

                // Animated loading indicator
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: SizedBox(
                    width: 40,
                    height: 40,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.leaf.withAlpha((0.7 * 255).round())
                      ),
                      strokeWidth: 2,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Bottom water wave effect
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: AnimatedBuilder(
              animation: _particleAnimation,
              builder: (context, child) {
                return CustomPaint(
                  size: Size(size.width, 100),
                  painter: WavePainter(
                    progress: _particleAnimation.value,
                    waveColor: AppColors.water.withAlpha((0.15 * 255).round()),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// Particles painter for ambient background effect
class ParticlesPainter extends CustomPainter {
  final double progress;
  final Color particleColor;

  ParticlesPainter({
    required this.progress,
    required this.particleColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = particleColor
      ..style = PaintingStyle.fill;

    // Generate particles with different sizes and positions
    final random = math.Random(42); // Fixed seed for consistent pattern

    for (int i = 0; i < 40; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final particleSize = random.nextDouble() * 5 + 1;

      // Animate position based on progress
      final animatedX = (x + 20 * math.sin(progress * math.pi * 2 + i)) % size.width;
      final animatedY = (y + 10 * math.cos(progress * math.pi * 2 + i)) % size.height;

      // Fade in/out based on position in animation cycle
      // Ensure opacity stays between 0.0 and 1.0
      final opacity = 0.3 + 0.7 * math.sin(progress * math.pi * 2 + i * 0.1);
      final clampedOpacity = opacity.clamp(0.0, 1.0);

      paint.color = particleColor.withAlpha((clampedOpacity * 255).round());

      canvas.drawCircle(Offset(animatedX, animatedY), particleSize, paint);
    }
  }

  @override
  bool shouldRepaint(ParticlesPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.particleColor != particleColor;
  }
}

// Wave painter for bottom water effect
class WavePainter extends CustomPainter {
  final double progress;
  final Color waveColor;

  WavePainter({
    required this.progress,
    required this.waveColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = waveColor
      ..style = PaintingStyle.fill;

    final path = Path();

    // Start at bottom left
    path.moveTo(0, size.height);

    // Draw wave pattern
    for (double i = 0; i <= size.width; i++) {
      final x = i;
      final y = size.height -
          20 * math.sin((i / size.width * 4 * math.pi) + (progress * math.pi * 2)) -
          12 * math.cos((i / size.width * 6 * math.pi) + (progress * math.pi * 4));

      path.lineTo(x, y);
    }

    // Complete the path
    path.lineTo(size.width, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(WavePainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.waveColor != waveColor;
  }
}
