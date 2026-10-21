import 'package:flutter/material.dart';

const ocean = Color(0xFF1E3A8A);
const cyan = Color(0xFF06B6D4);
const pageBackground = Color(0xFFF8FAFC);

class WelcomeBanner extends StatelessWidget {
  final String title, subtitle;
  final IconData icon;
  const WelcomeBanner({
    super.key,
    required this.title,
    required this.subtitle,
    this.icon = Icons.shield_outlined,
  });
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [ocean, Color(0xFF155E75)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: const TextStyle(color: Color(0xFFE0F2FE), height: 1.5),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        CircleAvatar(
          radius: 28,
          backgroundColor: Colors.white.withValues(alpha: 0.15),
          child: Icon(icon, color: Colors.white, size: 30),
        ),
      ],
    ),
  );
}

class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  const StatusBadge(this.label, {super.key, required this.color});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      label,
      style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700),
    ),
  );
}
