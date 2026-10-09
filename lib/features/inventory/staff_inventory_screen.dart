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
        title: const FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text('Inventory Management'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Inventory',
            onPressed: () => ref.read(inventoryProvider.notifier).refreshInventory(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: inventoryAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: EmberColors.primary)),
        error: (err, _) => Center(child: Text('Error: $err', style: const TextStyle(color: EmberColors.error))),
        data: (items) {
          return LayoutBuilder(
            builder: (context, rootConstraints) {
              final isMobile = rootConstraints.maxWidth < 600;
              return ListView.separated(
                padding: EdgeInsets.all(isMobile ? 16 : 24),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final item = items[index];
                  return _buildInventoryRowCard(context, ref, item);
                },
              );
            },
          );
        },
      ),
    );
  }

  void _handleToggleAvailability(BuildContext context, WidgetRef ref, InventoryItem item, bool val) {
    if (!val) {
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
  }

  Widget _buildInventoryRowCard(BuildContext context, WidgetRef ref, InventoryItem item) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: EmberColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: EmberColors.border),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 550;
          if (isNarrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.category.toUpperCase(),
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: EmberColors.primary, letterSpacing: 1.0)),
                          const SizedBox(height: 2),
                          Text(item.dishName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: EmberColors.textMain)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Switch(
                      value: item.isAvailable,
                      activeThumbColor: EmberColors.primary,
                      onChanged: (val) => _handleToggleAvailability(context, ref, item, val),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    EmberBadge.stockStatus(isAvailable: item.isAvailable, portions: item.availablePortions),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline, color: EmberColors.textMuted),
                          iconSize: 22,
                          constraints: const BoxConstraints(),
                          padding: const EdgeInsets.all(6),
                          onPressed: item.availablePortions > 0
                              ? () => ref.read(inventoryProvider.notifier).updatePortions(item.dishId, item.availablePortions - 1)
                              : null,
                        ),
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: EmberColors.background,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: EmberColors.border),
                          ),
                          child: Text(
                            '${item.availablePortions}',
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: EmberColors.textMain),
                          ),
                        ),
                        const SizedBox(width: 4),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline, color: EmberColors.textMuted),
                          iconSize: 22,
                          constraints: const BoxConstraints(),
                          padding: const EdgeInsets.all(6),
                          onPressed: () => ref.read(inventoryProvider.notifier).updatePortions(item.dishId, item.availablePortions + 1),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            );
          }

          return Row(
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
                onChanged: (val) => _handleToggleAvailability(context, ref, item, val),
              ),
            ],
          );
        },
      ),
    );
  }
}
