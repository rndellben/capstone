import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../ui/widgets/responsive_widget.dart';

class HelpCenterPage extends StatefulWidget {
  const HelpCenterPage({super.key});

  @override
  State<HelpCenterPage> createState() => _HelpCenterPageState();
}

class _HelpCenterPageState extends State<HelpCenterPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Help Center',
          style: TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ResponsiveWidget(
        mobile: _buildMobileLayout(),
        tablet: _buildTabletLayout(),
        desktop: _buildDesktopLayout(),
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Column(
        children: [
          // Premium gradient header
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.primary,
                  AppColors.primary.withOpacity(0.8),
                  AppColors.primary.withOpacity(0.6),
                ],
              ),
            ),
            child: Column(
              children: [
                // Search bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search help topics...',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      suffixIcon: _searchQuery.isNotEmpty 
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.grey),
                            onPressed: () {
                              setState(() {
                                _searchController.clear();
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide(color: AppColors.primary.withOpacity(0.3), width: 2),
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                ),
                
                // Premium-style tab bar
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      color: Colors.white,
                    ),
                    labelColor: AppColors.primary,
                    unselectedLabelColor: Colors.white,
                    labelStyle: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                    unselectedLabelStyle: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 15,
                    ),
                    tabs: const [
                      Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.question_answer_outlined, size: 18),
                            SizedBox(width: 8),
                            Text('FAQs'),
                          ],
                        ),
                      ),
                      Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.menu_book_outlined, size: 18),
                            SizedBox(width: 8),
                            Text('Guides'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
          
          // Content area
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[50],
              ),
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildFaqTab(),
                  _buildGuidesTab(),
                ],
              ),
            ),
          ),
        ],
      );
  }

  Widget _buildTabletLayout() {
    return Row(
      children: [
        // Left sidebar with search and tabs
        Container(
          width: 320,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.primary,
                AppColors.primary.withOpacity(0.8),
                AppColors.primary.withOpacity(0.7),
              ],
            ),
          ),
          child: Column(
            children: [
              // Search bar
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search help topics...',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    suffixIcon: _searchQuery.isNotEmpty 
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.grey),
                          onPressed: () {
                            setState(() {
                              _searchController.clear();
                              _searchQuery = '';
                            });
                          },
                        )
                      : null,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide(color: AppColors.primary.withOpacity(0.3), width: 2),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
              ),
              
              // Tab bar (vertical style)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: Colors.white,
                  ),
                  labelColor: AppColors.primary,
                  unselectedLabelColor: Colors.white,
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                  ),
                  tabs: const [
                    Tab(
                      height: 60,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.question_answer_outlined, size: 24),
                          SizedBox(width: 12),
                          Text('FAQs'),
                        ],
                      ),
                    ),
                    Tab(
                      height: 60,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.menu_book_outlined, size: 24),
                          SizedBox(width: 12),
                          Text('Guides'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              const Spacer(),
              
              // Contact support
              Container(
                margin: const EdgeInsets.all(24),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Need more help?',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(
                          Icons.mail_outline,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'hydrozapservice@gmail.com',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        // Content area
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey[50],
            ),
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildFaqTab(),
                _buildGuidesTab(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        // Left sidebar with search and tabs
        Container(
          width: 350,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.primary,
                AppColors.primary.withOpacity(0.8),
                AppColors.primary.withOpacity(0.7),
              ],
            ),
          ),
          child: Column(
            children: [
              // Search bar
              Padding(
                padding: const EdgeInsets.fromLTRB(30, 40, 30, 30),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search help topics...',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    suffixIcon: _searchQuery.isNotEmpty 
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.grey),
                          onPressed: () {
                            setState(() {
                              _searchController.clear();
                              _searchQuery = '';
                            });
                          },
                        )
                      : null,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide(color: AppColors.primary.withOpacity(0.3), width: 2),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
              ),
              
              // Tab options (vertical tabs)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 30),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: Colors.white,
                  ),
                  labelColor: AppColors.primary,
                  unselectedLabelColor: Colors.white,
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 18,
                  ),
                  tabs: const [
                    Tab(
                      height: 70,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.question_answer_outlined, size: 26),
                          SizedBox(width: 14),
                          Text('FAQs'),
                        ],
                      ),
                    ),
                    Tab(
                      height: 70,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.menu_book_outlined, size: 26),
                          SizedBox(width: 14),
                          Text('Guides'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              const Spacer(),
              
              // Contact support
              Container(
                margin: const EdgeInsets.all(30),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Need more help?',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Our support team is ready to assist you with any questions.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.mail_outline,
                            color: AppColors.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'hydrozapservice@gmail.com',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
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
        ),
        
        // Content area (with some additional padding for desktop)
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey[50],
            ),
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildFaqTab(),
                _buildGuidesTab(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFaqTab() {
    // All FAQ sections
    final List<Map<String, dynamic>> allSections = [
      {
        'title': 'Account & Login',
        'faqs': [
          {
            'question': 'How do I reset my password?',
            'answer': 'Go to the login screen and tap "Forgot Password". Enter your email address, and we\'ll send you a link to reset your password. Follow the instructions in the email to create a new password.'
          },
          {
            'question': 'Why do I need to verify my email?',
            'answer': 'Email verification helps secure your account and ensures we can contact you with important system alerts and notifications. It also allows you to recover your account if you forget your password.'
          },
        ],
      },
      {
        'title': 'System Setup',
        'faqs': [
          {
            'question': 'How do I connect my HydroZap device to WiFi?',
            'answer': 'Power on your HydroZap device and navigate to the Devices section in the app. Tap "Add New Device" and follow the on-screen instructions. You\'ll need to select your WiFi network and enter your password. The app will guide you through the complete setup process.'
          },
          {
            'question': 'What sensors are supported?',
            'answer': 'HydroZap supports a wide range of sensors including pH, EC/TDS, temperature, humidity, water level, and dissolved oxygen sensors. Check the "Compatible Sensors" section in the Device Settings for a complete and updated list.'
          },
        ],
      },
      {
        'title': 'Troubleshooting',
        'faqs': [
          {
            'question': 'Why am I not getting notifications?',
            'answer': 'First, check that notifications are enabled in your device settings. In the app, go to Settings > Notifications to verify that the types of alerts you want to receive are turned on. If you\'re still having issues, try reinstalling the app or contact support.'
          },
          {
            'question': 'The pH readings seem off — what should I do?',
            'answer': 'If your pH readings seem inaccurate, you may need to calibrate your pH sensor. Go to Devices > Select your device > Sensor Settings > pH Sensor > Calibrate. Follow the on-screen instructions using standard pH calibration solutions. If problems persist, the sensor may need replacement.'
          },
          {
            'question': 'How do I recalibrate my EC sensor?',
            'answer': 'To recalibrate your EC sensor, go to Devices > Select your device > Sensor Settings > EC Sensor > Calibrate. You\'ll need EC calibration solution (typically 1.413 mS/cm). Follow the step-by-step instructions in the app to complete the calibration process.'
          },
        ],
      },
      {
        'title': 'App Features',
        'faqs': [
          {
            'question': 'How do I create a custom grow profile?',
            'answer': 'To create a custom grow profile, go to Grow Profiles > Create New. Give your profile a name and select the plant type. You can then customize nutrient schedules, light cycles, and environmental parameters. Save your profile to apply it to current or future grows.'
          },
          {
            'question': 'What do the crop suggestions mean?',
            'answer': 'Crop suggestions are AI-powered recommendations based on your system setup, growing conditions, and past results. They indicate which plants are likely to thrive in your specific environment. Suggestions consider factors like available space, light levels, temperature range, and water quality.'
          },
        ],
      }
    ];

    // Filter FAQs based on search query
    List<Map<String, dynamic>> filteredSections = [];
    if (_searchQuery.isEmpty) {
      filteredSections = allSections;
    } else {
      // Search in questions and answers
      for (var section in allSections) {
        List<Map<String, String>> filteredFaqs = [];
        for (var faq in section['faqs']) {
          if (faq['question'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
              faq['answer'].toString().toLowerCase().contains(_searchQuery.toLowerCase())) {
            filteredFaqs.add(faq as Map<String, String>);
          }
        }
        if (filteredFaqs.isNotEmpty) {
          filteredSections.add({
            'title': section['title'],
            'faqs': filteredFaqs,
          });
        }
      }
    }

    if (filteredSections.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'No results found for "$_searchQuery"',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try different keywords or check the guides tab',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Only show header when not searching
          if (_searchQuery.isEmpty) ... [
            const SizedBox(height: 8),
            const Center(
              child: Text(
                'Frequently Asked Questions',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Container(
                width: 70,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Find answers to common questions about using your HydroZap system and app.',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
          ],
          
          // Showing search results count when searching
          if (_searchQuery.isNotEmpty) ... [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'Found ${filteredSections.fold(0, (sum, section) => sum + (section['faqs'] as List).length)} results for "$_searchQuery"',
                style: TextStyle(
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey[600],
                ),
              ),
            ),
          ],
          
          // FAQ sections
          ...filteredSections.map((section) => _buildFaqSection(
            section['title'],
            List<Map<String, String>>.from(section['faqs']),
          )),
          
          const SizedBox(height: 30),
          Container(
            padding: const EdgeInsets.all(24),
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primary.withOpacity(0.9),
                  AppColors.primary.withOpacity(0.7),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                const Text(
                  'Can\'t find what you\'re looking for?',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.mail_outline,
                        color: AppColors.primary,
                        size: 22,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'hydrozapservice@gmail.com',
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildGuidesTab() {
    final List<Map<String, dynamic>> guides = [
      {
        'title': 'Setting up your HydroZap device',
        'icon': Icons.settings_suggest_outlined,
        'color': const Color(0xFF2196F3), // Blue
        'steps': [
          'Unbox your HydroZap controller and connect power adapter',
          'Place sensors in your hydroponic system according to marked positions',
          'Power on the device using the side button',
          'Download the HydroZap app from your app store',
          'Create an account and follow the in-app setup wizard'
        ]
      },
      {
        'title': 'Connecting to Wi-Fi using SoftAP',
        'icon': Icons.wifi_outlined,
        'color': const Color(0xFF9C27B0), // Purple
        'steps': [
          'Press and hold the Wi-Fi button on your device for 5 seconds',
          'Open your phone\'s Wi-Fi settings',
          'Connect to the "HydroZap-Setup" network',
          'Return to the app and follow prompts to enter your home Wi-Fi credentials'
        ]
      },
      {
        'title': 'Configuring pumps and sensors',
        'icon': Icons.settings_input_component_outlined,
        'color': const Color(0xFFFF9800), // Orange
        'steps': [
          'Go to the Devices tab in the app',
          'Select your HydroZap controller',
          'Tap "Configure Accessories"',
          'Select which ports have pumps connected',
          'Configure dosing amounts and schedules',
          'Select and calibrate your connected sensors'
        ]
      },
      {
        'title': 'Monitoring your system in real time',
        'icon': Icons.monitor_heart_outlined,
        'color': const Color(0xFF4CAF50), // Green
        'steps': [
          'Navigate to the Dashboard tab',
          'View real-time readings for pH, EC, temperature',
          'Set up alert thresholds for each parameter',
          'Enable notifications for important events',
          'Use the timeline view to track historical data'
        ]
      },
      {
        'title': 'Setting up crop preferences',
        'icon': Icons.eco_outlined,
        'color': const Color(0xFF009688), // Teal
        'steps': [
          'Go to the Grow Profiles tab',
          'Tap "Create New Profile"',
          'Select your crop type from the database',
          'Customize nutrient targets if needed',
          'Set growth stage and expected harvest date',
          'Apply profile to your active system'
        ]
      },
    ];

    // Filter guides based on search query
    List<Map<String, dynamic>> filteredGuides = _searchQuery.isEmpty
        ? guides
        : guides.where((guide) {
            return guide['title'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
                guide['steps'].any((step) => step.toString().toLowerCase().contains(_searchQuery.toLowerCase()));
          }).toList();

    if (filteredGuides.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'No guides found for "$_searchQuery"',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try different keywords or check the FAQs tab',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Only show header when not searching
          if (_searchQuery.isEmpty) ... [
            const SizedBox(height: 8),
            const Center(
              child: Text(
                'Step-by-Step Guides',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Container(
                width: 70,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Follow these guides to get the most out of your HydroZap system.',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
          ],
          
          // Showing search results count when searching
          if (_searchQuery.isNotEmpty) ... [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'Found ${filteredGuides.length} guides for "$_searchQuery"',
                style: TextStyle(
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey[600],
                ),
              ),
            ),
          ],
          
          // Guides
          ...filteredGuides.map((guide) => _buildGuideCard(
            title: guide['title'],
            icon: guide['icon'],
            color: guide['color'],
            steps: List<String>.from(guide['steps']),
          )),
          
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildGuideCard({
    required String title,
    required IconData icon,
    required Color color,
    required List<String> steps,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24, left: 16, right: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Theme(
          data: Theme.of(context).copyWith(
            dividerColor: Colors.transparent,
          ),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.all(0),
            childrenPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 24),
            collapsedBackgroundColor: Colors.white,
            backgroundColor: Colors.white,
            expandedAlignment: Alignment.topLeft,
            title: Container(
              padding: const EdgeInsets.all(0),
              child: Column(
                children: [
                  // Premium-style header
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          color,
                          color.withOpacity(0.8),
                        ],
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.3),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            icon,
                            color: Colors.white,
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.3),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.keyboard_arrow_down,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            trailing: const SizedBox.shrink(),
            children: [
              const SizedBox(height: 16),
              ...List.generate(steps.length, (index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 30,
                        height: 30,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.9),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: color.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 5),
                          child: Text(
                            steps[index],
                            style: const TextStyle(
                              fontSize: 16,
                              height: 1.5,
                              color: Color(0xFF212121),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFaqSection(String title, List<Map<String, String>> faqs) {
    Color sectionColor = _getSectionColor(title);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 25),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  sectionColor.withOpacity(0.8),
                  sectionColor.withOpacity(0.6),
                ],
              ),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getSectionIcon(title),
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        ...faqs.map((faq) => _buildExpandableFaqItem(faq['question']!, faq['answer']!, sectionColor)),
      ],
    );
  }

  IconData _getSectionIcon(String section) {
    switch (section) {
      case 'Account & Login':
        return Icons.account_circle_outlined;
      case 'System Setup':
        return Icons.settings_outlined;
      case 'Troubleshooting':
        return Icons.help_outline;
      case 'App Features':
        return Icons.smartphone_outlined;
      default:
        return Icons.info_outline;
    }
  }
  
  Color _getSectionColor(String section) {
    switch (section) {
      case 'Account & Login':
        return const Color(0xFF3F51B5); // Indigo
      case 'System Setup':
        return const Color(0xFF009688); // Teal
      case 'Troubleshooting':
        return const Color(0xFFE91E63); // Pink
      case 'App Features':
        return const Color(0xFF4CAF50); // Green
      default:
        return AppColors.primary;
    }
  }

  Widget _buildExpandableFaqItem(String question, String answer, Color sectionColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16, left: 16, right: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Theme(
          data: Theme.of(context).copyWith(
            dividerColor: Colors.transparent,
          ),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            title: Text(
              question,
              style: const TextStyle(
                fontSize: 16, 
                fontWeight: FontWeight.w600,
                color: Color(0xFF212121),
              ),
            ),
            iconColor: sectionColor,
            collapsedIconColor: Colors.grey[600],
            backgroundColor: Colors.white,
            collapsedBackgroundColor: Colors.white,
            childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            expandedCrossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Divider(color: Colors.grey[200], height: 1),
              const SizedBox(height: 16),
              Text(
                answer,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey[800],
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 