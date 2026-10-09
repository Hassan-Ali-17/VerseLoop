import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/configuration/app_config.dart';
import '../../app/theme/ember_theme.dart';
import '../../data/providers/app_providers.dart';
import 'connection_status_badge.dart';

class ModeSwitcherBar extends ConsumerWidget {
  const ModeSwitcherBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentMode = ref.watch(appModeProvider);
    final currentRole = ref.watch(userRoleProvider);

    return Container(
      color: EmberColors.surfaceElevated,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // Connection Status
            const ConnectionStatusBadge(),
            const SizedBox(width: 12),
            const SizedBox(
              height: 16,
              child: VerticalDivider(width: 1, color: EmberColors.border),
            ),
            const SizedBox(width: 12),

            // Environment Mode Switcher
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: EmberColors.background,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: EmberColors.border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildModeBtn(
                    label: 'Development Fixture',
                    isSelected: currentMode == AppMode.fixture,
                    onTap: () {
                      ref.read(appModeProvider.notifier).setMode(AppMode.fixture);
                      ref.invalidate(activeOrdersProvider);
                      ref.invalidate(staffOrdersProvider);
                      ref.invalidate(completedOrdersProvider);
                      ref.invalidate(inventoryProvider);
                    },
                  ),
                  _buildModeBtn(
                    label: 'Connected Backend Mode',
                    isSelected: currentMode == AppMode.connected,
                    onTap: () {
                      ref.read(appModeProvider.notifier).setMode(AppMode.connected);
                      ref.invalidate(activeOrdersProvider);
                      ref.invalidate(staffOrdersProvider);
                      ref.invalidate(completedOrdersProvider);
                      ref.invalidate(inventoryProvider);
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(width: 24),

            // Role Switcher for Hackathon Presentation
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: EmberColors.background,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: EmberColors.border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildRoleBtn(
                    label: '🍽️ Customer View',
                    isSelected: currentRole == UserRole.customer,
                    onTap: () {
                      ref.read(userRoleProvider.notifier).setRole(UserRole.customer);
                      context.go('/discover');
                    },
                  ),
                  _buildRoleBtn(
                    label: '⚡ Staff Operations',
                    isSelected: currentRole == UserRole.staff,
                    onTap: () {
                      ref.read(userRoleProvider.notifier).setRole(UserRole.staff);
                      context.go('/staff/dashboard');
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(width: 16),

            // Reset Test Data Button
            InkWell(
              onTap: () async {
                ref.read(cartProvider.notifier).clearCart();
                final mode = ref.read(appModeProvider);
                if (mode == AppMode.connected) {
                  try {
                    await ref.read(apiClientProvider).post('/orders/reset-data');
                  } catch (_) {}
                }
                ref.invalidate(activeOrdersProvider);
                ref.invalidate(staffOrdersProvider);
                ref.invalidate(completedOrdersProvider);
                ref.invalidate(inventoryProvider);

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Test data reset! Cart and order queues are clean.'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: EmberColors.background,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: EmberColors.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.cleaning_services, size: 13, color: EmberColors.textMuted),
                    SizedBox(width: 5),
                    Text(
                      'Reset Test Data',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: EmberColors.textMuted),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeBtn({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? EmberColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isSelected ? EmberColors.background : EmberColors.textMuted,
          ),
        ),
      ),
    );
  }

  Widget _buildRoleBtn({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? EmberColors.surfaceElevated : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
          border: isSelected ? Border.all(color: EmberColors.primary.withOpacity(0.5)) : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isSelected ? EmberColors.primary : EmberColors.textMuted,
          ),
        ),
      ),
    );
  }
}
