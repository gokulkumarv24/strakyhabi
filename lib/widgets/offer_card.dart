import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/reward_providers.dart';
import '../widgets/scratch_coupon_card.dart';
import '../models/offer_model.dart';

class OfferCard extends ConsumerWidget {
  final OfferModel offer;
  final String userId;
  
  const OfferCard({
    Key? key,
    required this.offer,
    required this.userId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showOfferDetails(context, ref),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with brand logo and earning badges
              Row(
                children: [
                  // Brand logo
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.grey[100],
                    ),
                    child: offer.logoUrl.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              offer.logoUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Icon(Icons.store, color: Colors.grey[600]),
                            ),
                          )
                        : Icon(Icons.store, color: Colors.grey[600]),
                  ),
                  const SizedBox(width: 12),
                  
                  // Brand name and offer title
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          offer.brand,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          offer.title,
                          style: Theme.of(context).textTheme.bodyMedium,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  
                  // Earning badges
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // CPC badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green[100],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green[300]!),
                        ),
                        child: Text(
                          '₹${offer.cpcRate.toStringAsFixed(1)} CPC',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.green[700],
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      
                      // CPS badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue[100],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue[300]!),
                        ),
                        child: Text(
                          '${offer.cpsRate.toStringAsFixed(1)}% CPS',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Description
              Text(
                offer.description,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              
              const SizedBox(height: 12),
              
              // Category and source tags
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      offer.categoryDisplayName,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.orange[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      offer.source.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const Spacer(),
                  
                  // Earning potential
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Est. Earning',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        '₹${offer.estimatedEarning.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[700],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Action button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _handleOfferClick(context, ref),
                  icon: const Icon(Icons.touch_app, size: 18),
                  label: const Text('Tap to Earn', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[600],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showOfferDetails(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => OfferDetailsSheet(offer: offer, userId: userId),
    );
  }

  void _handleOfferClick(BuildContext context, WidgetRef ref) async {
    final rewardService = ref.read(rewardServiceProvider);
    
    // Show scratch card animation first
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: ScratchCouponCard(
          couponAmount: offer.cpcRate,
          onScratchComplete: () async {
            // Log the click
            await rewardService.logClick(
              userId: userId,
              offerId: offer.id,
              source: offer.source,
              cpcRate: offer.cpcRate,
            );
            Navigator.of(context).pop(true);
          },
        ),
      ),
    );
    
    if (result == true) {
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.celebration, color: Colors.white),
              const SizedBox(width: 8),
              Text('Earned ₹${offer.cpcRate}! Opening offer...'),
            ],
          ),
          backgroundColor: Colors.green[600],
          duration: const Duration(seconds: 2),
        ),
      );
      
      // Open affiliate link
      await Future.delayed(const Duration(milliseconds: 500));
      _openAffiliateLink(ref);
      
      // Refresh earnings
      ref.invalidate(userEarningsProvider(userId));
    }
  }

  void _openAffiliateLink(WidgetRef ref) async {
    final rewardService = ref.read(rewardServiceProvider);
    final affiliateUrl = rewardService.generateAffiliateLink(offer, userId);
    
    if (await canLaunchUrl(Uri.parse(affiliateUrl))) {
      await launchUrl(
        Uri.parse(affiliateUrl),
        mode: LaunchMode.externalApplication,
      );
    }
  }
}

class OfferDetailsSheet extends ConsumerWidget {
  final OfferModel offer;
  final String userId;
  
  const OfferDetailsSheet({
    Key? key,
    required this.offer,
    required this.userId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.9,
      minChildSize: 0.5,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 8),
                height: 4,
                width: 40,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: Colors.grey[100],
                            ),
                            child: offer.logoUrl.isNotEmpty
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.network(
                                      offer.logoUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) =>
                                          Icon(Icons.store, size: 30, color: Colors.grey[600]),
                                    ),
                                  )
                                : Icon(Icons.store, size: 30, color: Colors.grey[600]),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  offer.brand,
                                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  offer.title,
                                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Earning info cards
                      Row(
                        children: [
                          Expanded(
                            child: _buildEarningCard(
                              'Instant Click',
                              '₹${offer.cpcRate}',
                              'Earn immediately on click',
                              Colors.green,
                              Icons.touch_app,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildEarningCard(
                              'Sale Commission',
                              '${offer.cpsRate}%',
                              'Earn when someone buys',
                              Colors.blue,
                              Icons.shopping_cart,
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Description
                      Text(
                        'About this offer',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        offer.description,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[700],
                          height: 1.5,
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Terms and conditions
                      if (offer.terms.isNotEmpty) ...[
                        Text(
                          'Terms & Conditions',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          offer.terms,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                      
                      // Additional info
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: Column(
                          children: [
                            _buildInfoRow('Category', offer.categoryDisplayName),
                            const Divider(height: 16),
                            _buildInfoRow('Network', offer.source.toUpperCase()),
                            const Divider(height: 16),
                            _buildInfoRow('Currency', offer.currency),
                            const Divider(height: 16),
                            _buildInfoRow('Est. Earning', '₹${offer.estimatedEarning.toStringAsFixed(0)}'),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Action button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _handleOfferClick(context, ref);
                          },
                          icon: const Icon(Icons.celebration, size: 20),
                          label: Text(
                            'Earn ₹${offer.cpcRate} Now!',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green[600],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEarningCard(
    String title,
    String amount,
    String subtitle,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color.withOpacity(0.8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            amount,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 10,
              color: color.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  void _handleOfferClick(BuildContext context, WidgetRef ref) async {
    final rewardService = ref.read(rewardServiceProvider);
    
    // Show scratch card animation
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: ScratchCouponCard(
          couponAmount: offer.cpcRate,
          onScratchComplete: () async {
            await rewardService.logClick(
              userId: userId,
              offerId: offer.id,
              source: offer.source,
              cpcRate: offer.cpcRate,
            );
            Navigator.of(context).pop(true);
          },
        ),
      ),
    );
    
    if (result == true) {
      // Success feedback
      HapticFeedback.lightImpact();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.celebration, color: Colors.white),
              const SizedBox(width: 8),
              Text('Earned ₹${offer.cpcRate}! Opening ${offer.brand}...'),
            ],
          ),
          backgroundColor: Colors.green[600],
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
            label: 'View Earnings',
            textColor: Colors.white,
            onPressed: () {
              // Navigate to earnings tab
            },
          ),
        ),
      );
      
      // Open affiliate link
      await Future.delayed(const Duration(milliseconds: 500));
      _openAffiliateLink(ref);
      
      // Refresh data
      ref.invalidate(userEarningsProvider(userId));
      ref.invalidate(recentActivityProvider(userId));
    }
  }

  void _openAffiliateLink(WidgetRef ref) async {
    final rewardService = ref.read(rewardServiceProvider);
    final affiliateUrl = rewardService.generateAffiliateLink(offer, userId);
    
    if (await canLaunchUrl(Uri.parse(affiliateUrl))) {
      await launchUrl(
        Uri.parse(affiliateUrl),
        mode: LaunchMode.externalApplication,
      );
    }
  }
}