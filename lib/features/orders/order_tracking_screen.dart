import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/ember_theme.dart';
import '../../core/formatting/currency_formatter.dart';
import '../../core/formatting/date_formatter.dart';
import '../../core/widgets/ember_badge.dart';
import '../../core/widgets/ember_button.dart';
import '../../core/widgets/error_panel.dart';
import '../../data/providers/app_providers.dart';
import '../../models/order.dart';

class OrderTrackingScreen extends ConsumerWidget {
  final String orderId;

  const OrderTrackingScreen({
    super.key,
    required this.orderId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderRepo = ref.watch(orderRepositoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Order Tracking'),
        actions: [
          IconButton(
            icon: const Icon(Icons.receipt_long),
            tooltip: 'View Receipt',
            onPressed: () => context.go('/receipt/$orderId'),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: FutureBuilder<OrderModel?>(
        future: orderRepo.getOrderById(orderId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: EmberColors.primary));
          }

          final order = snapshot.data;
          if (order == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: ErrorPanel(
                  title: 'Order Not Found',
                  message: 'The requested order ID #$orderId could not be retrieved.',
                  onRetry: () => ref.refresh(orderRepositoryProvider),
                ),
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: EmberColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: EmberColors.border),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('ORDER #${order.orderNumber}',
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: EmberColors.primary)),
                          const SizedBox(height: 4),
                          Text('Placed by ${order.customerName} • ${DateFormatter.formatTime(order.createdAt)}',
                              style: const TextStyle(fontSize: 13, color: EmberColors.textMuted)),
                        ],
                      ),
                      EmberBadge.fromOrderStatus(order.status),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Status Timeline
                _buildStatusTimeline(context, order),

                const SizedBox(height: 24),

                // Ordered Items
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: EmberColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: EmberColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Ordered Items', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 16),
                      ...order.items.map((item) => Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: Image.network(
                                    item.dish.imageUrl,
                                    width: 50,
                                    height: 50,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(width: 50, height: 50, color: EmberColors.surfaceElevated),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('${item.quantity}x ${item.dish.name}',
                                          style: const TextStyle(fontWeight: FontWeight.bold, color: EmberColors.textMain)),
                                      Text(item.selectedOptionNames.values.join(' • '),
                                          style: const TextStyle(fontSize: 12, color: EmberColors.textMuted)),
                                    ],
                                  ),
                                ),
                                Text(CurrencyFormatter.formatCents(item.totalPriceCents),
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: EmberColors.primary)),
                              ],
                            ),
                          )),
                      const Divider(),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total Amount', style: TextStyle(fontWeight: FontWeight.bold)),
                          Text(CurrencyFormatter.formatCents(order.totalCents),
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: EmberColors.primary)),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Actions Bar (Receipt or Cancel)
                Row(
                  children: [
                    Expanded(
                      child: EmberButton(
                        label: 'View Order Receipt',
                        icon: Icons.receipt,
                        isSecondary: true,
                        onPressed: () => context.go('/receipt/${order.id}'),
                      ),
                    ),
                    if (order.status == OrderStatus.pending) ...[
                      const SizedBox(width: 16),
                      Expanded(
                        child: EmberButton(
                          label: 'Cancel Order',
                          icon: Icons.cancel_outlined,
                          onPressed: () async {
                            try {
                              await orderRepo.updateOrderStatus(order.id, OrderStatus.cancelled, note: 'Cancelled by customer');
                              ref.refresh(orderRepositoryProvider);
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Cancellation error: $e')),
                              );
                            }
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusTimeline(BuildContext context, OrderModel order) {
    final stages = [
      OrderStatus.pending,
      OrderStatus.accepted,
      OrderStatus.preparing,
      OrderStatus.ready,
      OrderStatus.handedOver,
    ];

    final currentIndex = stages.indexOf(order.status);
    final isCancelled = order.status == OrderStatus.cancelled;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: EmberColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: EmberColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Preparation Progress', style: Theme.of(context).textTheme.titleLarge),
              Text('Est. ${order.estimatedPrepMinutes} Mins',
                  style: const TextStyle(color: EmberColors.primary, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 20),

          if (isCancelled) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: EmberColors.error.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: EmberColors.error),
              ),
              child: const Row(
                children: [
                  Icon(Icons.cancel, color: EmberColors.error),
                  SizedBox(width: 12),
                  Text('This order was cancelled.', style: TextStyle(color: EmberColors.error, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ] else ...[
            Row(
              children: stages.asMap().entries.map((entry) {
                final idx = entry.key;
                final stage = entry.value;
                final isPassed = idx <= currentIndex;
                final isCurrent = idx == currentIndex;

                return Expanded(
                  child: Column(
                    children: [
                      Row(
                        children: [
                          if (idx > 0)
                            Expanded(
                              child: Container(
                                height: 3,
                                color: isPassed ? EmberColors.primary : EmberColors.border,
                              ),
                            ),
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isPassed ? EmberColors.primary : EmberColors.background,
                              border: Border.all(
                                color: isPassed ? EmberColors.primary : EmberColors.border,
                                width: 2,
                              ),
                            ),
                            child: isPassed
                                ? const Icon(Icons.check, size: 14, color: EmberColors.background)
                                : null,
                          ),
                          if (idx < stages.length - 1)
                            Expanded(
                              child: Container(
                                height: 3,
                                color: idx < currentIndex ? EmberColors.primary : EmberColors.border,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        stage.label,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                          color: isCurrent ? EmberColors.primary : (isPassed ? EmberColors.textMain : EmberColors.textMuted),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}
