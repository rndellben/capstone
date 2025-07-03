import 'package:flutter/material.dart';

class TeamProfileCard extends StatelessWidget {
  final String name;
  final String role;
  final String imageUrl;
  final List<Widget> socialIcons;
  final String? description;
  final bool isSelected;
  final VoidCallback? onTap;

  const TeamProfileCard({
    Key? key,
    required this.name,
    required this.role,
    required this.imageUrl,
    required this.socialIcons,
    this.description,
    this.isSelected = false,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Theme.of(context).primaryColor : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            Stack(
              alignment: Alignment.center,
              children: [
                CircleAvatar(
                  radius: 38,
                  backgroundColor: Colors.grey.shade100,
                  backgroundImage: NetworkImage(imageUrl),
                ),
                if (isSelected)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      padding: const EdgeInsets.all(4),
                      child: const Icon(Icons.check, color: Colors.white, size: 16),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              name,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              role,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
                letterSpacing: 1.2,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (description != null && description!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  description!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[700],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: socialIcons,
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
} 