import 'package:flutter/material.dart';

class AccuracyCircles extends StatelessWidget {
  final double value; // Value between 0 and 1
  final double size;
  final Color primaryColor;
  final Color backgroundColor;
  final Function(double) onValueChanged;

  const AccuracyCircles({
    Key? key,
    required this.value,
    this.size = 200,
    required this.primaryColor,
    required this.backgroundColor,
    required this.onValueChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Generate 5 concentric circles from largest to smallest
          for (int i = 4; i >= 0; i--) _buildCircle(context, i),
          // Center dot
          _buildCenterDot(context),
        ],
      ),
    );
  }

  Widget _buildCircle(BuildContext context, int index) {
    final circleSize = size * (0.4 + (index * 0.12));
    final circleValue = (index + 1) / 5;
    final isSelected = (value * 5).ceil() == index + 1;

    return GestureDetector(
      onTap: () => onValueChanged(circleValue),
      child: Container(
        width: circleSize,
        height: circleSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? primaryColor : backgroundColor,
            width: isSelected ? 3 : 2,
          ),
          color: isSelected
              ? primaryColor.withOpacity(0.1)
              : backgroundColor.withOpacity(0.05),
        ),
        child: AnimatedScale(
          scale: isSelected ? 1.05 : 1.0,
          duration: const Duration(milliseconds: 200),
          child: Container(),
        ),
      ),
    );
  }

  Widget _buildCenterDot(BuildContext context) {
    return Container(
      width: size * 0.12,
      height: size * 0.12,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: primaryColor,
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.3),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Center(
        child: Text(
          '${(value * 100).round()}%',
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.05,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
