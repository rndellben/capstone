import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../ui/pages/dashboard/dashboard_page.dart';
import '../../../core/helpers/validators.dart';
import '../../../core/constants/app_colors.dart';
import '../../components/custom_text_field.dart';
import '../../components/custom_button.dart';
import '../../widgets/responsive_widget.dart';
import 'forgot_password_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _identifierController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    _animationController.forward();
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final response = await authProvider.login(
        _identifierController.text.trim(),
        _passwordController.text.trim(),
      );

      if (response != null && response['user'] != null) {
        String userId = response['user']['uid'];
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => DashboardPage(userId: userId),
          ),
        );
      } else {
        _showErrorMessage("Login failed. Check your credentials.");
      }
    }
  }

  Future<void> _handleGoogleLogin() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final response = await authProvider.googleLogin();

      if (response != null && response['user'] != null) {
        String userId = response['user']['uid'];
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => DashboardPage(userId: userId),
          ),
        );
      } else if (!mounted) {
        // If the widget is no longer in the tree, do nothing
        return;
      } else if (authProvider.isLoading) {
        // If still loading, do nothing - could be user cancellation
        return;
      } else {
        // Authentication failed with a response from backend
        _showErrorMessage("Google sign-in failed. Please try again.");
      }
    } catch (e) {
      if (!mounted) return;
      
      // Show a more specific error message based on the exception
      if (e.toString().contains('network')) {
        _showErrorMessage("Network error during sign-in. Check your connection.");
      } else if (e.toString().contains('credential')) {
        _showErrorMessage("Authentication failed. Invalid credentials.");
      } else {
        _showErrorMessage("Sign-in error: ${e.toString().split('\n').first}");
      }
      
      print("Google login error: $e");
    }
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppColors.accent,
      body: ResponsiveWidget(
        mobile: _buildLoginMobileLayout(context, authProvider),
        tablet: _buildLoginTabletLayout(context, authProvider),
        desktop: _buildLoginDesktopLayout(context, authProvider),
      ),
    );
  }

  Widget _buildLoginMobileLayout(BuildContext context, AuthProvider authProvider) {
    return Stack(
      children: [
        // Background pattern
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1B5E20), Color(0xFF388E3C)], // Darker green gradient
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Opacity(
              opacity: 0.1, // Subtle pattern opacity
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 10,
                ),
                itemBuilder: (context, index) => Container(
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white, width: 0.5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                itemCount: 200,
              ),
            ),
          ),
        ),
        
        // Main content
        SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 40),
                  // Brand icon
                  Center(
                    child: Hero(
                      tag: 'app_logo',
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha((0.2 * 255).round()),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.eco,
                          size: 64,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  // Header with white text
                  _buildMobileHeader(),
                  const SizedBox(height: 40),
                  // Login form in a white container
                  _buildMobileLoginForm(context, authProvider),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileHeader() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Welcome Back",
            style: TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
              shadows: [
                Shadow(
                  color: Colors.black26,
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Sign in to your account to continue",
            style: TextStyle(
              color: Colors.white.withAlpha((0.9 * 255).round()),
              fontSize: 16,
              shadows: [
                Shadow(
                  color: Colors.black12,
                  blurRadius: 1,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLoginForm(BuildContext context, AuthProvider authProvider) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha((0.1 * 255).round()),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomTextField(
                label: "Email or Username",
                hint: "Enter your email or username",
                controller: _identifierController,
                validator: validateIdentifier,
                prefixIcon: Icons.person_outline,
                fillColor: AppColors.normal,
              ),
              const SizedBox(height: 20),
              CustomTextField(
                label: "Password",
                hint: "Enter your password",
                controller: _passwordController,
                obscureText: true,
                validator: validatePassword,
                prefixIcon: Icons.lock_outline,
                fillColor: AppColors.normal,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          height: 24,
                          width: 24,
                          child: Checkbox(
                            value: _rememberMe,
                            onChanged: (value) {
                              setState(() {
                                _rememberMe = value ?? false;
                              });
                            },
                            activeColor: AppColors.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            "Remember me",
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  CustomButton(
                    text: "Forgot password?",
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ForgotPasswordPage(),
                        ),
                      );
                    },
                    variant: ButtonVariant.text,
                    textColor: AppColors.primary,
                  ),
                ],
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: authProvider.isLoading
                    ? Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                        ),
                      )
                    : CustomButton(
                        text: "Sign in",
                        onPressed: _handleLogin,
                        backgroundColor: AppColors.primary,
                        variant: ButtonVariant.primary,
                      ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Divider(color: AppColors.textSecondary.withAlpha((0.3 * 255).round())),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      "Or continue with",
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Divider(color: AppColors.textSecondary.withAlpha((0.3 * 255).round())),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CustomButton(
                    text: "Sign in with Google",
                    onPressed: _handleGoogleLogin,
                    icon: Icons.g_mobiledata_rounded,
                    width: 250,
                    height: 50,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Removed Apple and Facebook sign-in buttons
                ],
              ),
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Don't have an account?",
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  CustomButton(
                    text: "Sign up",
                    onPressed: () {
                      Navigator.pushNamed(context, '/register');
                    },
                    variant: ButtonVariant.text,
                    textColor: AppColors.primary,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoginTabletLayout(BuildContext context, AuthProvider authProvider) {
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Container(
            width: 500,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withAlpha((0.1 * 255).round()),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 30),
                _buildLoginForm(context, authProvider),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginDesktopLayout(BuildContext context, AuthProvider authProvider) {
    return Row(
      children: [
        // Left panel with branding/image
        Expanded(
          flex: 5,
          child: Container(
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1B5E20), Color(0xFF388E3C)], // Darker green gradient
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Stack(
              children: [
                // Background pattern
                Positioned.fill(
                  child: Opacity(
                    opacity: 0.1,
                    child: GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 10,
                      ),
                      itemBuilder: (context, index) => Container(
                        margin: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white, width: 0.5),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      itemCount: 200,
                    ),
                  ),
                ),
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Hero(
                        tag: 'app_logo',
                        child: const Icon(
                          Icons.eco,
                          size: 100,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        "Welcome Back",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: 300,
                        child: Text(
                          "Log in to access your account and continue your journey",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withAlpha((0.9 * 255).round()),
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  bottom: 20,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "© 2025 HydroZap",
                          style: TextStyle(
                            color: Colors.white.withAlpha((0.7 * 255).round()),
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 20),
                        Text(
                          "Privacy Policy",
                          style: TextStyle(
                            color: Colors.white.withAlpha((0.9 * 255).round()),
                            fontSize: 14,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                        const SizedBox(width: 20),
                        Text(
                          "Terms of Service",
                          style: TextStyle(
                            color: Colors.white.withAlpha((0.9 * 255).round()),
                            fontSize: 14,
                            decoration: TextDecoration.underline,
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
        // Right panel with login form
        Expanded(
          flex: 4,
          child: Container(
            padding: const EdgeInsets.all(60),
            color: Colors.white,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.arrow_back,
                      color: AppColors.textPrimary,
                      size: 20,
                    ),
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(height: 40),
                _buildHeader(),
                const SizedBox(height: 30),
                Expanded(
                  child: SingleChildScrollView(
                    child: _buildLoginForm(context, authProvider),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Login",
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Welcome back! Please enter your details.",
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginForm(BuildContext context, AuthProvider authProvider) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomTextField(
              label: "Email or Username",
              hint: "Enter your email or username",
              controller: _identifierController,
              validator: validateIdentifier,
              prefixIcon: Icons.person_outline,
              fillColor: AppColors.normal,
            ),
            const SizedBox(height: 20),
            CustomTextField(
              label: "Password",
              hint: "Enter your password",
              controller: _passwordController,
              obscureText: true,
              validator: validatePassword,
              prefixIcon: Icons.lock_outline,
              fillColor: AppColors.normal,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        height: 24,
                        width: 24,
                        child: Checkbox(
                          value: _rememberMe,
                          onChanged: (value) {
                            setState(() {
                              _rememberMe = value ?? false;
                            });
                          },
                          activeColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          "Remember me",
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                CustomButton(
                  text: "Forgot password?",
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ForgotPasswordPage(),
                      ),
                    );
                  },
                  variant: ButtonVariant.text,
                  textColor: AppColors.primary,
                ),
              ],
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: authProvider.isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                      ),
                    )
                  : CustomButton(
                      text: "Sign in",
                      onPressed: _handleLogin,
                      backgroundColor: AppColors.primary,
                      variant: ButtonVariant.primary,
                    ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: Divider(color: AppColors.textSecondary.withAlpha((0.3 * 255).round())),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    "Or continue with",
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ),
                Expanded(
                  child: Divider(color: AppColors.textSecondary.withAlpha((0.3 * 255).round())),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CustomButton(
                  text: "Sign in with Google",
                  onPressed: _handleGoogleLogin,
                  icon: Icons.g_mobiledata_rounded,
                  width: 250,
                  height: 50,
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Removed Apple and Facebook sign-in buttons
              ],
            ),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Don't have an account?",
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
                CustomButton(
                  text: "Sign up",
                  onPressed: () {
                    Navigator.pushNamed(context, '/register');
                  },
                  variant: ButtonVariant.text,
                  textColor: AppColors.primary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }
}