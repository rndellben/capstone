import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/services.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../providers/user_profile_provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/helpers/utils.dart';
import '../../../../core/utils/logger.dart';
import '../../../widgets/responsive_widget.dart';
import '../../../components/custom_text_field.dart';
import '../../../../data/remote/firebase_service.dart';
import '../../../../core/api/api_service.dart';
import '../../../../data/local/shared_prefs.dart';
import '../../../widgets/sync_status_indicator.dart';

class AccountSettingsPage extends StatefulWidget {
  const AccountSettingsPage({super.key});

  @override
  _AccountSettingsPageState createState() => _AccountSettingsPageState();
}

class _AccountSettingsPageState extends State<AccountSettingsPage>
    with TickerProviderStateMixin {
  final _profileFormKey = GlobalKey<FormState>();
  final _passwordFormKey = GlobalKey<FormState>();
  final ScrollController _scrollController = ScrollController();
  final FirebaseService _firebaseService = FirebaseService();
  final ApiService _apiService = ApiService();
  final Connectivity _connectivity = Connectivity();
  
  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  // Profile Info Form Controllers
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  
  // Password Form Controllers
  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  bool _isEditMode = false;
  bool _isOffline = false;
  double _passwordStrength = 0.0;
  String _passwordStrengthText = 'Weak';
  Color _passwordStrengthColor = AppColors.error;
  File? _profileImage;
  
  @override
  void initState() {
    super.initState();
    
    // Initialize animations
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    
    // Start animations
    _fadeController.forward();
    _slideController.forward();
    
    // We need to use addPostFrameCallback to perform async operations after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initConnectivity();
      _loadUserProfile();
    });
    
    // Listen for connectivity changes
    _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
  }
  
  // Initialize connectivity status
  Future<void> _initConnectivity() async {
    try {
      ConnectivityResult result = await _connectivity.checkConnectivity();
      _updateConnectionStatus(result);
    } catch (e) {
      logger.e('Error checking connectivity: $e');
      _isOffline = true;
    }
  }
  
  // Update connection status based on connectivity result
  void _updateConnectionStatus(ConnectivityResult result) {
    setState(() {
      _isOffline = (result == ConnectivityResult.none);
      
      // If we just came back online, try to sync
      if (!_isOffline) {
        logger.d('Connection restored, attempting to sync...');
        _syncProfile();
      } else {
        logger.d('Device is offline');
      }
    });
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Remove this call as we're now handling it in initState with a post-frame callback
    // _loadUserProfile();
  }
  
  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _scrollController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
  
  Future<void> _loadUserProfile() async {
    setState(() {
      _isLoading = true;
    });

    final userProfileProvider = Provider.of<UserProfileProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    try {
      // Get the current user ID from AuthProvider
      final userId = await authProvider.getCurrentUserId();
      logger.d("Current user ID: $userId");

      if (userId != null) {
        try {
          logger.d("Attempting to fetch user profile...");
          
          // Try to load profile image from local cache
          final cachedImagePath = await SharedPrefs.getProfileImagePath();
          if (cachedImagePath != null) {
            try {
              final imageFile = File(cachedImagePath);
              if (await imageFile.exists()) {
                setState(() {
                  _profileImage = imageFile;
                });
                logger.d("Loaded profile image from cache: $cachedImagePath");
              }
            } catch (e) {
              logger.e("Error loading cached profile image: $e");
              // Continue loading the rest of the profile
            }
          }
          
          // If offline, try to load from cache first
          if (_isOffline) {
            logger.d("Device is offline, attempting to load from cache first");
            final cachedProfile = await SharedPrefs.getUserProfile();
            
            if (cachedProfile != null) {
              logger.d("Loaded profile from cache: $cachedProfile");
              setState(() {
                _firstNameController.text = cachedProfile['firstName'] ?? '';
                _lastNameController.text = cachedProfile['lastName'] ?? '';
                _emailController.text = cachedProfile['email'] ?? '';
                _phoneController.text = cachedProfile['phone'] ?? '';
                _isLoading = false;
              });
              
              // Display offline indicator but don't try to fetch online
              return;
            }
          }
          
          // Either we're online or there was no cached data
          final success = await userProfileProvider.fetchUserProfile(userId);
          logger.d("Fetch profile success: $success");
          logger.d("User profile data: ${userProfileProvider.userProfile}");
          
          if (success && userProfileProvider.userProfile != null) {
            final profile = userProfileProvider.userProfile!;
            setState(() {
              // Handle first and last name from the split name in UserProfileProvider
              _firstNameController.text = profile['firstName'] ?? '';
              _lastNameController.text = profile['lastName'] ?? '';
              _emailController.text = profile['email'] ?? '';
              _phoneController.text = profile['phone'] ?? '';
              
              // If we're online and there's a profile image URL in the data
              if (profile['profileImage'] != null && 
                  !_isOffline && 
                  _profileImage == null) {
                // TODO: Load profile image from URL
                // This would typically involve downloading and caching the image
                logger.d("Profile image URL found: ${profile['profileImage']}");
              }
            });
            logger.d("Profile data loaded into form fields");
          } else {
            logger.w("Failed to fetch user profile from provider");
            // Use post-frame callback to show SnackBar after build
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Failed to load user profile')),
              );
            }
          }
        } catch (e) {
          logger.e('Error loading user profile: $e');
          // Use post-frame callback to show SnackBar after build
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error loading profile: $e')),
            );
          }
        } 
      } else {
        logger.w('No user ID available');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please log in to view your profile')),
          );
        }
      }
    } catch (e) {
      logger.e('Error in account settings initialization: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error initializing profile: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  Future<void> _pickImage() async {
    try {
      final ImagePicker imagePicker = ImagePicker();
      final XFile? pickedFile = await imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      
      if (pickedFile != null) {
        setState(() {
          _profileImage = File(pickedFile.path);
        });
        
        // TODO: Add code to upload image to storage service
        // For now, we're just setting it locally
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile picture updated locally')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick image: $e')),
      );
    }
  }
  
  Future<void> _takePicture() async {
    try {
      final ImagePicker imagePicker = ImagePicker();
      final XFile? pickedFile = await imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      
      if (pickedFile != null) {
        setState(() {
          _profileImage = File(pickedFile.path);
        });
        
        // TODO: Add code to upload image to storage service
        // For now, we're just setting it locally
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile picture captured and updated locally')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to capture image: $e')),
      );
    }
  }
  
  void _evaluatePassword(String password) {
    // Simple password strength evaluation
    setState(() {
      if (password.isEmpty) {
        _passwordStrength = 0.0;
        _passwordStrengthText = 'Weak';
        _passwordStrengthColor = AppColors.error;
      } else if (password.length < 6) {
        _passwordStrength = 0.2;
        _passwordStrengthText = 'Weak';
        _passwordStrengthColor = AppColors.error;
      } else if (password.length < 8) {
        _passwordStrength = 0.4;
        _passwordStrengthText = 'Fair';
        _passwordStrengthColor = AppColors.sunset;
      } else if (password.length < 10) {
        _passwordStrength = 0.6;
        _passwordStrengthText = 'Good';
        _passwordStrengthColor = AppColors.sunlight;
      } else if (password.length < 12) {
        _passwordStrength = 0.8;
        _passwordStrengthText = 'Strong';
        _passwordStrengthColor = AppColors.leaf;
      } else {
        _passwordStrength = 1.0;
        _passwordStrengthText = 'Very Strong';
        _passwordStrengthColor = AppColors.success;
      }
      
      // Enhance evaluation with character types
      final hasUppercase = password.contains(RegExp(r'[A-Z]'));
      final hasLowercase = password.contains(RegExp(r'[a-z]'));
      final hasDigits = password.contains(RegExp(r'[0-9]'));
      final hasSpecialChars = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
      
      if (hasUppercase && hasLowercase && hasDigits && hasSpecialChars && password.length >= 8) {
        _passwordStrength = 1.0;
        _passwordStrengthText = 'Very Strong';
        _passwordStrengthColor = AppColors.success;
      } else if ((hasUppercase || hasLowercase) && (hasDigits || hasSpecialChars) && password.length >= 8) {
        _passwordStrength = min(_passwordStrength, 0.8);
        _passwordStrengthText = 'Strong';
        _passwordStrengthColor = AppColors.leaf;
      }
    });
  }
  
  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Success'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
  
  Future<void> _updateProfile() async {
    if (!_profileFormKey.currentState!.validate()) {
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Get user ID with safer approach
      String? userId;
      
      try {
        final currentUser = _firebaseService.getCurrentUser();
        userId = currentUser?.uid;
      } catch (e) {
        logger.e('Error getting Firebase user: $e');
        // Fall back to SharedPrefs
      }
      
      userId ??= await SharedPrefs.getUserId();
      
      if (userId == null) {
        throw Exception('No user ID available');
      }
      
      // Prepare user profile data
      final Map<String, dynamic> profileData = {
        'firstName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'phone': _phoneController.text.trim(),
      };
      
      // No need to include email as it's not updated in the backend
      
      // Upload profile image if changed
      String? profileImageUrl;
      if (_profileImage != null) {
        try {
          profileImageUrl = await _uploadProfileImage(userId);
          if (profileImageUrl != null) {
            profileData['profileImage'] = profileImageUrl;
          }
        } catch (e) {
          print('Error uploading profile image: $e');
          // Continue with profile update even if image upload fails
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to upload profile picture: $e')),
            );
          }
        }
      }
      
      // Use the UserProfileProvider to update profile
      final userProfileProvider = Provider.of<UserProfileProvider>(context, listen: false);
      final success = await userProfileProvider.updateUserProfile(userId, profileData);
      
      if (success) {
        String successMessage = _isOffline 
            ? 'Profile updated locally (offline mode)'
            : 'Profile updated successfully';
        
        if (mounted) {    
          _showSuccessDialog(successMessage);
        }
        
        setState(() {
          _isEditMode = false;
        });
      } else {
        throw Exception('Failed to update profile. Please check your connection and try again.');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update profile: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  Future<String?> _uploadProfileImage(String userId) async {
    // This is a placeholder for the actual implementation
    // In a real app, you would upload the image to Firebase Storage or another storage service
    
    if (_profileImage == null) {
      return null;
    }
    
    // Check if we're offline
    if (_isOffline) {
      // Store the image path locally until we can sync
      await SharedPrefs.setProfileImagePath(_profileImage!.path);
      return 'local://${_profileImage!.path}';
    }
    
    // For now, we'll just pretend we've uploaded it and return a fake URL
    // TODO: Implement proper image upload to Firebase Storage or your preferred storage
    await Future.delayed(const Duration(seconds: 1)); // Simulate network delay
    
    return 'https://example.com/profile_images/$userId.jpg';
  }
  
  Future<void> _updatePassword() async {
    // Skip password update if all fields are empty
    if (_currentPasswordController.text.isEmpty && 
        _newPasswordController.text.isEmpty && 
        _confirmPasswordController.text.isEmpty) {
      return;
    }
    
    if (!_passwordFormKey.currentState!.validate()) {
      return;
    }
    
    if (_newPasswordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('New passwords do not match')),
      );
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Get user ID with safer approach
      String? userId;
      
      try {
        final currentUser = _firebaseService.getCurrentUser();
        userId = currentUser?.uid;
      } catch (e) {
        logger.e('Error getting Firebase user: $e');
        // Fall back to SharedPrefs
      }
      
      userId ??= await SharedPrefs.getUserId();
      
      if (userId == null) {
        throw Exception('No user ID available');
      }
      
      // With the custom UserProfileView, we can directly update the password
      final userProfileProvider = Provider.of<UserProfileProvider>(context, listen: false);
      
      // Create password update data
      final Map<String, dynamic> passwordData = {
        'password': _newPasswordController.text,
      };
      
      // Call the API to update password directly
      final success = await userProfileProvider.updateUserProfile(userId, passwordData);
      
      if (success) {
        if (mounted) {
          _showSuccessDialog('Password updated successfully');
        }
        
        // Clear password fields after successful update
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
        
        setState(() {
          _isEditMode = false;
        });
      } else {
        throw Exception('Failed to update password. Please try again.');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update password: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  Future<void> _changeEmail() async {
    // Show change email dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final TextEditingController newEmailController = TextEditingController();
        final TextEditingController passwordController = TextEditingController();
        
        return AlertDialog(
          title: const Text('Change Email Address'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: newEmailController,
                  decoration: const InputDecoration(
                    labelText: 'New Email Address',
                    hintText: 'Enter your new email address',
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    hintText: 'Enter your password to confirm',
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 8),
                const Text(
                  'A verification email will be sent to your new address.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                // TODO: Implement email change and verification logic
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Verification email sent to your new address')),
                );
              },
              child: const Text('Change Email'),
            ),
          ],
        );
      },
    );
  }
  
  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Take a Picture'),
                onTap: () {
                  Navigator.of(context).pop();
                  _takePicture();
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage();
                },
              ),
              ListTile(
                leading: const Icon(Icons.auto_awesome),
                title: const Text('Generate Avatar'),
                onTap: () {
                  Navigator.of(context).pop();
                  // TODO: Implement avatar generator
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Avatar generator not implemented yet')),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
  
  @override
  Widget build(BuildContext context) {
    // Check for user authentication before showing the page
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      // Check if the user is logged in using the synchronous method that doesn't rely on Firebase
      SharedPrefs.getUserId().then((userId) {
        if (userId == null) {
          // If no user ID is found, show a message and navigate to login
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('You need to be logged in to view this page')),
          );
          
          // Navigate to login page
          Navigator.of(context).pushReplacementNamed('/login');
        }
      });
    });
    
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: _isLoading
        ? _buildLoadingState()
        : FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: _buildBody(),
            ),
          ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.transparent,
      foregroundColor: AppColors.textOnDark,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.leaf, AppColors.forest],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.textOnDark.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.person_outline, size: 20),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                'Account Settings',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
              ),
            ),
          ),
        ],
      ),
      actions: [
        if (_isOffline)
          Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.wifi_off, size: 16, color: AppColors.error),
                const SizedBox(width: 4),
                Text(
                  'Offline',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.error,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.textOnDark.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.refresh, size: 20),
          ),
          onPressed: _isLoading ? null : _loadUserProfile,
          tooltip: 'Refresh Profile',
        ),
        const SizedBox(width: 8),
        if (_isEditMode)
          TextButton.icon(
            icon: const Icon(Icons.close, size: 20),
            label: const Text('Cancel'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textOnDark,
              backgroundColor: AppColors.textOnDark.withOpacity(0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              setState(() {
                _isEditMode = false;
                _loadUserProfile(); // Reset to original values
              });
            },
          )
        else
          TextButton.icon(
            icon: const Icon(Icons.edit_outlined, size: 20),
            label: const Text('Edit'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textOnDark,
              backgroundColor: AppColors.textOnDark.withOpacity(0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              setState(() {
                _isEditMode = true;
              });
            },
          ),
        const SizedBox(width: 16),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Loading your profile...',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return Column(
      children: [
        // Offline status indicator
        if (_isOffline)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(0.1),
              border: Border(
                bottom: BorderSide(
                  color: AppColors.error.withOpacity(0.2),
                  width: 1,
                ),
              ),
            ),
            child: SyncStatusIndicator(),
          ),
        
        // Main content
        Expanded(
          child: ResponsiveWidget(
            mobile: _buildMobileLayout(),
            tablet: _buildTabletLayout(),
            desktop: _buildDesktopLayout(),
          ),
        ),
      ],
    );
  }
  
  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      controller: _scrollController,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildProfilePictureSection(),
            const SizedBox(height: 24),
            _buildProfileInfoCard(),
            const SizedBox(height: 24),
            _buildSecurityCard(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTabletLayout() {
    return SingleChildScrollView(
      controller: _scrollController,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildProfilePictureSection(),
                const SizedBox(height: 24),
                _buildProfileInfoCard(),
                const SizedBox(height: 24),
                _buildSecurityCard(),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildDesktopLayout() {
    return SingleChildScrollView(
      controller: _scrollController,
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 1,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 16.0),
                    child: Column(
                      children: [
                        _buildProfilePictureSection(),
                        const SizedBox(height: 24),
                        _buildProfileInfoCard(),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 16.0),
                    child: _buildSecurityCard(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildProfilePictureSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 80,
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  backgroundImage: _profileImage != null
                      ? FileImage(_profileImage!)
                      : null,
                  child: _profileImage == null
                      ? Icon(
                          Icons.person_outline,
                          size: 80,
                          color: AppColors.primary.withOpacity(0.6),
                        )
                      : null,
                ),
              ),
              if (_isEditMode)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.camera_alt, color: Colors.white, size: 24),
                      onPressed: _showImagePickerOptions,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Profile Picture',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add a photo to personalize your account',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          if (_isEditMode) ...[
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _showImagePickerOptions,
              icon: const Icon(Icons.photo_camera, size: 18),
              label: const Text('Change Photo'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 2,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildProfileInfoCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _profileFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.person_outline,
                      color: AppColors.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Profile Information',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          'Manage your personal details',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Name Fields
              Text(
                'Full Name',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth < 500) {
                    return Column(
                      children: [
                        _buildTextField(
                          controller: _firstNameController,
                          label: 'First Name',
                          icon: Icons.person_outline,
                          enabled: _isEditMode,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your first name';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _lastNameController,
                          label: 'Last Name',
                          icon: Icons.person_outline,
                          enabled: _isEditMode,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your last name';
                            }
                            return null;
                          },
                        ),
                      ],
                    );
                  } else {
                    return Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: _firstNameController,
                            label: 'First Name',
                            icon: Icons.person_outline,
                            enabled: _isEditMode,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your first name';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildTextField(
                            controller: _lastNameController,
                            label: 'Last Name',
                            icon: Icons.person_outline,
                            enabled: _isEditMode,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your last name';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    );
                  }
                },
              ),
              const SizedBox(height: 24),
              
              // Email Field
              Text(
                'Email Address',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth < 500) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildTextField(
                          controller: _emailController,
                          label: 'Email',
                          icon: Icons.email_outlined,
                          enabled: false,
                          validator: null,
                        ),
                        if (_isEditMode) ...[
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _changeEmail,
                            icon: const Icon(Icons.edit_outlined, size: 18),
                            label: const Text('Change Email'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.secondary,
                              foregroundColor: Colors.white,
                              elevation: 2,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ],
                      ],
                    );
                  } else {
                    return Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: _emailController,
                            label: 'Email',
                            icon: Icons.email_outlined,
                            enabled: false,
                            validator: null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        if (_isEditMode)
                          ElevatedButton.icon(
                            onPressed: _changeEmail,
                            icon: const Icon(Icons.edit_outlined, size: 18),
                            label: const Text('Change Email'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.secondary,
                              foregroundColor: Colors.white,
                              elevation: 2,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                      ],
                    );
                  }
                },
              ),
              const SizedBox(height: 24),
              
              // Phone Field
              Text(
                'Phone Number',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _phoneController,
                label: 'Phone Number',
                icon: Icons.phone_outlined,
                enabled: _isEditMode,
                keyboardType: TextInputType.phone,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: null,
              ),
              const SizedBox(height: 32),
              
              if (_isEditMode)
                Center(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _updateProfile,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Icon(Icons.save_outlined, size: 20),
                    label: Text(_isLoading ? 'Saving...' : 'Save Changes'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 3,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool enabled,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      style: TextStyle(
        color: enabled ? AppColors.textPrimary : AppColors.textSecondary,
        fontSize: 16,
      ),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.primary.withOpacity(0.6)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.border.withOpacity(0.5)),
        ),
        filled: true,
        fillColor: enabled ? Colors.white : AppColors.background,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        labelStyle: TextStyle(
          color: enabled ? AppColors.textSecondary : AppColors.textSecondary.withOpacity(0.7),
        ),
      ),
    );
  }
  
  Widget _buildSecurityCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _passwordFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.security_outlined,
                      color: AppColors.secondary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Authentication & Security',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          'Keep your account secure',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!_isEditMode)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.success.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.lock, size: 14, color: AppColors.success),
                          const SizedBox(width: 4),
                          Text(
                            'Protected',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.success,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 24),
              
              if (!_isEditMode) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.border,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.password_outlined,
                          color: AppColors.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Change Password',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              'Update your password for increased security',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _isEditMode = true;
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 2,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Change'),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                // Password Change Form
                Text(
                  'Change Password',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Current Password
                _buildPasswordField(
                  controller: _currentPasswordController,
                  label: 'Current Password',
                  icon: Icons.lock_outline,
                  obscureText: _obscureCurrentPassword,
                  onToggleVisibility: () {
                    setState(() {
                      _obscureCurrentPassword = !_obscureCurrentPassword;
                    });
                  },
                  validator: (value) {
                    if (_currentPasswordController.text.isEmpty && 
                        _newPasswordController.text.isEmpty && 
                        _confirmPasswordController.text.isEmpty) {
                      return null;
                    }
                    if (value == null || value.isEmpty) {
                      return 'Please enter your current password';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // New Password
                _buildPasswordField(
                  controller: _newPasswordController,
                  label: 'New Password',
                  icon: Icons.lock_outline,
                  obscureText: _obscureNewPassword,
                  onToggleVisibility: () {
                    setState(() {
                      _obscureNewPassword = !_obscureNewPassword;
                    });
                  },
                  onChanged: _evaluatePassword,
                  validator: (value) {
                    if (_currentPasswordController.text.isEmpty && 
                        _newPasswordController.text.isEmpty && 
                        _confirmPasswordController.text.isEmpty) {
                      return null;
                    }
                    if (value == null || value.isEmpty) {
                      return 'Please enter a new password';
                    }
                    if (value.length < 8) {
                      return 'Password must be at least 8 characters';
                    }
                    return null;
                  },
                ),
                
                // Password Strength Indicator
                if (_newPasswordController.text.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _passwordStrengthColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _passwordStrengthColor.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              _passwordStrength >= 0.8 ? Icons.check_circle : Icons.info_outline,
                              color: _passwordStrengthColor,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Password Strength: $_passwordStrengthText',
                              style: TextStyle(
                                fontSize: 14,
                                color: _passwordStrengthColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: _passwordStrength,
                            backgroundColor: _passwordStrengthColor.withOpacity(0.2),
                            color: _passwordStrengthColor,
                            minHeight: 6,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                
                // Confirm Password
                _buildPasswordField(
                  controller: _confirmPasswordController,
                  label: 'Confirm New Password',
                  icon: Icons.lock_outline,
                  obscureText: _obscureConfirmPassword,
                  onToggleVisibility: () {
                    setState(() {
                      _obscureConfirmPassword = !_obscureConfirmPassword;
                    });
                  },
                  validator: (value) {
                    if (_currentPasswordController.text.isEmpty && 
                        _newPasswordController.text.isEmpty && 
                        _confirmPasswordController.text.isEmpty) {
                      return null;
                    }
                    if (value == null || value.isEmpty) {
                      return 'Please confirm your new password';
                    }
                    if (value != _newPasswordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),
                
                Center(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _updatePassword,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Icon(Icons.security_update, size: 20),
                    label: Text(_isLoading ? 'Updating...' : 'Update Password'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondary,
                      foregroundColor: Colors.white,
                      elevation: 3,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool obscureText,
    required VoidCallback onToggleVisibility,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      onChanged: onChanged,
      validator: validator,
      style: TextStyle(
        color: AppColors.textPrimary,
        fontSize: 16,
      ),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.secondary.withOpacity(0.6)),
        suffixIcon: IconButton(
          icon: Icon(
            obscureText ? Icons.visibility_outlined : Icons.visibility_off_outlined,
            color: AppColors.textSecondary,
          ),
          onPressed: onToggleVisibility,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.secondary, width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        labelStyle: TextStyle(
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
  
  // Helper function for min value between two doubles
  double min(double a, double b) {
    return a < b ? a : b;
  }

  // Add a new method to handle sync when online again
  Future<void> _syncProfile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userProfileProvider = Provider.of<UserProfileProvider>(context, listen: false);
      
      final userId = await authProvider.getCurrentUserId();
      
      if (userId != null) {
        final syncSuccess = await userProfileProvider.syncProfile(userId);
        
        if (syncSuccess) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Profile synced successfully')),
            );
          }
          
          // Update UI with synced profile
          final profile = userProfileProvider.userProfile!;
          setState(() {
            _firstNameController.text = profile['firstName'] ?? '';
            _lastNameController.text = profile['lastName'] ?? '';
            _emailController.text = profile['email'] ?? '';
            _phoneController.text = profile['phone'] ?? '';
          });
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Failed to sync profile. Still offline?')),
            );
          }
        }
      }
    } catch (e) {
      print('Error syncing profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error syncing profile: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
} 