import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/ember_theme.dart';
import '../../core/formatting/currency_formatter.dart';
import '../../core/formatting/date_formatter.dart';
import '../../core/widgets/ember_badge.dart';
import '../../data/providers/app_providers.dart';
import '../../models/order.dart';

class StaffCompletedOrdersScreen extends ConsumerWidget {
  const StaffCompletedOrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderRepo = ref.watch(orderRepositoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Completed Orders History'),
      ),
      body: FutureBuilder<List<OrderModel>>(
        future: orderRepo.getCompletedOrders(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: EmberColors.primary));
          }

          final completed = snapshot.data ?? [];

          if (completed.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.history, size: 64, color: EmberColors.textMuted),
                  SizedBox(height: 16),
                  Text('No completed orders yet', style: TextStyle(fontSize: 16, color: EmberColors.textMuted)),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(24),
            itemCount: completed.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final order = completed[index];
              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: EmberColors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: EmberColors.border),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('TICKET #${order.orderNumber} • ${order.customerName}',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: EmberColors.textMain)),
                        const SizedBox(height: 4),
                        Text('Completed ${DateFormatter.formatDateTime(order.updatedAt)}',
                            style: const TextStyle(fontSize: 12, color: EmberColors.textMuted)),
                      ],
                    ),
                    Row(
                      children: [
                        EmberBadge.fromOrderStatus(order.status),
                        const SizedBox(width: 16),
                        Text(CurrencyFormatter.formatCents(order.totalCents),
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: EmberColors.primary)),
                        const SizedBox(width: 16),
                        IconButton(
                          icon: const Icon(Icons.receipt_long, color: EmberColors.textMain),
                          onPressed: () => context.go('/receipt/${order.id}'),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
