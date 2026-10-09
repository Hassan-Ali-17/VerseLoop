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

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartState = ref.watch(cartProvider);
    final activeOrdersAsync = ref.watch(activeOrdersProvider);
    final completedOrdersAsync = ref.watch(completedOrdersProvider);

    final hasActive = (activeOrdersAsync.value ?? []).isNotEmpty;
    final hasCompleted = (completedOrdersAsync.value ?? []).isNotEmpty;

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
        title: Text('Your Order Cart', style: Theme.of(context).textTheme.headlineMedium),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Orders',
            onPressed: () {
              ref.read(activeOrdersProvider.notifier).refreshOrders();
              ref.read(completedOrdersProvider.notifier).refreshOrders();
            },
          ),
          if (cartState.items.isNotEmpty)
            TextButton(
              onPressed: () => ref.read(cartProvider.notifier).clearCart(),
              child: const Text('Clear Cart', style: TextStyle(color: EmberColors.error)),
            ),
          const SizedBox(width: 12),
        ],
      ),
      body: cartState.items.isEmpty
          ? (hasActive
              ? _buildActiveOrdersView(context, activeOrdersAsync.value!)
              : (hasCompleted
                  ? _buildCompletedOrdersView(context, completedOrdersAsync.value!)
                  : (activeOrdersAsync.isLoading || completedOrdersAsync.isLoading
                      ? const Center(child: CircularProgressIndicator(color: EmberColors.primary))
                      : _buildEmptyPlaceholder(context))))
          : LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 900;
                if (isWide) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Cart Line Items List
                      Expanded(
                        flex: 6,
                        child: _buildItemList(context, ref, cartState),
                      ),
                      // Order Summary Card
                      Expanded(
                        flex: 4,
                        child: _buildSummaryCard(context, ref, cartState),
                      ),
                    ],
                  );
                } else {
                  return SingleChildScrollView(
                    child: Column(
                      children: [
                        _buildItemList(context, ref, cartState),
                        _buildSummaryCard(context, ref, cartState),
                      ],
                    ),
                  );
                }
              },
            ),
    );
  }

  Widget _buildItemList(BuildContext context, WidgetRef ref, CartState cartState) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      itemCount: cartState.items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final item = cartState.items[index];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: EmberColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: EmberColors.border),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  item.dish.imageUrl,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(width: 80, height: 80, color: EmberColors.surfaceElevated),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.dish.name,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: EmberColors.textMain),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.selectedOptionNames.values.join(' • '),
                      style: const TextStyle(fontSize: 12, color: EmberColors.textMuted),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      CurrencyFormatter.formatCents(item.unitPriceCents),
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: EmberColors.primary),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline, size: 20),
                        onPressed: () => ref.read(cartProvider.notifier).updateQuantity(item.id, item.quantity - 1),
                      ),
                      Text('${item.quantity}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline, size: 20),
                        onPressed: () => ref.read(cartProvider.notifier).updateQuantity(item.id, item.quantity + 1),
                      ),
                    ],
                  ),
                  Text(
                    CurrencyFormatter.formatCents(item.totalPriceCents),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: EmberColors.textMain),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryCard(BuildContext context, WidgetRef ref, CartState cartState) {
    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: EmberColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: EmberColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Order Summary', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Subtotal', style: TextStyle(color: EmberColors.textMuted)),
              Text(CurrencyFormatter.formatCents(cartState.subtotalCents),
                  style: const TextStyle(color: EmberColors.textMain, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Service & Prep Fee', style: TextStyle(color: EmberColors.textMuted)),
              Text(CurrencyFormatter.formatCents(cartState.serviceFeeCents),
                  style: const TextStyle(color: EmberColors.textMain, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Estimated Total', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Text(
                CurrencyFormatter.formatCents(cartState.totalCents),
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: EmberColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 24),
          EmberButton(
            label: 'Proceed to Checkout →',
            onPressed: () => context.go('/checkout'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyPlaceholder(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.shopping_bag_outlined, size: 64, color: EmberColors.textMuted),
          const SizedBox(height: 16),
          Text('Your cart is empty', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          const Text('Add gourmet dishes from our 3D Studio menu.',
              style: TextStyle(color: EmberColors.textMuted)),
          const SizedBox(height: 24),
          EmberButton(
            label: 'Browse Menu',
            icon: Icons.restaurant_menu,
            onPressed: () => context.go('/menu'),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveOrdersView(BuildContext context, List<OrderModel> orders) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: EmberColors.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: EmberColors.primary.withOpacity(0.4)),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: EmberColors.primary, size: 28),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Order Placed & In Kitchen Preparation!',
                        style: TextStyle(fontWeight: FontWeight.bold, color: EmberColors.primary, fontSize: 15),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Your placed order is being prepared by our kitchen staff. Track live progress below.',
                        style: TextStyle(color: EmberColors.textMuted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Active Kitchen Orders (${orders.length})',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add Items'),
                onPressed: () => context.go('/menu'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...orders.map((order) => _buildActiveOrderCard(context, order)),
        ],
      ),
    );
  }

  Widget _buildCompletedOrdersView(BuildContext context, List<OrderModel> orders) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: EmberColors.success.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: EmberColors.success.withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: EmberColors.success, size: 28),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Order Handed Over & Completed!',
                        style: TextStyle(fontWeight: FontWeight.bold, color: EmberColors.success, fontSize: 15),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Your meal has been handed over. You can review your receipt or track history below.',
                        style: TextStyle(color: EmberColors.textMuted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Recent Orders (${orders.length})',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                icon: const Icon(Icons.restaurant_menu, size: 16),
                label: const Text('Order More'),
                onPressed: () => context.go('/menu'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...orders.map((order) => _buildActiveOrderCard(context, order)),
        ],
      ),
    );
  }

  Widget _buildActiveOrderCard(BuildContext context, OrderModel order) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: EmberColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: EmberColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: EmberColors.surfaceElevated,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('ORDER #${order.orderNumber}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: EmberColors.primary)),
                      const SizedBox(height: 2),
                      Text(
                        'Placed by ${order.customerName} • ${DateFormatter.formatTime(order.createdAt)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, color: EmberColors.textMuted),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                EmberBadge.fromOrderStatus(order.status),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...order.items.map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: EmberColors.primary.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${item.quantity}x',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: EmberColors.primary, fontSize: 12),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              item.dish.name,
                              style: const TextStyle(fontWeight: FontWeight.w600, color: EmberColors.textMain),
                            ),
                          ),
                          Text(
                            CurrencyFormatter.formatCents(item.totalPriceCents),
                            style: const TextStyle(color: EmberColors.textMuted, fontSize: 13),
                          ),
                        ],
                      ),
                    )),
                const Divider(height: 24),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isNarrow = constraints.maxWidth < 450;
                    if (isNarrow) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Total: ${CurrencyFormatter.formatCents(order.totalCents)}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: EmberColors.textMain),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  icon: const Icon(Icons.receipt_long, size: 16),
                                  label: const Text('Receipt'),
                                  onPressed: () => context.go('/receipt/${order.id}'),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: EmberColors.primary,
                                    foregroundColor: EmberColors.background,
                                  ),
                                  icon: const Icon(Icons.timeline, size: 16),
                                  label: const Text('Track →'),
                                  onPressed: () => context.go('/orders/tracking/${order.id}'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    }

                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total: ${CurrencyFormatter.formatCents(order.totalCents)}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: EmberColors.textMain),
                        ),
                        Row(
                          children: [
                            OutlinedButton.icon(
                              icon: const Icon(Icons.receipt_long, size: 16),
                              label: const Text('Receipt'),
                              onPressed: () => context.go('/receipt/${order.id}'),
                            ),
                            const SizedBox(width: 10),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: EmberColors.primary,
                                foregroundColor: EmberColors.background,
                              ),
                              icon: const Icon(Icons.timeline, size: 16),
                              label: const Text('Track Order →'),
                              onPressed: () => context.go('/orders/tracking/${order.id}'),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
