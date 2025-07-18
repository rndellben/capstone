import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../providers/performance_matrix_provider.dart';
import '../../../core/models/performance_matrix_model.dart';
import '../../../core/constants/app_colors.dart';
import '../../widgets/responsive_widget.dart';
import '../../widgets/app_drawer.dart';
import 'leaderboard_entry_detail_page.dart';

class GlobalLeaderboardPage extends StatefulWidget {
  final String userId;
  
  const GlobalLeaderboardPage({super.key, required this.userId});

  @override
  State<GlobalLeaderboardPage> createState() => _GlobalLeaderboardPageState();
}

class _GlobalLeaderboardPageState extends State<GlobalLeaderboardPage> {
  String _sortBy = 'rank'; // Default sort
  bool _isAscending = true;
  String? _selectedCropType;
  String _timeFilter = 'all'; // Default to all time
  
  @override
  void initState() {
    super.initState();
    
    // Load leaderboard data when the page is opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<PerformanceMatrixProvider>(context, listen: false);
      provider.fetchGlobalLeaderboard();
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Global Leaderboard',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.leaf, AppColors.forest],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // Time filter button
          PopupMenuButton<String>(
            icon: const Icon(Icons.calendar_today),
            tooltip: 'Filter by time',
            onSelected: (value) {
              setState(() {
                _timeFilter = value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'all',
                child: Text('All Time'),
              ),
              const PopupMenuItem(
                value: '30days',
                child: Text('Last 30 Days'),
              ),
              const PopupMenuItem(
                value: '90days',
                child: Text('Last 90 Days'),
              ),
            ],
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            tooltip: 'Sort by',
            onSelected: (value) {
              setState(() {
                if (_sortBy == value) {
                  // Toggle direction if same field
                  _isAscending = !_isAscending;
                } else {
                  // New field, default to ascending
                  _sortBy = value;
                  _isAscending = true;
                }
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'rank',
                child: Text('Rank'),
              ),
              const PopupMenuItem(
                value: 'score',
                child: Text('Score'),
              ),
              const PopupMenuItem(
                value: 'cropName',
                child: Text('Crop Name'),
              ),
              const PopupMenuItem(
                value: 'harvestDate',
                child: Text('Harvest Date'),
              ),
              const PopupMenuItem(
                value: 'yieldAmount',
                child: Text('Yield Amount'),
              ),
            ],
          ),
        ],
      ),
      drawer: AppDrawer(userId: widget.userId),
      body: Column(
        children: [
          // Crop type filter
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Consumer<PerformanceMatrixProvider>(
              builder: (context, provider, child) {
                // Get unique crop types from leaderboard
                final cropTypes = provider.globalLeaderboard.isEmpty 
                    ? <String>[] 
                    : provider.globalLeaderboard
                        .map((entry) => entry.cropName)
                        .toSet()
                        .toList();
                
                return DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'Filter by Crop Type',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  value: _selectedCropType,
                  onChanged: (newValue) {
                    setState(() {
                      _selectedCropType = newValue;
                    });
                  },
                  items: [
                    const DropdownMenuItem<String>(
                      value: null,
                      child: Text('All Crops'),
                    ),
                    ...cropTypes.map((cropType) => DropdownMenuItem<String>(
                      value: cropType,
                      child: Text(cropType),
                    )),
                  ],
                );
              },
            ),
          ),
          // Time filter indicator
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              children: [
                Icon(
                  Icons.filter_list,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Showing: ${_timeFilter == 'all' ? 'All Time' : _timeFilter == '30days' ? 'Last 30 Days' : 'Last 90 Days'}',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Consumer<PerformanceMatrixProvider>(
              builder: (context, provider, child) {
                if (provider.isLoadingLeaderboard) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: AppColors.leaf),
                        const SizedBox(height: 16),
                        Text(
                          'Loading global leaderboard...',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  );
                }
                
                final leaderboard = provider.globalLeaderboard;
                
                if (leaderboard.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.emoji_events_outlined,
                          size: 64,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No leaderboard entries yet',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Be the first to submit your harvest results!',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  );
                }
                
                // Apply filters
                final DateTime now = DateTime.now();
                final filteredLeaderboard = leaderboard.where((entry) {
                  // Apply crop type filter
                  if (_selectedCropType != null && entry.cropName != _selectedCropType) {
                    return false;
                  }
                  
                  // Apply time filter
                  if (_timeFilter != 'all') {
                    final harvestDate = entry.harvestDate;
                    final int daysToFilter = _timeFilter == '30days' ? 30 : 90;
                    final DateTime cutoffDate = now.subtract(Duration(days: daysToFilter));
                    
                    if (harvestDate.isBefore(cutoffDate)) {
                      return false;
                    }
                  }
                  
                  return true;
                }).toList();
                
                // Sort the filtered leaderboard
                filteredLeaderboard.sort((a, b) {
                  int comparison;
                  
                  switch (_sortBy) {
                    case 'rank':
                      comparison = a.rank.compareTo(b.rank);
                      break;
                    case 'score':
                      comparison = a.score.compareTo(b.score);
                      break;
                    case 'cropName':
                      comparison = a.cropName.compareTo(b.cropName);
                      break;
                    case 'harvestDate':
                      comparison = a.harvestDate.compareTo(b.harvestDate);
                      break;
                    case 'yieldAmount':
                      comparison = a.yieldAmount.compareTo(b.yieldAmount);
                      break;
                    default:
                      comparison = a.rank.compareTo(b.rank);
                  }
                  
                  return _isAscending ? comparison : -comparison;
                });
                
                // Update ranks based on filtered results
                for (int i = 0; i < filteredLeaderboard.length; i++) {
                  filteredLeaderboard[i] = filteredLeaderboard[i].copyWith(rank: i + 1);
                }
                
                if (filteredLeaderboard.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.filter_alt_off,
                          size: 64,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No results match your filters',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextButton.icon(
                          icon: const Icon(Icons.refresh),
                          label: const Text('Reset Filters'),
                          onPressed: () {
                            setState(() {
                              _selectedCropType = null;
                              _timeFilter = 'all';
                            });
                          },
                        ),
                      ],
                    ),
                  );
                }
                
                return ResponsiveWidget(
                  mobile: _buildMobileLayout(filteredLeaderboard),
                  tablet: _buildTabletLayout(filteredLeaderboard),
                  desktop: _buildDesktopLayout(filteredLeaderboard),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildMobileLayout(List<LeaderboardEntry> leaderboard) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: leaderboard.length,
      itemBuilder: (context, index) {
        final entry = leaderboard[index];
        return _buildLeaderboardCard(entry);
      },
    );
  }
  
  Widget _buildTabletLayout(List<LeaderboardEntry> leaderboard) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 2.5,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: leaderboard.length,
      itemBuilder: (context, index) {
        final entry = leaderboard[index];
        return _buildLeaderboardCard(entry);
      },
    );
  }
  
  Widget _buildDesktopLayout(List<LeaderboardEntry> leaderboard) {
    return Column(
      children: [
        _buildLeaderboardHeader(),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            itemCount: leaderboard.length,
            itemBuilder: (context, index) {
              final entry = leaderboard[index];
              return _buildLeaderboardRow(entry);
            },
          ),
        ),
      ],
    );
  }
  
  Widget _buildLeaderboardHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              _buildHeaderCell('Rank', 'rank', flex: 1),
              _buildHeaderCell('Crop', 'cropName', flex: 3),
              _buildHeaderCell('Profile', '', flex: 3),
              _buildHeaderCell('Yield', 'yieldAmount', flex: 2),
              _buildHeaderCell('Rating', '', flex: 1),
              _buildHeaderCell('Date', 'harvestDate', flex: 2),
              _buildHeaderCell('Score', 'score', flex: 2),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildHeaderCell(String title, String sortKey, {int flex = 1}) {
    final isCurrentSort = _sortBy == sortKey;
    
    return Expanded(
      flex: flex,
      child: InkWell(
        onTap: sortKey.isNotEmpty ? () {
          setState(() {
            if (_sortBy == sortKey) {
              _isAscending = !_isAscending;
            } else {
              _sortBy = sortKey;
              _isAscending = true;
            }
          });
        } : null,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontWeight: isCurrentSort ? FontWeight.bold : FontWeight.w600,
                color: isCurrentSort ? AppColors.forest : Colors.grey[700],
              ),
            ),
            if (isCurrentSort)
              Icon(
                _isAscending ? Icons.arrow_upward : Icons.arrow_downward,
                size: 16,
                color: AppColors.forest,
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildLeaderboardRow(LeaderboardEntry entry) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      elevation: 1,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => LeaderboardEntryDetailPage(entry: entry),
            ),
          );
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          child: Row(
            children: [
              // Rank
              Expanded(
                flex: 1,
                child: _buildRankBadge(entry.rank),
              ),
              
              // Crop name
              Expanded(
                flex: 3,
                child: Text(
                  entry.cropName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                  softWrap: true,
                  overflow: TextOverflow.visible,
                ),
              ),
              
              // Profile name
              Expanded(
                flex: 3,
                child: Text(
                  entry.growProfileName,
                  style: TextStyle(
                    color: Colors.grey[700],
                  ),
                  softWrap: true,
                  overflow: TextOverflow.visible,
                ),
              ),
              
              // Yield amount
              Expanded(
                flex: 2,
                child: Text(
                  '${entry.yieldAmount.toStringAsFixed(1)} g',
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              
              // Rating
              Expanded(
                flex: 1,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.star,
                      size: 16,
                      color: Colors.amber[700],
                    ),
                    const SizedBox(width: 4),
                    Text('${entry.rating}'),
                  ],
                ),
              ),
              
              // Harvest date
              Expanded(
                flex: 2,
                child: Text(
                  DateFormat('MMM d, yyyy').format(entry.harvestDate),
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 13,
                  ),
                ),
              ),
              
              // Score
              Expanded(
                flex: 2,
                child: Text(
                  entry.score.toStringAsFixed(1),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.forest,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildLeaderboardCard(LeaderboardEntry entry) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 2,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => LeaderboardEntryDetailPage(entry: entry),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row with rank and score
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildRankBadge(entry.rank),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.forest.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.emoji_events,
                          size: 16,
                          color: AppColors.forest,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Score: ${entry.score.toStringAsFixed(1)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.forest,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Crop name
              Text(
                entry.cropName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                softWrap: true,
                overflow: TextOverflow.visible,
              ),
              
              const SizedBox(height: 4),
              
              // Grow profile
              Text(
                'Profile: ${entry.growProfileName}',
                style: TextStyle(
                  color: Colors.grey[700],
                ),
                softWrap: true,
                overflow: TextOverflow.visible,
              ),
              
              const SizedBox(height: 12),
              
              // Details row
              Wrap(
                spacing: 16,
                runSpacing: 12,
                alignment: WrapAlignment.spaceBetween,
                children: [
                  // Yield
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Yield',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        '${entry.yieldAmount.toStringAsFixed(1)} g',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  
                  // Rating
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Rating',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.star,
                            size: 16,
                            color: Colors.amber[700],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${entry.rating}/5',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  
                  // Date
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Harvested',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        DateFormat('MMM d, yyyy').format(entry.harvestDate),
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildRankBadge(int rank) {
    Color badgeColor;
    Color textColor = Colors.white;
    
    // Set colors based on rank
    if (rank == 1) {
      badgeColor = Colors.amber[700]!;
    } else if (rank == 2) {
      badgeColor = Colors.grey[400]!;
    } else if (rank == 3) {
      badgeColor = Colors.brown[300]!;
    } else {
      badgeColor = Colors.grey[200]!;
      textColor = Colors.grey[700]!;
    }
    
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: badgeColor,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          '$rank',
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
} 