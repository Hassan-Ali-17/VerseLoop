import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/ember_theme.dart';
import '../../core/formatting/currency_formatter.dart';
import '../../core/widgets/ember_button.dart';
import '../../core/widgets/error_panel.dart';
import '../../data/providers/app_providers.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final _nameController = TextEditingController(text: 'Alexander Wright');
  final _notesController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cartState = ref.watch(cartProvider);
    final checkoutState = ref.watch(checkoutProvider);

    if (cartState.items.isEmpty && checkoutState.confirmedOrder == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Checkout')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('No items in cart for checkout.', style: TextStyle(color: EmberColors.textMuted)),
              const SizedBox(height: 16),
              EmberButton(
                label: 'Return to Menu',
                onPressed: () => context.go('/menu'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back to Cart',
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/cart');
            }
          },
        ),
        title: Text('Checkout & Order Confirmation', style: Theme.of(context).textTheme.headlineMedium),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Idempotency Key Info Panel
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: EmberColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: EmberColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.security, size: 18, color: EmberColors.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Idempotency Protection Active: ${checkoutState.idempotencyKey}',
                        style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: EmberColors.textMuted),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Error Message Panel (e.g., Inventory Conflict or Network Failure)
              if (checkoutState.errorMessage != null) ...[
                ErrorPanel(
                  title: 'Order Placement Error',
                  message: checkoutState.errorMessage!,
                  onRetry: () {
                    ref.read(checkoutProvider.notifier).submitOrder(
                          customerName: _nameController.text,
                          customerNotes: _notesController.text,
                        );
                  },
                ),
                const SizedBox(height: 24),
              ],

              // Customer Details Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: EmberColors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: EmberColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Customer Information', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Full Name *',
                        prefixIcon: Icon(Icons.person_outline, color: EmberColors.textMuted),
                      ),
                      validator: (val) => (val == null || val.trim().isEmpty) ? 'Name is required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _notesController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Chef Notes / Special Instructions',
                        prefixIcon: Icon(Icons.note_alt_outlined, color: EmberColors.textMuted),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Items Summary
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: EmberColors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: EmberColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Ordered Items Review', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 16),
                    ...cartState.items.map((item) => Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('${item.quantity}x ${item.dish.name}',
                                        style: const TextStyle(fontWeight: FontWeight.bold, color: EmberColors.textMain)),
                                    Text(item.selectedOptionNames.values.join(' • '),
                                        style: const TextStyle(fontSize: 12, color: EmberColors.textMuted)),
                                  ],
                                ),
                              ),
                              Text(CurrencyFormatter.formatCents(item.totalPriceCents),
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: EmberColors.primary)),
                            ],
                          ),
                        )),
                    const Divider(),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Estimated Amount',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        Text(
                          CurrencyFormatter.formatCents(cartState.totalCents),
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: EmberColors.primary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Place Order Action Button
              SizedBox(
                width: double.infinity,
                child: EmberButton(
                  label: checkoutState.isSubmitting
                      ? 'Submitting Order to Backend...'
                      : 'Place Authoritative Order • ${CurrencyFormatter.formatCents(cartState.totalCents)}',
                  icon: Icons.check_circle_outline,
                  isLoading: checkoutState.isSubmitting,
                  onPressed: checkoutState.isSubmitting
                      ? null
                      : () async {
                          if (_formKey.currentState!.validate()) {
                            final success = await ref.read(checkoutProvider.notifier).submitOrder(
                                  customerName: _nameController.text,
                                  customerNotes: _notesController.text,
                                );
                            if (success && mounted) {
                              final confirmed = ref.read(checkoutProvider).confirmedOrder;
                              if (confirmed != null) {
                                ref.read(checkoutProvider.notifier).resetKey();
                                context.go('/orders/tracking/${confirmed.id}');
                              }
                            }
                          }
                        },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
