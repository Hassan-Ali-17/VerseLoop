import 'package:flutter/material.dart';
import '../../app/theme/ember_theme.dart';

class LoadingSkeletonCard extends StatelessWidget {
  final double height;

  const LoadingSkeletonCard({super.key, this.height = 140});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: EmberColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: EmberColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 18,
            width: 140,
            decoration: BoxDecoration(
              color: EmberColors.surfaceElevated,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            height: 12,
            width: double.infinity,
            decoration: BoxDecoration(
              color: EmberColors.surfaceElevated,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 12,
            width: 200,
            decoration: BoxDecoration(
              color: EmberColors.surfaceElevated,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const Spacer(),
          Container(
            height: 24,
            width: 80,
            decoration: BoxDecoration(
              color: EmberColors.surfaceElevated,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }
}
