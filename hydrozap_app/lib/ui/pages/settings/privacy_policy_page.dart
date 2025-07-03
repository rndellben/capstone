import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
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
                'HYDROZAP - Privacy Policy',
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
                'Effective Date: April 30, 2024',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Your privacy is important to us. This Privacy Policy explains how we collect, use, and protect your personal information.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            _buildSection(
              '1. Information We Collect',
              'Personal Information: Name, email, account credentials.\n\n'
              'Device Data: Sensor readings, grow profiles, system status.\n\n'
              'Usage Data: Interactions with the app, features used.',
            ),
            _buildSection(
              '2. How We Use Your Information',
              'To provide and maintain our services.\n\n'
              'To monitor system performance and improve features.\n\n'
              'To communicate with users (support, notifications).',
            ),
            _buildSection(
              '3. Data Sharing and Disclosure',
              'We do not sell or rent your personal data.\n\n'
              'Data may be shared with third-party services only for hosting and analytics purposes.',
            ),
            _buildSection(
              '4. Data Security',
              'We use encryption, authentication, and access controls to protect data.\n\n'
              'Users are responsible for keeping their credentials secure.',
            ),
            _buildSection(
              '5. Your Rights',
              'You may access or update your personal information via your account settings.\n\n'
              'If you wish to request deletion of your personal data, please contact our support team at hydrozapservice@gmail.com. We will process your request in accordance with applicable laws and inform you of the outcome.',
            ),
            _buildSection(
              '6. Children\'s Privacy',
              'HYDROZAP is not intended for children under 13. We do not knowingly collect data from minors.',
            ),
            _buildSection(
              '7. International Users and Legal Compliance',
              'GDPR (General Data Protection Regulation)\n\n'
              'If you are located in the European Economic Area (EEA), you have the right to:\n\n'
              '• Access your data\n'
              '• Correct inaccurate or incomplete data\n'
              '• Request deletion of your data\n'
              '(To request deletion, please contact our support or DPO. Deletion is not available directly in the app.)\n'
              '• Restrict or object to data processing\n'
              '• Data portability\n\n'
              'We process personal data in accordance with GDPR and provide appropriate safeguards when transferring data internationally.\n\n'
              'CCPA (California Consumer Privacy Act)\n\n'
              'If you are a California resident, you have the right to:\n\n'
              '• Know what personal information we collect and how we use it\n'
              '• Request deletion of your personal data\n'
              '• Opt out of the sale of personal information (we do not sell personal data)\n'
              '• Non-discrimination for exercising your privacy rights\n\n'
              'Philippines Data Privacy Act (DPA)\n\n'
              'If you are located in the Philippines, we process your personal data in accordance with Republic Act No. 10173 (Data Privacy Act of 2012).\n\n'
              'Legal Basis for Processing:\n'
              '• Your consent\n'
              '• Performance of a contract\n'
              '• Compliance with legal obligations\n'
              '• Legitimate interests\n\n'
              'Your Rights under the DPA:\n'
              '• Right to be informed\n'
              '• Right to object\n'
              '• Right to access\n'
              '• Right to rectify\n'
              '• Right to erase or block\n'
              '• Right to data portability\n'
              '• Right to damages\n'
              '• Right to file a complaint\n\n'
              'Data Retention and Disposal:\n'
              'We retain your personal data only as long as necessary for the purposes stated in this policy or as required by law. Data is securely disposed of when no longer needed.\n\n'
              'Data Breach Notification:\n'
              'In the event of a data breach that may compromise your personal data, we will notify you and the National Privacy Commission as required by law.\n\n'
              'To exercise your rights or for privacy concerns, contact our team at: hydrozapservice@gmail.com.\n\n'
              'To exercise any of these rights, please contact us at: hydrozapservice@gmail.com.',
            ),
            _buildSection(
              '8. Changes to Privacy Policy',
              'We may update this policy and will notify users of significant changes.',
            ),
            _buildSection(
              '9. Contact Us',
              'For questions or concerns, contact us at: hydrozapservice@gmail.com',
            ),
            const SizedBox(height: 40),
            Center(
              child: Text(
                'Last updated: April 30, 2024',
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