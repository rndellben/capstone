import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../components/custom_button.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  _OnboardingPageState createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final List<OnboardingItem> _onboardingItems = [
    OnboardingItem(
      title: "Welcome to Hydrozap!",
      description: "Revolutionize your hydroponic farming with intelligent dosing and monitoring.",
      icon: Icons.agriculture,
      color: Colors.green,
    ),
    OnboardingItem(
      title: "Smart Dosing Control",
      description: "Automate nutrient and pH adjustments with precision for optimal plant health.",
      icon: Icons.precision_manufacturing,
      color: Colors.blue,
    ),
    OnboardingItem(
      title: "Real-Time Monitoring",
      description: "Track EC, pH, temperature, and water levels from anywhere in real time.",
      icon: Icons.sensors,
      color: Colors.orange,
    ),
    OnboardingItem(
      title: "Grow Smarter, Not Harder",
      description: "Access insights and trends to boost yields and streamline your operations.",
      icon: Icons.insights,
      color: Colors.purple,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.2, 0.0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
    _animationController.reset();
    _animationController.forward();
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
    
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                itemCount: _onboardingItems.length,
                itemBuilder: (context, index) {
                  return _buildOnboardingPage(_onboardingItems[index]);
                },
              ),
            ),
            _buildBottomSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildOnboardingPage(OnboardingItem item) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated icon with gradient background
              TweenAnimationBuilder(
                tween: Tween<double>(begin: 0, end: 1),
                duration: const Duration(milliseconds: 800),
                builder: (context, double value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            item.color.withOpacity(0.1),
                            item.color.withOpacity(0.2),
                          ],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: item.color.withOpacity(0.2),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Icon(
                        item.icon,
                        size: 80,
                        color: item.color,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 40),
              Text(
                item.title,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  height: 1.2,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                item.description,
                style: TextStyle(
                  fontSize: 18,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Animated progress dots
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _onboardingItems.length,
              (index) => TweenAnimationBuilder(
                tween: Tween<double>(
                  begin: 0,
                  end: _currentPage == index ? 1.0 : 0.0,
                ),
                duration: const Duration(milliseconds: 300),
                builder: (context, double value, child) {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: 8 + (value * 8),
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.rectangle,
                      borderRadius: BorderRadius.circular(4),
                      color: _currentPage == index
                          ? AppColors.secondary
                          : AppColors.secondary.withOpacity(0.3),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 32),
          CustomButton(
            text: _currentPage == _onboardingItems.length - 1
                ? "Get Started"
                : "Next",
            onPressed: () {
              if (_currentPage == _onboardingItems.length - 1) {
                _completeOnboarding();
              } else {
                _pageController.nextPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              }
            },
            variant: ButtonVariant.secondary,
            backgroundColor: AppColors.secondary,
            height: 56,
          ),
          if (_currentPage < _onboardingItems.length - 1) ...[
            const SizedBox(height: 16),
            TextButton(
              onPressed: _completeOnboarding,
              child: Text(
                "Skip",
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class OnboardingItem {
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  OnboardingItem({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
} 