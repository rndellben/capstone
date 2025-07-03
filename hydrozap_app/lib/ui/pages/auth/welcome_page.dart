import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_styles.dart';
import '../../widgets/responsive_widget.dart';
import '../auth/login_page.dart';
import '../auth/register_page.dart';

class GradientText extends StatelessWidget {
  final String text;
  final TextStyle style;
  final Gradient gradient;
  final TextAlign? textAlign;
  final int? maxLines;

  const GradientText(
    this.text, {
    required this.style,
    required this.gradient,
    this.textAlign,
    this.maxLines,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) => gradient.createShader(
        Rect.fromLTWH(0, 0, bounds.width, bounds.height),
      ),
      child: Text(
        text,
        style: style.copyWith(color: Colors.white),
        textAlign: textAlign,
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.background,
              AppColors.secondary.withAlpha(204), // 0.8 * 255 = 204
              AppColors.primary.withAlpha(26),    // 0.1 * 255 = 25.5 ≈ 26
            ],
          ),
        ),
        child: SafeArea(
          child: ResponsiveWidget(
            mobile: _buildMobileLayout(context),
            tablet: _buildTabletLayout(context),
            desktop: _buildDesktopLayout(context),
          ),
        ),
      ),
    );
  }

  // 📱 Mobile Layout
  Widget _buildMobileLayout(BuildContext context) {
    return Stack(
      children: [
        // Background pattern
        Positioned.fill(
          child: Opacity(
            opacity: 0.08,
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 8,
              ),
              itemBuilder: (context, index) => Container(
                margin: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.secondary, width: 0.5),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              itemCount: 200,
            ),
          ),
        ),
        
        // Main content
        Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Hero(
                    tag: 'app_logo',
                    child: _buildLogoWithAnimation(),
                  ),
                  const SizedBox(height: 30),
                  GradientText(
                    AppStrings.welcomeMessage,
                    style: AppStyles.heading1.copyWith(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.leaf, AppColors.forest],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      AppStrings.welcomeSubtitle,
                      textAlign: TextAlign.center,
                      style: AppStyles.heading2.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.5,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  
                  // Visual elements similar to desktop
                  Container(
                    height: 200,
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(vertical: 20),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(13), // 0.05 * 255 = 12.75 ≈ 13
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withAlpha(26), // 0.1 * 255 = 25.5 ≈ 26
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Image.asset(
                          'assets/images/logo.png',
                          height: 120,
                          fit: BoxFit.contain,
                        ),
                        Positioned(
                          top: 30,
                          right: 30,
                          child: _buildFloatingElements(Colors.red.withAlpha(204), 15), // 0.8 * 255 = 204
                        ),
                        Positioned(
                          bottom: 40,
                          left: 30,
                          child: _buildFloatingElements(Colors.blue.withAlpha(204), 20), // 0.8 * 255 = 204
                        ),
                        Positioned(
                          bottom: 70,
                          right: 50,
                          child: _buildFloatingElements(Colors.green.withAlpha(204), 12), // 0.8 * 255 = 204
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    child: _buildGetStartedButton(context),
                  ),
                  const SizedBox(height: 20),
                  OutlinedButton(
                    onPressed: () {
                      _navigateToRegister(context);
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppColors.primary),
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Create Account',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // 📚 Tablet Layout
  Widget _buildTabletLayout(BuildContext context) {
    return Stack(
      children: [
        // Background pattern
        Positioned.fill(
          child: Opacity(
            opacity: 0.08,
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 12,
              ),
              itemBuilder: (context, index) => Container(
                margin: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.secondary, width: 0.5),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              itemCount: 300,
            ),
          ),
        ),
        
        // Main content in a row similar to desktop
        Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(40.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Left section (content)
                  Expanded(
                    flex: 5,
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Hero(
                            tag: 'app_logo',
                            child: _buildLogoWithAnimation(),
                          ),
                          const SizedBox(height: 30),
                          GradientText(
                            AppStrings.welcomeMessage,
                            style: AppStyles.heading1.copyWith(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [AppColors.leaf, AppColors.forest],
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          Container(
                            constraints: const BoxConstraints(maxWidth: 450),
                            child: Text(
                              AppStrings.welcomeSubtitle,
                              style: AppStyles.heading2.copyWith(
                                fontSize: 17,
                                color: AppColors.textSecondary,
                                height: 1.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 40),
                          // Fixed the overflow by using Wrap instead of Row
                          Wrap(
                            spacing: 16,
                            runSpacing: 16,
                            children: [
                              SizedBox(
                                width: 200,
                                child: _buildGetStartedButton(context),
                              ),
                              OutlinedButton(
                                onPressed: () {
                                  _navigateToRegister(context);
                                },
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: AppColors.primary),
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  'Create Account',
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Right section (visual)
                  Expanded(
                    flex: 4,
                    child: Container(
                      height: 400,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha(13), // 0.05 * 255 = 12.75 ≈ 13
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withAlpha(26), // 0.1 * 255 = 25.5 ≈ 26
                            blurRadius: 20,
                            offset: const Offset(-5, 0),
                          ),
                        ],
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Image.asset(
                            'assets/images/logo.png',
                            height: 180,
                            fit: BoxFit.contain,
                          ),
                          Positioned(
                            top: 60,
                            right: 60,
                            child: _buildFloatingElements(Colors.red.withAlpha(204), 20), // 0.8 * 255 = 204
                          ),
                          Positioned(
                            bottom: 100,
                            left: 60,
                            child: _buildFloatingElements(Colors.blue.withAlpha(204), 28), // 0.8 * 255 = 204
                          ),
                          Positioned(
                            bottom: 180,
                            right: 80,
                            child: _buildFloatingElements(Colors.green.withAlpha(204), 16), // 0.8 * 255 = 204
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
      ],
    );
  }

  // 🖥️ Desktop Layout
  Widget _buildDesktopLayout(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 5,
          child: Padding(
            padding: const EdgeInsets.all(60.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Hero(
                  tag: 'app_logo',
                  child: _buildLogoWithAnimation(),
                ),
                const SizedBox(height: 40),
                GradientText(
                  AppStrings.welcomeMessage,
                  style: AppStyles.heading1.copyWith(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.leaf, AppColors.forest],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Container(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Text(
                    AppStrings.welcomeSubtitle,
                    style: AppStyles.heading2.copyWith(
                      fontSize: 18,
                      color: AppColors.textSecondary,
                      height: 1.6,
                    ),
                  ),
                ),
                const SizedBox(height: 50),
                // Fixed the overflow by using Wrap instead of Row
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    SizedBox(
                      width: 200,
                      child: _buildGetStartedButton(context),
                    ),
                    OutlinedButton(
                      onPressed: () {
                        _navigateToRegister(context);
                      },
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppColors.primary),
                        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Create Account',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        Expanded(
          flex: 4,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(13), // 0.05 * 255 = 12.75 ≈ 13
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(30),
                bottomLeft: Radius.circular(30),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withAlpha(26), // 0.1 * 255 = 25.5 ≈ 26
                  blurRadius: 20,
                  offset: const Offset(-5, 0),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Image.asset(
                  'assets/images/logo.png',
                  height: 320,
                  fit: BoxFit.contain,
                ),
                Positioned(
                  top: 60,
                  right: 60,
                  child: _buildFloatingElements(Colors.red.withAlpha(204), 25), // 0.8 * 255 = 204
                ),
                Positioned(
                  bottom: 100,
                  left: 60,
                  child: _buildFloatingElements(Colors.blue.withAlpha(204), 35), // 0.8 * 255 = 204
                ),
                Positioned(
                  bottom: 200,
                  right: 100,
                  child: _buildFloatingElements(Colors.green.withAlpha(204), 20), // 0.8 * 255 = 204
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // 🎯 Get Started Button with improved styling
  Widget _buildGetStartedButton(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.leaf, AppColors.forest],
        ),
        borderRadius: BorderRadius.all(Radius.circular(12)),
        boxShadow: [
          BoxShadow(
            color: AppColors.forest,
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            _navigateToLogin(context);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Text(
                  'Sign In',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward_rounded,
                  size: 18,
                  color: Colors.white,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Navigation methods with transitions
  void _navigateToLogin(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const LoginPage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOutCubic;
          
          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          var offsetAnimation = animation.drive(tween);
          
          return SlideTransition(
            position: offsetAnimation,
            child: FadeTransition(
              opacity: animation, 
              child: child
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }
  
  void _navigateToRegister(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const RegisterPage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(0.0, 1.0);
          const end = Offset.zero;
          const curve = Curves.easeInOutCubic;
          
          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          var offsetAnimation = animation.drive(tween);
          
          return SlideTransition(
            position: offsetAnimation,
            child: FadeTransition(
              opacity: animation, 
              child: child
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  // ✨ Logo with subtle animation effect
  Widget _buildLogoWithAnimation() {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 1200),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Opacity(
            opacity: value,
            child: ShaderMask(
              shaderCallback: (Rect bounds) {
                return const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.leaf, AppColors.forest],
                ).createShader(bounds);
              },
              child: const Icon(
                Icons.eco,
                size: 100,
                color: Colors.white,
              ),
            ),
          ),
        );
      },
    );
  }

  // 🔵 Decorative floating elements
  Widget _buildFloatingElements(Color color, double size) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 1500),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withAlpha(77), // 0.3 * 255 = 76.5 ≈ 77
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}