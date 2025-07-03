import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class TermsOfServicePage extends StatelessWidget {
  const TermsOfServicePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms of Service'),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: Text(
                'HYDROZAP - Terms of Service',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 10),
            const Center(
              child: Text(
                'Effective Date: July 05, 2025',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Welcome to HYDROZAP, a smart hydroponics control and monitoring platform. By using our app, website, and services, you agree to the following terms and conditions.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            _buildSection(
              '1. Acceptance of Terms',
              'By accessing or using HYDROZAP, you agree to be bound by these Terms of Service. If you do not agree, you may not use our services.',
            ),
            _buildSection(
              '2. Description of Service',
              'HYDROZAP provides automated hydroponic system control using IoT devices, sensors, and web/mobile dashboards.',
            ),
            _buildSection(
              '3. User Accounts',
              'You must register an account to access certain features.\n\n'
              'You are responsible for maintaining the confidentiality of your account credentials.\n\n'
              'You agree to provide accurate and complete information during registration.',
            ),
            _buildSection(
              '4. Device and Data Usage',
              'You agree to use HYDROZAP-compatible hardware and sensors.\n\n'
              'We are not responsible for damage or losses due to misuse of devices or system errors.',
            ),
            _buildSection(
              '5. License and Restrictions',
              'We grant you a limited, non-exclusive, non-transferable license to use HYDROZAP.\n\n'
              'You may not copy, modify, distribute, sell, or lease any part of our service.',
            ),
            _buildSection(
              '6. Service Availability',
              'We strive to keep HYDROZAP running smoothly but do not guarantee uninterrupted service.\n\n'
              'Maintenance, updates, or technical issues may temporarily affect availability.',
            ),
            _buildSection(
              '7. Termination',
              'We reserve the right to suspend or terminate access to the service if you violate these terms.',
            ),
            _buildSection(
              '8. Limitation of Liability',
              'HYDROZAP is provided "as is" without warranties of any kind.\n\n'
              'We are not liable for indirect or consequential damages.',
            ),
            _buildSection(
              '9. Changes to Terms',
              'We may update these terms from time to time. Continued use indicates acceptance of any changes.',
            ),
            const SizedBox(height: 40),
            Center(
              child: Text(
                'Last updated: July 05, 2025',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: const TextStyle(fontSize: 16),
        ),
      ],
    );
  }
} 