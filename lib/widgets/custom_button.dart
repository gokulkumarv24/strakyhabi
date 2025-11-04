import 'package:flutter/material.dart';

/// Highly customizable animated button widget with multiple styles and states
class CustomButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final ButtonStyle style;
  final ButtonSize size;
  final Color? color;
  final Color? textColor;
  final bool isLoading;
  final bool isEnabled;
  final double? width;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final Widget? child;

  const CustomButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.icon,
    this.style = ButtonStyle.filled,
    this.size = ButtonSize.medium,
    this.color,
    this.textColor,
    this.isLoading = false,
    this.isEnabled = true,
    this.width,
    this.margin,
    this.padding,
    this.child,
  }) : super(key: key);

  factory CustomButton.primary({
    required String text,
    VoidCallback? onPressed,
    IconData? icon,
    ButtonSize size = ButtonSize.medium,
    bool isLoading = false,
    double? width,
  }) {
    return CustomButton(
      text: text,
      onPressed: onPressed,
      icon: icon,
      style: ButtonStyle.filled,
      size: size,
      isLoading: isLoading,
      width: width,
    );
  }

  factory CustomButton.secondary({
    required String text,
    VoidCallback? onPressed,
    IconData? icon,
    ButtonSize size = ButtonSize.medium,
    bool isLoading = false,
    double? width,
  }) {
    return CustomButton(
      text: text,
      onPressed: onPressed,
      icon: icon,
      style: ButtonStyle.outlined,
      size: size,
      isLoading: isLoading,
      width: width,
    );
  }

  factory CustomButton.text({
    required String text,
    VoidCallback? onPressed,
    IconData? icon,
    ButtonSize size = ButtonSize.medium,
    Color? textColor,
    double? width,
  }) {
    return CustomButton(
      text: text,
      onPressed: onPressed,
      icon: icon,
      style: ButtonStyle.text,
      size: size,
      textColor: textColor,
      width: width,
    );
  }

  factory CustomButton.floating({
    required IconData icon,
    VoidCallback? onPressed,
    Color? color,
    ButtonSize size = ButtonSize.medium,
  }) {
    return CustomButton(
      text: '',
      icon: icon,
      onPressed: onPressed,
      style: ButtonStyle.floating,
      size: size,
      color: color,
    );
  }

  @override
  State<CustomButton> createState() => _CustomButtonState();
}

enum ButtonStyle {
  filled,
  outlined,
  text,
  floating,
  gradient,
}

enum ButtonSize {
  small,
  medium,
  large,
}

