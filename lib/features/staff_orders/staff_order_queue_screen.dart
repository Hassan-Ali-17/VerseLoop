import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/ember_theme.dart';
import '../../core/formatting/currency_formatter.dart';
import '../../core/formatting/date_formatter.dart';
import '../../core/widgets/ember_badge.dart';
import '../../core/widgets/ember_button.dart';
import '../../data/providers/app_providers.dart';
import '../../models/order.dart';

class StaffOrderQueueScreen extends ConsumerWidget {
  const StaffOrderQueueScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeOrdersAsync = ref.watch(staffOrdersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Kitchen Order Queue'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(staffOrdersProvider.notifier).refreshOrders(),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: activeOrdersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: EmberColors.primary)),
        error: (err, _) => Center(child: Text('Error: $err', style: const TextStyle(color: EmberColors.error))),
        data: (orders) {
          if (orders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.check_circle_outline, size: 64, color: EmberColors.success),
                  SizedBox(height: 16),
                  Text('All orders are clear!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Text('New customer tickets will appear here automatically.', style: TextStyle(color: EmberColors.textMuted)),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(24),
            itemCount: orders.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final order = orders[index];
              return _buildOrderTicketCard(context, ref, order);
            },
          );
        },
      ),
    );
  }

  Widget _buildOrderTicketCard(BuildContext context, WidgetRef ref, OrderModel order) {
    return Container(
      decoration: BoxDecoration(
        color: EmberColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: order.status == OrderStatus.pending ? EmberColors.statusPending : EmberColors.border,
          width: order.status == OrderStatus.pending ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: EmberColors.surfaceElevated,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      'TICKET #${order.orderNumber}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: EmberColors.primary),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      order.customerName,
                      style: const TextStyle(fontSize: 14, color: EmberColors.textMain, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Text(
                      DateFormatter.formatTime(order.createdAt),
                      style: const TextStyle(fontSize: 12, color: EmberColors.textMuted),
                    ),
                    const SizedBox(width: 12),
                    EmberBadge.fromOrderStatus(order.status),
                  ],
                ),
              ],
            ),
          ),

          // Items List
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (order.customerNotes != null && order.customerNotes!.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: EmberColors.warning.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: EmberColors.warning.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber, size: 16, color: EmberColors.warning),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Customer Note: ${order.customerNotes}',
                            style: const TextStyle(fontSize: 12, color: EmberColors.warning, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                ...order.items.map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: EmberColors.primary.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${item.quantity}x',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: EmberColors.primary, fontSize: 13),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.dish.name,
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: EmberColors.textMain)),
                                Text(item.selectedOptionNames.values.join(' • '),
                                    style: const TextStyle(fontSize: 12, color: EmberColors.textMuted)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )),

                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),

                // Action Controls Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total: ${CurrencyFormatter.formatCents(order.totalCents)}',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: EmberColors.textMain),
                    ),
                    _buildActionButton(context, ref, order),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, WidgetRef ref, OrderModel order) {
    switch (order.status) {
      case OrderStatus.pending:
        return EmberButton(
          label: 'Accept Order',
          icon: Icons.check,
          onPressed: () => _updateStatus(context, ref, order.id, OrderStatus.accepted),
        );
      case OrderStatus.accepted:
        return EmberButton(
          label: 'Start Preparation',
          icon: Icons.soup_kitchen,
          onPressed: () => _updateStatus(context, ref, order.id, OrderStatus.preparing),
        );
      case OrderStatus.preparing:
        return EmberButton(
          label: 'Mark Ready for Pickup',
          icon: Icons.check_circle,
          onPressed: () => _updateStatus(context, ref, order.id, OrderStatus.ready),
        );
      case OrderStatus.ready:
        return EmberButton(
          label: 'Complete Handover',
          icon: Icons.task_alt,
          onPressed: () => _updateStatus(context, ref, order.id, OrderStatus.handedOver),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Future<void> _updateStatus(BuildContext context, WidgetRef ref, String orderId, OrderStatus nextStatus) async {
    try {
      await ref.read(staffOrdersProvider.notifier).updateStatus(orderId, nextStatus);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Order #$orderId status updated to ${nextStatus.label}.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating status: $e'), backgroundColor: EmberColors.error),
      );
    }
  }
}
