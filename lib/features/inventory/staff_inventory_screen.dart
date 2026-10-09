import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/ember_theme.dart';
import '../../core/widgets/ember_badge.dart';
import '../../data/providers/app_providers.dart';
import '../../models/inventory_item.dart';

class StaffInventoryScreen extends ConsumerWidget {
  const StaffInventoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inventoryAsync = ref.watch(inventoryProvider);

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
        title: const Text('Menu & Portion Inventory Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(inventoryProvider.notifier).refreshInventory(),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: inventoryAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: EmberColors.primary)),
        error: (err, _) => Center(child: Text('Error: $err', style: const TextStyle(color: EmberColors.error))),
        data: (items) {
          return ListView.separated(
            padding: const EdgeInsets.all(24),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final item = items[index];
              return _buildInventoryRowCard(context, ref, item);
            },
          );
        },
      ),
    );
  }

  Widget _buildInventoryRowCard(BuildContext context, WidgetRef ref, InventoryItem item) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: EmberColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: EmberColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.category.toUpperCase(),
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: EmberColors.primary, letterSpacing: 1.0)),
                const SizedBox(height: 4),
                Text(item.dishName,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: EmberColors.textMain)),
              ],
            ),
          ),
          EmberBadge.stockStatus(isAvailable: item.isAvailable, portions: item.availablePortions),
          const SizedBox(width: 24),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle_outline, color: EmberColors.textMuted),
                onPressed: item.availablePortions > 0
                    ? () => ref.read(inventoryProvider.notifier).updatePortions(item.dishId, item.availablePortions - 1)
                    : null,
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: EmberColors.background,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: EmberColors.border),
                ),
                child: Text(
                  '${item.availablePortions}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: EmberColors.textMain),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline, color: EmberColors.textMuted),
                onPressed: () => ref.read(inventoryProvider.notifier).updatePortions(item.dishId, item.availablePortions + 1),
              ),
            ],
          ),
          const SizedBox(width: 24),
          Switch(
            value: item.isAvailable,
            activeThumbColor: EmberColors.primary,
            onChanged: (val) {
              if (!val) {
                // Confirmation dialog before marking sold out
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: EmberColors.surface,
                    title: const Text('Mark Dish Sold Out?'),
                    content: Text('Are you sure you want to disable ${item.dishName} for customers?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Cancel', style: TextStyle(color: EmberColors.textMuted)),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          ref.read(inventoryProvider.notifier).toggleAvailability(item.dishId, false);
                          Navigator.pop(ctx);
                        },
                        child: const Text('Confirm Sold Out'),
                      ),
                    ],
                  ),
                );
              } else {
                ref.read(inventoryProvider.notifier).toggleAvailability(item.dishId, true);
              }
            },
          ),
        ],
      ),
    );
  }
}
