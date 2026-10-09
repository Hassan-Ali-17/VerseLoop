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
    final orderAsync = ref.watch(orderTrackingProvider(orderId));

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back to Menu',
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/menu');
            }
          },
        ),
        title: const Text('Live Order Tracking'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Status',
            onPressed: () => ref.read(orderTrackingProvider(orderId).notifier).refresh(),
          ),
          IconButton(
            icon: const Icon(Icons.receipt_long),
            tooltip: 'View Receipt',
            onPressed: () => context.go('/receipt/$orderId'),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: orderAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: EmberColors.primary)),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: ErrorPanel(
              title: 'Error Loading Order',
              message: err.toString(),
              onRetry: () => ref.read(orderTrackingProvider(orderId).notifier).refresh(),
            ),
          ),
        ),
        data: (order) {
          if (order == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: ErrorPanel(
                  title: 'Order Not Found',
                  message: 'The requested order ID #$orderId could not be retrieved.',
                  onRetry: () => ref.read(orderTrackingProvider(orderId).notifier).refresh(),
                ),
              ),
            );
          }

          return _buildOrderBody(context, ref, order);
        },
      ),
    );
  }

  Widget _buildOrderBody(BuildContext context, WidgetRef ref, OrderModel order) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (order.status == OrderStatus.handedOver) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 24),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: EmberColors.success.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: EmberColors.success.withValues(alpha: 0.6)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: EmberColors.success, size: 32),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Order Handed Over & Completed!',
                          style: TextStyle(fontWeight: FontWeight.bold, color: EmberColors.success, fontSize: 16),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Your meal has been handed over by the kitchen team. Enjoy your wood-fired dining experience!',
                          style: TextStyle(fontSize: 13, color: EmberColors.textMain),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ORDER #${order.orderNumber}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: EmberColors.primary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Placed by ${order.customerName} • ${DateFormatter.formatTime(order.createdAt)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13, color: EmberColors.textMuted),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
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
                                      Text(
                                        '${item.quantity}x ${item.dish.name}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontWeight: FontWeight.bold, color: EmberColors.textMain),
                                      ),
                                      Text(
                                        item.selectedOptionNames.values.join(' • '),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontSize: 12, color: EmberColors.textMuted),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  CurrencyFormatter.formatCents(item.totalPriceCents),
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: EmberColors.primary),
                                ),
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

                // Responsive Actions Bar (Receipt or Cancel)
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isNarrow = constraints.maxWidth < 450;
                    final buttons = [
                      EmberButton(
                        label: 'View Order Receipt',
                        icon: Icons.receipt,
                        isSecondary: true,
                        onPressed: () => context.go('/receipt/${order.id}'),
                      ),
                      if (order.status == OrderStatus.pending)
                        EmberButton(
                          label: 'Cancel Order',
                          icon: Icons.cancel_outlined,
                          onPressed: () async {
                            try {
                              await ref.read(orderRepositoryProvider).updateOrderStatus(order.id, OrderStatus.cancelled, note: 'Cancelled by customer');
                              ref.read(activeOrdersProvider.notifier).refreshOrders();
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Cancellation error: $e')),
                                );
                              }
                            }
                          },
                        ),
                    ];

                    if (isNarrow) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          buttons[0],
                          if (buttons.length > 1) ...[
                            const SizedBox(height: 12),
                            buttons[1],
                          ],
                        ],
                      );
                    }

                    return Row(
                      children: [
                        Expanded(child: buttons[0]),
                        if (buttons.length > 1) ...[
                          const SizedBox(width: 16),
                          Expanded(child: buttons[1]),
                        ],
                      ],
                    );
                  },
                ),
              ],
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
              Expanded(
                child: Text(
                  'Preparation Progress',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Est. ${order.estimatedPrepMinutes} Mins',
                style: const TextStyle(color: EmberColors.primary, fontWeight: FontWeight.bold),
              ),
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
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2.0),
                        child: Text(
                          stage.label,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                            color: isCurrent ? EmberColors.primary : (isPassed ? EmberColors.textMain : EmberColors.textMuted),
                          ),
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
