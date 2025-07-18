import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/models/performance_matrix_model.dart';
import '../../../providers/performance_matrix_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../widgets/responsive_widget.dart';
import '../../widgets/app_drawer.dart';
import 'performance_matrix_page.dart';
import '../harvest/harvest_log_page.dart';
import '../../../providers/device_provider.dart';

class PerformanceResultsPage extends StatefulWidget {
  final String userId;
  
  const PerformanceResultsPage({super.key, required this.userId});

  @override
  State<PerformanceResultsPage> createState() => _PerformanceResultsPageState();
}

class _PerformanceResultsPageState extends State<PerformanceResultsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _selectedResultId;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // Initialize the provider if needed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<PerformanceMatrixProvider>(context, listen: false);
      if (provider.currentMatrix == null) {
        provider.initializeDefaultMatrix();
      }
      
      // Load real harvest data
      _loadHarvestData(provider);
    });
  }
  
  Future<void> _loadHarvestData(PerformanceMatrixProvider provider) async {
    // Get the device ID from the DeviceProvider
    final deviceProvider = Provider.of<DeviceProvider>(context, listen: false);
    await deviceProvider.fetchDevices(widget.userId);
    
    if (deviceProvider.devices.isEmpty) {
      print('No devices found for user ${widget.userId}');
      return;
    }

    // Use the new method to fetch and aggregate harvest data from all devices
    final deviceIds = deviceProvider.devices.map((device) => device.id).toList();
    await provider.fetchHarvestDataFromMultipleDevices(deviceIds);
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ResponsiveWidget.isDesktop(context)
          ? PreferredSize(
              preferredSize: const Size.fromHeight(50),
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.leaf, AppColors.forest],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: AppBar(
                  title: const Text(
                    'Performance Results',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  toolbarHeight: 50,
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.public, size: 20),
                      tooltip: 'Global Leaderboard',
                      onPressed: () {
                        Navigator.pushNamed(
                          context,
                          '/global-leaderboard',
                          arguments: widget.userId,
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.tune, size: 20),
                      tooltip: 'Configure Matrix',
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PerformanceMatrixPage(userId: widget.userId),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
              ),
            )
          : PreferredSize(
              preferredSize: const Size.fromHeight(kToolbarHeight + 48),
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.leaf, AppColors.forest],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: AppBar(
                  title: const Text(
                    'Performance Results',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.public),
                      tooltip: 'Global Leaderboard',
                      onPressed: () {
                        Navigator.pushNamed(
                          context,
                          '/global-leaderboard',
                          arguments: widget.userId,
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.tune),
                      tooltip: 'Configure Matrix',
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PerformanceMatrixPage(userId: widget.userId),
                          ),
                        );
                      },
                    ),
                  ],
                  bottom: TabBar(
                    controller: _tabController,
                    indicatorColor: AppColors.leaf,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white.withOpacity(0.7),
                    tabs: const [
                      Tab(text: 'All Results'),
                      Tab(text: 'Top Performers'),
                    ],
                  ),
                ),
              ),
            ),
      drawer: ResponsiveWidget.isDesktop(context) ? null : AppDrawer(userId: widget.userId),
      body: Consumer<PerformanceMatrixProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppColors.leaf),
                  const SizedBox(height: 16),
                  Text(
                    'Loading harvest data...',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            );
          }
          
          return ResponsiveWidget(
            mobile: _buildMobileLayout(),
            tablet: _buildTabletLayout(),
            desktop: _buildDesktopLayout(),
          );
        },
      ),
    );
  }
  
  Widget _buildMobileLayout() {
    return Column(
      children: [
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildResultsList(false),
              _buildResultsList(true),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTabletLayout() {
    return Column(
      children: [
        Expanded(
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildResultsList(false),
                    _buildResultsList(true),
                  ],
                ),
              ),
              Expanded(
                flex: 3,
                child: _selectedResultId != null
                    ? _buildResultDetails(_selectedResultId!)
                    : _buildNoSelectionPlaceholder(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopLayout() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildMatrixSummary(),
          const SizedBox(height: 8),
          
          // Tab bar
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: AppColors.forest.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorColor: AppColors.leaf,
              labelColor: AppColors.forest,
              unselectedLabelColor: Colors.grey[600],
              indicatorSize: TabBarIndicatorSize.label,
              tabs: const [
                Tab(
                  icon: Icon(Icons.list_alt, size: 20),
                  text: 'All Results',
                ),
                Tab(
                  icon: Icon(Icons.emoji_events, size: 20),
                  text: 'Top Performers',
                ),
              ],
            ),
          ),
          
          // Content area
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Results list
                Expanded(
                  flex: 2,
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 2,
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildResultsList(false),
                        _buildResultsList(true),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // Details panel
                Expanded(
                  flex: 3,
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 2,
                    child: _selectedResultId != null
                        ? _buildResultDetails(_selectedResultId!)
                        : _buildNoSelectionPlaceholder(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildMatrixSummary() {
    return Consumer<PerformanceMatrixProvider>(
      builder: (context, provider, child) {
        final matrix = provider.currentMatrix;
        final selectedMetrics = matrix?.selectedMetrics ?? [];
        
        return Card(
          margin: const EdgeInsets.fromLTRB(0, 0, 0, 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 1,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Matrix info
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.forest.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.insights,
                          color: AppColors.forest,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            matrix?.name ?? 'Performance Matrix',
                            style: TextStyle(
                              color: AppColors.forest,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          if (selectedMetrics.isEmpty)
                            Text(
                              'No active metrics',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Active metrics display
                if (selectedMetrics.isNotEmpty)
                  Expanded(
                    flex: 2,
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.end,
                      children: selectedMetrics.take(4).map((metric) {
                        final isGrowth = metric.category == 'growth';
                        final primaryColor = isGrowth ? AppColors.forest : AppColors.moss;
                        
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: primaryColor.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isGrowth ? Icons.trending_up : Icons.star_outline,
                                color: primaryColor,
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                metric.name,
                                style: TextStyle(
                                  color: primaryColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                
                // Configure button  
                OutlinedButton.icon(
                  icon: const Icon(Icons.tune, size: 16),
                  label: const Text('Configure', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                    minimumSize: const Size(0, 32),
                    foregroundColor: AppColors.leaf,
                    side: BorderSide(color: AppColors.leaf),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PerformanceMatrixPage(userId: widget.userId),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildResultsList(bool topPerformersOnly) {
    return Consumer<PerformanceMatrixProvider>(
      builder: (context, provider, child) {
        final results = topPerformersOnly
            ? provider.topPerformers
            : provider.harvestResults;
        
        if (results.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  topPerformersOnly ? Icons.emoji_events_outlined : Icons.science_outlined,
                  size: 64,
                  color: Colors.grey[300],
                ),
                const SizedBox(height: 16),
                Text(
                  topPerformersOnly
                      ? 'No top performers identified yet'
                      : 'No harvest results recorded yet',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          );
        }
        
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: results.length,
          itemBuilder: (context, index) {
            final result = results[index];
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: _selectedResultId == result.id
                      ? AppColors.forest
                      : (result.isTopPerformer
                          ? AppColors.leaf.withOpacity(0.3)
                          : Colors.transparent),
                  width: _selectedResultId == result.id ? 2 : 1,
                ),
              ),
              elevation: _selectedResultId == result.id ? 3 : 1,
              child: InkWell(
                onTap: () {
                  setState(() {
                    _selectedResultId = result.id;
                  });
                  
                  // If on mobile, navigate to detail page
                  if (ResponsiveWidget.isMobile(context)) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => _buildResultDetailPage(result.id),
                      ),
                    );
                  }
                },
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: AppColors.forest.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Icon(
                                      Icons.spa,
                                      size: 20,
                                      color: AppColors.forest,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        result.plantId,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Harvest ID: ${result.harvestId}',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (result.isTopPerformer)
                            Container(
                              margin: const EdgeInsets.only(left: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.leaf.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: AppColors.leaf.withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.star,
                                    color: AppColors.leaf,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Top Performer',
                                    style: TextStyle(
                                      color: AppColors.leaf,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 14,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Harvested: ${DateFormat('MMM d, yyyy').format(result.harvestDate)}',
                              style: TextStyle(
                                color: Colors.grey[700],
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildResultMetricsSummary(result, provider),
                      const SizedBox(height: 10),
                      if (result.totalScore != null)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.forest.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.score,
                                    color: AppColors.forest,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Score: ${(result.totalScore! * 100).toStringAsFixed(1)}%',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.forest,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
  
  Widget _buildResultMetricsSummary(
    HarvestResult result, 
    PerformanceMatrixProvider provider,
  ) {
    final matrix = provider.currentMatrix;
    if (matrix == null) return const SizedBox();
    
    // Get top 3 or fewer selected metrics
    final metrics = matrix.selectedMetrics.take(3).toList();
    
    if (metrics.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            Icon(
              Icons.info_outline,
              size: 14,
              color: Colors.grey[600],
            ),
            const SizedBox(width: 8),
            Text(
              'No active metrics',
              style: TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: metrics.map((metric) {
          final value = result.metricValues[metric.id] ?? 0.0;
          final isGrowth = metric.category == 'growth';
          final primaryColor = isGrowth ? AppColors.forest : AppColors.moss;
          
          return Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isGrowth ? Icons.trending_up : Icons.star_outline,
                  color: primaryColor,
                  size: 12,
                ),
                const SizedBox(width: 6),
                Text(
                  '${metric.name}: ${value.toStringAsFixed(1)} ${metric.unit}',
                  style: TextStyle(
                    fontSize: 12,
                    color: primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
  
  Widget _buildNoSelectionPlaceholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.forest.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.touch_app_outlined,
              size: 56,
              color: AppColors.forest.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Select a result to view details',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.forest,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Click on any result from the list to see detailed performance metrics',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
  
  Widget _buildResultDetailPage(String resultId) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Result Details'),
        backgroundColor: AppColors.forest,
        foregroundColor: Colors.white,
      ),
      body: _buildResultDetails(resultId),
    );
  }
  
  Widget _buildResultDetails(String resultId) {
    return Consumer<PerformanceMatrixProvider>(
      builder: (context, provider, child) {
        final details = provider.getPerformanceDetails(resultId);
        
        if (details.isEmpty) {
          return Center(
            child: Text(
              'Result not found',
              style: TextStyle(color: Colors.grey[600]),
            ),
          );
        }
        
        final result = details['result'] as HarvestResult;
        final metricDetails = details['metricDetails'] as List<Map<String, dynamic>>;
        
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    color: AppColors.forest.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Icon(
                                      Icons.spa,
                                      size: 28,
                                      color: AppColors.forest,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        result.plantId,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 22,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Harvest ID: ${result.harvestId}',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (result.isTopPerformer)
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.leaf.withOpacity(0.1),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.leaf,
                                  width: 2,
                                ),
                              ),
                              child: Icon(
                                Icons.emoji_events,
                                color: AppColors.leaf,
                                size: 28,
                              ),
                            ),
                        ],
                      ),
                      const Divider(height: 40, thickness: 1),
                      Row(
                        children: [
                          Expanded(
                            child: _buildInfoItem(
                              'Harvest Date',
                              DateFormat('MMMM d, yyyy').format(result.harvestDate),
                              Icons.calendar_today,
                              AppColors.forest,
                            ),
                          ),
                          const SizedBox(width: 32),
                          Expanded(
                            child: _buildInfoItem(
                              'Performance Score',
                              result.totalScore != null
                                  ? '${(result.totalScore! * 100).toStringAsFixed(1)}%'
                                  : 'N/A',
                              Icons.score,
                              AppColors.leaf,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.forest.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.analytics,
                      color: AppColors.forest,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Performance Details',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.forest,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildPerformanceMetricsCard(metricDetails),
              const SizedBox(height: 28),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.moss.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.pie_chart,
                      color: AppColors.moss,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Metric Breakdown',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.moss,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildMetricDetailsCards(metricDetails),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildInfoItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: color,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildPerformanceMetricsCard(List<Map<String, dynamic>> metricDetails) {
    // Filter to only include active metrics
    final activeMetricDetails = metricDetails
        .where((detail) => (detail['metric'] as PerformanceMetric).isSelected)
        .toList();
    
    if (activeMetricDetails.isEmpty) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: Column(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Colors.grey[400],
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  'No active metrics selected',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Enable metrics in the Performance Matrix Configuration',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ...activeMetricDetails.map((detail) {
              final metric = detail['metric'] as PerformanceMetric;
              final value = detail['value'] as double;
              final score = detail['score'] as double;
              final contribution = detail['contribution'] as double;
              
              final isGrowth = metric.category == 'growth';
              final primaryColor = isGrowth ? AppColors.forest : AppColors.moss;
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            metric.name,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: primaryColor,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${value.toStringAsFixed(1)} ${metric.unit}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: score,
                              backgroundColor: Colors.grey[200],
                              color: primaryColor,
                              minHeight: 8,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 40,
                          child: Text(
                            '${(score * 100).toStringAsFixed(0)}%',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Weight: ${metric.weight.toStringAsFixed(1)} • Contribution: ${(contribution * 100).toStringAsFixed(0)}%',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[500],
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
  
  Widget _buildMetricDetailsCards(List<Map<String, dynamic>> metricDetails) {
    // Filter to only include active metrics
    final activeMetricDetails = metricDetails
        .where((detail) => (detail['metric'] as PerformanceMetric).isSelected)
        .toList();
    
    if (activeMetricDetails.isEmpty) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Column(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Colors.grey[400],
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  'No active metrics selected',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Configure your performance metrics in the Performance Matrix page',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }
    
    return LayoutBuilder(
      builder: (context, constraints) {
        // Adjust crossAxisCount based on available width
        final crossAxisCount = constraints.maxWidth > 600 ? 2 : 1;
        
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: 1.8,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: activeMetricDetails.length,
          itemBuilder: (context, index) {
            final detail = activeMetricDetails[index];
            final metric = detail['metric'] as PerformanceMetric;
            final value = detail['value'] as double;
            final score = detail['score'] as double;
            
            final isGrowth = metric.category == 'growth';
            final primaryColor = isGrowth ? AppColors.forest : AppColors.moss;
            
            return Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            metric.name,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: primaryColor,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            metric.category,
                            style: TextStyle(
                              fontSize: 10,
                              color: primaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${value.toStringAsFixed(1)} ${metric.unit}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                metric.description,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey[500],
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: score,
                              backgroundColor: Colors.grey[200],
                              color: primaryColor,
                              minHeight: 6,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${(score * 100).toStringAsFixed(0)}%',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
} 