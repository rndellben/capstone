// ui/pages/auth/register_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../core/helpers/validators.dart';
import '../../../core/constants/app_colors.dart';
import '../../widgets/responsive_widget.dart';
import '../../components/custom_text_field.dart';
import '../../components/custom_button.dart';
import '../../pages/settings/terms_of_service_page.dart';
import '../../pages/settings/privacy_policy_page.dart';
import 'package:flutter/gestures.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  bool _acceptTerms = false;
  String _passwordStrength = '';
  Color _passwordStrengthColor = Colors.grey;

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
    
    // Add listener to password controller to check strength
    _passwordController.addListener(_checkPasswordStrength);
  }

  void _checkPasswordStrength() {
    final password = _passwordController.text;
    if (password.isEmpty) {
      setState(() {
        _passwordStrength = '';
        _passwordStrengthColor = Colors.grey;
      });
      return;
    }

    int score = 0;
    bool hasLower = false;
    bool hasUpper = false;
    bool hasDigit = false;
    bool hasSpecial = false;

    for (int i = 0; i < password.length; i++) {
      if (password[i].contains(RegExp(r'[a-z]'))) hasLower = true;
      if (password[i].contains(RegExp(r'[A-Z]'))) hasUpper = true;
      if (password[i].contains(RegExp(r'[0-9]'))) hasDigit = true;
      if (password[i].contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) hasSpecial = true;
    }

    if (hasLower) score++;
    if (hasUpper) score++;
    if (hasDigit) score++;
    if (hasSpecial) score++;
    if (password.length >= 8) score++;

    setState(() {
      if (score <= 2) {
        _passwordStrength = 'Weak';
        _passwordStrengthColor = Colors.red;
      } else if (score <= 3) {
        _passwordStrength = 'Fair';
        _passwordStrengthColor = Colors.orange;
      } else if (score <= 4) {
        _passwordStrength = 'Good';
        _passwordStrengthColor = Colors.yellow.shade700;
      } else {
        _passwordStrength = 'Strong';
        _passwordStrengthColor = Colors.green;
      }
    });
  }

  double _getPasswordStrengthValue() {
    final password = _passwordController.text;
    if (password.isEmpty) return 0.0;

    int score = 0;
    bool hasLower = false;
    bool hasUpper = false;
    bool hasDigit = false;
    bool hasSpecial = false;

    for (int i = 0; i < password.length; i++) {
      if (password[i].contains(RegExp(r'[a-z]'))) hasLower = true;
      if (password[i].contains(RegExp(r'[A-Z]'))) hasUpper = true;
      if (password[i].contains(RegExp(r'[0-9]'))) hasDigit = true;
      if (password[i].contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) hasSpecial = true;
    }

    if (hasLower) score++;
    if (hasUpper) score++;
    if (hasDigit) score++;
    if (hasSpecial) score++;
    if (password.length >= 8) score++;

    return score / 5.0; // Normalize to 0.0 - 1.0
  }

  Future<void> _handleRegister() async {
    if (_formKey.currentState!.validate() && _acceptTerms) {
      if (_passwordController.text != _confirmPasswordController.text) {
        _showErrorMessage("Passwords don't match");
        return;
      }
      
      // Format phone number - remove "+63 " prefix if present
      String phoneNumber = _phoneController.text.trim();
      if (phoneNumber.startsWith("+63 ")) {
        phoneNumber = phoneNumber.substring(4); // Remove "+63 "
      }
      
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.register({
        "name": "${_firstNameController.text.trim()} ${_lastNameController.text.trim()}".trim(),
        "username": _usernameController.text.trim(),
        "email": _emailController.text.trim(),
        "phone": phoneNumber,
        "password": _passwordController.text.trim(),
      });

      if (success) {
        // Automatically log in after successful registration
        final loginResponse = await authProvider.login(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );

        if (loginResponse != null && loginResponse['token'] != null) {
          // Show completion dialog
          await showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return Dialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.check_circle,
                          color: AppColors.secondary,
                          size: 48,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        "Registration Complete!",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "Welcome to Hydrozap! Your account has been created successfully.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 24),
                      CustomButton(
                        text: "Get Started",
                        onPressed: () {
                          Navigator.of(context).pop(); // Close dialog
                          // Navigate to onboarding flow
                          Navigator.of(context).pushReplacementNamed('/onboarding-flow');
                        },
                        variant: ButtonVariant.secondary,
                        backgroundColor: AppColors.secondary,
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        } else {
          _showErrorMessage("Registration successful but login failed. Please try logging in manually.");
        }
      } else {
        _showErrorMessage("Registration failed. Please try again.");
      }
    } else if (!_acceptTerms) {
      _showErrorMessage("You must accept the Terms and Conditions");
    }
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.secondary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: EdgeInsets.all(16),
      ),
    );
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

    return Scaffold(
      backgroundColor: AppColors.background,
      body: ResponsiveWidget(
        mobile: _buildRegisterMobileLayout(context, authProvider),
        tablet: _buildRegisterTabletLayout(context, authProvider),
        desktop: _buildRegisterDesktopLayout(context, authProvider),
      ),
    );
  }

  Widget _buildRegisterMobileLayout(BuildContext context, AuthProvider authProvider) {
    return Stack(
      children: [
        // Background pattern
        Positioned.fill(
          child: Container(
            color: AppColors.secondary,
            child: Opacity(
              opacity: 0.1,
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
                  const SizedBox(height: 30),
                  // App icon
                  Center(
                    child: Hero(
                      tag: 'app_logo',
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.eco,
                          size: 50,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  // Header with white text
                  _buildMobileHeader(),
                  const SizedBox(height: 30),
                  // Registration form in a white container
                  _buildMobileRegisterForm(context, authProvider),
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
            "Create Account",
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
            "Join our community to start growing",
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
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
  
  Widget _buildMobileRegisterForm(BuildContext context, AuthProvider authProvider) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
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
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      label: "First Name",
                      hint: "Enter your first name",
                      controller: _firstNameController,
                      validator: validateName,
                      prefixIcon: Icons.person_outline,
                      fillColor: AppColors.normal,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: CustomTextField(
                      label: "Last Name",
                      hint: "Enter your last name",
                      controller: _lastNameController,
                      validator: validateName,
                      prefixIcon: Icons.person_outline,
                      fillColor: AppColors.normal,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: "Username",
                hint: "Choose a username",
                controller: _usernameController,
                validator: validateName,
                prefixIcon: Icons.alternate_email,
                fillColor: AppColors.normal,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: "Email",
                hint: "Enter your email address",
                controller: _emailController,
                validator: validateEmail,
                prefixIcon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                fillColor: AppColors.normal,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: "Phone Number",
                hint: "Enter your phone number",
                controller: _phoneController,
                validator: validatePhone,
                prefixIcon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                fillColor: AppColors.normal,
                prefixText: "+63 ",
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: "Password",
                hint: "Create a strong password",
                controller: _passwordController,
                validator: validatePassword,
                obscureText: true,
                prefixIcon: Icons.lock_outline,
                fillColor: AppColors.normal,
              ),
              if (_passwordStrength.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      "Password strength: ",
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      _passwordStrength,
                      style: TextStyle(
                        color: _passwordStrengthColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: _getPasswordStrengthValue(),
                  backgroundColor: Colors.grey.shade300,
                  valueColor: AlwaysStoppedAnimation<Color>(_passwordStrengthColor),
                ),
              ],
              const SizedBox(height: 16),
              CustomTextField(
                label: "Confirm Password",
                hint: "Confirm your password",
                controller: _confirmPasswordController,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please confirm your password';
                  }
                  if (value != _passwordController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
                obscureText: true,
                prefixIcon: Icons.lock_outline,
                fillColor: AppColors.normal,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  SizedBox(
                    height: 24,
                    width: 24,
                    child: Checkbox(
                      value: _acceptTerms,
                      onChanged: (value) {
                        setState(() {
                          _acceptTerms = value ?? false;
                        });
                      },
                      activeColor: AppColors.secondary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                        children: [
                          const TextSpan(text: "I agree to the "),
                          TextSpan(
                            text: "Terms of Service",
                            style: TextStyle(
                              color: AppColors.secondary,
                              decoration: TextDecoration.underline,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const TermsOfServicePage(),
                                  ),
                                );
                              },
                          ),
                          const TextSpan(text: " and "),
                          TextSpan(
                            text: "Privacy Policy",
                            style: TextStyle(
                              color: AppColors.secondary,
                              decoration: TextDecoration.underline,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const PrivacyPolicyPage(),
                                  ),
                                );
                              },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: CustomButton(
                  text: "Create Account",
                  onPressed: _handleRegister,
                  variant: ButtonVariant.secondary,
                  backgroundColor: AppColors.secondary,
                  isLoading: authProvider.isLoading,
                ),
              ),
              const SizedBox(height: 20),
             

              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Already have an account?",
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  CustomButton(
                    text: "Sign in",
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    variant: ButtonVariant.text,
                    backgroundColor: AppColors.secondary,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRegisterTabletLayout(BuildContext context, AuthProvider authProvider) {
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
          child: Container(
            width: 500,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.1),
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
                _buildRegisterForm(context, authProvider),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRegisterDesktopLayout(BuildContext context, AuthProvider authProvider) {
    return Row(
      children: [
        // Left panel with branding/image
        Expanded(
          flex: 5,
          child: Container(
            height: double.infinity,
            color: AppColors.secondary,
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
                        "Create Account",
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
                          "Join our community and start your sustainable journey today",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
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
                          "© 2025 Hydrozap",
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 20),
                        InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const PrivacyPolicyPage(),
                              ),
                            );
                          },
                          child: Text(
                            "Privacy Policy",
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 14,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                        const SizedBox(width: 20),
                        InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const TermsOfServicePage(),
                              ),
                            );
                          },
                          child: Text(
                            "Terms of Service",
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 14,
                              decoration: TextDecoration.underline,
                            ),
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
        // Right panel with registration form
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
                    child: _buildRegisterForm(context, authProvider),
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
            "Sign Up",
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Create an account to get started with us.",
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegisterForm(BuildContext context, AuthProvider authProvider) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    label: "First Name",
                    hint: "Enter your first name",
                    controller: _firstNameController,
                    validator: validateName,
                    prefixIcon: Icons.person_outline,
                    fillColor: AppColors.normal,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: CustomTextField(
                    label: "Last Name",
                    hint: "Enter your last name",
                    controller: _lastNameController,
                    validator: validateName,
                    prefixIcon: Icons.person_outline,
                    fillColor: AppColors.normal,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            CustomTextField(
              label: "Username",
              hint: "Choose a username",
              controller: _usernameController,
              validator: validateName,
              prefixIcon: Icons.alternate_email,
              fillColor: AppColors.normal,
            ),
            const SizedBox(height: 20),
            CustomTextField(
              label: "Email",
              hint: "Enter your email address",
              controller: _emailController,
              validator: validateEmail,
              prefixIcon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              fillColor: AppColors.normal,
            ),
            const SizedBox(height: 20),
            CustomTextField(
              label: "Phone Number",
              hint: "Enter your phone number",
              controller: _phoneController,
              validator: validatePhone,
              prefixIcon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              fillColor: AppColors.normal,
              prefixText: "+63 ",
            ),
            const SizedBox(height: 20),
            CustomTextField(
              label: "Password",
              hint: "Create a strong password",
              controller: _passwordController,
              validator: validatePassword,
              obscureText: true,
              prefixIcon: Icons.lock_outline,
              fillColor: AppColors.normal,
            ),
            if (_passwordStrength.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    "Password strength: ",
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    _passwordStrength,
                    style: TextStyle(
                      color: _passwordStrengthColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              LinearProgressIndicator(
                value: _getPasswordStrengthValue(),
                backgroundColor: Colors.grey.shade300,
                valueColor: AlwaysStoppedAnimation<Color>(_passwordStrengthColor),
              ),
            ],
            const SizedBox(height: 16),
            CustomTextField(
              label: "Confirm Password",
              hint: "Confirm your password",
              controller: _confirmPasswordController,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please confirm your password';
                }
                if (value != _passwordController.text) {
                  return 'Passwords do not match';
                }
                return null;
              },
              obscureText: true,
              prefixIcon: Icons.lock_outline,
              fillColor: AppColors.normal,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                SizedBox(
                  height: 24,
                  width: 24,
                  child: Checkbox(
                    value: _acceptTerms,
                    onChanged: (value) {
                      setState(() {
                        _acceptTerms = value ?? false;
                      });
                    },
                    activeColor: AppColors.secondary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                      children: [
                        const TextSpan(text: "I agree to the "),
                        TextSpan(
                          text: "Terms of Service",
                          style: TextStyle(
                            color: AppColors.secondary,
                            decoration: TextDecoration.underline,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const TermsOfServicePage(),
                                ),
                              );
                            },
                        ),
                        const TextSpan(text: " and "),
                        TextSpan(
                          text: "Privacy Policy",
                          style: TextStyle(
                            color: AppColors.secondary,
                            decoration: TextDecoration.underline,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const PrivacyPolicyPage(),
                                ),
                              );
                            },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
            CustomButton(
              text: "Create Account",
              onPressed: _handleRegister,
              variant: ButtonVariant.secondary,
              backgroundColor: AppColors.secondary,
              isLoading: authProvider.isLoading,
            ),
            const SizedBox(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Already have an account?",
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
                CustomButton(
                  text: "Sign in",
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  variant: ButtonVariant.text,
                  backgroundColor: AppColors.secondary,
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
    _firstNameController.dispose();
    _lastNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _animationController.dispose();
    super.dispose();
  }
}