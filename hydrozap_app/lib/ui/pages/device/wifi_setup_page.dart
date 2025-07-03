import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../core/constants/app_colors.dart';
import '../../components/custom_button.dart';
import '../../widgets/responsive_widget.dart';

class WifiSetupPage extends StatefulWidget {
  final Function(String, String) onWifiCredentialsSubmitted;
  final String? initialSsid;
  final String? initialPassword;
  final VoidCallback? onCancel;

  const WifiSetupPage({
    Key? key, 
    required this.onWifiCredentialsSubmitted,
    this.initialSsid,
    this.initialPassword,
    this.onCancel,
  }) : super(key: key);

  @override
  _WifiSetupPageState createState() => _WifiSetupPageState();
}

class _WifiSetupPageState extends State<WifiSetupPage> {
  final TextEditingController _ssidController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isValid = false;
  bool _isLoading = false;
  String? _errorMessage;
  
  @override
  void initState() {
    super.initState();
    
    // Set initial values if available
    if (widget.initialSsid != null) {
      _ssidController.text = widget.initialSsid!;
    }
    if (widget.initialPassword != null) {
      _passwordController.text = widget.initialPassword!;
    }
    
    // Add listeners to validate input
    _ssidController.addListener(_validateInputs);
    _passwordController.addListener(_validateInputs);
    
    // Initial validation
    _validateInputs();
  }
  
  @override
  void dispose() {
    _ssidController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
  
  void _validateInputs() {
    setState(() {
      _isValid = _ssidController.text.trim().isNotEmpty && 
                _passwordController.text.length >= 8;
      _errorMessage = null;
    });
  }
  
  Future<void> _handleNext() async {
    if (!_isValid) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await http.post(
        Uri.parse('http://192.168.4.1/connect'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'ssid': _ssidController.text.trim(),
          'password': _passwordController.text,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          widget.onWifiCredentialsSubmitted(
            _ssidController.text.trim(),
            _passwordController.text
          );
        } else {
          setState(() {
            _errorMessage = data['message'] ?? 'Failed to connect to Wi-Fi network';
          });
        }
      } else {
        setState(() {
          _errorMessage = 'Failed to connect to device. Please try again.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Could not reach device. Make sure you are connected to the device\'s Wi-Fi network.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  void _handleCancel() {
    if (widget.onCancel != null) {
      widget.onCancel!();
    } else {
      Navigator.of(context).pop();
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: ResponsiveWidget(
          mobile: _buildMobileLayout(),
          tablet: _buildTabletLayout(),
          desktop: _buildDesktopLayout(),
        ),
      ),
    );
  }
  
  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _buildContent(),
      ),
    );
  }
  
  Widget _buildTabletLayout() {
    return SingleChildScrollView(
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          padding: const EdgeInsets.all(24.0),
          child: _buildContent(),
        ),
      ),
    );
  }
  
  Widget _buildDesktopLayout() {
    return SingleChildScrollView(
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800),
          padding: const EdgeInsets.all(32.0),
          child: _buildContent(),
        ),
      ),
    );
  }
  
  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeaderSection(),
        const SizedBox(height: 24),
        
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.wifi_tethering,
                    color: AppColors.water,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "Wi-Fi Connection",
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // SSID field
              TextField(
                controller: _ssidController,
                decoration: InputDecoration(
                  labelText: "Wi-Fi Network Name (SSID)",
                  hintText: "Enter your Wi-Fi network name",
                  prefixIcon: const Icon(Icons.wifi),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: Colors.grey.withOpacity(0.3),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: AppColors.water,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Password field
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: "Wi-Fi Password",
                  hintText: "Enter your Wi-Fi password",
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility : Icons.visibility_off,
                      color: Colors.grey.withOpacity(0.7),
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: Colors.grey.withOpacity(0.3),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: AppColors.water,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Error message
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              
              const SizedBox(height: 24),
              
              // Help info box
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.blue.shade700,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "Connection Information",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Your device needs Wi-Fi access to sync data and receive updates. Make sure your Wi-Fi network is 2.4GHz as some devices don't support 5GHz networks.",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        
        // Navigation buttons
        Row(
          children: [
            Expanded(
              child: CustomButton(
                text: "Back",
                onPressed: _isLoading ? () {} : _handleCancel,
                variant: ButtonVariant.outline,
                backgroundColor: Colors.white,
                textColor: Colors.grey[800],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: CustomButton(
                text: _isLoading ? "Connecting..." : "Next",
                onPressed: _isLoading || !_isValid ? () {} : () => _handleNext(),
                variant: ButtonVariant.primary,
                backgroundColor: AppColors.primary,
                icon: _isLoading ? null : Icons.arrow_forward,
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildHeaderSection() {
    final bool isMobile = MediaQuery.of(context).size.width < 600;
    
    return Container(
      height: isMobile ? 120 : 140,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Opacity(
                opacity: 0.1,
                child: Image.asset(
                  'assets/images/main.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    AppColors.water.withOpacity(0.8),
                    AppColors.secondary.withOpacity(0.7),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(isMobile ? 12.0 : 20.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(isMobile ? 8 : 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.wifi,
                    color: Colors.white,
                    size: isMobile ? 28 : 36,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "Connect to Wi-Fi",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isMobile ? 20 : 24,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Set up your device's internet connection",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: isMobile ? 12 : 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 