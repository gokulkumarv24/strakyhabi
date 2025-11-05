// Copilot Prompt:# 🎁 Reward Coupon CPS/CPC Development Guide

// Create a Flutter widget for a scratch coupon card with animated reveal, shimmer effects, and reward display in Material Design 3 style.### **Building Paytm-Style Cashback & Coupon Engine with Affiliate Monetization**



import 'package:flutter/material.dart';---

import 'package:flutter/services.dart';

import 'dart:math' as math;## 🎯 **Vision: Gamified Coupon Engine**

import '../models/reward_model.dart';

Transform your productivity app into a **cashback rewards platform** where:

class ScratchCouponCard extends StatefulWidget {- Users earn **instant scratch coupons** on clicks (CPC)

  final RewardModel reward;- Users get **real cashback** on purchases (CPS)

  final VoidCallback? onRevealed;- You monetize through **affiliate commissions** behind the scenes

  final VoidCallback? onClaim;- Experience feels like **Paytm, GPay, or PhonePe rewards**

  final bool isScratched;

---

  const ScratchCouponCard({

    Key? key,## 💡 **How Users See It vs. How You Earn**

    required this.reward,

    this.onRevealed,| User Experience | Behind the Scenes | Your Revenue |

    this.onClaim,|---|---|---|

    this.isScratched = false,| "Tap to unlock ₹10 coupon!" | CPC click via Cuelinks affiliate link | ₹0.50-₹2.00 per click |

  }) : super(key: key);| "Buy & get ₹50 cashback!" | CPS sale confirmation webhook | 5-15% of purchase value |

| "Streak bonus: ₹25 coins!" | Engagement multiplier on existing CPC | Retention boost = more clicks |

  @override| "Scratch card unlocked!" | Gamification layer over real rewards | Higher user engagement |

  State<ScratchCouponCard> createState() => _ScratchCouponCardState();

}---



