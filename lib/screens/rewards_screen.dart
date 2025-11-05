import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/offer_model.dart';
import '../models/reward_model.dart';
import '../models/user_earnings_model.dart';
import '../services/reward_service.dart';
import '../widgets/scratch_coupon_card.dart';

class RewardsScreen extends ConsumerStatefulWidget {
  const RewardsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends ConsumerState<RewardsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  String _selectedCategory = 'All';
  RewardService? _rewardService;
  List<OfferModel> _offers = [];
  UserEarningsModel? _userEarnings;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initializeRewardService();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _initializeRewardService() async {
    try {
      _rewardService = await RewardService.getInstance();
      await _loadInitialData();
    } catch (e) {
      debugPrint('Error initializing reward service: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadInitialData() async {
    if (_rewardService != null) {
      try {
        final offers = await _rewardService!.fetchAvailableOffers();
        final earnings = await _rewardService!.getUserEarnings('current_user');
        
        if (mounted) {
          setState(() {
            _offers = offers;
            _userEarnings = earnings;
          });
        }
      } catch (e) {
        debugPrint('Error loading initial data: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('🎁 Rewards & Cashback'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.amber,
          tabs: const [
            Tab(icon: Icon(Icons.local_offer), text: 'Offers'),
            Tab(icon: Icon(Icons.account_balance_wallet), text: 'Earnings'),
            Tab(icon: Icon(Icons.history), text: 'History'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOffersTab(),
          _buildEarningsTab(),
          _buildHistoryTab(),
        ],
      ),
    );
  }

  Widget _buildOffersTab() {
    return Column(
      children: [
        _buildCategoryFilter(),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadInitialData,
            child: _offers.isEmpty
                ? _buildEmptyOffersWidget()
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _offers.length,
                    itemBuilder: (context, index) {
                      final offer = _offers[index];
                      if (_selectedCategory != 'All' && offer.category != _selectedCategory) {
                        return const SizedBox.shrink();
                      }
                      return _buildOfferCard(offer);
                    },
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryFilter() {
    final categories = ['All', 'Shopping', 'Electronics', 'Education', 'Fashion', 'Food & Dining', 'Travel'];

    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = _selectedCategory == category;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(category),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedCategory = category;
                });
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildOfferCard(OfferModel offer) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Offer image header
          Container(
            height: 120,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              gradient: LinearGradient(
                colors: [
                  Colors.blue.shade400,
                  Colors.purple.shade400,
                ],
              ),
            ),
            child: Stack(
              children: [
                // Network badge
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      offer.source.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                
                // Center logo/icon
                Center(
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Icon(
                      _getOfferIcon(offer.category),
                      size: 32,
                      color: Colors.deepPurple,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Offer details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  offer.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                
                const SizedBox(height: 8),
                
                Text(
                  offer.description,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // Earnings info
                Row(
                  children: [
                    _buildEarningChip(
                      'CPC: ₹${offer.cpcRate}',
                      Colors.green,
                      Icons.touch_app,
                    ),
                    const SizedBox(width: 8),
                    _buildEarningChip(
                      'CPS: ${offer.cpsRate}%',
                      Colors.blue,
                      Icons.shopping_cart,
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Action button with scratch card
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _handleOfferTap(offer),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.touch_app, size: 20),
                        const SizedBox(width: 8),
                        Text('Tap to Earn ₹${offer.cpcRate}'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEarningChip(String text, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEarningsTab() {
    if (_userEarnings == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Total earnings card
          Card(
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green.shade400, Colors.green.shade600],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.account_balance_wallet,
                    color: Colors.white,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '₹${_userEarnings!.totalEarnings.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    'Total Earnings',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Earnings breakdown
          Row(
            children: [
              Expanded(
                child: _buildEarningsStatCard(
                  'CPC Earnings',
                  '₹${_userEarnings!.totalCpcEarnings.toStringAsFixed(2)}',
                  Icons.touch_app,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildEarningsStatCard(
                  'CPS Earnings',
                  '₹${_userEarnings!.totalCpsEarnings.toStringAsFixed(2)}',
                  Icons.shopping_cart,
                  Colors.orange,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Stats row
          Row(
            children: [
              Expanded(
                child: _buildEarningsStatCard(
                  'Total Clicks',
                  '${_userEarnings!.totalClicks}',
                  Icons.mouse,
                  Colors.purple,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildEarningsStatCard(
                  'Total Sales',
                  '${_userEarnings!.totalSales}',
                  Icons.confirmation_number,
                  Colors.teal,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Withdraw button
          if (_userEarnings!.pendingPayout >= 10)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _showWithdrawDialog(_userEarnings!.pendingPayout),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.account_balance, size: 24),
                    const SizedBox(width: 8),
                    Text(
                      'Withdraw ₹${_userEarnings!.pendingPayout.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEarningsStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryTab() {
    if (_userEarnings == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final allHistory = [
      ..._userEarnings!.clickHistory.map((h) => {...h.toMap(), 'type': 'CPC'}),
      ..._userEarnings!.salesHistory.map((h) => {...h.toMap(), 'type': 'CPS'}),
    ];
    
    // Sort by timestamp descending
    allHistory.sort((a, b) => 
        DateTime.parse(b['timestamp'] as String)
            .compareTo(DateTime.parse(a['timestamp'] as String))
    );

    if (allHistory.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No transaction history yet'),
            Text('Start earning by tapping on offers!'),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: allHistory.length,
      itemBuilder: (context, index) {
        final item = allHistory[index];
        final isClick = item['type'] == 'CPC';
        
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: isClick ? Colors.blue.shade100 : Colors.green.shade100,
              child: Icon(
                isClick ? Icons.touch_app : Icons.shopping_cart,
                color: isClick ? Colors.blue : Colors.green,
              ),
            ),
            title: Text(
              isClick ? 'Click Reward' : 'Sale Commission',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              '${item['source']} • ${_formatDateTime(item['timestamp'] as String)}',
            ),
            trailing: Text(
              '+₹${(item['amount'] as num).toStringAsFixed(2)}',
              style: TextStyle(
                color: isClick ? Colors.blue : Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyOffersWidget() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_bag_outlined, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text('No offers available right now'),
          Text('Check back later for exciting deals!'),
        ],
      ),
    );
  }

  IconData _getOfferIcon(String category) {
    switch (category.toLowerCase()) {
      case 'shopping':
        return Icons.shopping_bag;
      case 'travel':
        return Icons.flight;
      case 'food':
      case 'food & dining':
        return Icons.restaurant;
      case 'electronics':
        return Icons.devices;
      case 'fashion':
        return Icons.checkroom;
      case 'education':
        return Icons.school;
      default:
        return Icons.local_offer;
    }
  }

  String _formatDateTime(String timestamp) {
    final dateTime = DateTime.parse(timestamp);
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  void _handleOfferTap(OfferModel offer) async {
    try {
      // Show scratch card animation
      final earnedAmount = await showDialog<double>(
        context: context,
        barrierDismissible: false,
        builder: (context) => Dialog(
          backgroundColor: Colors.transparent,
          child: ScratchCouponCard(
            title: 'Instant Reward! 🎉',
            description: 'You earned ₹${offer.cpcRate} for trying this offer',
            coinValue: offer.cpcRate.toInt(),
            onScratch: () {
              Navigator.of(context).pop(offer.cpcRate);
            },
          ),
        ),
      );

      if (earnedAmount != null && _rewardService != null) {
        // Process the click with backend
        await _rewardService!.processClick(offer);
        
        // Refresh earnings
        await _loadInitialData();
        
        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Earned ₹${offer.cpcRate}! Opening offer...'),
              backgroundColor: Colors.green,
            ),
          );
        }

        // Open affiliate link
        await _rewardService!.openAffiliateLink(offer);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _showWithdrawDialog(double amount) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('💰 Withdraw Earnings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Available: ₹${amount.toStringAsFixed(2)}'),
            const SizedBox(height: 16),
            const Text('Minimum withdrawal: ₹10'),
            const Text('Processing time: 1-3 business days'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement withdrawal
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Withdrawal feature coming soon!'),
                ),
              );
            },
            child: const Text('Withdraw'),
          ),
        ],
      ),
    );
  }
}