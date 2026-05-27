import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isLoading;
  final Color? color;
  final Color? textColor;
  final double? width;
  final double height;
  final double borderRadius;
  final bool isOutlined;
  final bool isSmall;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.color,
    this.textColor,
    this.width,
    this.height = 55,
    this.borderRadius = 14,
    this.isOutlined = false,
    this.isSmall = false,
  });

  @override
  Widget build(BuildContext context) {
    final double effectiveHeight = isSmall ? 40 : height;
    final double effectiveFontSize = isSmall ? 13 : 15;

    return SizedBox(
      width: width ?? double.infinity,
      height: effectiveHeight,
      child: isOutlined 
      ? OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: color ?? AppColors.primary,
            side: BorderSide(color: color ?? AppColors.primary, width: 1.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(isSmall ? 10 : borderRadius),
            ),
          ),
          child: _buildChild(effectiveFontSize),
        )
      : ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: color ?? AppColors.primary,
            foregroundColor: textColor ?? Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(isSmall ? 10 : borderRadius),
            ),
            elevation: 0,
          ),
          child: _buildChild(effectiveFontSize),
        ),
    );
  }

  Widget _buildChild(double fontSize) {
    return isLoading
        ? const SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          )
        : Text(
            text,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          );
  }
}
