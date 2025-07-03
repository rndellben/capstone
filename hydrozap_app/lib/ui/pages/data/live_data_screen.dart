import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:hydrozap_app/core/models/device_model.dart';
import 'package:hydrozap_app/providers/device_provider.dart';
import 'package:hydrozap_app/ui/widgets/metric_card.dart';
import 'package:hydrozap_app/core/constants/app_colors.dart';
import 'package:hydrozap_app/ui/widgets/responsive_widget.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:open_file/open_file.dart';
import 'package:hydrozap_app/core/api/endpoints.dart';
import 'dart:math';

class LiveDataScreen extends StatefulWidget {
  final DeviceModel device;

  const LiveDataScreen({super.key, required this.device});

  @override
  State<LiveDataScreen> createState() => _LiveDataScreenState();
}

class _LiveDataScreenState extends State<LiveDataScreen> {
  // Data points for each sensor (last 60 seconds of data)
  final List<FlSpot> _temperatureData = [];
  final List<FlSpot> _ecData = [];
  final List<FlSpot> _tdsData = [];
  final List<FlSpot> _phData = [];
  
  // Store latest sensor values
  double _latestTemperature = 0.0;
  double _latestEC = 0.0;
  double _latestTDS = 0.0;
  double _latestPH = 0.0;
  
  // Timer for data refresh (simulate real-time)
  Timer? _updateTimer;
  
  // Base time for the X-axis (time in seconds)
  int _baseTime = 0;

  // Key for capturing chart image
  final GlobalKey _chartKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    // Initialize data with initial reading
    _updateSensorData(widget.device);
    
    // Set up timer to update data every second
    _updateTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      // Get the latest device data from provider
      final deviceProvider = Provider.of<DeviceProvider>(context, listen: false);
      final latestDevices = deviceProvider.devices;
      final latestDevice = latestDevices.firstWhere(
        (d) => d.id == widget.device.id,
        orElse: () => widget.device
      );
      
