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
    super.key,
    required this.title,
    required this.icon,
    required this.onTap,
    this.backgroundColor,
    this.iconColor,
    this.index = 0,
  });

  @override
  State<HomeMenuCard> createState() => _HomeMenuCardState();
}

class _HomeMenuCardState extends State<HomeMenuCard>
    with SingleTickerProviderStateMixin {
  bool _isPressed = false;
  bool _isHovered = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  final List<List<Color>> _gradients = [
  [
    Color(0xFFFF0066),  // More intense, bright Pink
    Color(0xFFFF3385),  // Vibrant Soft Pink
  ], // Find Blood Donors - Vibrant Pink to Soft Pink
  [
    Color(0xFF303F9F),  // Deep, intense Indigo
    Color(0xFF5E35B1),  // Strong, vibrant Periwinkle
  ], // Request Blood - Deep Indigo to Periwinkle
  [
    Color(0xFF1565C0),  // Bold, bright Blue
    Color(0xFF42A5F5),  // Intense Light Blue
  ], // Blood Requests - Bright Blue to Light Blue
  [
    Color(0xFF00796B),  // Deep, rich Teal
    Color(0xFF26A69A),  // Vivid Light Teal
  ], // Nearby Blood Banks - Teal to Light Teal
  [
    Color(0xFFFF3D00),  // More intense Orange
    Color(0xFFFF7043),  // Bright, strong Light Orange
  ], // Donation History - Orange to Light Orange
  [
    Color(0xFF388E3C),  // Deep, vibrant Green
    Color(0xFF66BB6A),  // Strong, intense Light Green
  ], // Health Tips - Green to Light Green
  [
    Color(0xFF4527A0),  // Rich, deep Purple
    Color(0xFF7E57C2),  // Bright, intense Light Purple
  ], // Emergency Contacts - Deep Purple to Light Purple
  [
    Color(0xFFD5006D),  // Bright, bold Pink
    Color(0xFFF50057),  // Intense Light Pink
  ], // Settings - Pink to Light Pink
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

  List<Color> get _cardGradient =>
      widget.index < _gradients.length
          ? _gradients[widget.index]
          : [
            AppConstants.primaryColor,
            AppConstants.primaryColor.withOpacity(0.7),
          ];

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    // Get screen dimensions for responsive sizing
    final Size screenSize = MediaQuery.of(context).size;
    final double screenWidth = screenSize.width;

    // Determine if we're on a small screen
    final bool isSmallScreen = screenWidth < 360;

    // Calculate responsive sizes
    final double iconSize = isSmallScreen ? 24.0 : 28.0;
    final double titleFontSize = isSmallScreen ? 10.0 : 12.0;
    final double badgeFontSize = isSmallScreen ? 8.0 : 10.0;
    final double iconPadding = isSmallScreen ? 10.0 : 14.0;
    final double contentPadding = isSmallScreen ? 12.0 : 16.0;
    final double spacingHeight = isSmallScreen ? 8.0 : 12.0;

    // Calculate decorative element sizes
    final double largeBubbleSize = isSmallScreen ? 60.0 : 80.0;
    final double mediumBubbleSize = isSmallScreen ? 60.0 : 70.0;
    final double smallBubbleSize = isSmallScreen ? 16.0 : 20.0;

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
                      colors:
                          _isPressed
                              ? [
                                isDark ? const Color(0xFF1E1E1E) : Colors.white,
                                isDark ? const Color(0xFF1E1E1E) : Colors.white,
                              ]
                              : _cardGradient,
                    ),
                    borderRadius: BorderRadius.circular(AppConstants.radiusL),
                    boxShadow: [
                      BoxShadow(
                        color: _cardGradient.first.withOpacity(
                          _isPressed ? 0.1 : (_isHovered ? 0.5 : 0.3),
                        ),
                        spreadRadius: _isPressed ? 0 : (_isHovered ? 2 : 1),
                        blurRadius: _isPressed ? 3 : (_isHovered ? 12 : 8),
                        offset: Offset(
                          0,
                          _isPressed ? 1 : (_isHovered ? 6 : 4),
                        ),
                      ),
                      // Additional inner glow effect for hover state
                      if (_isHovered)
                        BoxShadow(
                          color: Colors.white.withOpacity(0.1),
                          spreadRadius: 0,
                          blurRadius: 15,
                          offset: Offset(0, 0),
                        ),
                    ],
                  ),
                  transform:
                      Matrix4.identity()
                        ..scale(_isPressed ? 0.97 : (_isHovered ? 1.03 : 1.0))
                        ..translate(0.0, _isHovered ? -2.0 : 0.0),
                  child: Stack(
                    children: [
                      // Decorative elements and pattern
                      Positioned(
                        right: -20,
                        top: -20,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: mediumBubbleSize,
                          height: mediumBubbleSize,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(
                              _isHovered ? 0.15 : 0.1,
                            ),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      Positioned(
                        left: -25,
                        bottom: -25,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: largeBubbleSize,
                          height: largeBubbleSize,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(
                              _isHovered ? 0.12 : 0.08,
                            ),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      // Smaller decorative circles
                      Positioned(
                        right: 40,
                        bottom: 30,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: smallBubbleSize,
                          height: smallBubbleSize,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(
                              _isHovered ? 0.2 : 0.15,
                            ),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      // Additional small decorative circle for visual interest
                      Positioned(
                        left: 30,
                        top: 20,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: smallBubbleSize * 0.7,
                          height: smallBubbleSize * 0.7,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(
                              _isHovered ? 0.25 : 0.15,
                            ),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      // Content with improved spacing and styling
                      Padding(
                        padding: EdgeInsets.all(contentPadding),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: EdgeInsets.all(iconPadding),
                              decoration: BoxDecoration(
                                color:
                                    isDark
                                        ? const Color(0xFF2C2C2C)
                                        : Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: _cardGradient.first.withOpacity(
                                      _isHovered ? 0.4 : 0.2,
                                    ),
                                    blurRadius: _isHovered ? 10 : 6,
                                    spreadRadius: _isHovered ? 2 : 0,
                                    offset: Offset(0, _isHovered ? 3 : 2),
                                  ),
                                  if (_isHovered)
                                    BoxShadow(
                                      color: Colors.white.withOpacity(0.15),
                                      blurRadius: 10,
                                      spreadRadius: 1,
                                      offset: Offset(0, 0),
                                    ),
                                ],
                              ),
                              child: Icon(
                                widget.icon,
                                color: _cardGradient.first,
                                size: iconSize,
                              ),
                            ),
                            SizedBox(height: spacingHeight),
                            Flexible(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4.0,
                                ),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    widget.title,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: titleFontSize,
                                      color: Colors.white,
                                      letterSpacing: 0.3,
                                      shadows: [
                                        Shadow(
                                          color: Colors.black.withOpacity(0.4),
                                          blurRadius: 3,
                                          offset: Offset(0, 1),
                                        ),
                                      ],
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // "New" badge for a special feature (optional)
                      if (widget.index == 1) // Just for the Request Blood card
                        Positioned(
                          top: isSmallScreen ? 8 : 10,
                          right: isSmallScreen ? 8 : 10,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: isSmallScreen ? 6 : 8,
                              vertical: isSmallScreen ? 3 : 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(
                                isSmallScreen ? 10 : 12,
                              ),
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
                                fontSize: badgeFontSize,
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
