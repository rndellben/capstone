import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:hydrozap_app/core/models/device_model.dart';
import 'package:hydrozap_app/providers/device_provider.dart';
import 'package:hydrozap_app/core/constants/app_colors.dart';
import 'package:hydrozap_app/ui/widgets/responsive_widget.dart';
import 'package:hydrozap_app/core/api/api_service.dart';
import 'dart:math';
import 'package:hydrozap_app/core/utils/logger.dart';

class HistoricalDataScreen extends StatefulWidget {
  final DeviceModel device;

  const HistoricalDataScreen({super.key, required this.device});

  @override
  State<HistoricalDataScreen> createState() => _HistoricalDataScreenState();
}

class _HistoricalDataScreenState extends State<HistoricalDataScreen> {
  // API service for fetching data
  final ApiService _apiService = ApiService();
  
  // Selected date range
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime _endDate = DateTime.now();
  
  // Selected sensor type
  String _selectedSensorType = 'temperature';
  
  // Historical data points
  List<FlSpot> _historicalData = [];
  
  // Loading state
  bool _isLoading = false;
  
  // Error state
  String? _errorMessage;
  
  // Time range options
  final List<String> _timeRangeOptions = [
    'Last 24 Hours',
    'Last 7 Days',
    'Last 30 Days',
    'Custom Range'
  ];
  
  String _selectedTimeRange = 'Last 7 Days';
  
  // Sensor type options with labels
  final Map<String, String> _sensorTypes = {
    'temperature': 'Temperature',
    'ph': 'pH Level',
    'ec': 'EC Level',
    'tds': 'TDS Level',
  };

  // Colors for each sensor type
  final Map<String, Color> _sensorColors = {
    'temperature': AppColors.sunset,
    'ph': AppColors.secondary,
    'ec': AppColors.water,
    'tds': AppColors.leaf,
  };
  
  @override
  void initState() {
    super.initState();
    // Initial load of historical data
    _loadHistoricalData();
  }
  
  Future<void> _loadHistoricalData() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      // Fetch historical data from the API
      final historicalData = await _apiService.getHistoricalSensorData(
        widget.device.id,
        _startDate,
        _endDate,
        _selectedSensorType
      );
      
      if (historicalData.isEmpty || historicalData[_selectedSensorType]?.isEmpty == true) {
        setState(() {
          _historicalData = [];
          _isLoading = false;
          _errorMessage = 'No data available for the selected time period';
        });
        return;
      }
      
      // Convert to FlSpot for the chart
      final dataPoints = <FlSpot>[];
      
      for (final point in historicalData[_selectedSensorType]!) {
        dataPoints.add(FlSpot(
          point['timestamp'].toDouble(),
          point['value'].toDouble(),
        ));
      }
      
