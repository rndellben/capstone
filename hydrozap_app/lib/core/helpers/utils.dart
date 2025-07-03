import 'package:flutter/material.dart';

// ===== Snackbar and Dialog Utilities =====

void showMessage(BuildContext context, String message, {bool isError = false}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: isError ? Colors.red : Colors.green,
    ),
  );
}

enum AlertType {
  success,
  error,
  warning,
  info,
  question
}

Future<bool?> showAlertDialog({
  required BuildContext context,
  required String title,
  required String message,
  AlertType type = AlertType.info,
  String? confirmButtonText,
  String? cancelButtonText,
  bool showCancelButton = true,
  VoidCallback? onConfirm,
  VoidCallback? onCancel,
}) async {
  // Define colors and icons for different alert types
  final Map<AlertType, Map<String, dynamic>> alertStyles = {
    AlertType.success: {
      'color': Colors.green,
      'icon': Icons.check_circle_outline,
    },
    AlertType.error: {
      'color': Colors.red,
      'icon': Icons.error_outline,
    },
    AlertType.warning: {
      'color': Colors.orange,
      'icon': Icons.warning_amber_outlined,
    },
    AlertType.info: {
      'color': Colors.blue,
      'icon': Icons.info_outline,
    },
    AlertType.question: {
      'color': Colors.purple,
      'icon': Icons.help_outline,
    },
  };

  final style = alertStyles[type]!;
  
  // Use responsive sizing for dialog components based on device type
  final isSmallScreen = ResponsiveUtils.isMobile(context);
  final isMediumScreen = ResponsiveUtils.isTablet(context);
  
  final iconSize = isSmallScreen ? 40.0 : (isMediumScreen ? 50.0 : 60.0);
  final titleFontSize = isSmallScreen ? 20.0 : (isMediumScreen ? 22.0 : 24.0);
  final messageFontSize = isSmallScreen ? 14.0 : (isMediumScreen ? 15.0 : 16.0);
  final buttonFontSize = isSmallScreen ? 14.0 : (isMediumScreen ? 15.0 : 16.0);
  final buttonPadding = isSmallScreen 
      ? const EdgeInsets.symmetric(horizontal: 16, vertical: 8)
      : (isMediumScreen 
          ? const EdgeInsets.symmetric(horizontal: 20, vertical: 10)
          : const EdgeInsets.symmetric(horizontal: 24, vertical: 12));
  
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          width: ResponsiveUtils.dialogWidth(context),
          padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.rectangle,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 10.0,
                offset: Offset(0.0, 10.0),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                style['icon'],
                size: iconSize,
                color: style['color'],
              ),
              SizedBox(height: isSmallScreen ? 12 : 16),
              Text(
                title,
                style: TextStyle(
                  fontSize: titleFontSize,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: isSmallScreen ? 6 : 8),
              Text(
                message,
                style: TextStyle(
                  fontSize: messageFontSize,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: isSmallScreen ? 20 : 24),
              ResponsiveUtils.isDesktop(context)
                  ? _buildDesktopButtons(
                      context,
                      style,
                      confirmButtonText,
                      cancelButtonText,
                      showCancelButton,
                      buttonFontSize,
                      buttonPadding,
                      onConfirm,
                      onCancel,
                    )
                  : _buildMobileTabletButtons(
                      context,
                      style,
                      confirmButtonText,
                      cancelButtonText,
                      showCancelButton,
                      buttonFontSize,
                      buttonPadding,
                      onConfirm,
                      onCancel,
                    ),
            ],
          ),
        ),
      );
    },
  );
}

Widget _buildDesktopButtons(
  BuildContext context,
  Map<String, dynamic> style,
  String? confirmButtonText,
  String? cancelButtonText,
  bool showCancelButton,
  double fontSize,
  EdgeInsetsGeometry padding,
  VoidCallback? onConfirm,
  VoidCallback? onCancel,
) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      if (showCancelButton)
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(false);
            onCancel?.call();
          },
          child: Text(
            cancelButtonText ?? 'Cancel',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: fontSize,
            ),
          ),
        ),
      if (showCancelButton) const SizedBox(width: 8),
      ElevatedButton(
        onPressed: () {
          Navigator.of(context).pop(true);
          onConfirm?.call();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: style['color'],
          padding: padding,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Text(
          confirmButtonText ?? 'Confirm',
          style: TextStyle(
            fontSize: fontSize,
            color: Colors.white,
          ),
        ),
      ),
    ],
  );
}

