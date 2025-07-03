import 'package:flutter/material.dart';
import '../../../core/api/api_service.dart';
import '../../../core/constants/app_colors.dart';
import '../../components/custom_text_field.dart';
import '../../components/custom_button.dart';
import '../../../core/helpers/validators.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  _ForgotPasswordPageState createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;
  final ApiService _apiService = ApiService();

  // Get current device screen size
  double _getScreenWidth(BuildContext context) => MediaQuery.of(context).size.width;
  
  // Check if current device is mobile
  bool _isMobile(BuildContext context) => _getScreenWidth(context) < 600;
  
  // Check if current device is tablet
  bool _isTablet(BuildContext context) => _getScreenWidth(context) >= 600 && _getScreenWidth(context) < 1200;
  
  // Check if current device is desktop
  bool _isDesktop(BuildContext context) => _getScreenWidth(context) >= 1200;

  Future<void> _handleResetPassword() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final response = await _apiService.resetPassword(_emailController.text.trim());
        
        if (!mounted) return;

        if (response['success'] == true) {
          _showSuccessDialog();
        } else {
          final errorMessage = response['error'];
          // Check for the specific error message from Firebase when user not found
          if (errorMessage == 'No user with that email found.' || 
              errorMessage == 'Failed to generate email action link.') {
            _showErrorMessage("No user with that email found.");
          } else {
            _showErrorMessage(errorMessage ?? "Failed to send reset link. Please try again.");
          }
        }
      } catch (e) {
        if (!mounted) return;
        _showErrorMessage("An error occurred. Please try again later.");
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Reset Link Sent"),
          content: const Text(
            "A password reset link has been sent to your email address. Please check your inbox and follow the instructions.",
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          actions: [
            TextButton(
              child: const Text("Back to Login"),
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pop(); // Go back to login
              },
            ),
          ],
        );
      },
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
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: AppColors.textPrimary,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Center(
              child: SingleChildScrollView(
                child: _buildResponsiveContainer(context, constraints),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildResponsiveContainer(BuildContext context, BoxConstraints constraints) {
    // Determine max width based on device type
    double maxWidth;
    double horizontalPadding;
    
    if (_isDesktop(context)) {
      maxWidth = 600;
      horizontalPadding = 40;
    } else if (_isTablet(context)) {
      maxWidth = 500;
      horizontalPadding = 32;
    } else {
      maxWidth = constraints.maxWidth;
      horizontalPadding = 24;
    }

    return Container(
      constraints: BoxConstraints(maxWidth: maxWidth),
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: _isMobile(context) ? 24 : 40,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Logo or brand image can be added here for larger screens
          if (_isDesktop(context) || _isTablet(context))
            Center(
              child: Icon(
                Icons.lock_reset,
                size: _isDesktop(context) ? 80 : 64,
                color: AppColors.primary,
              ),
            ),
          
          SizedBox(height: _isMobile(context) ? 20 : 32),
          
          Text(
            "Forgot Password",
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: _isMobile(context) ? 28 : 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 12),
          
          Text(
            "Enter your email address and we'll send you a link to reset your password.",
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: _isMobile(context) ? 14 : 16,
            ),
          ),
          
          SizedBox(height: _isMobile(context) ? 32 : 40),
          
          _buildForm(),
          
          if (!_isMobile(context))
            const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          CustomTextField(
            label: "Email",
            hint: "Enter your email address",
            controller: _emailController,
            validator: validateEmail,
            prefixIcon: Icons.email_outlined,
            fillColor: AppColors.normal,
            keyboardType: TextInputType.emailAddress,
          ),
          
          SizedBox(height: _isMobile(context) ? 24 : 32),
          
          SizedBox(
            width: double.infinity,
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  )
                : CustomButton(
                    text: "Send Reset Link",
                    onPressed: _handleResetPassword,
                    backgroundColor: AppColors.primary,
                    variant: ButtonVariant.primary,
                    height: _isMobile(context) ? 48 : 54,
                  ),
          ),

          // Back to login button
          SizedBox(height: _isMobile(context) ? 16 : 24),
          
          Center(
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                "Back to Login",
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }
}