      if (mounted) {
        setState(() {
          _historicalData = dataPoints;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _historicalData = [];
          _isLoading = false;
          _errorMessage = 'Error loading data: ${e.toString()}';
        });
      }
      logger.e('Error loading historical data: $e');
    }
  }
  
  void _updateTimeRange(String value) {
    if (value == _selectedTimeRange) return;
    
    setState(() {
      _selectedTimeRange = value;
      
      // Update date range based on selection
      switch (value) {
        case 'Last 24 Hours':
          _endDate = DateTime.now();
          _startDate = _endDate.subtract(const Duration(hours: 24));
          break;
        case 'Last 7 Days':
          _endDate = DateTime.now();
          _startDate = _endDate.subtract(const Duration(days: 7));
          break;
        case 'Last 30 Days':
          _endDate = DateTime.now();
          _startDate = _endDate.subtract(const Duration(days: 30));
          break;
        case 'Custom Range':
          // Will be handled by date picker
          _showDateRangePicker();
          return;
      }
      
      // Reload data with new time range
      _loadHistoricalData();
    });
  }
  
  Future<void> _showDateRangePicker() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(
        start: _startDate,
        end: _endDate,
      ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
              ),
            ), dialogTheme: DialogThemeData(backgroundColor: Colors.white),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _loadHistoricalData();
    }
  }
  
  void _changeSensorType(String? type) {
    if (type != null && type != _selectedSensorType) {
      setState(() {
        _selectedSensorType = type;
      });
      _loadHistoricalData();
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWideScreen = constraints.maxWidth > 900;
        final isMobileScreen = constraints.maxWidth < 600;
        
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader('Historical Data Analysis'),
              const SizedBox(height: 16),
              _buildFilterSection(isWideScreen),
              const SizedBox(height: 24),
              Expanded(
                child: _isLoading 
                  ? const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                      ),
                    )
                  : _buildHistoricalChart(isMobileScreen),
              ),
            ],
          ),
        );
      }
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
  
  Widget _buildFilterSection(bool isWideScreen) {
    if (isWideScreen) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.timer, size: 16, color: AppColors.primary),
                        const SizedBox(width: 8),
                        const Text(
                          'Time Range',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _buildTimeRangeSelector(),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.sensors, size: 16, color: AppColors.primary),
                        const SizedBox(width: 8),
                        const Text(
                          'Sensor Type',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _buildSensorTypeSelector(),
                  ],
                ),
              ),
              if (_selectedTimeRange == 'Custom Range') ...[
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.calendar_today, size: 16, color: AppColors.primary),
                          const SizedBox(width: 8),
                          const Text(
                            'Date Range',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _buildDateRangeDisplay(),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    } else {
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
                  Icon(Icons.timer, size: 16, color: AppColors.primary),
                  const SizedBox(width: 8),
                  const Text(
                    'Time Range',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _buildTimeRangeSelector(),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.sensors, size: 16, color: AppColors.primary),
                  const SizedBox(width: 8),
                  const Text(
                    'Sensor Type',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _buildSensorTypeSelector(),
              if (_selectedTimeRange == 'Custom Range') ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 16, color: AppColors.primary),
                    const SizedBox(width: 8),
                    const Text(
                      'Date Range',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _buildDateRangeDisplay(),
              ],
            ],
          ),
        ),
      );
    }
  }
  
  Widget _buildTimeRangeSelector() {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.normal.withOpacity(0.5)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.normal.withOpacity(0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.primary),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      value: _selectedTimeRange,
      icon: Icon(Icons.arrow_drop_down, color: AppColors.primary),
      items: _timeRangeOptions.map((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textPrimary,
            ),
          ),
        );
      }).toList(),
      onChanged: (String? newValue) {
        if (newValue != null) {
          _updateTimeRange(newValue);
        }
      },
    );
  }
  
  Widget _buildSensorTypeSelector() {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.normal.withOpacity(0.5)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.normal.withOpacity(0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.primary),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      value: _selectedSensorType,
      icon: Icon(Icons.arrow_drop_down, color: AppColors.primary),
      items: _sensorTypes.entries.map((entry) {
        final Color sensorColor = _sensorColors[entry.key] ?? AppColors.primary;
        return DropdownMenuItem<String>(
          value: entry.key,
          child: Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: sensorColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                entry.value,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        );
      }).toList(),
      onChanged: _changeSensorType,
    );
  }
  
  Widget _buildDateRangeDisplay() {
    final DateFormat formatter = DateFormat('MMM d, yyyy');
    
    return GestureDetector(
      onTap: _showDateRangePicker,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.normal.withOpacity(0.5)),
          borderRadius: BorderRadius.circular(8),
          color: Colors.white,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                '${formatter.format(_startDate)} - ${formatter.format(_endDate)}',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            Icon(Icons.calendar_today_outlined, color: AppColors.primary, size: 18),
          ],
        ),
      ),
    );
  }
  
  Widget _buildHistoricalChart([bool isMobileScreen = false]) {
    // Get appropriate color for the chart based on sensor type
    Color chartColor = _sensorColors[_selectedSensorType] ?? AppColors.primary;
    
    // Get appropriate title based on sensor type
    String chartTitle = _sensorTypes[_selectedSensorType] ?? 'Unknown';
    String chartUnit = _selectedSensorType == 'temperature' ? '°C' :
                       _selectedSensorType == 'ph' ? '' :
                       _selectedSensorType == 'ec' ? 'mS/cm' :
                       _selectedSensorType == 'tds' ? 'ppm' : '';
    
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
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: chartColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getIconForChart(),
                    color: chartColor,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Historical $chartTitle Data',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.normal.withOpacity(0.1)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: AppColors.secondary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Data for ${widget.device.deviceName} from ${DateFormat('MMM d').format(_startDate)} to ${DateFormat('MMM d').format(_endDate)}',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _historicalData.isEmpty 
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.bar_chart_outlined,
                          size: 48,
                          color: AppColors.stone.withOpacity(0.4),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage ?? 'No data available for selected time period',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed: _loadHistoricalData,
                          icon: const Icon(Icons.refresh, size: 16),
                          label: const Text('Refresh'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : isMobileScreen 
                  ? _buildMobileChart(chartColor, chartUnit)
                  : _buildDesktopChart(chartColor, chartUnit),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildMobileChart(Color chartColor, String chartUnit) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const AlwaysScrollableScrollPhysics(),
            child: SizedBox(
              // Ensure minimum width based on data points (adjust as needed)
              width: max(MediaQuery.of(context).size.width - 64, _historicalData.length * 10.0),
              child: _buildChartWidget(chartColor, chartUnit),
            ),
          ),
        ),
        // Optional hint for users to know they can scroll
        Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.only(top: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.swipe, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text(
                'Swipe to view more data',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopChart(Color chartColor, String chartUnit) {
    return _buildChartWidget(chartColor, chartUnit);
  }

  Widget _buildChartWidget(Color chartColor, String chartUnit) {
    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
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
              interval: _getDateInterval(),
              getTitlesWidget: (value, meta) {
                double interval = _getDateInterval();
                int labelIndex = ((value - _historicalData.first.x) / interval).round();
                int totalLabels = ((_historicalData.last.x - _historicalData.first.x) / interval).round();
                if (totalLabels > 7 && labelIndex % 2 != 0) {
                  return Container(); // Skip some labels
                }
                final date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    DateFormat('MMM d').format(date),
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
              interval: _getValueInterval(),
              getTitlesWidget: (value, meta) {
                return Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Text(
                    value.toStringAsFixed(_getDecimalPlaces()) + chartUnit,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                );
              },
              reservedSize: 56,
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: AppColors.normal.withOpacity(0.3), width: 1),
        ),
        minX: _historicalData.first.x,
        maxX: _historicalData.last.x,
        minY: _getMinY() - _getYPadding(),
        maxY: _getMaxY() + _getYPadding(),
        lineBarsData: [
          LineChartBarData(
            spots: _historicalData,
            isCurved: true,
            barWidth: 3,
            isStrokeCapRound: true,
            color: chartColor,
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  chartColor.withOpacity(0.4),
                  chartColor.withOpacity(0.1),
                  chartColor.withOpacity(0.0),
                ],
              ),
            ),
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: chartColor,
                  strokeWidth: 1,
                  strokeColor: Colors.white,
                );
              },
              checkToShowDot: (spot, barData) {
                // Show dots only at regular intervals to avoid clutter
                final daySpan = _endDate.difference(_startDate).inDays;
                if (daySpan >= 30) {
                  // Every 5th data point for long periods
                  final index = _historicalData.indexOf(spot);
                  return index % 5 == 0;
                } else if (daySpan >= 14) {
                  // Every 3rd data point for medium periods
                  final index = _historicalData.indexOf(spot);
                  return index % 3 == 0;
                } else if (daySpan >= 7) {
                  // Every 2nd data point for shorter periods
                  final index = _historicalData.indexOf(spot);
                  return index % 2 == 0;
                }
                return true; // All dots for very short periods
              },
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            tooltipBgColor: AppColors.textPrimary.withOpacity(0.8),
            tooltipRoundedRadius: 8,
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((touchedSpot) {
                final date = DateTime.fromMillisecondsSinceEpoch(touchedSpot.x.toInt());
                final formattedDate = DateFormat('MMM d, yyyy').format(date);
                final formattedValue = touchedSpot.y.toStringAsFixed(_getDecimalPlaces());
                
                return LineTooltipItem(
                  '$formattedDate\n$formattedValue $chartUnit',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }
  
  // Helper methods for chart scaling and appearance
  double _getDateInterval() {
    final difference = _endDate.difference(_startDate).inDays;
    if (difference <= 7) {
      return 86400000; // 1 day in milliseconds
    } else if (difference <= 31) {
      return 86400000 * 3; // 3 days
    } else {
      return 86400000 * 7; // 7 days
    }
  }
  
  double _getValueInterval() {
    double minY = _getMinY();
    double maxY = _getMaxY();
    double range = maxY - minY;
    if (range == 0) return 1; // fallback
    double roughInterval = range / 6; // Aim for ~6 labels
    // Round to nearest "nice" number
    double magnitude = pow(10, (log(roughInterval) / ln10).floor()).toDouble();
    double niceInterval = (roughInterval / magnitude).ceil() * magnitude;
    return niceInterval;
  }
  
  int _getDecimalPlaces() {
    if (_selectedSensorType == 'tds') {
      return 0;
    } else {
      return 1;
    }
  }
  
  double _getMinY() {
    return _historicalData.map((e) => e.y).reduce((a, b) => a < b ? a : b);
  }
  
  double _getMaxY() {
    return _historicalData.map((e) => e.y).reduce((a, b) => a > b ? a : b);
  }
  
  double _getYPadding() {
    if (_selectedSensorType == 'tds') {
      return 20;
    } else if (_selectedSensorType == 'temperature') {
      return 0.5;
    } else {
      return 0.2;
    }
  }

  IconData _getIconForChart() {
    switch(_selectedSensorType) {
      case 'temperature': 
        return Icons.thermostat;
      case 'ph': 
        return Icons.science_outlined;
      case 'ec':
        return Icons.bolt_outlined;
      case 'tds':
        return Icons.opacity_outlined;
      default:
        return Icons.show_chart;
    }
  }

  double max(double a, double b) {
    return a > b ? a : b;
  }
} 