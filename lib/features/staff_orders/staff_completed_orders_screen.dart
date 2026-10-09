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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back to Dashboard',
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/staff/dashboard');
            }
          },
        ),
        title: const FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text('Completed Orders History'),
        ),
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

          return LayoutBuilder(
            builder: (context, rootConstraints) {
              final isMobile = rootConstraints.maxWidth < 600;
              return ListView.separated(
                padding: EdgeInsets.all(isMobile ? 16 : 24),
                itemCount: completed.length,
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final order = completed[index];
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: EmberColors.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: EmberColors.border),
                    ),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final isNarrow = constraints.maxWidth < 500;
                        if (isNarrow) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      'TICKET #${order.orderNumber} • ${order.customerName}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: EmberColors.textMain),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  EmberBadge.fromOrderStatus(order.status),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Completed ${DateFormatter.formatDateTime(order.updatedAt)}',
                                style: const TextStyle(fontSize: 12, color: EmberColors.textMuted),
                              ),
                              const SizedBox(height: 12),
                              const Divider(),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    CurrencyFormatter.formatCents(order.totalCents),
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: EmberColors.primary),
                                  ),
                                  OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(color: EmberColors.border),
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    ),
                                    icon: const Icon(Icons.receipt_long, size: 16, color: EmberColors.textMain),
                                    label: const Text('View Receipt', style: TextStyle(fontSize: 12, color: EmberColors.textMain)),
                                    onPressed: () => context.go('/receipt/${order.id}'),
                                  ),
                                ],
                              ),
                            ],
                          );
                        }

                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'TICKET #${order.orderNumber} • ${order.customerName}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: EmberColors.textMain),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Completed ${DateFormatter.formatDateTime(order.updatedAt)}',
                                    style: const TextStyle(fontSize: 12, color: EmberColors.textMuted),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                EmberBadge.fromOrderStatus(order.status),
                                const SizedBox(width: 16),
                                Text(
                                  CurrencyFormatter.formatCents(order.totalCents),
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: EmberColors.primary),
                                ),
                                const SizedBox(width: 12),
                                IconButton(
                                  icon: const Icon(Icons.receipt_long, color: EmberColors.textMain),
                                  tooltip: 'View Receipt',
                                  onPressed: () => context.go('/receipt/${order.id}'),
                                ),
                              ],
                            ),
                          ],
                        );
                      },
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
