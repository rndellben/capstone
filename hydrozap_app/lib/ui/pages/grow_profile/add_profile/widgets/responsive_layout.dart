import 'package:flutter/material.dart';

class ResponsiveConditionsLayout extends StatelessWidget {
  final List<Widget> children;

  const ResponsiveConditionsLayout({
    super.key,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 1200) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: children[0]),
              const SizedBox(width: 24),
              Expanded(child: children[1]),
            ],
          );
        } else if (constraints.maxWidth > 800) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: children[0]),
              const SizedBox(width: 16),
              Expanded(child: children[1]),
            ],
          );
        } else {
          return Column(
            children: [
              children[0],
              const SizedBox(height: 24),
              children[1],
            ],
          );
        }
      },
    );
  }
} 