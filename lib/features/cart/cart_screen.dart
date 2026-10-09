import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/ember_theme.dart';
import '../../core/formatting/currency_formatter.dart';
import '../../core/widgets/ember_button.dart';
import '../../data/providers/app_providers.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartState = ref.watch(cartProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Your Order Cart', style: Theme.of(context).textTheme.headlineMedium),
        actions: [
          if (cartState.items.isNotEmpty)
            TextButton(
              onPressed: () => ref.read(cartProvider.notifier).clearCart(),
              child: const Text('Clear Cart', style: TextStyle(color: EmberColors.error)),
            ),
          const SizedBox(width: 12),
        ],
      ),
      body: cartState.items.isEmpty
          ? Center(
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
            )
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
}
