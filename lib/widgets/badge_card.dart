import 'package:flutter/material.dart';
import '../models/badge.dart' as badge_model;

class BadgeCard extends StatelessWidget {
  final badge_model.Badge badge;

  const BadgeCard({super.key, required this.badge});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final earned = badge.isEarned;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: earned
            ? LinearGradient(
                colors: [
                  theme.colorScheme.primary.withOpacity(0.3),
                  theme.colorScheme.secondary.withOpacity(0.2),
                ],
              )
            : null,
        color: !earned ? theme.colorScheme.surface : null,
        border: Border.all(
          color: earned
              ? theme.colorScheme.primary.withOpacity(0.5)
              : Colors.grey.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: earned
                  ? theme.colorScheme.primary.withOpacity(0.2)
                  : Colors.grey.withOpacity(0.1),
            ),
            child: Icon(
              IconData(badge.iconCode, fontFamily: 'MaterialIcons'),
              size: 28,
              color: earned ? theme.colorScheme.primary : Colors.grey,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      badge.title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: earned ? null : Colors.grey,
                      ),
                    ),
                    if (earned) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'مُحرَز',
                          style: TextStyle(
                              fontSize: 10,
                              color: theme.colorScheme.primary),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  badge.description,
                  style: TextStyle(
                    fontSize: 12,
                    color: earned ? null : Colors.grey,
                  ),
                ),
                if (badge.earnedDate != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'حصلت عليه: ${badge.earnedDate!.day}/${badge.earnedDate!.month}/${badge.earnedDate!.year}',
                    style: TextStyle(
                        fontSize: 10, color: theme.colorScheme.primary),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