      _updateSensorData(latestDevice);
    });
  }
  
  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
  }
  
  void _updateSensorData(DeviceModel device) {
    if (!mounted) return;
    
    setState(() {
      // Extract latest readings from device
      final latestReadings = device.getLatestSensorReadings();
      
      // Update latest values
      _latestTemperature = (latestReadings['temperature'] as num?)?.toDouble() ?? 0.0;
      _latestEC = (latestReadings['ec'] as num?)?.toDouble() ?? 0.0;
      _latestTDS = (latestReadings['tds'] as num?)?.toDouble() ?? 0.0;
      _latestPH = (latestReadings['ph'] as num?)?.toDouble() ?? 0.0;
      
      // Add new data points
      _baseTime++;
      
      // Keep only the last 60 data points (60 seconds)
      if (_temperatureData.length >= 60) {
        _temperatureData.removeAt(0);
        _ecData.removeAt(0);
        _tdsData.removeAt(0);
        _phData.removeAt(0);
      }
      
      _temperatureData.add(FlSpot(_baseTime.toDouble(), _latestTemperature));
      _ecData.add(FlSpot(_baseTime.toDouble(), _latestEC));
      _tdsData.add(FlSpot(_baseTime.toDouble(), _latestTDS));
      _phData.add(FlSpot(_baseTime.toDouble(), _latestPH));
    });
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveWidget(
      mobile: _buildCompactLayout(),
      tablet: _buildMediumLayout(),
      desktop: _buildWideLayout(),
    );
  }
  
  Widget _buildWideLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildGenerateReportButton(),
          const SizedBox(height: 16),
          _buildSectionHeader('Real-time Sensor Readings'),
          const SizedBox(height: 16),
          _buildCurrentReadings(),
          const SizedBox(height: 24),
          _buildSectionHeader('Live Sensor Charts'),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildChart(
                  'Temperature (°C)',
                  _temperatureData,
                  AppColors.sunset,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildChart(
                  'pH Level',
                  _phData,
                  AppColors.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildChart(
                  'EC (mS/cm)',
                  _ecData,
                  AppColors.water,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildChart(
                  'TDS (ppm)',
                  _tdsData,
                  AppColors.leaf,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildMediumLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildGenerateReportButton(),
          const SizedBox(height: 16),
          _buildSectionHeader('Real-time Sensor Readings'),
          const SizedBox(height: 16),
          _buildCurrentReadings(),
          const SizedBox(height: 24),
          _buildSectionHeader('Live Sensor Charts'),
          const SizedBox(height: 16),
          _buildChart('Temperature (°C)', _temperatureData, AppColors.sunset),
          const SizedBox(height: 16),
          _buildChart('pH Level', _phData, AppColors.secondary),
          const SizedBox(height: 16),
          _buildChart('EC (mS/cm)', _ecData, AppColors.water),
          const SizedBox(height: 16),
          _buildChart('TDS (ppm)', _tdsData, AppColors.leaf),
        ],
      ),
    );
  }
  
  Widget _buildCompactLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildGenerateReportButton(),
          const SizedBox(height: 12),
          _buildSectionHeader('Real-time Sensor Readings'),
          const SizedBox(height: 12),
          _buildCurrentReadings(),
          const SizedBox(height: 20),
          _buildSectionHeader('Live Sensor Charts'),
          const SizedBox(height: 12),
          _buildChart('Temperature (°C)', _temperatureData, AppColors.sunset),
          const SizedBox(height: 16),
          _buildChart('pH Level', _phData, AppColors.secondary),
          const SizedBox(height: 16),
          _buildChart('EC (mS/cm)', _ecData, AppColors.water),
          const SizedBox(height: 16),
          _buildChart('TDS (ppm)', _tdsData, AppColors.leaf),
        ],
      ),
    );
  }
  
  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 24,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }
  
  Widget _buildGenerateReportButton() {
    return Align(
      alignment: Alignment.centerRight,
      child: ElevatedButton.icon(
        onPressed: _generatePDFReport,
        icon: const Icon(Icons.picture_as_pdf),
        label: const Text('Generate Report'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
  
  Widget _buildCurrentReadings() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.sensors, color: AppColors.primary),
                const SizedBox(width: 8),
                const Text(
                  'Current Readings',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.leaf.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.leaf.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.update, size: 14, color: AppColors.leaf),
                      const SizedBox(width: 4),
                      Text(
                        'Live',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.leaf,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 600;
                return Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: _buildSensorCards().map((card) {
                    return SizedBox(
                      width: isWide
                          ? (constraints.maxWidth - 16) / 2 // 2 columns
                          : constraints.maxWidth,           // 1 column
                      child: card,
                    );
                  }).toList(),
                );
              }
            ),
          ],
        ),
      ),
    );
  }
  
  List<Widget> _buildSensorCards() {
    return [
      MetricCard(
        title: "Temperature",
        value: "${_latestTemperature.toStringAsFixed(1)}°C",
        icon: Icons.thermostat,
        iconColor: AppColors.sunset,
      ),
      MetricCard(
        title: "pH Level",
        value: _latestPH.toStringAsFixed(2),
        icon: Icons.science_outlined,
        iconColor: AppColors.secondary,
      ),
      MetricCard(
        title: "EC Level",
        value: "${_latestEC.toStringAsFixed(2)} mS/cm",
        icon: Icons.bolt_outlined,
        iconColor: AppColors.water,
      ),
      MetricCard(
        title: "TDS Level",
        value: "${_latestTDS.toStringAsFixed(1)} ppm",
        icon: Icons.opacity_outlined,
        iconColor: AppColors.leaf,
      ),
    ];
  }
  
  Widget _buildChart(String title, List<FlSpot> data, Color color) {
    final isTemperatureChart = title == 'Temperature (°C)';
    
    return Container(
      height: 250,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getIconForChart(title),
                  color: color,
                  size: 18,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: data.isEmpty 
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.hourglass_empty,
                        color: AppColors.stone.withOpacity(0.5),
                        size: 32,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Waiting for data...',
                        style: TextStyle(
                          color: AppColors.stone,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                )
              : RepaintBoundary(
                  key: isTemperatureChart ? _chartKey : null,
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: true,
                        horizontalInterval: 1,
                        verticalInterval: 10,
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: AppColors.normal.withOpacity(0.2),
                            strokeWidth: 1,
                          );
                        },
                        getDrawingVerticalLine: (value) {
                          return FlLine(
                            color: AppColors.normal.withOpacity(0.2),
                            strokeWidth: 1,
                          );
                        },
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        rightTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                            interval: 10,
                            getTitlesWidget: (value, meta) {
                              final secondsAgo = _baseTime - value.toInt();
                              int labelIndex = value ~/ 10;
                              int totalLabels = ((data.isNotEmpty ? data.last.x : 60) / 10).round();
                              if (totalLabels > 7 && labelIndex % 2 != 0) {
                                return Container();
                              }
                              return Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  secondsAgo <= 0 ? 'now' : '-${secondsAgo}s',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: _getLiveChartYInterval(data),
                            getTitlesWidget: (value, meta) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 12),
                                child: Text(
                                  value.toStringAsFixed(1),
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              );
                            },
                            reservedSize: 48,
                          ),
                        ),
                      ),
                      borderData: FlBorderData(
                        show: true,
                        border: Border.all(color: AppColors.normal.withOpacity(0.3), width: 1),
                      ),
                      minX: data.isNotEmpty ? (data.first.x) : 0,
                      maxX: data.isNotEmpty ? (data.last.x) : 60,
                      minY: data.isNotEmpty 
                          ? (data.map((e) => e.y).reduce((a, b) => a < b ? a : b) - 1) 
                          : 0,
                      maxY: data.isNotEmpty 
                          ? (data.map((e) => e.y).reduce((a, b) => a > b ? a : b) + 1) 
                          : 10,
                      lineBarsData: [
                        LineChartBarData(
                          spots: data,
                          isCurved: true,
                          barWidth: 3,
                          isStrokeCapRound: true,
                          color: color,
                          belowBarData: BarAreaData(
                            show: true,
                            color: color.withOpacity(0.2),
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                color.withOpacity(0.4),
                                color.withOpacity(0.1),
                                color.withOpacity(0.0),
                              ],
                            ),
                          ),
                          dotData: FlDotData(
                            show: false,
                            getDotPainter: (spot, percent, barData, index) {
                              if (index == data.length - 1) {
                                return FlDotCirclePainter(
                                  radius: 4,
                                  color: color,
                                  strokeWidth: 2,
                                  strokeColor: Colors.white,
                                );
                              }
                              return FlDotCirclePainter(
                                radius: 0,
                                color: Colors.transparent,
                                strokeWidth: 0,
                                strokeColor: Colors.transparent,
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
          ),
        ],
      ),
    );
  }

  IconData _getIconForChart(String title) {
    if (title.contains('Temperature')) {
      return Icons.thermostat;
    } else if (title.contains('pH')) {
      return Icons.science_outlined;
    } else if (title.contains('EC')) {
      return Icons.bolt_outlined;
    } else if (title.contains('TDS')) {
      return Icons.opacity_outlined;
    }
    return Icons.show_chart;
  }

  Future<void> _generatePDFReport() async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );
       final url = Uri.parse(ApiEndpoints.generateReport);

      // Prepare request body
      final body = {
        'user_id': widget.device.userId,
        'device_id': widget.device.id,
      };

      // Make API call
      final response = await http.post(
       url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/pdf',
        },
        body: jsonEncode(body),
      );

      // Hide loading indicator
      Navigator.pop(context);

      if (response.statusCode == 200) {
        // Get temporary directory
        final directory = await getTemporaryDirectory();
        final filePath = '${directory.path}/hydrozap_report.pdf';
        
        // Save PDF file
        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);
        
        // Open PDF file
        await OpenFile.open(filePath);
      } else {
        // Show error message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to generate PDF report: ${response.statusCode}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      // Hide loading indicator if still showing
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating PDF report: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  double _getLiveChartYInterval(List<FlSpot> data) {
    if (data.isEmpty) return 1;
    double minY = data.map((e) => e.y).reduce((a, b) => a < b ? a : b);
    double maxY = data.map((e) => e.y).reduce((a, b) => a > b ? a : b);
    double range = maxY - minY;
    if (range == 0) return 1;
    double roughInterval = range / 5; // Aim for ~5 labels
    double magnitude = pow(10, (log(roughInterval) / ln10).floor()).toDouble();
    double niceInterval = (roughInterval / magnitude).ceil() * magnitude;
    return niceInterval;
  }
} 