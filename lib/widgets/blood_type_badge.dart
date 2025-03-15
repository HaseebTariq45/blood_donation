import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

class BloodTypeBadge extends StatelessWidget {
  final String bloodType;
  final double size;

  const BloodTypeBadge({super.key, required this.bloodType, this.size = 45.0});

  @override
  Widget build(BuildContext context) {
    // Get blood group and rhesus factor
    String group = '';
    String rhesus = '';

    if (bloodType.isNotEmpty) {
      if (bloodType.length > 1) {
        group = bloodType.substring(0, bloodType.length - 1);
        rhesus = bloodType.substring(bloodType.length - 1);
      } else {
        group = bloodType;
      }
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppConstants.primaryColor,
            AppConstants.primaryColor.withOpacity(0.8),
          ],
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppConstants.primaryColor.withOpacity(0.4),
            blurRadius: 8,
            spreadRadius: 0,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(color: Colors.white.withOpacity(0.6), width: 2),
      ),
      child: Stack(
        children: [
          // Decorative elements
          Positioned(
            top: size * 0.2,
            left: size * 0.2,
            child: Icon(
              Icons.water_drop_outlined,
              color: Colors.white.withOpacity(0.15),
              size: size * 0.6,
            ),
          ),

          // Blood type text
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      group,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: size * 0.4,
                        height: 0.9,
                      ),
                    ),
                    if (rhesus.isNotEmpty)
                      Text(
                        rhesus,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: size * 0.3,
                          height: 0.9,
                        ),
                      ),
                  ],
                ),
                Container(
                  margin: EdgeInsets.only(top: size * 0.05),
                  width: size * 0.45,
                  height: 1.5,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
                Text(
                  'type',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: size * 0.18,
                    letterSpacing: 0.5,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),

          // Pulse animation effect
          Positioned.fill(
            child: AnimatedPulse(color: Colors.white.withOpacity(0.2)),
          ),
        ],
      ),
    );
  }
}

class AnimatedPulse extends StatefulWidget {
  final Color color;

  const AnimatedPulse({Key? key, required this.color}) : super(key: key);

  @override
  State<AnimatedPulse> createState() => _AnimatedPulseState();
}

class _AnimatedPulseState extends State<AnimatedPulse>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: widget.color.withOpacity(_animation.value * 0.6),
              width: 2 * (1 - _animation.value),
            ),
          ),
        );
      },
    );
  }
}
