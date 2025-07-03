import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/api/api_service.dart';
import '../../../../data/local/shared_prefs.dart';

class SendFeedbackPage extends StatefulWidget {
  const SendFeedbackPage({super.key});

  @override
  _SendFeedbackPageState createState() => _SendFeedbackPageState();
}

class _SendFeedbackPageState extends State<SendFeedbackPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _feedbackController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  
  String _selectedFeedbackType = 'Bug Report';
  bool _isSubmitting = false;
  final ApiService _apiService = ApiService();

  final List<Map<String, dynamic>> _feedbackTypes = [
    {'type': 'Bug Report', 'icon': '🐞', 'color': Color(0xFFE53935)},
    {'type': 'Feature Request', 'icon': '💡', 'color': Color(0xFFFFB300)},
    {'type': 'General Feedback', 'icon': '👍', 'color': Color(0xFF43A047)},
  ];

  @override
  void dispose() {
    _feedbackController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submitFeedback() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSubmitting = true;
      });

      try {
        // Get user ID if available
        final userId = await SharedPrefs.getUserId();
        
        // Create feedback data
        final feedbackData = {
          'type': _selectedFeedbackType,
          'message': _feedbackController.text,
          'email': _emailController.text,
          'phone': _phoneController.text.isEmpty ? null : _phoneController.text,
          'timestamp': DateTime.now().toIso8601String(),
        };
        
        // Add user ID if available
        if (userId != null) {
          feedbackData['user_id'] = userId;
        }

        // Submit feedback using API service
        final success = await _apiService.sendFeedback(feedbackData);

        if (success) {
          // Show success message with alert dialog
          if (!mounted) return;
          
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Row(
                  children: [
                    Icon(Icons.check_circle, color: AppColors.success),
                    SizedBox(width: 10),
                    Text('Thank You!'),
                  ],
                ),
                content: Text(
                  'Your feedback has been submitted successfully. We appreciate your input and will review it shortly.',
                  style: TextStyle(fontSize: 16),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop(); // Close dialog
                      Navigator.pop(context); // Return to previous screen
                    },
                    child: Text(
                      'OK',
                      style: TextStyle(
                        color: AppColors.moss,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        } else {
          // Show error message with alert dialog
          if (!mounted) return;
          
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Row(
                  children: [
                    Icon(Icons.error, color: AppColors.error),
                    SizedBox(width: 10),
                    Text('Submission Failed'),
                  ],
                ),
                content: Text(
                  'There was a problem submitting your feedback. Please try again later.',
                  style: TextStyle(fontSize: 16),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop(); // Close dialog
                    },
                    child: Text(
                      'OK',
                      style: TextStyle(
                        color: AppColors.forest,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        }
      } catch (e) {
        // Show exception error with alert dialog
        if (!mounted) return;
        
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.warning, color: Colors.orange),
                  SizedBox(width: 10),
                  Text('Error'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'An error occurred while submitting your feedback:',
                    style: TextStyle(fontSize: 16),
                  ),
                  SizedBox(height: 10),
                  Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      e.toString(),
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 14,
                        color: Colors.red[700],
                      ),
                    ),
                  ),
                ],
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Close dialog
                  },
                  child: Text(
                    'OK',
                    style: TextStyle(
                      color: AppColors.forest,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      } finally {
        if (mounted) {
          setState(() {
            _isSubmitting = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:  Text(
          'Send Feedback',
          style: TextStyle(
            color: AppColors.textOnDark,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppColors.forest,
        elevation: 0,
        iconTheme:  IconThemeData(color: AppColors.textOnDark),
      ),
      body: Container(
        color: Colors.grey[100],
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader(
                      'What kind of feedback do you have?',
                      AppColors.forest,
                    ),
                    _buildFeedbackTypeSelector(),
                    const SizedBox(height: 24),
                    _buildSectionHeader(
                      'Tell us more',
                      AppColors.forest,
                    ),
                    _buildFeedbackMessageField(),
                    const SizedBox(height: 24),
                    _buildSectionHeader(
                      'Contact Information (Optional)',
                      AppColors.forest,
                    ),
                    _buildContactFields(),
                    const SizedBox(height: 32),
                    _buildSubmitButton(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            height: 2,
            width: 60,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackTypeSelector() {
    return Center(
      child: Wrap(
        spacing: 16,
        runSpacing: 16,
        children: _feedbackTypes.map((type) {
          final bool isSelected = _selectedFeedbackType == type['type'];
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedFeedbackType = type['type'];
              });
            },
            child: Container(
              width: 110,
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSelected ? type['color'].withOpacity(0.2) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? type['color'] : Colors.grey.shade300,
                  width: isSelected ? 2 : 1,
                ),
                boxShadow: [
                  if (isSelected)
                    BoxShadow(
                      color: type['color'].withOpacity(0.3),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    )
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    type['icon'],
                    style: TextStyle(fontSize: 32),
                  ),
                  SizedBox(height: 8),
                  Text(
                    type['type'],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? type['color'] : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFeedbackMessageField() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: TextFormField(
          controller: _feedbackController,
          maxLines: 8,
          minLines: 5,
          decoration: InputDecoration(
            hintText: "Tell us what's on your mind...",
            border: InputBorder.none,
            filled: true,
            fillColor: Colors.white,
          ),
          validator: (value) {
            if (value == null || value.trim().length < 10) {
              return 'Please provide at least 10 characters of feedback';
            }
            return null;
          },
        ),
      ),
    );
  }

  Widget _buildContactFields() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Email Address',
                prefixIcon: Icon(Icons.email, color: AppColors.moss),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  // Simple email validation
                  if (!value.contains('@') || !value.contains('.')) {
                    return 'Please enter a valid email address';
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Phone Number (Optional)',
                prefixIcon: Icon(Icons.phone, color: AppColors.sand),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Center(
      child: ElevatedButton.icon(
        onPressed: _isSubmitting ? null : _submitFeedback,
        icon: _isSubmitting
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: Colors.white,
                ),
              )
            : Icon(Icons.send),
        label: Text(
          _isSubmitting ? 'Submitting...' : 'Submit Feedback',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.moss,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(horizontal: 40, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 3,
        ),
      ),
    );
  }
} 