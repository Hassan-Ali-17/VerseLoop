import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/ember_theme.dart';
import '../../core/widgets/connection_status_badge.dart';
import '../../data/providers/app_providers.dart';
import '../../models/order.dart';

class StaffDashboardScreen extends ConsumerWidget {
  const StaffDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeOrdersAsync = ref.watch(staffOrdersProvider);
    final inventoryAsync = ref.watch(inventoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Staff Operations Dashboard'),
        actions: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Center(child: ConnectionStatusBadge()),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(staffOrdersProvider.notifier).refreshOrders();
              ref.read(inventoryProvider.notifier).refreshInventory();
            },
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Headline Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Kitchen Operations Console', style: Theme.of(context).textTheme.headlineMedium),
                    const SizedBox(height: 4),
                    const Text('Real-Time Order Queue & Inventory Synchronization',
                        style: TextStyle(color: EmberColors.textMuted)),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () => context.go('/staff/queue'),
                  icon: const Icon(Icons.receipt_long),
                  label: const Text('Open Live Order Queue →'),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Live Metrics Grid
            activeOrdersAsync.when(
              loading: () => const Center(child: CircularProgressIndicator(color: EmberColors.primary)),
              error: (err, _) => Text('Error loading orders: $err', style: const TextStyle(color: EmberColors.error)),
              data: (orders) {
                final pendingCount = orders.where((o) => o.status == OrderStatus.pending).length;
                final preparingCount = orders.where((o) => o.status == OrderStatus.preparing || o.status == OrderStatus.accepted).length;
                final readyCount = orders.where((o) => o.status == OrderStatus.ready).length;

                return inventoryAsync.when(
                  loading: () => const SizedBox.shrink(),
                  error: (err, _) => const SizedBox.shrink(),
                  data: (inventory) {
                    final soldOutCount = inventory.where((i) => i.isSoldOut).length;
                    final lowStockCount = inventory.where((i) => i.isLowStock).length;

                    return LayoutBuilder(
                      builder: (context, constraints) {
                        final crossCount = constraints.maxWidth > 900 ? 4 : (constraints.maxWidth > 500 ? 2 : 1);
                        return GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: crossCount,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 1.8,
                          children: [
                            _buildMetricCard(
                              context,
                              title: 'New Tickets (Action Required)',
                              value: '$pendingCount',
                              color: EmberColors.statusPending,
                              icon: Icons.notifications_active,
                              onTap: () => context.go('/staff/queue'),
                            ),
                            _buildMetricCard(
                              context,
                              title: 'Active Preparation',
                              value: '$preparingCount',
                              color: EmberColors.statusPreparing,
                              icon: Icons.soup_kitchen,
                              onTap: () => context.go('/staff/queue'),
                            ),
                            _buildMetricCard(
                              context,
                              title: 'Ready for Pickup',
                              value: '$readyCount',
                              color: EmberColors.statusReady,
                              icon: Icons.check_circle_outline,
                              onTap: () => context.go('/staff/queue'),
                            ),
                            _buildMetricCard(
                              context,
                              title: 'Sold Out / Low Stock Dishes',
                              value: '$soldOutCount Sold / $lowStockCount Low',
                              color: soldOutCount > 0 ? EmberColors.error : EmberColors.warning,
                              icon: Icons.inventory_2,
                              onTap: () => context.go('/staff/inventory'),
                            ),
                          ],
                        );
                      },
                    );
                  },
                );
              },
            ),

            const SizedBox(height: 32),

            // Navigation Cards Grid
            Text('Quick Operational Modules', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: _buildNavModuleCard(
                    context,
                    title: 'Live Order Queue',
                    subtitle: 'Inspect incoming customer tickets, update status, and manage prep times.',
                    icon: Icons.queue_play_next,
                    route: '/staff/queue',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildNavModuleCard(
                    context,
                    title: 'Menu & Portion Inventory',
                    subtitle: 'Toggle dish availability and adjust portion counts in real time.',
                    icon: Icons.inventory,
                    route: '/staff/inventory',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildNavModuleCard(
                    context,
                    title: 'Completed Orders Log',
                    subtitle: 'Review historical handed-over transactions and receipt copies.',
                    icon: Icons.history,
                    route: '/staff/completed',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(
    BuildContext context, {
    required String title,
    required String value,
    required Color color,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: EmberColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: EmberColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: const TextStyle(fontSize: 12, color: EmberColors.textMuted, fontWeight: FontWeight.bold)),
                Icon(icon, size: 20, color: color),
              ],
            ),
            Text(
              value,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavModuleCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required String route,
  }) {
    return InkWell(
      onTap: () => context.go(route),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: EmberColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: EmberColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 32, color: EmberColors.primary),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: EmberColors.textMain)),
            const SizedBox(height: 6),
            Text(subtitle, style: const TextStyle(fontSize: 12, color: EmberColors.textMuted)),
          ],
        ),
      ),
    );
  }
}
