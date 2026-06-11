import 'package:flutter/material.dart';

class BudgetProgressBar extends StatelessWidget {
  final double percent; // 0.0 to 1.0

  const BudgetProgressBar({super.key, required this.percent});

  Color _barColor() {
    if (percent < 0.6) return const Color(0xFF00D4AA);
    if (percent < 0.8) return Colors.orange;
    return const Color(0xFFFF4757);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: percent.clamp(0.0, 1.0)),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOutCubic,
            builder: (ctx, value, _) {
              return LinearProgressIndicator(
                value: value,
                minHeight: 14,
                backgroundColor: Colors.grey.withOpacity(0.15),
                valueColor: AlwaysStoppedAnimation(_barColor()),
              );
            },
          ),
        ),
        const SizedBox(height: 6),
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: Text(
            '${(percent * 100).clamp(0, 100).toStringAsFixed(1)}% من الميزانية',
            style: TextStyle(
              fontSize: 11,
              color: _barColor(),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