Widget _buildMobileTabletButtons(
  BuildContext context,
  Map<String, dynamic> style,
  String? confirmButtonText,
  String? cancelButtonText,
  bool showCancelButton,
  double fontSize,
  EdgeInsetsGeometry padding,
  VoidCallback? onConfirm,
  VoidCallback? onCancel,
) {
  // On smaller screens, stack buttons vertically for better space usage
  if (ResponsiveUtils.isMobile(context) && showCancelButton) {
    return Column(
      children: [
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop(true);
            onConfirm?.call();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: style['color'],
            padding: padding,
            minimumSize: const Size(double.infinity, 0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(
            confirmButtonText ?? 'Confirm',
            style: TextStyle(
              fontSize: fontSize,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(false);
            onCancel?.call();
          },
          style: TextButton.styleFrom(
            minimumSize: const Size(double.infinity, 0),
          ),
          child: Text(
            cancelButtonText ?? 'Cancel',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: fontSize,
            ),
          ),
        ),
      ],
    );
  } else {
    // Tablet layout - horizontal buttons with appropriate spacing
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (showCancelButton)
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(false);
              onCancel?.call();
            },
            child: Text(
              cancelButtonText ?? 'Cancel',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: fontSize,
              ),
            ),
          ),
        if (showCancelButton) const SizedBox(width: 8),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop(true);
            onConfirm?.call();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: style['color'],
            padding: padding,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(
            confirmButtonText ?? 'Confirm',
            style: TextStyle(
              fontSize: fontSize,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}

// ===== Responsive Utilities =====

class ResponsiveUtils {
  // Screen breakpoints
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 1200;
  
  // Device type detection
  static bool isMobile(BuildContext context) => 
      MediaQuery.of(context).size.width < mobileBreakpoint;
  
  static bool isTablet(BuildContext context) => 
      MediaQuery.of(context).size.width >= mobileBreakpoint && 
      MediaQuery.of(context).size.width < tabletBreakpoint;
  
  static bool isDesktop(BuildContext context) => 
      MediaQuery.of(context).size.width >= tabletBreakpoint;
  
  // Get appropriate dialog width based on screen size
  static double dialogWidth(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (isMobile(context)) {
      return width * 0.9;
    } else if (isTablet(context)) {
      return width * 0.7;
    } else {
      return width * 0.5;
    }
  }
  
  // Helper method to get padding based on screen size
  static EdgeInsets getPadding(BuildContext context) {
    if (isMobile(context)) {
      return const EdgeInsets.all(12);
    } else if (isTablet(context)) {
      return const EdgeInsets.all(16);
    } else {
      return const EdgeInsets.all(24);
    }
  }
  
  // Helper method to get text scale factor based on screen size
  static double getTextScaleFactor(BuildContext context) {
    if (isMobile(context)) {
      return 0.9;
    } else if (isTablet(context)) {
      return 1.0;
    } else {
      return 1.1;
    }
  }
  
  // Widget builder that returns appropriate widget based on screen size
  static Widget builder({
    required BuildContext context,
    required Widget mobile,
    required Widget tablet,
    required Widget desktop,
  }) {
    if (isDesktop(context)) {
      return desktop;
    } else if (isTablet(context)) {
      return tablet;
    } else {
      return mobile;
    }
  }
}

// Convenient extension methods for BuildContext
extension ResponsiveContextExtension on BuildContext {
  bool get isMobile => ResponsiveUtils.isMobile(this);
  bool get isTablet => ResponsiveUtils.isTablet(this);
  bool get isDesktop => ResponsiveUtils.isDesktop(this);
  
  double get dialogWidth => ResponsiveUtils.dialogWidth(this);
  EdgeInsets get responsivePadding => ResponsiveUtils.getPadding(this);
  double get responsiveTextScale => ResponsiveUtils.getTextScaleFactor(this);
}