import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/ember_theme.dart';
import '../../core/formatting/currency_formatter.dart';
import '../../core/formatting/date_formatter.dart';
import '../../core/widgets/ember_badge.dart';
import '../../core/widgets/ember_button.dart';
import '../../core/widgets/error_panel.dart';
import '../../data/providers/app_providers.dart';
import '../../models/receipt.dart';

class ReceiptScreen extends ConsumerWidget {
  final String orderId;

  const ReceiptScreen({
    super.key,
    required this.orderId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderRepo = ref.watch(orderRepositoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Official Tax Receipt'),
      ),
      body: FutureBuilder<ReceiptModel>(
        future: orderRepo.getReceipt(orderId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: EmberColors.primary));
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: ErrorPanel(
                  title: 'Receipt Generation Error',
                  message: 'Could not fetch receipt details for Order ID #$orderId.',
                  onRetry: () => ref.refresh(orderRepositoryProvider),
                ),
              ),
            );
          }

          final receipt = snapshot.data!;

          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 500),
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: EmberColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: EmberColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.4),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    )
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Brand Header
                    Center(
                      child: Column(
                        children: [
                          const Text(
                            'LOOPSERVE • EMBER',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2.0,
                              color: EmberColors.primary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text('Modern Fine Dining Gastronomy', style: TextStyle(fontSize: 12, color: EmberColors.textMuted)),
                          const SizedBox(height: 12),
                          EmberBadge.fromOrderStatus(receipt.status),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 16),

                    // Receipt Meta
                    _buildMetaRow('Receipt No.', receipt.receiptNumber),
                    _buildMetaRow('Order No.', '#${receipt.orderNumber}'),
                    _buildMetaRow('Issued Date', DateFormatter.formatDateTime(receipt.issuedAt)),
                    _buildMetaRow('Customer', receipt.customerName),

                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 16),

                    // Items List
                    Text('ITEMIZED BILL', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 12),

                    ...receipt.items.map((item) => Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      '${item.quantity}x ${item.dishName}',
                                      style: const TextStyle(fontWeight: FontWeight.bold, color: EmberColors.textMain),
                                    ),
                                  ),
                                  Text(
                                    CurrencyFormatter.formatCents(item.totalPriceCents),
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: EmberColors.textMain),
                                  ),
                                ],
                              ),
                              if (item.customizationSummary.isNotEmpty)
                                Text(
                                  item.customizationSummary,
                                  style: const TextStyle(fontSize: 12, color: EmberColors.textMuted),
                                ),
                            ],
                          ),
                        )),

                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 16),

                    // Financial Calculations Breakdown
                    _buildMetaRow('Subtotal', CurrencyFormatter.formatCents(receipt.subtotalCents)),
                    _buildMetaRow('Tax (8% VAT)', CurrencyFormatter.formatCents(receipt.taxCents)),
                    _buildMetaRow('Service & Prep Fee', CurrencyFormatter.formatCents(receipt.serviceFeeCents)),

                    const SizedBox(height: 12),
                    const Divider(),
                    const SizedBox(height: 12),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'TOTAL PAID',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: EmberColors.textMain),
                        ),
                        Text(
                          CurrencyFormatter.formatCents(receipt.totalCents),
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: EmberColors.primary),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // Print / Back Actions
                    Row(
                      children: [
                        Expanded(
                          child: EmberButton(
                            label: 'Back to Menu',
                            isSecondary: true,
                            onPressed: () => context.go('/menu'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: EmberButton(
                            label: 'Track Progress',
                            icon: Icons.track_changes,
                            onPressed: () => context.go('/orders/tracking/$orderId'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMetaRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: EmberColors.textMuted)),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: EmberColors.textMain)),
        ],
      ),
    );
  }
}
