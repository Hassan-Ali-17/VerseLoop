import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/configuration/app_config.dart';
import '../../app/theme/ember_theme.dart';
import '../../data/providers/app_providers.dart';
import 'connection_status_badge.dart';
import 'staff_auth_dialog.dart';

class ModeSwitcherBar extends ConsumerWidget {
  const ModeSwitcherBar({super.key});

  void _invalidateAll(WidgetRef ref) {
    ref.invalidate(activeOrdersProvider);
    ref.invalidate(staffOrdersProvider);
    ref.invalidate(completedOrdersProvider);
    ref.invalidate(inventoryProvider);
    ref.invalidate(dishesProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentMode = ref.watch(appModeProvider);
    final currentRole = ref.watch(userRoleProvider);

    return Container(
      color: EmberColors.surfaceElevated,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 650;

          if (isMobile) {
            // Mobile layout: 2 lines
            // Line 1: Customer / Staff + Reset button
            // Line 2: Connection badge + Connected / Offline switcher
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Line 1: Role Switcher (Customer / Staff)
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: EmberColors.background,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: EmberColors.border),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildRoleBtn(
                                label: '🍽️ Customer',
                                isSelected: currentRole == UserRole.customer,
                                onTap: () {
                                  ref.read(userRoleProvider.notifier).setRole(UserRole.customer);
                                  context.go('/discover');
                                },
                              ),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: _buildRoleBtn(
                                label: '⚡ Staff',
                                isSelected: currentRole == UserRole.staff,
                                onTap: () {
                                  if (currentRole == UserRole.staff) {
                                    context.go('/staff/dashboard');
                                  } else {
                                    StaffAuthDialog.show(context);
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildResetButton(context, ref, compact: true),
                  ],
                ),
                const SizedBox(height: 8),

                // Line 2: Connection Status & Mode Switcher (Connected / Offline)
                Row(
                  children: [
                    const ConnectionStatusBadge(compact: true),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: EmberColors.background,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: EmberColors.border),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildModeBtn(
                                label: 'Connected',
                                isSelected: currentMode == AppMode.connected,
                                onTap: () {
                                  if (currentMode != AppMode.connected) {
                                    ref.read(appModeProvider.notifier).setMode(AppMode.connected);
                                    _invalidateAll(ref);
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: _buildModeBtn(
                                label: 'Offline',
                                isSelected: currentMode == AppMode.fixture,
                                onTap: () {
                                  if (currentMode != AppMode.fixture) {
                                    ref.read(appModeProvider.notifier).setMode(AppMode.fixture);
                                    _invalidateAll(ref);
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          }

          // Desktop / Tablet layout: single row
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                const ConnectionStatusBadge(),
                const SizedBox(width: 12),
                const SizedBox(
                  height: 16,
                  child: VerticalDivider(width: 1, color: EmberColors.border),
                ),
                const SizedBox(width: 12),

                // Environment Mode Switcher (Connected / Offline)
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
                        label: 'Offline (Fixture)',
                        isSelected: currentMode == AppMode.fixture,
                        onTap: () {
                          if (currentMode != AppMode.fixture) {
                            ref.read(appModeProvider.notifier).setMode(AppMode.fixture);
                            _invalidateAll(ref);
                          }
                        },
                      ),
                      _buildModeBtn(
                        label: 'Connected Backend',
                        isSelected: currentMode == AppMode.connected,
                        onTap: () {
                          if (currentMode != AppMode.connected) {
                            ref.read(appModeProvider.notifier).setMode(AppMode.connected);
                            _invalidateAll(ref);
                          }
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 20),

                // Role Switcher (Customer / Staff)
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
                          if (currentRole == UserRole.staff) {
                            context.go('/staff/dashboard');
                          } else {
                            StaffAuthDialog.show(context);
                          }
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 16),
                _buildResetButton(context, ref, compact: false),
              ],
            ),
          );
        },
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
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? EmberColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
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
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? EmberColors.surfaceElevated : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
          border: isSelected ? Border.all(color: EmberColors.primary.withValues(alpha: 0.5)) : null,
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isSelected ? EmberColors.primary : EmberColors.textMuted,
          ),
        ),
      ),
    );
  }

  Widget _buildResetButton(BuildContext context, WidgetRef ref, {bool compact = false}) {
    return InkWell(
      onTap: () async {
        ref.read(cartProvider.notifier).clearCart();
        final mode = ref.read(appModeProvider);
        if (mode == AppMode.connected) {
          try {
            await ref.read(apiClientProvider).post('/orders/reset-data');
          } catch (_) {}
        }
        _invalidateAll(ref);

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
        padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 10, vertical: 6),
        decoration: BoxDecoration(
          color: EmberColors.background,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: EmberColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cleaning_services, size: 13, color: EmberColors.textMuted),
            if (!compact) ...[
              const SizedBox(width: 5),
              const Text(
                'Reset Test Data',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: EmberColors.textMuted),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
