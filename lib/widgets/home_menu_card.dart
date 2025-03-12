import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../utils/theme_helper.dart';

class HomeMenuCard extends StatefulWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;
  final Color? backgroundColor;
  final Color? iconColor;
  final int index;

  const HomeMenuCard({
    Key? key,
    required this.title,
    required this.icon,
    required this.onTap,
    this.backgroundColor,
    this.iconColor,
    this.index = 0,
  }) : super(key: key);

  @override
  State<HomeMenuCard> createState() => _HomeMenuCardState();
}

class _HomeMenuCardState extends State<HomeMenuCard> with SingleTickerProviderStateMixin {
  bool _isPressed = false;
  bool _isHovered = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  final List<List<Color>> _gradients = [
    [Color(0xFFFF4B6E), Color(0xFFFF84A1)], // Vibrant Pink to Soft Pink
    [Color(0xFF7E57C2), Color(0xFF9575CD)], // Deep Purple to Light Purple
    [Color(0xFF2196F3), Color(0xFF90CAF9)], // Bright Blue to Light Blue
    [Color(0xFF26A69A), Color(0xFF80CBC4)], // Teal to Light Teal
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 600),
    );
    
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );
    
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Interval(0.5, 1.0, curve: Curves.easeInOut),
      ),
    );
    
    // Staggered animation based on card index
    Future.delayed(Duration(milliseconds: widget.index * 100), () {
      if (mounted) {
        _animationController.forward();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  List<Color> get _cardGradient => widget.index < _gradients.length 
      ? _gradients[widget.index]
      : [AppConstants.primaryColor, AppConstants.primaryColor.withOpacity(0.7)];

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: MouseRegion(
              onEnter: (_) => setState(() => _isHovered = true),
              onExit: (_) => setState(() => _isHovered = false),
              child: GestureDetector(
                onTap: widget.onTap,
                onTapDown: (_) => setState(() => _isPressed = true),
                onTapUp: (_) => setState(() => _isPressed = false),
                onTapCancel: () => setState(() => _isPressed = false),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: _isPressed 
                          ? [isDark ? const Color(0xFF1E1E1E) : Colors.white, 
                             isDark ? const Color(0xFF1E1E1E) : Colors.white]
                          : _cardGradient,
                    ),
                    borderRadius: BorderRadius.circular(AppConstants.radiusL),
                    boxShadow: [
                      BoxShadow(
                        color: _cardGradient.first.withOpacity(_isPressed ? 0.1 : (_isHovered ? 0.5 : 0.3)),
                        spreadRadius: _isPressed ? 0 : (_isHovered ? 2 : 1),
                        blurRadius: _isPressed ? 3 : (_isHovered ? 12 : 8),
                        offset: Offset(0, _isPressed ? 1 : (_isHovered ? 6 : 4)),
                      ),
                    ],
                  ),
                  transform: Matrix4.identity()
                    ..scale(_isPressed ? 0.97 : (_isHovered ? 1.02 : 1.0)),
                  child: Stack(
                    children: [
                      // Decorative elements and pattern
                      Positioned(
                        right: -20,
                        top: -20,
                        child: Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      Positioned(
                        left: -25,
                        bottom: -25,
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.08),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      // Smaller decorative circles
                      Positioned(
                        right: 40,
                        bottom: 30,
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      // Content with improved spacing and styling
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: _cardGradient.first.withOpacity(_isHovered ? 0.3 : 0.1),
                                    blurRadius: _isHovered ? 8 : 5,
                                    spreadRadius: _isHovered ? 2 : 0,
                                    offset: Offset(0, _isHovered ? 3 : 2),
                                  ),
                                ],
                              ),
                              child: Icon(
                                widget.icon,
                                color: _cardGradient.first,
                                size: 28,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Flexible(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                                child: Text(
                                  widget.title,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                    color: Colors.white,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black.withOpacity(0.3),
                                        blurRadius: 2,
                                        offset: Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // "New" badge for a special feature (optional)
                      if (widget.index == 1) // Just for the Request Blood card
                        Positioned(
                          top: 10,
                          right: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 4,
                                  spreadRadius: 0,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              'NEW',
                              style: TextStyle(
                                color: _cardGradient.first,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
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