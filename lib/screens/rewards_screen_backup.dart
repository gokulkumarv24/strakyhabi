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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // Initialize reward service and load data
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _rewardService = await RewardService.getInstance();
      if (mounted) {
        await _loadInitialData();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    if (_rewardService != null) {
      await _rewardService!.loadOffers();
      await _rewardService!.loadUserEarnings('current_user');
    }
  }

  @override

  Widget build(BuildContext context) {

  @override    final rewardService = ref.watch(rewardServiceProvider);

  void dispose() {    final offers = ref.watch(offersProvider);

    _tabController.dispose();    final earnings = ref.watch(userEarningsProvider);

    _scrollController.dispose();

    super.dispose();    return Scaffold(

  }      backgroundColor: Colors.grey.shade50,

      appBar: AppBar(

  @override        title: const Text('🎁 Rewards & Cashback'),

  Widget build(BuildContext context) {        backgroundColor: Colors.deepPurple,

    final theme = Theme.of(context);        foregroundColor: Colors.white,

    final colorScheme = theme.colorScheme;        elevation: 0,

            bottom: TabBar(

    return Scaffold(          controller: _tabController,

      backgroundColor: colorScheme.surface,          indicatorColor: Colors.amber,

      body: CustomScrollView(          tabs: const [

        controller: _scrollController,            Tab(icon: Icon(Icons.local_offer), text: 'Offers'),

        slivers: [            Tab(icon: Icon(Icons.account_balance_wallet), text: 'Earnings'),

          // App Bar with earnings summary            Tab(icon: Icon(Icons.history), text: 'History'),

          _buildSliverAppBar(theme, colorScheme),          ],

                  ),

          // Tab Bar      ),

          SliverPersistentHeader(      body: TabBarView(

            pinned: true,        controller: _tabController,

            delegate: _TabBarDelegate(        children: [

              child: Container(          _buildOffersTab(offers),

                color: colorScheme.surface,          _buildEarningsTab(earnings),

                child: TabBar(          _buildHistoryTab(earnings),

                  controller: _tabController,        ],

                  labelColor: colorScheme.primary,      ),

                  unselectedLabelColor: colorScheme.onSurfaceVariant,    );

                  indicatorColor: colorScheme.primary,  }

                  tabs: const [

                    Tab(text: 'Rewards', icon: Icon(Icons.card_giftcard)),  Widget _buildOffersTab(AsyncValue<List<Offer>> offers) {

                    Tab(text: 'Offers', icon: Icon(Icons.local_offer)),    return offers.when(

                    Tab(text: 'History', icon: Icon(Icons.history)),      loading: () => const Center(

                    Tab(text: 'Earnings', icon: Icon(Icons.account_balance_wallet)),        child: CircularProgressIndicator(),

                  ],      ),

                ),      error: (error, stack) => Center(

              ),        child: Column(

            ),          mainAxisAlignment: MainAxisAlignment.center,

          ),          children: [

                      const Icon(Icons.error_outline, size: 64, color: Colors.red),

          // Tab Content            const SizedBox(height: 16),

          SliverFillRemaining(            Text('Failed to load offers: $error'),

            child: TabBarView(            const SizedBox(height: 16),

              controller: _tabController,            ElevatedButton(

              children: [              onPressed: () => ref.refresh(offersProvider),

                _buildRewardsTab(),              child: const Text('Retry'),

                _buildOffersTab(),            ),

                _buildHistoryTab(),          ],

                _buildEarningsTab(),        ),

              ],      ),

            ),      data: (offerList) {

          ),        if (offerList.isEmpty) {

        ],          return const Center(

      ),            child: Column(

      floatingActionButton: _buildFloatingActionButton(colorScheme),              mainAxisAlignment: MainAxisAlignment.center,

    );              children: [

  }                Icon(Icons.shopping_bag_outlined, size: 64, color: Colors.grey),

                SizedBox(height: 16),

  Widget _buildSliverAppBar(ThemeData theme, ColorScheme colorScheme) {                Text('No offers available right now'),

    return Consumer(                Text('Check back later for exciting deals!'),

      builder: (context, ref, child) {              ],

        final rewardState = ref.watch(rewardProvider);            ),

        final earnings = rewardState.userEarnings;          );

                }

        return SliverAppBar(

          expandedHeight: 200,        return RefreshIndicator(

          floating: false,          onRefresh: () async {

          pinned: true,            ref.refresh(offersProvider);

          flexibleSpace: FlexibleSpaceBar(          },

            title: Text(          child: ListView.builder(

              'Rewards',            padding: const EdgeInsets.all(16),

              style: TextStyle(color: colorScheme.onPrimary),            itemCount: offerList.length,

            ),            itemBuilder: (context, index) {

            background: Container(              final offer = offerList[index];

              decoration: BoxDecoration(              return _buildOfferCard(offer);

                gradient: LinearGradient(            },

                  colors: [          ),

                    colorScheme.primary,        );

                    colorScheme.primary.withOpacity(0.8),      },

                  ],    );

                  begin: Alignment.topCenter,  }

                  end: Alignment.bottomCenter,

                ),  Widget _buildOfferCard(Offer offer) {

              ),    return Card(

              child: SafeArea(      margin: const EdgeInsets.only(bottom: 16),

                child: Padding(      elevation: 4,

                  padding: const EdgeInsets.all(16.0),      shape: RoundedRectangleBorder(

                  child: Column(        borderRadius: BorderRadius.circular(16),

                    children: [      ),

                      const SizedBox(height: 40),      child: Column(

                      Row(        crossAxisAlignment: CrossAxisAlignment.start,

                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,        children: [

                        children: [          // Offer image

                          _buildEarningStat(          Container(

                            'Total Earned',            height: 120,

                            earnings?.formattedTotalEarnings ?? '₹0.00',            decoration: BoxDecoration(

                            Icons.account_balance_wallet,              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),

                            colorScheme.onPrimary,              gradient: LinearGradient(

                          ),                colors: [

                          _buildEarningStat(                  Colors.blue.shade400,

                            'Pending',                  Colors.purple.shade400,

                            earnings?.formattedPendingPayout ?? '₹0.00',                ],

                            Icons.hourglass_empty,              ),

                            colorScheme.onPrimary,            ),

                          ),            child: Stack(

                          _buildEarningStat(              children: [

                            'Conversion',                // Network badge

                            earnings?.formattedConversionRate ?? '0.0%',                Positioned(

                            Icons.trending_up,                  top: 8,

                            colorScheme.onPrimary,                  right: 8,

                          ),                  child: Container(

                        ],                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),

                      ),                    decoration: BoxDecoration(

                    ],                      color: Colors.white.withOpacity(0.9),

                  ),                      borderRadius: BorderRadius.circular(12),

                ),                    ),

              ),                    child: Text(

            ),                      offer.source.toUpperCase(),

          ),                      style: const TextStyle(

        );                        fontSize: 10,

      },                        fontWeight: FontWeight.bold,

    );                      ),

  }                    ),

                  ),

  Widget _buildEarningStat(String label, String value, IconData icon, Color color) {                ),

    return Column(                

      children: [                // Center logo/icon

        Icon(icon, color: color, size: 24),                Center(

        const SizedBox(height: 8),                  child: Container(

        Text(                    width: 60,

          value,                    height: 60,

          style: TextStyle(                    decoration: BoxDecoration(

            color: color,                      color: Colors.white,

            fontSize: 16,                      borderRadius: BorderRadius.circular(12),

            fontWeight: FontWeight.bold,                      boxShadow: [

          ),                        BoxShadow(

        ),                          color: Colors.black.withOpacity(0.1),

        Text(                          blurRadius: 8,

          label,                        ),

          style: TextStyle(                      ],

            color: color.withOpacity(0.8),                    ),

            fontSize: 12,                    child: Icon(

          ),                      _getOfferIcon(offer.category),

        ),                      size: 32,

      ],                      color: Colors.deepPurple,

    );                    ),

  }                  ),

                ),

  Widget _buildRewardsTab() {              ],

    return Consumer(            ),

      builder: (context, ref, child) {          ),

        final rewardState = ref.watch(rewardProvider);          

                  // Offer details

        if (rewardState.isLoading) {          Padding(

          return const Center(child: CircularProgressIndicator());            padding: const EdgeInsets.all(16),

        }            child: Column(

                      crossAxisAlignment: CrossAxisAlignment.start,

        if (rewardState.error != null) {              children: [

          return _buildErrorWidget(rewardState.error!);                Text(

        }                  offer.title,

                          style: const TextStyle(

        final rewards = rewardState.userRewards;                    fontSize: 18,

                            fontWeight: FontWeight.bold,

        if (rewards.isEmpty) {                  ),

          return _buildEmptyRewardsWidget();                ),

        }                

                        const SizedBox(height: 8),

        return RefreshIndicator(                

          onRefresh: () async {                Text(

            await ref.read(rewardProvider.notifier).loadUserRewards();                  offer.description,

          },                  style: TextStyle(

          child: ListView.builder(                    color: Colors.grey.shade600,

            padding: const EdgeInsets.all(16),                    fontSize: 14,

            itemCount: rewards.length,                  ),

            itemBuilder: (context, index) {                ),

              final reward = rewards[index];                

              return Padding(                const SizedBox(height: 12),

                padding: const EdgeInsets.only(bottom: 16),                

                child: ScratchCouponCard(                // Earnings info

                  reward: reward,                Row(

                  isScratched: reward.isClaimed || reward.isUnlocked,                  children: [

                  onRevealed: () {                    _buildEarningChip(

                    _handleRewardRevealed(reward);                      'CPC: ₹${offer.cpcRate}',

                  },                      Colors.green,

                  onClaim: () {                      Icons.touch_app,

                    _handleRewardClaim(reward);                    ),

                  },                    const SizedBox(width: 8),

                ),                    _buildEarningChip(

              );                      'CPS: ${offer.cpsRate}%',

            },                      Colors.blue,

          ),                      Icons.shopping_cart,

        );                    ),

      },                  ],

    );                ),

  }                

                const SizedBox(height: 16),

  Widget _buildOffersTab() {                

    return Consumer(                // Action button

      builder: (context, ref, child) {                SizedBox(

        final rewardState = ref.watch(rewardProvider);                  width: double.infinity,

        final offers = rewardState.availableOffers;                  child: ElevatedButton(

                            onPressed: () => _handleOfferTap(offer),

        return Column(                    style: ElevatedButton.styleFrom(

          children: [                      backgroundColor: Colors.deepPurple,

            // Category filter                      foregroundColor: Colors.white,

            _buildCategoryFilter(),                      padding: const EdgeInsets.symmetric(vertical: 12),

                                  shape: RoundedRectangleBorder(

            // Offers list                        borderRadius: BorderRadius.circular(8),

            Expanded(                      ),

              child: RefreshIndicator(                    ),

                onRefresh: () async {                    child: Row(

                  await ref.read(rewardProvider.notifier).loadAvailableOffers();                      mainAxisAlignment: MainAxisAlignment.center,

                },                      children: [

                child: offers.isEmpty                        const Icon(Icons.touch_app, size: 20),

                    ? _buildEmptyOffersWidget()                        const SizedBox(width: 8),

                    : ListView.builder(                        Text('Tap to Earn ₹${offer.cpcRate}'),

                        padding: const EdgeInsets.all(16),                      ],

                        itemCount: offers.length,                    ),

                        itemBuilder: (context, index) {                  ),

                          final offer = offers[index];                ),

                          return _buildOfferCard(offer);              ],

                        },            ),

                      ),          ),

              ),        ],

            ),      ),

          ],    );

        );  }

      },

    );  Widget _buildEarningChip(String text, Color color, IconData icon) {

  }    return Container(

      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),

  Widget _buildCategoryFilter() {      decoration: BoxDecoration(

    final categories = ['All', 'Shopping', 'Food', 'Travel', 'Fashion', 'Electronics'];        color: color.withOpacity(0.1),

            borderRadius: BorderRadius.circular(12),

    return Container(        border: Border.all(color: color.withOpacity(0.3)),

      height: 60,      ),

      padding: const EdgeInsets.symmetric(vertical: 8),      child: Row(

      child: ListView.builder(        mainAxisSize: MainAxisSize.min,

        scrollDirection: Axis.horizontal,        children: [

        padding: const EdgeInsets.symmetric(horizontal: 16),          Icon(icon, size: 14, color: color),

        itemCount: categories.length,          const SizedBox(width: 4),

        itemBuilder: (context, index) {          Text(

          final category = categories[index];            text,

          final isSelected = _selectedCategory == category;            style: TextStyle(

                        color: color,

          return Padding(              fontSize: 12,

            padding: const EdgeInsets.only(right: 8),              fontWeight: FontWeight.w600,

            child: FilterChip(            ),

              label: Text(category),          ),

              selected: isSelected,        ],

              onSelected: (selected) {      ),

                setState(() {    );

                  _selectedCategory = category;  }

                });

                _filterOffersByCategory(category);  Widget _buildEarningsTab(AsyncValue<UserEarnings> earnings) {

              },    return earnings.when(

            ),      loading: () => const Center(child: CircularProgressIndicator()),

          );      error: (error, stack) => Center(child: Text('Error: $error')),

        },      data: (userEarnings) {

      ),        return SingleChildScrollView(

    );          padding: const EdgeInsets.all(16),

  }          child: Column(

            children: [

  Widget _buildOfferCard(OfferModel offer) {              // Total earnings card

    final theme = Theme.of(context);              Card(

    final colorScheme = theme.colorScheme;                elevation: 8,

                    shape: RoundedRectangleBorder(

    return Card(                  borderRadius: BorderRadius.circular(16),

      margin: const EdgeInsets.only(bottom: 12),                ),

      child: InkWell(                child: Container(

        onTap: () => _handleOfferTap(offer),                  width: double.infinity,

        borderRadius: BorderRadius.circular(12),                  padding: const EdgeInsets.all(24),

        child: Padding(                  decoration: BoxDecoration(

          padding: const EdgeInsets.all(16),                    gradient: LinearGradient(

          child: Row(                      colors: [Colors.green.shade400, Colors.green.shade600],

            children: [                      begin: Alignment.topLeft,

              // Offer image                      end: Alignment.bottomRight,

              ClipRRect(                    ),

                borderRadius: BorderRadius.circular(8),                    borderRadius: BorderRadius.circular(16),

                child: Image.network(                  ),

                  offer.imageUrl,                  child: Column(

                  width: 60,                    children: [

                  height: 60,                      const Icon(

                  fit: BoxFit.cover,                        Icons.account_balance_wallet,

                  errorBuilder: (context, error, stackTrace) {                        color: Colors.white,

                    return Container(                        size: 48,

                      width: 60,                      ),

                      height: 60,                      const SizedBox(height: 16),

                      color: colorScheme.surfaceVariant,                      Text(

                      child: Icon(                        '₹${userEarnings.totalEarnings.toStringAsFixed(2)}',

                        Icons.store,                        style: const TextStyle(

                        color: colorScheme.onSurfaceVariant,                          color: Colors.white,

                      ),                          fontSize: 32,

                    );                          fontWeight: FontWeight.bold,

                  },                        ),

                ),                      ),

              ),                      const Text(

                                      'Total Earnings',

              const SizedBox(width: 16),                        style: TextStyle(

                                        color: Colors.white,

              // Offer details                          fontSize: 16,

              Expanded(                        ),

                child: Column(                      ),

                  crossAxisAlignment: CrossAxisAlignment.start,                    ],

                  children: [                  ),

                    Text(                ),

                      offer.title,              ),

                      style: theme.textTheme.titleMedium?.copyWith(              

                        fontWeight: FontWeight.w600,              const SizedBox(height: 16),

                      ),              

                      maxLines: 2,              // Earnings breakdown

                      overflow: TextOverflow.ellipsis,              Row(

                    ),                children: [

                    const SizedBox(height: 4),                  Expanded(

                    Text(                    child: _buildEarningsStatCard(

                      offer.brand,                      'CPC Earnings',

                      style: theme.textTheme.bodySmall?.copyWith(                      '₹${userEarnings.totalCpcEarnings.toStringAsFixed(2)}',

                        color: colorScheme.primary,                      Icons.touch_app,

                        fontWeight: FontWeight.w500,                      Colors.blue,

                      ),                    ),

                    ),                  ),

                    const SizedBox(height: 8),                  const SizedBox(width: 8),

                    Row(                  Expanded(

                      children: [                    child: _buildEarningsStatCard(

                        _buildRewardChip(                      'CPS Earnings',

                          'CPC: ${offer.formattedCpc}',                      '₹${userEarnings.totalCpsEarnings.toStringAsFixed(2)}',

                          colorScheme.primaryContainer,                      Icons.shopping_cart,

                          colorScheme.onPrimaryContainer,                      Colors.orange,

                        ),                    ),

                        const SizedBox(width: 8),                  ),

                        _buildRewardChip(                ],

                          'CPS: ${offer.formattedCps}',              ),

                          colorScheme.secondaryContainer,              

                          colorScheme.onSecondaryContainer,              const SizedBox(height: 16),

                        ),              

                      ],              // Stats row

                    ),              Row(

                  ],                children: [

                ),                  Expanded(

              ),                    child: _buildEarningsStatCard(

                                    'Total Clicks',

              // Action button                      '${userEarnings.totalClicks}',

              IconButton(                      Icons.mouse,

                onPressed: () => _handleOfferTap(offer),                      Colors.purple,

                icon: const Icon(Icons.arrow_forward_ios),                    ),

              ),                  ),

            ],                  const SizedBox(width: 8),

          ),                  Expanded(

        ),                    child: _buildEarningsStatCard(

      ),                      'Total Sales',

    );                      '${userEarnings.totalSales}',

  }                      Icons.confirmation_number,

                      Colors.teal,

  Widget _buildRewardChip(String text, Color backgroundColor, Color textColor) {                    ),

    return Container(                  ),

      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),                ],

      decoration: BoxDecoration(              ),

        color: backgroundColor,              

        borderRadius: BorderRadius.circular(12),              const SizedBox(height: 24),

      ),              

      child: Text(              // Withdraw button

        text,              if (userEarnings.pendingPayout >= 10)

        style: TextStyle(                SizedBox(

          color: textColor,                  width: double.infinity,

          fontSize: 12,                  child: ElevatedButton(

          fontWeight: FontWeight.w500,                    onPressed: () => _showWithdrawDialog(userEarnings.pendingPayout),

        ),                    style: ElevatedButton.styleFrom(

      ),                      backgroundColor: Colors.green,

    );                      foregroundColor: Colors.white,

  }                      padding: const EdgeInsets.symmetric(vertical: 16),

                      shape: RoundedRectangleBorder(

  Widget _buildHistoryTab() {                        borderRadius: BorderRadius.circular(12),

    return Consumer(                      ),

      builder: (context, ref, child) {                    ),

        final rewardState = ref.watch(rewardProvider);                    child: Row(

        final earnings = rewardState.userEarnings;                      mainAxisAlignment: MainAxisAlignment.center,

                              children: [

        if (earnings == null) {                        const Icon(Icons.account_balance, size: 24),

          return const Center(child: CircularProgressIndicator());                        const SizedBox(width: 8),

        }                        Text(

                                  'Withdraw ₹${userEarnings.pendingPayout.toStringAsFixed(2)}',

        return DefaultTabController(                          style: const TextStyle(fontSize: 16),

          length: 2,                        ),

          child: Column(                      ],

            children: [                    ),

              const TabBar(                  ),

                tabs: [                ),

                  Tab(text: 'Clicks'),            ],

                  Tab(text: 'Sales'),          ),

                ],        );

              ),      },

              Expanded(    );

                child: TabBarView(  }

                  children: [

                    _buildClickHistory(earnings.clickHistory),  Widget _buildEarningsStatCard(String title, String value, IconData icon, Color color) {

                    _buildSalesHistory(earnings.salesHistory),    return Card(

                  ],      child: Padding(

                ),        padding: const EdgeInsets.all(16),

              ),        child: Column(

            ],          children: [

          ),            Icon(icon, color: color, size: 24),

        );            const SizedBox(height: 8),

      },            Text(

    );              value,

  }              style: TextStyle(

                fontSize: 18,

  Widget _buildClickHistory(List<ClickHistoryModel> clicks) {                fontWeight: FontWeight.bold,

    if (clicks.isEmpty) {                color: color,

      return const Center(              ),

        child: Text('No click history yet'),            ),

      );            Text(

    }              title,

                  style: TextStyle(

    return ListView.builder(                fontSize: 12,

      padding: const EdgeInsets.all(16),                color: Colors.grey.shade600,

      itemCount: clicks.length,              ),

      itemBuilder: (context, index) {              textAlign: TextAlign.center,

        final click = clicks[index];            ),

        return ListTile(          ],

          leading: const Icon(Icons.touch_app),        ),

          title: Text('₹${click.amount.toStringAsFixed(2)}'),      ),

          subtitle: Text(click.source),    );

          trailing: Text(  }

            _formatDateTime(click.timestamp),

            style: Theme.of(context).textTheme.bodySmall,  Widget _buildHistoryTab(AsyncValue<UserEarnings> earnings) {

          ),    return earnings.when(

        );      loading: () => const Center(child: CircularProgressIndicator()),

      },      error: (error, stack) => Center(child: Text('Error: $error')),

    );      data: (userEarnings) {

  }        final allHistory = [

          ...userEarnings.clickHistory.map((h) => {...h, 'type': 'CPC'}),

  Widget _buildSalesHistory(List<SaleHistoryModel> sales) {          ...userEarnings.salesHistory.map((h) => {...h, 'type': 'CPS'}),

    if (sales.isEmpty) {        ];

      return const Center(        

        child: Text('No sales history yet'),        // Sort by timestamp descending

      );        allHistory.sort((a, b) => 

    }          DateTime.parse(b['timestamp'] as String)

                  .compareTo(DateTime.parse(a['timestamp'] as String))

    return ListView.builder(        );

      padding: const EdgeInsets.all(16),

      itemCount: sales.length,        return ListView.builder(

      itemBuilder: (context, index) {          padding: const EdgeInsets.all(16),

        final sale = sales[index];          itemCount: allHistory.length,

        return ListTile(          itemBuilder: (context, index) {

          leading: const Icon(Icons.shopping_cart),            final item = allHistory[index];

          title: Text('₹${sale.amount.toStringAsFixed(2)}'),            final isClick = item['type'] == 'CPC';

          subtitle: Text('Order: ₹${sale.orderValue.toStringAsFixed(2)} • ${sale.source}'),            

          trailing: Column(            return Card(

            mainAxisAlignment: MainAxisAlignment.center,              margin: const EdgeInsets.only(bottom: 8),

            crossAxisAlignment: CrossAxisAlignment.end,              child: ListTile(

            children: [                leading: CircleAvatar(

              Text(                  backgroundColor: isClick ? Colors.blue.shade100 : Colors.green.shade100,

                _formatDateTime(sale.timestamp),                  child: Icon(

                style: Theme.of(context).textTheme.bodySmall,                    isClick ? Icons.touch_app : Icons.shopping_cart,

              ),                    color: isClick ? Colors.blue : Colors.green,

              Text(                  ),

                sale.status,                ),

                style: Theme.of(context).textTheme.bodySmall?.copyWith(                title: Text(

                  color: sale.status == 'confirmed' ? Colors.green : Colors.orange,                  isClick ? 'Click Reward' : 'Sale Commission',

                ),                  style: const TextStyle(fontWeight: FontWeight.w600),

              ),                ),

            ],                subtitle: Text(

          ),                  '${item['source']} • ${_formatDateTime(item['timestamp'] as String)}',

        );                ),

      },                trailing: Text(

    );                  '+₹${(item['amount'] as num).toStringAsFixed(2)}',

  }                  style: TextStyle(

                    color: isClick ? Colors.blue : Colors.green,

  Widget _buildEarningsTab() {                    fontWeight: FontWeight.bold,

    return Consumer(                  ),

      builder: (context, ref, child) {                ),

        final rewardState = ref.watch(rewardProvider);              ),

        final earnings = rewardState.userEarnings;            );

                  },

        if (earnings == null) {        );

          return const Center(child: CircularProgressIndicator());      },

        }    );

          }

        return Padding(

          padding: const EdgeInsets.all(16),  IconData _getOfferIcon(String category) {

          child: Column(    switch (category.toLowerCase()) {

            crossAxisAlignment: CrossAxisAlignment.start,      case 'shopping':

            children: [        return Icons.shopping_bag;

              _buildEarningsCard(earnings),      case 'travel':

              const SizedBox(height: 16),        return Icons.flight;

              _buildPayoutSection(earnings),      case 'food':

            ],        return Icons.restaurant;

          ),      case 'electronics':

        );        return Icons.devices;

      },      case 'fashion':

    );        return Icons.checkroom;

  }      default:

        return Icons.local_offer;

  Widget _buildEarningsCard(UserEarningsModel earnings) {    }

    final theme = Theme.of(context);  }

    

    return Card(  String _formatDateTime(String timestamp) {

      child: Padding(    final dateTime = DateTime.parse(timestamp);

        padding: const EdgeInsets.all(16),    final now = DateTime.now();

        child: Column(    final difference = now.difference(dateTime);

          crossAxisAlignment: CrossAxisAlignment.start,    

          children: [    if (difference.inDays > 0) {

            Text(      return '${difference.inDays}d ago';

              'Earnings Summary',    } else if (difference.inHours > 0) {

              style: theme.textTheme.titleLarge,      return '${difference.inHours}h ago';

            ),    } else if (difference.inMinutes > 0) {

            const SizedBox(height: 16),      return '${difference.inMinutes}m ago';

            Row(    } else {

              mainAxisAlignment: MainAxisAlignment.spaceEvenly,      return 'Just now';

              children: [    }

                _buildEarningItem('CPC Earnings', earnings.formattedTotalEarnings),  }

                _buildEarningItem('Total Clicks', earnings.totalClicks.toString()),

                _buildEarningItem('Total Sales', earnings.totalSales.toString()),  void _handleOfferTap(Offer offer) async {

              ],    try {

            ),      // Show scratch card animation

          ],      showDialog(

        ),        context: context,

      ),        barrierDismissible: false,

    );        builder: (context) => Dialog(

  }          backgroundColor: Colors.transparent,

          child: ScratchCouponCard(

  Widget _buildEarningItem(String label, String value) {            title: 'Instant Reward!',

    final theme = Theme.of(context);            description: 'You earned ₹${offer.cpcRate} for trying this offer',

                coinValue: offer.cpcRate.toInt(),

    return Column(            onScratch: () {

      children: [              Navigator.of(context).pop();

        Text(              _processCpcClick(offer);

          value,            },

          style: theme.textTheme.headlineSmall?.copyWith(          ),

            fontWeight: FontWeight.bold,        ),

          ),      );

        ),    } catch (e) {

        Text(      ScaffoldMessenger.of(context).showSnackBar(

          label,        SnackBar(content: Text('Error: $e')),

          style: theme.textTheme.bodySmall,      );

        ),    }

      ],  }

    );

  }  void _processCpcClick(Offer offer) async {

    try {

  Widget _buildPayoutSection(UserEarningsModel earnings) {      await ref.read(rewardServiceProvider).processClick(offer);

    final theme = Theme.of(context);      

    final colorScheme = theme.colorScheme;      // Refresh earnings

          ref.refresh(userEarningsProvider);

    return Card(      

      child: Padding(      ScaffoldMessenger.of(context).showSnackBar(

        padding: const EdgeInsets.all(16),        SnackBar(

        child: Column(          content: Text('✅ Earned ₹${offer.cpcRate}! Opening offer...'),

          crossAxisAlignment: CrossAxisAlignment.start,          backgroundColor: Colors.green,

          children: [        ),

            Text(      );

              'Payout',      

              style: theme.textTheme.titleLarge,      // Open affiliate link

            ),      await ref.read(rewardServiceProvider).openAffiliateLink(offer);

            const SizedBox(height: 16),      

            Text(    } catch (e) {

              'Pending: ${earnings.formattedPendingPayout}',      ScaffoldMessenger.of(context).showSnackBar(

              style: theme.textTheme.titleMedium,        SnackBar(content: Text('Error processing click: $e')),

            ),      );

            const SizedBox(height: 8),    }

            Text(  }

              'Minimum payout: ₹100',

              style: theme.textTheme.bodySmall,  void _showWithdrawDialog(double amount) {

            ),    showDialog(

            const SizedBox(height: 16),      context: context,

            SizedBox(      builder: (context) => AlertDialog(

              width: double.infinity,        title: const Text('💰 Withdraw Earnings'),

              child: ElevatedButton(        content: Column(

                onPressed: earnings.canWithdraw ? _handlePayoutRequest : null,          mainAxisSize: MainAxisSize.min,

                style: ElevatedButton.styleFrom(          children: [

                  backgroundColor: colorScheme.primary,            Text('Available: ₹${amount.toStringAsFixed(2)}'),

                  foregroundColor: colorScheme.onPrimary,            const SizedBox(height: 16),

                ),            const Text('Minimum withdrawal: ₹10'),

                child: Text(            const Text('Processing time: 1-3 business days'),

                  earnings.canWithdraw ? 'Request Payout' : 'Minimum not reached',          ],

                ),        ),

              ),        actions: [

            ),          TextButton(

          ],            onPressed: () => Navigator.pop(context),

        ),            child: const Text('Cancel'),

      ),          ),

    );          ElevatedButton(

  }            onPressed: () {

              Navigator.pop(context);

  Widget _buildEmptyRewardsWidget() {              // TODO: Implement withdrawal

    return Center(              ScaffoldMessenger.of(context).showSnackBar(

      child: Column(                const SnackBar(

        mainAxisAlignment: MainAxisAlignment.center,                  content: Text('Withdrawal feature coming soon!'),

        children: [                ),

          Icon(              );

            Icons.card_giftcard_outlined,            },

            size: 80,            child: const Text('Withdraw'),

            color: Colors.grey[400],          ),

          ),        ],

          const SizedBox(height: 16),      ),

          Text(    );

            'No rewards yet',  }

            style: Theme.of(context).textTheme.titleLarge,}
          ),
          const SizedBox(height: 8),
          Text(
            'Complete tasks to earn reward coupons',
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyOffersWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.local_offer_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No offers available',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Check back later for new offers',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 80,
            color: Colors.red[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Something went wrong',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              ref.read(rewardProvider.notifier).loadUserRewards();
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton(ColorScheme colorScheme) {
    return FloatingActionButton.extended(
      onPressed: _handleScanQR,
      backgroundColor: colorScheme.primary,
      foregroundColor: colorScheme.onPrimary,
      icon: const Icon(Icons.qr_code_scanner),
      label: const Text('Scan Offer'),
    );
  }

  // Event handlers
  void _handleRewardRevealed(RewardModel reward) {
    ref.read(rewardProvider.notifier).markRewardAsRevealed(reward.couponId);
  }

  void _handleRewardClaim(RewardModel reward) async {
    try {
      await ref.read(rewardProvider.notifier).claimReward(reward.couponId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reward claimed successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to claim reward: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _handleOfferTap(OfferModel offer) {
    // Navigate to offer details screen
    Navigator.pushNamed(
      context,
      '/offer-details',
      arguments: offer,
    );
  }

  void _handlePayoutRequest() async {
    try {
      await ref.read(rewardProvider.notifier).requestPayout();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payout request submitted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to request payout: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _handleScanQR() {
    // Implement QR code scanning for special offers
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('QR Scanner coming soon!'),
      ),
    );
  }

  void _filterOffersByCategory(String category) {
    ref.read(rewardProvider.notifier).filterOffersByCategory(
      category == 'All' ? null : category,
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _TabBarDelegate({required this.child});

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  double get maxExtent => 60;

  @override
  double get minExtent => 60;

  @override
  bool shouldRebuild(_TabBarDelegate oldDelegate) => false;
}