class _CustomButtonState extends State<CustomButton>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _loadingController;
  late AnimationController _rippleController;
  
  late Animation<double> _scaleAnimation;
  late Animation<double> _loadingAnimation;
  late Animation<double> _rippleAnimation;

  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    
    _loadingController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _rippleController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeInOut,
    ));

    _loadingAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _loadingController,
      curve: Curves.easeInOut,
    ));

    _rippleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _rippleController,
      curve: Curves.easeOut,
    ));

    if (widget.isLoading) {
      _loadingController.repeat();
    }
  }

  @override
  void didUpdateWidget(CustomButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.isLoading != oldWidget.isLoading) {
      if (widget.isLoading) {
        _loadingController.repeat();
      } else {
        _loadingController.stop();
        _loadingController.reset();
      }
    }
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _loadingController.dispose();
    _rippleController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (!_canPress()) return;
    
    setState(() {
      _isPressed = true;
    });
    
    _scaleController.forward();
    _rippleController.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _handleTapEnd();
  }

  void _onTapCancel() {
    _handleTapEnd();
  }

  void _handleTapEnd() {
    setState(() {
      _isPressed = false;
    });
    
    _scaleController.reverse();
    
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _rippleController.reverse();
      }
    });
  }

  bool _canPress() {
    return widget.isEnabled && !widget.isLoading && widget.onPressed != null;
  }

  Size _getButtonSize() {
    switch (widget.size) {
      case ButtonSize.small:
        return const Size(80, 32);
      case ButtonSize.medium:
        return const Size(120, 44);
      case ButtonSize.large:
        return const Size(160, 56);
    }
  }

  EdgeInsetsGeometry _getButtonPadding() {
    if (widget.padding != null) return widget.padding!;
    
    switch (widget.size) {
      case ButtonSize.small:
        return const EdgeInsets.symmetric(horizontal: 12, vertical: 6);
      case ButtonSize.medium:
        return const EdgeInsets.symmetric(horizontal: 16, vertical: 10);
      case ButtonSize.large:
        return const EdgeInsets.symmetric(horizontal: 24, vertical: 14);
    }
  }

  double _getIconSize() {
    switch (widget.size) {
      case ButtonSize.small:
        return 16;
      case ButtonSize.medium:
        return 20;
      case ButtonSize.large:
        return 24;
    }
  }

  TextStyle _getTextStyle(ThemeData theme) {
    final baseStyle = switch (widget.size) {
      ButtonSize.small => theme.textTheme.labelMedium,
      ButtonSize.medium => theme.textTheme.labelLarge,
      ButtonSize.large => theme.textTheme.titleMedium,
    };

    return baseStyle?.copyWith(
      fontWeight: FontWeight.w600,
      color: _getTextColor(theme),
    ) ?? TextStyle(color: _getTextColor(theme));
  }

  Color _getBackgroundColor(ThemeData theme) {
    if (widget.color != null) return widget.color!;
    
    switch (widget.style) {
      case ButtonStyle.filled:
        return theme.colorScheme.primary;
      case ButtonStyle.outlined:
        return Colors.transparent;
      case ButtonStyle.text:
        return Colors.transparent;
      case ButtonStyle.floating:
        return theme.colorScheme.primary;
      case ButtonStyle.gradient:
        return Colors.transparent;
    }
  }

  Color _getTextColor(ThemeData theme) {
    if (widget.textColor != null) return widget.textColor!;
    
    switch (widget.style) {
      case ButtonStyle.filled:
        return theme.colorScheme.onPrimary;
      case ButtonStyle.outlined:
        return theme.colorScheme.primary;
      case ButtonStyle.text:
        return theme.colorScheme.primary;
      case ButtonStyle.floating:
        return theme.colorScheme.onPrimary;
      case ButtonStyle.gradient:
        return Colors.white;
    }
  }

  Border? _getBorder(ThemeData theme) {
    switch (widget.style) {
      case ButtonStyle.outlined:
        return Border.all(
          color: widget.color ?? theme.colorScheme.primary,
          width: 2,
        );
      default:
        return null;
    }
  }

  Gradient? _getGradient(ThemeData theme) {
    if (widget.style != ButtonStyle.gradient) return null;
    
    final color = widget.color ?? theme.colorScheme.primary;
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        color,
        color.withOpacity(0.8),
      ],
    );
  }

  double _getBorderRadius() {
    switch (widget.style) {
      case ButtonStyle.floating:
        return _getButtonSize().height / 2;
      default:
        return switch (widget.size) {
          ButtonSize.small => 8,
          ButtonSize.medium => 12,
          ButtonSize.large => 16,
        };
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = _getButtonSize();
    final isFloating = widget.style == ButtonStyle.floating;

    return Container(
      margin: widget.margin,
      width: widget.width,
      height: isFloating ? size.height : null,
      child: GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        onTap: _canPress() ? widget.onPressed : null,
        child: AnimatedBuilder(
          animation: Listenable.merge([
            _scaleAnimation,
            _rippleAnimation,
          ]),
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Main button
                  Container(
                    width: isFloating ? size.height : null,
                    height: isFloating ? size.height : null,
                    padding: isFloating ? EdgeInsets.zero : _getButtonPadding(),
                    decoration: BoxDecoration(
                      color: _getBackgroundColor(theme),
                      gradient: _getGradient(theme),
                      border: _getBorder(theme),
                      borderRadius: BorderRadius.circular(_getBorderRadius()),
                      boxShadow: widget.style == ButtonStyle.floating
                          ? [
                              BoxShadow(
                                color: theme.shadowColor.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : null,
                    ),
                    child: Opacity(
                      opacity: _canPress() ? 1.0 : 0.6,
                      child: widget.child ?? _buildButtonContent(theme),
                    ),
                  ),
                  
                  // Ripple effect
                  if (_isPressed && _canPress())
                    Positioned.fill(
                      child: AnimatedBuilder(
                        animation: _rippleAnimation,
                        builder: (context, child) {
                          return Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(_getBorderRadius()),
                              color: Colors.white.withOpacity(
                                0.3 * (1 - _rippleAnimation.value),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildButtonContent(ThemeData theme) {
    if (widget.isLoading) {
      return _buildLoadingContent(theme);
    }

    if (widget.style == ButtonStyle.floating) {
      return Center(
        child: Icon(
          widget.icon,
          size: _getIconSize(),
          color: _getTextColor(theme),
        ),
      );
    }

    if (widget.icon != null && widget.text.isNotEmpty) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            widget.icon,
            size: _getIconSize(),
            color: _getTextColor(theme),
          ),
          const SizedBox(width: 8),
          Text(
            widget.text,
            style: _getTextStyle(theme),
          ),
        ],
      );
    }

    if (widget.icon != null) {
      return Icon(
        widget.icon,
        size: _getIconSize(),
        color: _getTextColor(theme),
      );
    }

    return Text(
      widget.text,
      style: _getTextStyle(theme),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildLoadingContent(ThemeData theme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AnimatedBuilder(
          animation: _loadingAnimation,
          builder: (context, child) {
            return Transform.rotate(
              angle: _loadingAnimation.value * 2 * 3.14159,
              child: SizedBox(
                width: _getIconSize(),
                height: _getIconSize(),
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _getTextColor(theme),
                  ),
                ),
              ),
            );
          },
        ),
        
        if (widget.text.isNotEmpty) ...[
          const SizedBox(width: 8),
          Text(
            widget.text,
            style: _getTextStyle(theme),
          ),
        ],
      ],
    );
  }
}