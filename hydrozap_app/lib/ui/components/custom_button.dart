import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

enum ButtonVariant {
  primary,
  secondary,
  outline,
  text,
  social,
  google
}

const List<Color> forestToLeafGradient = [
  Color(0xFF14532D), // Forest green
  Color(0xFF2E7D32), // Mid green
  Color(0xFF81C784), // Leaf green
];

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final Color? backgroundColor;
  final Color? textColor;
  final bool isLoading;
  final IconData? icon;
  final ButtonVariant variant;
  final double? width;
  final double? height;
  final bool useGradient;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.backgroundColor,
    this.textColor,
    this.isLoading = false,
    this.icon,
    this.variant = ButtonVariant.primary,
    this.width,
    this.height,
    this.useGradient = false,
  });

  @override
  Widget build(BuildContext context) {
    switch (variant) {
      case ButtonVariant.primary:
      case ButtonVariant.secondary:
        return _buildStandardButton(context);
      case ButtonVariant.outline:
        return _buildOutlineButton(context);
      case ButtonVariant.text:
        return _buildTextButton(context);
      case ButtonVariant.social:
        return _buildSocialButton(context);
      case ButtonVariant.google:
        return _buildGoogleButton(context);
    }
  }

  Widget _buildStandardButton(BuildContext context) {
    final button = isLoading
        ? Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                variant == ButtonVariant.primary 
                  ? Colors.white 
                  : Theme.of(context).colorScheme.secondary,
              ),
            ),
          )
        : ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: useGradient ? Colors.transparent : (backgroundColor ?? (variant == ButtonVariant.primary ? Theme.of(context).primaryColor : Theme.of(context).colorScheme.secondary)),
              foregroundColor: textColor ?? Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 1,
              shadowColor: useGradient ? Colors.transparent : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 20),
                  const SizedBox(width: 8),
                ],
                Text(
                  text,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          );
    if (!useGradient) {
      return SizedBox(
        width: width ?? double.infinity,
        height: height,
        child: button,
      );
    }
    return Container(
      width: width ?? double.infinity,
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: forestToLeafGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: button,
    );
  }

  Widget _buildOutlineButton(BuildContext context) {
    final borderColor = backgroundColor ?? Theme.of(context).primaryColor;
    
    return SizedBox(
      width: width ?? double.infinity,
      height: height,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: borderColor),
          foregroundColor: textColor ?? borderColor,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildTextButton(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: backgroundColor ?? Theme.of(context).primaryColor,
        padding: EdgeInsets.zero,
        minimumSize: Size(0, 0),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildSocialButton(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: width ?? 70,
        height: height ?? 50,
        decoration: BoxDecoration(
          border: Border.all(
            color: backgroundColor ?? Theme.of(context).colorScheme.onSurface.withAlpha((0.2 * 255).round()),
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: icon != null 
            ? Icon(
                icon,
                color: textColor ?? Theme.of(context).colorScheme.onSurface,
                size: 24,
              )
            : Text(text),
        ),
      ),
    );
  }

  Widget _buildGoogleButton(BuildContext context) {
    return SizedBox(
      width: width ?? double.infinity,
      height: height ?? 48,
      child: isLoading
        ? Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).primaryColor,
              ),
            ),
          )
        : ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: backgroundColor ?? Colors.white,
              foregroundColor: textColor ?? Colors.black87,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(
                  color: Colors.grey.shade300,
                  width: 1,
                ),
              ),
              elevation: 1,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.g_mobiledata_rounded,
                  size: 28,
                  color: Color(0xFF4285F4), // Google blue color
                ),
                const SizedBox(width: 12),
                Text(
                  text.isNotEmpty ? text : "Sign in with Google",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
    );
  }
}