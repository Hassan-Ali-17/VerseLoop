import 'package:flutter/material.dart';
import '../../app/theme/ember_theme.dart';
import '../../models/order.dart';

class EmberBadge extends StatelessWidget {
  final String label;
  final Color color;
  final Color? textColor;

  const EmberBadge({
    super.key,
    required this.label,
    required this.color,
    this.textColor,
  });

  factory EmberBadge.fromOrderStatus(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return const EmberBadge(label: 'Pending', color: EmberColors.statusPending);
      case OrderStatus.accepted:
        return const EmberBadge(label: 'Accepted', color: EmberColors.primary);
      case OrderStatus.preparing:
        return const EmberBadge(label: 'Preparing', color: EmberColors.statusPreparing);
      case OrderStatus.ready:
        return const EmberBadge(label: 'Ready for Pickup', color: EmberColors.statusReady);
      case OrderStatus.handedOver:
        return const EmberBadge(label: 'Completed', color: EmberColors.statusCompleted);
      case OrderStatus.cancelled:
        return const EmberBadge(label: 'Cancelled', color: EmberColors.statusCancelled);
    }
  }

  factory EmberBadge.stockStatus({required bool isAvailable, required int portions}) {
    if (!isAvailable || portions <= 0) {
      return const EmberBadge(label: 'Sold Out', color: EmberColors.error);
    } else if (portions <= 5) {
      return EmberBadge(label: 'Low Stock ($portions left)', color: EmberColors.warning);
    } else {
      return EmberBadge(label: '$portions Available', color: EmberColors.success);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.4), width: 1),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
          color: textColor ?? color,
        ),
      ),
    );
  }
}
