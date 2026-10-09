import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/ember_theme.dart';
import '../../core/formatting/currency_formatter.dart';
import '../../core/widgets/ember_badge.dart';
import '../../core/widgets/ember_button.dart';
import '../../data/providers/app_providers.dart';
import '../../models/dish.dart';
import '../../models/order.dart';

class DiscoverScreen extends ConsumerWidget {
  const DiscoverScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dishesAsync = ref.watch(dishesProvider);
    final cartState = ref.watch(cartProvider);
    final activeOrdersAsync = ref.watch(activeOrdersProvider);
    final completedOrdersAsync = ref.watch(completedOrdersProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Hero Banner Header
          SliverAppBar(
            expandedHeight: 320,
            pinned: true,
            backgroundColor: EmberColors.background,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    'https://images.unsplash.com/photo-1544025162-d76694265947?w=1200&auto=format&fit=crop',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: EmberColors.surfaceElevated,
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          EmberColors.background.withOpacity(0.3),
                          EmberColors.background.withOpacity(0.85),
                          EmberColors.background,
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: EmberColors.primary.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: EmberColors.primary, width: 1),
                          ),
                          child: const Text(
                            'EMBER • FINE DINING EXPERIENCE',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                              color: EmberColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Cinematic Gastronomy & 3D Interactive Studio',
                          style: Theme.of(context).textTheme.displayMedium,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Experience precision culinary craftsmanship with our real-time 3D customization studio.',
                          style: TextStyle(color: EmberColors.textMuted, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Main Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Action CTA Bar
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isNarrow = constraints.maxWidth < 480;
                      if (isNarrow) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            EmberButton(
                              label: 'Explore 3D Menu',
                              icon: Icons.restaurant_menu,
                              onPressed: () => context.go('/menu'),
                            ),
                            const SizedBox(height: 10),
                            OutlinedButton.icon(
                              onPressed: () => context.go('/cart'),
                              icon: Icon(
                                cartState.itemCount > 0 ? Icons.shopping_bag : Icons.receipt_long,
                                color: cartState.itemCount > 0 ? EmberColors.primary : EmberColors.textMuted,
                                size: 18,
                              ),
                              label: Text(
                                cartState.itemCount > 0
                                    ? 'Cart (${cartState.itemCount}) • ${CurrencyFormatter.formatCents(cartState.totalCents)}'
                                    : 'View Orders / Cart',
                                style: TextStyle(
                                  color: cartState.itemCount > 0 ? EmberColors.primary : EmberColors.textMain,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: cartState.itemCount > 0 ? EmberColors.primary : EmberColors.border),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              ),
                            ),
                          ],
                        );
                      }

                      return Row(
                        children: [
                          Expanded(
                            child: EmberButton(
                              label: 'Explore 3D Menu',
                              icon: Icons.restaurant_menu,
                              onPressed: () => context.go('/menu'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          OutlinedButton.icon(
                            onPressed: () => context.go('/cart'),
                            icon: Icon(
                              cartState.itemCount > 0 ? Icons.shopping_bag : Icons.receipt_long,
                              color: cartState.itemCount > 0 ? EmberColors.primary : EmberColors.textMuted,
                              size: 18,
                            ),
                            label: Text(
                              cartState.itemCount > 0
                                  ? 'Cart (${cartState.itemCount}) • ${CurrencyFormatter.formatCents(cartState.totalCents)}'
                                  : 'View Orders / Cart',
                              style: TextStyle(
                                color: cartState.itemCount > 0 ? EmberColors.primary : EmberColors.textMain,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: cartState.itemCount > 0 ? EmberColors.primary : EmberColors.border),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            ),
                          ),
                        ],
                      );
                    },
                  ),

                  // Active or Recent Order Live Tracker Banner
                  () {
                    final activeOrders = activeOrdersAsync.value ?? [];
                    final completedOrders = completedOrdersAsync.value ?? [];
                    final latest = activeOrders.isNotEmpty
                        ? activeOrders.first
                        : (completedOrders.isNotEmpty ? completedOrders.first : null);
                    if (latest == null) return const SizedBox.shrink();
                    final isHandedOver = latest.status == OrderStatus.handedOver;

                    return Container(
                      margin: const EdgeInsets.only(top: 20),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: EmberColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isHandedOver
                              ? EmberColors.success.withValues(alpha: 0.6)
                              : EmberColors.primary.withValues(alpha: 0.5),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.25),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final isNarrow = constraints.maxWidth < 580;
                          if (isNarrow) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      isHandedOver ? Icons.check_circle : Icons.soup_kitchen,
                                      color: isHandedOver ? EmberColors.success : EmberColors.primary,
                                      size: 24,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        '${isHandedOver ? "Completed" : "Active"} Order #${latest.orderNumber}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: EmberColors.textMain),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    EmberBadge.fromOrderStatus(latest.status),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  isHandedOver
                                      ? 'Order handed over. Enjoy your meal!'
                                      : '${latest.items.length} item(s) • Total: ${CurrencyFormatter.formatCents(latest.totalCents)}',
                                  style: const TextStyle(fontSize: 12, color: EmberColors.textMuted),
                                ),
                                const SizedBox(height: 14),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: EmberColors.primary,
                                      foregroundColor: EmberColors.background,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      padding: const EdgeInsets.symmetric(vertical: 10),
                                    ),
                                    icon: const Icon(Icons.timeline, size: 16),
                                    label: const Text('Track Order Progress →', style: TextStyle(fontWeight: FontWeight.bold)),
                                    onPressed: () => context.go('/orders/tracking/${latest.id}'),
                                  ),
                                ),
                              ],
                            );
                          }

                          return Row(
                            children: [
                              Icon(
                                isHandedOver ? Icons.check_circle : Icons.soup_kitchen,
                                color: isHandedOver ? EmberColors.success : EmberColors.primary,
                                size: 28,
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Wrap(
                                      crossAxisAlignment: WrapCrossAlignment.center,
                                      spacing: 8,
                                      runSpacing: 4,
                                      children: [
                                        Text(
                                          '${isHandedOver ? "Completed" : "Active"} Order #${latest.orderNumber}',
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: EmberColors.textMain),
                                        ),
                                        EmberBadge.fromOrderStatus(latest.status),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      isHandedOver
                                          ? 'Order handed over. Enjoy your meal!'
                                          : '${latest.items.length} item(s) • Total: ${CurrencyFormatter.formatCents(latest.totalCents)}',
                                      style: const TextStyle(fontSize: 12, color: EmberColors.textMuted),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: EmberColors.primary,
                                  foregroundColor: EmberColors.background,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                icon: const Icon(Icons.timeline, size: 16),
                                label: const Text('Track Order →'),
                                onPressed: () => context.go('/orders/tracking/${latest.id}'),
                              ),
                            ],
                          );
                        },
                      ),
                    );
                  }(),

                  const SizedBox(height: 36),

                  // Section 1: Featured 3D Studio Dishes
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Featured 3D Dishes',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.headlineLarge,
                        ),
                      ),
                      TextButton(
                        onPressed: () => context.go('/menu'),
                        child: const Text('View All Menu →', style: TextStyle(color: EmberColors.primary)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  dishesAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator(color: EmberColors.primary)),
                    error: (err, _) => const Center(child: Text('Failed to load menu dishes', style: TextStyle(color: EmberColors.error))),
                    data: (dishes) {
                      final featured = dishes.where((d) => d.isFeatured).toList();

                      return LayoutBuilder(
                        builder: (context, constraints) {
                          final crossAxisCount = constraints.maxWidth > 800 ? 3 : (constraints.maxWidth > 500 ? 2 : 1);
                          return GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: crossAxisCount,
                              childAspectRatio: 0.85,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                            ),
                            itemCount: featured.length,
                            itemBuilder: (context, index) {
                              final dish = featured[index];
                              return _buildFeaturedCard(context, dish);
                            },
                          );
                        },
                      );
                    },
                  ),

                  const SizedBox(height: 40),

                  // Section 2: Dining Promises
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: EmberColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: EmberColors.border),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.view_in_ar, size: 40, color: EmberColors.primary),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'Real-Time 3D Customization Studio',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: EmberColors.textMain,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Every portion, sauce, and topping choice is rendered dynamically in 3D WebGL before placing your order.',
                                style: TextStyle(fontSize: 13, color: EmberColors.textMuted),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedCard(BuildContext context, Dish dish) {
    return InkWell(
      onTap: () => context.go('/dish/${dish.id}'),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        decoration: BoxDecoration(
          color: EmberColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: EmberColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                    child: Image.network(
                      dish.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(color: EmberColors.surfaceElevated),
                    ),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: EmberColors.background.withOpacity(0.85),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: EmberColors.primary.withOpacity(0.6)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.threed_rotation, size: 12, color: EmberColors.primary),
                          SizedBox(width: 4),
                          Text(
                            '3D STUDIO',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: EmberColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          dish.category,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 11, color: EmberColors.primary, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 6),
                      EmberBadge.stockStatus(isAvailable: dish.isAvailable, portions: dish.stockCount),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    dish.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: EmberColors.textMain),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    CurrencyFormatter.formatCents(dish.basePriceCents),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: EmberColors.primary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
