import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../components/custom_button.dart';
import '../../../providers/auth_provider.dart';
import 'onboarding_add_device_page.dart';
import 'onboarding_add_profile_page.dart';
import 'onboarding_add_grow_page.dart';

class OnboardingFlow extends StatefulWidget {
  const OnboardingFlow({super.key});

  @override
  _OnboardingFlowState createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> with SingleTickerProviderStateMixin {
  int _currentStep = 0;
  final PageController _pageController = PageController();
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  String? _userId;
  String? _deviceId;
  String? _profileId;

  final List<String> _stepTitles = [
    'Add Device',
    'Create Profile',
    'Setup Grow',
    'Complete'
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _slideAnimation = Tween<double>(begin: 0.1, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();
    _initializeUserId();
  }

  Future<void> _initializeUserId() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = await authProvider.getCurrentUserId();
    if (mounted) {
      setState(() {
        _userId = userId;
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < 3) {
      _animationController.reset();
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() {
        _currentStep++;
      });
      _animationController.forward();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _animationController.reset();
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() {
        _currentStep--;
      });
      _animationController.forward();
    }
  }

  void _onDeviceAdded(String deviceId) {
    setState(() {
      _deviceId = deviceId;
    });
    _nextStep();
  }

  void _onProfileAdded(String profileId) {
    setState(() {
      _profileId = profileId;
    });
    _nextStep();
  }

  void _onGrowAdded() {
    _nextStep();
  }

  Future<void> _completeOnboarding() async {
    // Show confirmation dialog
    final bool? shouldSkip = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Skip Onboarding?',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          content: Text(
            'Are you sure you want to skip the onboarding process? You can always set up your device and profile later from the dashboard.',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(
                'Skip',
                style: TextStyle(
                  color: AppColors.secondary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );

    // If user confirms, navigate to dashboard
    if (shouldSkip == true) {
      Navigator.of(context).pushReplacementNamed('/dashboard', arguments: _userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_userId == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Enhanced header with back button and progress
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
              child: Column(
                children: [
                  Row(
                    children: [
                      if (_currentStep > 0)
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios),
                          onPressed: _previousStep,
                          color: AppColors.textPrimary,
                        ),
                      const Spacer(),
                      Text(
                        _stepTitles[_currentStep],
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      // Skip button
                      TextButton(
                        onPressed: _completeOnboarding,
                        child: Text(
                          'Skip',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Enhanced progress indicator
                  Row(
                    children: List.generate(
                      4,
                      (index) => Expanded(
                        child: Stack(
                          children: [
                            Container(
                              height: 6,
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              decoration: BoxDecoration(
                                color: AppColors.secondary.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                            if (index <= _currentStep)
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                height: 6,
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.secondary,
                                  borderRadius: BorderRadius.circular(3),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.secondary.withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Main content with enhanced animations
            Expanded(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.1, 0),
                    end: Offset.zero,
                  ).animate(_slideAnimation),
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      OnboardingAddDevicePage(
                        userId: _userId!,
                        onDeviceAdded: _onDeviceAdded,
                      ),
                      OnboardingAddProfilePage(
                        userId: _userId!,
                        onProfileAdded: _onProfileAdded,
                      ),
                      if (_deviceId != null && _profileId != null)
                        OnboardingAddGrowPage(
                          userId: _userId!,
                          deviceId: _deviceId!,
                          profileId: _profileId!,
                          onGrowAdded: _onGrowAdded,
                        )
                      else
                        const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 16),
                              Text('Loading...'),
                            ],
                          ),
                        ),
                      _buildCompletionScreen(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompletionScreen() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Enhanced success animation
          TweenAnimationBuilder(
            tween: Tween<double>(begin: 0, end: 1),
            duration: const Duration(milliseconds: 1000),
            builder: (context, double value, child) {
              return Transform.scale(
                scale: value,
                child: Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withOpacity(0.1),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.secondary.withOpacity(0.2),
                        blurRadius: 30,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.check_circle,
                    size: 100,
                    color: AppColors.secondary,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 48),
          Text(
            "You're All Set!",
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Text(
            "Your Hydrozap system is ready to go. Start monitoring your grow and enjoy the journey!",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 48),
          CustomButton(
            text: "Go to Dashboard",
            onPressed: _completeOnboarding,
            variant: ButtonVariant.secondary,
            backgroundColor: AppColors.secondary,
            height: 60,
            width: double.infinity,
          ),
        ],
      ),
    );
  }
} 