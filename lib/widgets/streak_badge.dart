import 'package:flutter/material.dart';
import 'package:streaky_app/models/streak_model.dart';

/// Animated streak badge widget with progress indicator and milestone effects
class StreakBadge extends StatefulWidget {
  final Streak streak;
  final VoidCallback? onTap;
  final bool showDetails;
  final bool isCompact;
  final bool showProgress;

  const StreakBadge({
    Key? key,
    required this.streak,
    this.onTap,
    this.showDetails = true,
    this.isCompact = false,
    this.showProgress = true,
  }) : super(key: key);

  @override
  State<StreakBadge> createState() => _StreakBadgeState();
}

class _StreakBadgeState extends State<StreakBadge>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _bounceController;
  late AnimationController _progressController;
  late AnimationController _shimmerController;
  
  late Animation<double> _pulseAnimation;
  late Animation<double> _bounceAnimation;
  late Animation<double> _progressAnimation;
  late Animation<double> _shimmerAnimation;

  bool _showCelebration = false;

  @override
  void initState() {
    super.initState();
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _bounceAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _bounceController,
      curve: Curves.elasticOut,
    ));

    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeOutCubic,
    ));

    _shimmerAnimation = Tween<double>(
      begin: -1.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _shimmerController,
      curve: Curves.easeInOut,
    ));

    // Start animations
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _progressController.forward();
      if (_shouldPulse()) {
        _startPulseAnimation();
      }
      if (_isMilestone()) {
        _startMilestoneCelebration();
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _bounceController.dispose();
    _progressController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  bool _shouldPulse() {
    return widget.streak.isActive && widget.streak.currentCount >= 7;
  }

  bool _isMilestone() {
    final count = widget.streak.currentCount;
    return count > 0 && (count % 10 == 0 || count % 7 == 0);
  }

  void _startPulseAnimation() {
    _pulseController.repeat(reverse: true);
  }

  void _startMilestoneCelebration() {
    _bounceController.forward().then((_) {
      _bounceController.reverse();
    });
    
    _shimmerController.repeat();
    
    setState(() {
      _showCelebration = true;
    });
    
    // Stop celebration after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        _shimmerController.stop();
        setState(() {
          _showCelebration = false;
        });
      }
    });
  }

  Color _getStreakColor() {
    if (!widget.streak.isActive) {
      return Colors.grey;
    }
    
    final count = widget.streak.currentCount;
    if (count >= 30) return Colors.purple;
    if (count >= 21) return Colors.indigo;
    if (count >= 14) return Colors.blue;
    if (count >= 7) return Colors.green;
    if (count >= 3) return Colors.orange;
    return Colors.red;
  }

  IconData _getStreakIcon() {
    final count = widget.streak.currentCount;
    if (count >= 30) return Icons.auto_awesome;
    if (count >= 21) return Icons.star;
    if (count >= 14) return Icons.local_fire_department;
    if (count >= 7) return Icons.whatshot;
    if (count >= 3) return Icons.trending_up;
    return Icons.play_arrow;
  }

  String _getStreakDescription() {
    final count = widget.streak.currentCount;
    if (count >= 30) return 'Legendary!';
    if (count >= 21) return 'Amazing!';
    if (count >= 14) return 'On Fire!';
    if (count >= 7) return 'Great!';
    if (count >= 3) return 'Good!';
    if (count > 0) return 'Started!';
    return 'Begin';
  }

  double _getProgressValue() {
    final nextMilestone = _getNextMilestone();
    if (nextMilestone == 0) return 1.0;
    
    final progress = widget.streak.currentCount / nextMilestone;
    return progress.clamp(0.0, 1.0);
  }

  int _getNextMilestone() {
    final count = widget.streak.currentCount;
    final milestones = [3, 7, 14, 21, 30, 60, 90, 180, 365];
    
    for (final milestone in milestones) {
      if (count < milestone) return milestone;
    }
    
    return (count ~/ 100 + 1) * 100; // After 365, go by 100s
  }

  String _getProgressText() {
    final nextMilestone = _getNextMilestone();
    return '${widget.streak.currentCount}/${nextMilestone}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final streakColor = _getStreakColor();
    final progressValue = _getProgressValue();

    return GestureDetector(
      onTap: () {
        _bounceController.forward().then((_) {
          _bounceController.reverse();
        });
        widget.onTap?.call();
      },
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _pulseAnimation,
          _bounceAnimation,
          _progressAnimation,
        ]),
        builder: (context, child) {
          return Transform.scale(
            scale: _pulseAnimation.value * _bounceAnimation.value,
            child: Container(
              margin: EdgeInsets.all(widget.isCompact ? 4 : 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    streakColor.withOpacity(0.1),
                    streakColor.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(widget.isCompact ? 12 : 16),
                border: Border.all(
                  color: streakColor.withOpacity(0.3),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: streakColor.withOpacity(0.2),
                    blurRadius: widget.isCompact ? 4 : 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Shimmer effect for milestones
                  if (_showCelebration)
                    Positioned.fill(
                      child: AnimatedBuilder(
                        animation: _shimmerAnimation,
                        builder: (context, child) {
                          return Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(widget.isCompact ? 12 : 16),
                              gradient: LinearGradient(
                                begin: Alignment(-1.0 + _shimmerAnimation.value, 0.0),
                                end: Alignment(1.0 + _shimmerAnimation.value, 0.0),
                                colors: [
                                  Colors.transparent,
                                  Colors.white.withOpacity(0.3),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  
                  // Main content
                  Padding(
                    padding: EdgeInsets.all(widget.isCompact ? 12 : 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Header row
                        Row(
                          children: [
                            // Streak icon
                            Container(
                              padding: EdgeInsets.all(widget.isCompact ? 8 : 12),
                              decoration: BoxDecoration(
                                color: streakColor,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: streakColor.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Icon(
                                _getStreakIcon(),
                                color: Colors.white,
                                size: widget.isCompact ? 16 : 20,
                              ),
                            ),
                            
                            const SizedBox(width: 12),
                            
                            // Streak info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.streak.name,
                                    style: (widget.isCompact 
                                        ? theme.textTheme.titleSmall 
                                        : theme.textTheme.titleMedium)?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: streakColor,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  
                                  if (widget.showDetails)
                                    Text(
                                      _getStreakDescription(),
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            
                            // Streak count
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: streakColor,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '${widget.streak.currentCount}',
                                style: (widget.isCompact 
                                    ? theme.textTheme.titleSmall 
                                    : theme.textTheme.titleMedium)?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        
                        // Progress bar
                        if (widget.showProgress && !widget.isCompact)
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Progress to ${_getNextMilestone()}',
                                      style: theme.textTheme.labelSmall?.copyWith(
                                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                                      ),
                                    ),
                                    Text(
                                      _getProgressText(),
                                      style: theme.textTheme.labelSmall?.copyWith(
                                        color: streakColor,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                
                                const SizedBox(height: 8),
                                
                                Container(
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: streakColor.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                  child: AnimatedBuilder(
                                    animation: _progressAnimation,
                                    builder: (context, child) {
                                      return FractionallySizedBox(
                                        alignment: Alignment.centerLeft,
                                        widthFactor: progressValue * _progressAnimation.value,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                streakColor,
                                                streakColor.withOpacity(0.8),
                                              ],
                                            ),
                                            borderRadius: BorderRadius.circular(3),
                                            boxShadow: [
                                              BoxShadow(
                                                color: streakColor.withOpacity(0.3),
                                                blurRadius: 4,
                                                offset: const Offset(0, 1),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        
                        // Additional details
                        if (widget.showDetails && !widget.isCompact)
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Row(
                              children: [
                                // Best streak
                                Expanded(
                                  child: _buildStatItem(
                                    icon: Icons.emoji_events,
                                    label: 'Best',
                                    value: '${widget.streak.longestStreak}',
                                    color: Colors.amber,
                                  ),
                                ),
                                
                                const SizedBox(width: 12),
                                
                                // Total days
                                Expanded(
                                  child: _buildStatItem(
                                    icon: Icons.calendar_today,
                                    label: 'Total',
                                    value: '${widget.streak.totalDays}',
                                    color: Colors.blue,
                                  ),
                                ),
                                
                                const SizedBox(width: 12),
                                
                                // Status
                                Expanded(
                                  child: _buildStatItem(
                                    icon: widget.streak.isActive 
                                        ? Icons.trending_up 
                                        : Icons.pause,
                                    label: 'Status',
                                    value: widget.streak.isActive ? 'Active' : 'Paused',
                                    color: widget.streak.isActive 
                                        ? Colors.green 
                                        : Colors.orange,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  
                  // Milestone celebration overlay
                  if (_showCelebration)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(widget.isCompact ? 12 : 16),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.celebration,
                            size: widget.isCompact ? 24 : 32,
                            color: Colors.amber,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    final theme = Theme.of(context);
    
    return Column(
      children: [
        Icon(
          icon,
          size: 16,
          color: color,
        ),
        
        const SizedBox(height: 4),
        
        Text(
          value,
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
      ],
    );
  }
}