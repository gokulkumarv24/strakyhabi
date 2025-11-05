import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ScratchCouponCard extends StatefulWidget {
  final String title;
  final String description;
  final int coinValue;
  final VoidCallback? onScratch;
  final bool isScratched;

  const ScratchCouponCard({
    Key? key,
    required this.title,
    required this.description,
    required this.coinValue,
    this.onScratch,
    this.isScratched = false,
  }) : super(key: key);

  @override
  _ScratchCouponCardState createState() => _ScratchCouponCardState();
}

class _ScratchCouponCardState extends State<ScratchCouponCard>
    with TickerProviderStateMixin {
  late AnimationController _shimmerController;
  late AnimationController _bounceController;
  bool _isScratching = false;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
    
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    _bounceController.dispose();
    super.dispose();
  }

  void _handleScratch() {
    if (widget.isScratched || _isScratching) return;
    
    setState(() {
      _isScratching = true;
    });
    
    // Haptic feedback
    HapticFeedback.mediumImpact();
    
    // Bounce animation
    _bounceController.forward().then((_) {
      _bounceController.reverse();
    });
    
    // Call parent callback after animation
    Future.delayed(const Duration(milliseconds: 300), () {
      widget.onScratch?.call();
      setState(() {
        _isScratching = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _bounceController,
      builder: (context, child) {
        return Transform.scale(
          scale: 1.0 + (_bounceController.value * 0.1),
          child: Container(
            width: 280,
            height: 180,
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: widget.isScratched 
                  ? [Colors.green.shade400, Colors.green.shade600]
                  : [Colors.orange.shade400, Colors.deepOrange.shade600],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _handleScratch,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Coin icon with shimmer
                      if (!widget.isScratched)
                        AnimatedBuilder(
                          animation: _shimmerController,
                          builder: (context, child) {
                            return Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.white.withOpacity(0.1),
                                    Colors.white.withOpacity(0.3),
                                    Colors.white.withOpacity(0.1),
                                  ],
                                  stops: [
                                    (_shimmerController.value - 0.3).clamp(0.0, 1.0),
                                    _shimmerController.value.clamp(0.0, 1.0),
                                    (_shimmerController.value + 0.3).clamp(0.0, 1.0),
                                  ],
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.monetization_on,
                                size: 48,
                                color: Colors.amber,
                              ),
                            );
                          },
                        ),
                      
                      // Success icon
                      if (widget.isScratched)
                        const Icon(
                          Icons.check_circle,
                          size: 48,
                          color: Colors.white,
                        ),
                      
                      const SizedBox(height: 12),
                      
                      // Title
                      Text(
                        widget.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      
                      const SizedBox(height: 8),
                      
                      // Description
                      Text(
                        widget.description,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // Coin value
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.stars,
                              color: Colors.amber,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '₹${widget.coinValue}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 8),
                      
                      // Action text
                      Text(
                        widget.isScratched 
                          ? '✅ Reward Earned!' 
                          : _isScratching 
                            ? '✨ Scratching...' 
                            : '👆 Tap to scratch!',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}