import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.violet.withValues(alpha: 0.18),
                  AppColors.pink.withValues(alpha: 0.18),
                ],
              ),
            ),
            child: ShaderMask(
              shaderCallback: (rect) =>
                  AppColors.primaryGradient.createShader(rect),
              child: const Icon(
                Icons.checklist_rounded,
                size: 64,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'No tasks for this day',
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: const Color(0xFF3D3463),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Tap + to add one',
            style: textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF8A82AD),
            ),
          ),
        ],
      ),
    );
  }
}
