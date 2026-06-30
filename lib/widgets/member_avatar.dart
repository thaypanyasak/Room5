import 'package:flutter/material.dart';
import '../models/member.dart';

class MemberAvatar extends StatelessWidget {
  final Member member;
  final double radius;

  const MemberAvatar({
    super.key,
    required this.member,
    this.radius = 24,
  });

  @override
  Widget build(BuildContext context) {
    final hasUrl = member.avatarUrl.isNotEmpty && member.avatarUrl.startsWith('http');
    final initials = member.name.isNotEmpty ? member.name[0].toUpperCase() : '?';

    // High quality modern color palette for fallback circles
    final colors = [
      const Color(0xFF3B82F6), // Blue
      const Color(0xFF10B981), // Emerald
      const Color(0xFFF59E0B), // Amber
      const Color(0xFFEC4899), // Pink
      const Color(0xFF8B5CF6), // Purple
      const Color(0xFFEF4444), // Red
    ];
    final colorIndex = member.name.hashCode % colors.length;
    final bgColor = colors[colorIndex];

    return CircleAvatar(
      radius: radius,
      backgroundColor: bgColor,
      child: hasUrl
          ? ClipOval(
              child: Image.network(
                member.avatarUrl,
                fit: BoxFit.cover,
                width: radius * 2,
                height: radius * 2,
                errorBuilder: (context, error, stackTrace) {
                  return Center(
                    child: Text(
                      initials,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: radius * 0.8,
                      ),
                    ),
                  );
                },
              ),
            )
          : Text(
              initials,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: radius * 0.8,
              ),
            ),
    );
  }
}