class _ScratchCouponCardState extends State<ScratchCouponCard>## 🏗️ **Architecture Overview**

    with TickerProviderStateMixin {

  late AnimationController _scratchController;```

  late AnimationController _revealController;Flutter App (Coupon UI) ←→ Cloudflare Worker (CPC/CPS Logic) ←→ Affiliate Networks

  late AnimationController _shimmerController;     ↓                           ↓                                    ↓

  Hive Local Storage         KV Storage (Clicks/Sales)           Real Commission APIs

  late Animation<double> _scratchProgress;(Offline rewards)         (Revenue tracking)                  (Cuelinks, Admitad, etc.)

  late Animation<double> _revealScale;```

  late Animation<double> _shimmerAnimation;

  ---

  bool _isScratched = false;

  bool _isRevealed = false;## 🎨 **1. Flutter Reward UI Components**

  List<Offset> _scratchPoints = [];

  ### **A. Scratch Card Widget**

  @override

  void initState() {<function_calls>

    super.initState();<invoke name="create_file">

    _isScratched = widget.isScratched;<parameter name="content">import 'package:flutter/material.dart';

    import 'package:flutter/services.dart';

    _scratchController = AnimationController(import 'package:lottie/lottie.dart';

      duration: const Duration(milliseconds: 800),

      vsync: this,class ScratchCouponCard extends StatefulWidget {

    );  final String title;

      final String description;

    _revealController = AnimationController(  final int coinValue;

      duration: const Duration(milliseconds: 1200),  final VoidCallback? onScratch;

      vsync: this,  final bool isScratched;

    );

      const ScratchCouponCard({

    _shimmerController = AnimationController(    Key? key,

      duration: const Duration(seconds: 2),    required this.title,

      vsync: this,    required this.description,

    )..repeat();    required this.coinValue,

        this.onScratch,

    _scratchProgress = Tween<double>(begin: 0.0, end: 1.0).animate(    this.isScratched = false,

      CurvedAnimation(parent: _scratchController, curve: Curves.easeInOut),  }) : super(key: key);

    );

      @override

    _revealScale = Tween<double>(begin: 0.8, end: 1.0).animate(  _ScratchCouponCardState createState() => _ScratchCouponCardState();

      CurvedAnimation(parent: _revealController, curve: Curves.elasticOut),}

    );

    class _ScratchCouponCardState extends State<ScratchCouponCard>

    _shimmerAnimation = Tween<double>(begin: -1.0, end: 2.0).animate(    with TickerProviderStateMixin {

      CurvedAnimation(parent: _shimmerController, curve: Curves.linear),  late AnimationController _shimmerController;

    );  late AnimationController _bounceController;

      bool _isScratching = false;

    if (_isScratched) {

      _scratchController.value = 1.0;  @override

      _revealController.forward();  void initState() {

    }    super.initState();

  }    _shimmerController = AnimationController(

      duration: const Duration(seconds: 2),

  @override      vsync: this,

  void dispose() {    )..repeat();

    _scratchController.dispose();    

    _revealController.dispose();    _bounceController = AnimationController(

    _shimmerController.dispose();      duration: const Duration(milliseconds: 600),

    super.dispose();      vsync: this,

  }    );

  }

  void _onPanUpdate(DragUpdateDetails details) {

    if (_isScratched) return;  @override

      void dispose() {

    setState(() {    _shimmerController.dispose();

      _scratchPoints.add(details.localPosition);    _bounceController.dispose();

    });    super.dispose();

      }

    // Check if enough area is scratched

    if (_scratchPoints.length > 50 && !_isRevealed) {  void _handleScratch() {

      _revealReward();    if (widget.isScratched || _isScratching) return;

    }    

  }    setState(() {

      _isScratching = true;

  void _revealReward() {    });

    if (_isRevealed) return;    

        // Haptic feedback

    setState(() {    HapticFeedback.mediumImpact();

      _isScratched = true;    

      _isRevealed = true;    // Bounce animation

    });    _bounceController.forward().then((_) {

          _bounceController.reverse();

    HapticFeedback.mediumImpact();    });

    _scratchController.forward();    

    _revealController.forward();    // Call parent callback after animation

        Future.delayed(const Duration(milliseconds: 300), () {

    widget.onRevealed?.call();      widget.onScratch?.call();

  }      setState(() {

        _isScratching = false;

  @override      });

  Widget build(BuildContext context) {    });

    final theme = Theme.of(context);  }

    final colorScheme = theme.colorScheme;

      @override

    return Card(  Widget build(BuildContext context) {

      elevation: 8,    return AnimatedBuilder(

      clipBehavior: Clip.antiAlias,      animation: _bounceController,

      child: Container(      builder: (context, child) {

        height: 200,        return Transform.scale(

        decoration: BoxDecoration(          scale: 1.0 + (_bounceController.value * 0.1),

          gradient: LinearGradient(          child: Container(

            colors: [            margin: const EdgeInsets.all(8),

              widget.reward.type == RewardType.cpc             decoration: BoxDecoration(

                ? colorScheme.primaryContainer              gradient: LinearGradient(

                : colorScheme.secondaryContainer,                colors: widget.isScratched 

              widget.reward.type == RewardType.cpc                  ? [Colors.green.shade400, Colors.green.shade600]

                ? colorScheme.primary.withOpacity(0.7)                  : [Colors.orange.shade400, Colors.deepOrange.shade600],

                : colorScheme.secondary.withOpacity(0.7),                begin: Alignment.topLeft,

            ],                end: Alignment.bottomRight,

            begin: Alignment.topLeft,              ),

            end: Alignment.bottomRight,              borderRadius: BorderRadius.circular(16),

          ),              boxShadow: [

        ),                BoxShadow(

        child: Stack(                  color: Colors.black.withOpacity(0.2),

          children: [                  blurRadius: 8,

            // Background pattern                  offset: const Offset(0, 4),

            _buildBackgroundPattern(),                ),

                          ],

            // Shimmer effect            ),

            if (!_isScratched) _buildShimmerEffect(),            child: Material(

                          color: Colors.transparent,

            // Scratch overlay              child: InkWell(

            if (!_isScratched) _buildScratchOverlay(),                onTap: _handleScratch,

                            borderRadius: BorderRadius.circular(16),

            // Revealed content                child: Container(

            AnimatedBuilder(                  padding: const EdgeInsets.all(16),

              animation: _revealScale,                  child: Column(

              builder: (context, child) {                    mainAxisSize: MainAxisSize.min,

                return Transform.scale(                    children: [

                  scale: _revealScale.value,                      // Coin icon with shimmer

                  child: Opacity(                      if (!widget.isScratched)

                    opacity: _isScratched ? 1.0 : 0.0,                        AnimatedBuilder(

                    child: _buildRevealedContent(theme, colorScheme),                          animation: _shimmerController,

                  ),                          builder: (context, child) {

                );                            return Container(

              },                              decoration: BoxDecoration(

            ),                                gradient: LinearGradient(

                                              colors: [

            // Scratch instruction                                    Colors.white.withOpacity(0.1),

            if (!_isScratched) _buildScratchInstruction(theme),                                    Colors.white.withOpacity(0.3),

          ],                                    Colors.white.withOpacity(0.1),

        ),                                  ],

      ),                                  stops: [

    );                                    _shimmerController.value - 0.3,

  }                                    _shimmerController.value,

                                    _shimmerController.value + 0.3,

  Widget _buildBackgroundPattern() {                                  ].map((e) => e.clamp(0.0, 1.0)).toList(),

    return CustomPaint(                                ),

      painter: PatternPainter(),                                shape: BoxShape.circle,

      size: Size.infinite,                              ),

    );                              child: const Icon(

  }                                Icons.monetization_on,

                                size: 48,

  Widget _buildShimmerEffect() {                                color: Colors.amber,

    return AnimatedBuilder(                              ),

      animation: _shimmerAnimation,                            );

      builder: (context, child) {                          },

        return Container(                        ),

          decoration: BoxDecoration(                      

            gradient: LinearGradient(                      // Success animation

              colors: [                      if (widget.isScratched)

                Colors.transparent,                        Lottie.asset(

                Colors.white.withOpacity(0.3),                          'assets/animations/success_coins.json',

                Colors.transparent,                          width: 64,

              ],                          height: 64,

              stops: const [0.0, 0.5, 1.0],                          repeat: false,

              begin: Alignment(-1.0 + _shimmerAnimation.value, -1.0),                        ),

              end: Alignment(1.0 + _shimmerAnimation.value, 1.0),                      

            ),                      const SizedBox(height: 12),

          ),                      

        );                      // Title

      },                      Text(

    );                        widget.title,

  }                        style: const TextStyle(

                          color: Colors.white,

  Widget _buildScratchOverlay() {                          fontSize: 18,

    return GestureDetector(                          fontWeight: FontWeight.bold,

      onPanUpdate: _onPanUpdate,                        ),

      onTap: _revealReward,                        textAlign: TextAlign.center,

      child: CustomPaint(                      ),

        painter: ScratchPainter(_scratchPoints),                      

        size: Size.infinite,                      const SizedBox(height: 8),

        child: Container(                      

          decoration: BoxDecoration(                      // Description

            gradient: LinearGradient(                      Text(

              colors: [                        widget.description,

                Colors.grey[300]!,                        style: TextStyle(

                Colors.grey[400]!,                          color: Colors.white.withOpacity(0.9),

              ],                          fontSize: 14,

              begin: Alignment.topLeft,                        ),

              end: Alignment.bottomRight,                        textAlign: TextAlign.center,

            ),                      ),

          ),                      

        ),                      const SizedBox(height: 12),

      ),                      

    );                      // Coin value

  }                      Container(

                        padding: const EdgeInsets.symmetric(

  Widget _buildRevealedContent(ThemeData theme, ColorScheme colorScheme) {                          horizontal: 16,

    return Padding(                          vertical: 8,

      padding: const EdgeInsets.all(20.0),                        ),

      child: Column(                        decoration: BoxDecoration(

        crossAxisAlignment: CrossAxisAlignment.start,                          color: Colors.white.withOpacity(0.2),

        children: [                          borderRadius: BorderRadius.circular(20),

          // Reward type badge                        ),

          Container(                        child: Row(

            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),                          mainAxisSize: MainAxisSize.min,

            decoration: BoxDecoration(                          children: [

              color: widget.reward.type == RewardType.cpc                             const Icon(

                ? colorScheme.primary                              Icons.stars,

                : colorScheme.secondary,                              color: Colors.amber,

              borderRadius: BorderRadius.circular(20),                              size: 20,

            ),                            ),

            child: Text(                            const SizedBox(width: 8),

              widget.reward.typeDisplayName,                            Text(

              style: theme.textTheme.labelSmall?.copyWith(                              '${widget.coinValue} Coins',

                color: widget.reward.type == RewardType.cpc                               style: const TextStyle(

                  ? colorScheme.onPrimary                                color: Colors.white,

                  : colorScheme.onSecondary,                                fontSize: 16,

                fontWeight: FontWeight.bold,                                fontWeight: FontWeight.w600,

              ),                              ),

            ),                            ),

          ),                          ],

                                  ),

          const Spacer(),                      ),

                                

          // Reward amount                      const SizedBox(height: 12),

          Row(                      

            children: [                      // Action text

              Icon(                      Text(

                widget.reward.type == RewardType.cpc                         widget.isScratched 

                  ? Icons.currency_rupee                          ? '✅ Scratched!' 

                  : Icons.percent,                          : _isScratching 

                size: 32,                            ? '✨ Scratching...' 

                color: colorScheme.onPrimaryContainer,                            : '👆 Tap to scratch!',

              ),                        style: TextStyle(

              const SizedBox(width: 8),                          color: Colors.white.withOpacity(0.8),

              Text(                          fontSize: 12,

                widget.reward.formattedReward,                          fontStyle: FontStyle.italic,

                style: theme.textTheme.headlineMedium?.copyWith(                        ),

                  color: colorScheme.onPrimaryContainer,                      ),

                  fontWeight: FontWeight.bold,                    ],

                ),                  ),

              ),                ),

            ],              ),

          ),            ),

                    ),

          const SizedBox(height: 8),        );

                },

          // Reward title    );

          Text(  }

            widget.reward.title,}

            style: theme.textTheme.titleMedium?.copyWith(

              color: colorScheme.onPrimaryContainer,// Usage Example

              fontWeight: FontWeight.w600,class RewardExample extends StatelessWidget {

            ),  @override

            maxLines: 2,  Widget build(BuildContext context) {

            overflow: TextOverflow.ellipsis,    return ScratchCouponCard(

          ),      title: 'Flipkart Flash Sale',

                description: 'Shop electronics & earn cashback',

          const Spacer(),      coinValue: 10,

                onScratch: () {

          // Claim button        // Trigger CPC logging

          if (widget.reward.isUnlocked && !widget.reward.isClaimed)        print('Coupon scratched - logging CPC event');

            SizedBox(      },

              width: double.infinity,    );

              child: ElevatedButton.icon(  }

                onPressed: widget.onClaim,}
                icon: const Icon(Icons.redeem),
                label: const Text('Claim Reward'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  elevation: 4,
                  shadowColor: colorScheme.primary.withOpacity(0.5),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildScratchInstruction(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.touch_app,
            size: 48,
            color: Colors.white.withOpacity(0.8),
          ),
          const SizedBox(height: 12),
          Text(
            'Scratch to reveal\nyour reward!',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              shadows: [
                Shadow(
                  offset: const Offset(1, 1),
                  blurRadius: 3,
                  color: Colors.black.withOpacity(0.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ScratchPainter extends CustomPainter {
  final List<Offset> points;
  
  ScratchPainter(this.points);
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.transparent
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 20.0
      ..blendMode = BlendMode.dstOut;
    
    for (int i = 0; i < points.length - 1; i++) {
      canvas.drawLine(points[i], points[i + 1], paint);
    }
    
    // Draw circles at each point for smoother scratching
    for (final point in points) {
      canvas.drawCircle(point, 15, paint);
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class PatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..strokeWidth = 1;
    
    const spacing = 20.0;
    
    // Draw diagonal lines pattern
    for (double i = -size.height; i < size.width + size.height; i += spacing) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i + size.height, size.height),
        paint,
      );
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Animated sparkles effect for revealed rewards
class SparklesPainter extends CustomPainter {
  final Animation<double> animation;
  final List<Sparkle> sparkles;
  
  SparklesPainter(this.animation, this.sparkles);
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.yellow.withOpacity(0.8)
      ..strokeWidth = 2;
    
    for (final sparkle in sparkles) {
      final progress = (animation.value - sparkle.delay).clamp(0.0, 1.0);
      if (progress > 0) {
        final opacity = (1 - progress) * sparkle.opacity;
        paint.color = sparkle.color.withOpacity(opacity);
        
        final x = sparkle.position.dx;
        final y = sparkle.position.dy - (progress * 50);
        
        canvas.drawCircle(Offset(x, y), sparkle.size * progress, paint);
      }
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class Sparkle {
  final Offset position;
  final double size;
  final Color color;
  final double delay;
  final double opacity;
  
  Sparkle({
    required this.position,
    required this.size,
    required this.color,
    required this.delay,
    required this.opacity,
  });
  
  static List<Sparkle> generate(Size size, int count) {
    final random = math.Random();
    return List.generate(count, (index) {
      return Sparkle(
        position: Offset(
          random.nextDouble() * size.width,
          random.nextDouble() * size.height,
        ),
        size: random.nextDouble() * 4 + 2,
        color: [Colors.yellow, Colors.orange, Colors.pink][random.nextInt(3)],
        delay: random.nextDouble() * 0.5,
        opacity: random.nextDouble() * 0.8 + 0.2,
      );
    });
  }
}