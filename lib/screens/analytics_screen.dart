import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:streaky_app/services/local_storage.dart';
import 'package:streaky_app/models/user_model.dart';
import 'package:streaky_app/models/streak_model.dart';

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  User? _currentUser;
  StreakAnalytics? _analytics;
  String _selectedPeriod = 'This Month';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    setState(() {
      _currentUser = LocalStorageService.getCurrentUser();
      if (_currentUser != null) {
        _analytics = LocalStorageService.getAnalyticsForUser(_currentUser!.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            backgroundColor: const Color(0xFF4facfe),
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'Analytics',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF4facfe),
                      Color(0xFF00f2fe),
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Spacer(),
                        const SizedBox(height: 40), // Account for title
                        // Period Selector
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: DropdownButton<String>(
                            value: _selectedPeriod,
                            items: ['This Week', 'This Month', 'This Year']
                                .map((period) => DropdownMenuItem(
                                      value: period,
                                      child: Text(
                                        period,
                                        style: const TextStyle(color: Colors.white),
                                      ),
                                    ))
                                .toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedPeriod = value!;
                              });
                            },
                            underline: const SizedBox(),
                            dropdownColor: const Color(0xFF4facfe),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.share),
                onPressed: () {
                  // TODO: Share analytics
                  _shareAnalytics();
                },
              ),
            ],
          ),

          // Overview Cards
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _buildMetricCard(
                    title: 'Tasks Completed',
                    value: '${_analytics?.totalCompletedTasks ?? 0}',
                    icon: Icons.check_circle,
                    color: Colors.green,
                  ),
                  _buildMetricCard(
                    title: 'Active Streaks',
                    value: '${_analytics?.totalActiveStreaks ?? 0}',
                    icon: Icons.local_fire_department,
                    color: Colors.orange,
                  ),
                  _buildMetricCard(
                    title: 'Longest Streak',
                    value: '${_analytics?.longestOverallStreak ?? 0} days',
                    icon: Icons.emoji_events,
                    color: Colors.amber,
                  ),
                  _buildMetricCard(
                    title: 'Categories',
                    value: '${_analytics?.categoryStats.length ?? 0}',
                    icon: Icons.category,
                    color: Colors.blue,
                  ),
                ],
              ),
            ),
          ),

          // Category Breakdown
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Category Breakdown',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _analytics?.categoryStats.isEmpty ?? true
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(32.0),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.pie_chart_outline,
                                      size: 48,
                                      color: Colors.grey[400],
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'No data yet',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : Column(
                              children: _analytics!.categoryStats.entries
                                  .map((entry) => _buildCategoryBar(
                                        entry.key,
                                        entry.value,
                                        _analytics!.totalCompletedTasks,
                                      ))
                                  .toList(),
                            ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Weekly Activity
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Weekly Activity',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _analytics?.weekdayStats.isEmpty ?? true
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(32.0),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.bar_chart,
                                      size: 48,
                                      color: Colors.grey[400],
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Complete tasks to see activity',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : _buildWeeklyChart(),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Insights Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Insights',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildInsight(
                        icon: Icons.star,
                        title: 'Most Productive Day',
                        description: _analytics?.mostProductiveWeekday ?? 'Monday',
                        color: Colors.amber,
                      ),
                      const SizedBox(height: 12),
                      _buildInsight(
                        icon: Icons.trending_up,
                        title: 'Top Category',
                        description: _analytics?.mostActiveCategory ?? 'Personal',
                        color: Colors.green,
                      ),
                      const SizedBox(height: 12),
                      _buildInsight(
                        icon: Icons.psychology,
                        title: 'AI Tip',
                        description: 'You\'re most productive on ${_analytics?.mostProductiveWeekday ?? 'Monday'}s. Schedule important tasks then!',
                        color: Colors.blue,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Bottom padding
          const SliverToBoxAdapter(
            child: SizedBox(height: 80),
          ),
        ],
      ),

      // Bottom Navigation
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF4facfe),
        unselectedItemColor: Colors.grey,
        currentIndex: 2,
        onTap: (index) {
          switch (index) {
            case 0:
              context.go('/home');
              break;
            case 1:
              context.go('/streaks');
              break;
            case 2:
              // Already on analytics
              break;
            case 3:
              context.go('/profile');
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.local_fire_department),
            label: 'Streaks',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: 'Analytics',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryBar(String category, int count, int total) {
    final percentage = total > 0 ? (count / total) : 0.0;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(category),
              Text('$count tasks'),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: percentage,
            backgroundColor: Colors.grey[300],
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF4facfe)),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyChart() {
    final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final maxCount = _analytics!.weekdayStats.values.isNotEmpty 
        ? _analytics!.weekdayStats.values.reduce((a, b) => a > b ? a : b)
        : 1;

    return SizedBox(
      height: 150,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: weekdays.asMap().entries.map((entry) {
          final dayIndex = entry.key + 1;
          final day = entry.value;
          final count = _analytics!.weekdayStats[dayIndex.toString()] ?? 0;
          final height = count > 0 ? (count / maxCount) * 100 : 0.0;

          return Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                width: 20,
                height: height,
                decoration: BoxDecoration(
                  color: const Color(0xFF4facfe),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                day,
                style: const TextStyle(fontSize: 12),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildInsight({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _shareAnalytics() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Share Analytics'),
        content: const Text('Share your productivity insights with friends!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: Implement sharing
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Sharing feature coming soon!'),
                ),
              );
            },
            child: const Text('Share'),
          ),
        ],
      ),
    );
  }
}