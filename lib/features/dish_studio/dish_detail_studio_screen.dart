import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/ember_theme.dart';
import '../../core/formatting/currency_formatter.dart';
import '../../core/widgets/ember_badge.dart';
import '../../core/widgets/ember_button.dart';
import '../../data/providers/app_providers.dart';
import '../../models/dish.dart';
import 'threed_viewer_widget.dart';

class DishDetailStudioScreen extends ConsumerStatefulWidget {
  final String dishId;

  const DishDetailStudioScreen({
    super.key,
    required this.dishId,
  });

  @override
  ConsumerState<DishDetailStudioScreen> createState() => _DishDetailStudioScreenState();
}

class _DishDetailStudioScreenState extends ConsumerState<DishDetailStudioScreen> {
  final Map<String, String> _selectedOptions = {};
  final Map<String, String> _selectedOptionNames = {};
  int _quantity = 1;
  Dish? _dish;

  @override
  void initState() {
    super.initState();
    _loadDishDefaults();
  }

  void _loadDishDefaults() async {
    final repo = ref.read(menuRepositoryProvider);
    final dish = await repo.getDishById(widget.dishId);
    if (dish != null && mounted) {
      setState(() {
        _dish = dish;
        // Pre-select required options
        for (var group in dish.customizationGroups) {
          if (group.options.isNotEmpty) {
            _selectedOptions[group.id] = group.options.first.id;
            _selectedOptionNames[group.id] = group.options.first.name;
          }
        }
      });
    }
  }

  int _calculateExtraCents() {
    if (_dish == null) return 0;
    int extra = 0;
    for (var group in _dish!.customizationGroups) {
      final selectedOptId = _selectedOptions[group.id];
      if (selectedOptId != null) {
        final opt = group.options.firstWhere(
          (o) => o.id == selectedOptId,
          orElse: () => group.options.first,
        );
        extra += opt.priceDeltaCents;
      }
    }
    return extra;
  }

  @override
  Widget build(BuildContext context) {
    final dishesAsync = ref.watch(dishesProvider);
    final dishes = dishesAsync.asData?.value;
    final liveDish = dishes != null
        ? dishes.cast<Dish?>().firstWhere((d) => d?.id == widget.dishId, orElse: () => null)
        : null;
    final dish = liveDish ?? _dish;

    if (dish == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: EmberColors.primary),
        ),
      );
    }

    final effectiveQuantity = dish.stockCount > 0 ? (_quantity > dish.stockCount ? dish.stockCount : _quantity) : 1;
    final extraCents = _calculateExtraCents();
    final unitTotalCents = dish.basePriceCents + extraCents;
    final itemTotalCents = unitTotalCents * effectiveQuantity;

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
        title: Text(dish.name, style: Theme.of(context).textTheme.headlineMedium),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_bag_outlined),
            onPressed: () => context.go('/cart'),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 900;

          if (isWide) {
            return Row(
              children: [
                // Left 60%: 3D Viewport Studio
                Expanded(
                  flex: 6,
                  child: _build3DStudioViewport(dish),
                ),
                // Right 40%: Customization Controls & Add to Cart
                Expanded(
                  flex: 4,
                  child: _buildCustomizationSidebar(dish, extraCents, unitTotalCents, itemTotalCents),
                ),
              ],
            );
          } else {
            return SingleChildScrollView(
              child: Column(
                children: [
                  SizedBox(
                    height: 360,
                    child: _build3DStudioViewport(dish),
                  ),
                  _buildCustomizationSidebar(dish, extraCents, unitTotalCents, itemTotalCents),
                ],
              ),
            );
          }
        },
      ),
    );
  }

  Widget _build3DStudioViewport(Dish dish) {
    return Container(
      color: EmberColors.background,
      child: Stack(
        children: [
          ThreeDViewerWidget(
            dishId: dish.model3dId,
            selectedOptions: _selectedOptions,
          ),
          Positioned(
            top: 16,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: EmberColors.surfaceElevated.withOpacity(0.85),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: EmberColors.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.threed_rotation, size: 16, color: EmberColors.primary),
                  const SizedBox(width: 6),
                  Text(
                    '${dish.name} • 3D Viewport',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: EmberColors.textMain),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomizationSidebar(
    Dish dish,
    int extraCents,
    int unitTotalCents,
    int itemTotalCents,
  ) {
    final effectiveQuantity = dish.stockCount > 0 ? (_quantity > dish.stockCount ? dish.stockCount : _quantity) : 1;
    return Container(
      color: EmberColors.surface,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          // Category & Stock Status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                dish.category.toUpperCase(),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: EmberColors.primary,
                ),
              ),
              EmberBadge.stockStatus(isAvailable: dish.isAvailable, portions: dish.stockCount),
            ],
          ),
          const SizedBox(height: 8),

          Text(
            dish.name,
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const SizedBox(height: 8),

          Text(
            dish.description,
            style: const TextStyle(fontSize: 14, color: EmberColors.textMuted, height: 1.4),
          ),

          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 16),

          // Customization Groups
          Text('CUSTOMIZE YOUR DISH', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),

          ...dish.customizationGroups.map((group) {
            final currentSelectedOptId = _selectedOptions[group.id];
            return Padding(
              padding: const EdgeInsets.only(bottom: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        group.name,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: EmberColors.textMain),
                      ),
                      if (group.isRequired) ...[
                        const SizedBox(width: 6),
                        const Text('*Required', style: TextStyle(fontSize: 11, color: EmberColors.primary)),
                      ]
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: group.options.map((opt) {
                      final isSelected = currentSelectedOptId == opt.id;
                      final deltaText = opt.priceDeltaCents != 0
                          ? ' (${opt.priceDeltaCents > 0 ? '+' : ''}${CurrencyFormatter.formatCents(opt.priceDeltaCents)})'
                          : '';

                      return ChoiceChip(
                        label: Text('${opt.name}$deltaText'),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _selectedOptions[group.id] = opt.id;
                              _selectedOptionNames[group.id] = opt.name;
                            });
                          }
                        },
                        selectedColor: EmberColors.primary,
                        backgroundColor: EmberColors.background,
                        labelStyle: TextStyle(
                          fontSize: 12,
                          color: isSelected ? EmberColors.background : EmberColors.textMain,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        side: BorderSide(
                          color: isSelected ? EmberColors.primary : EmberColors.border,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            );
          }),

          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 16),

          // Dynamic Price Breakdown Box
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: EmberColors.background,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: EmberColors.border),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Base Price', style: TextStyle(color: EmberColors.textMuted, fontSize: 13)),
                    Text(CurrencyFormatter.formatCents(dish.basePriceCents),
                        style: const TextStyle(color: EmberColors.textMain, fontSize: 13)),
                  ],
                ),
                if (extraCents != 0) ...[
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Customizations Extra', style: TextStyle(color: EmberColors.textMuted, fontSize: 13)),
                      Text('+${CurrencyFormatter.formatCents(extraCents)}',
                          style: const TextStyle(color: EmberColors.primary, fontSize: 13, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
                const SizedBox(height: 8),
                const Divider(),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Unit Price', style: TextStyle(color: EmberColors.textMain, fontWeight: FontWeight.bold)),
                    Text(CurrencyFormatter.formatCents(unitTotalCents),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: EmberColors.primary)),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Quantity Adjuster & Add to Cart
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: EmberColors.background,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: EmberColors.border),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove, size: 18),
                      onPressed: effectiveQuantity > 1 ? () => setState(() => _quantity = effectiveQuantity - 1) : null,
                    ),
                    Text(
                      '$effectiveQuantity',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add, size: 18),
                      onPressed: effectiveQuantity < dish.stockCount ? () => setState(() => _quantity = effectiveQuantity + 1) : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: EmberButton(
                  label: dish.isAvailable && dish.stockCount >= effectiveQuantity
                      ? 'Add to Cart • ${CurrencyFormatter.formatCents(itemTotalCents)}'
                      : (dish.stockCount == 0 ? 'Sold Out' : 'Insufficient Stock'),
                  icon: Icons.add_shopping_cart,
                  onPressed: dish.isAvailable && dish.stockCount >= effectiveQuantity
                      ? () {
                          ref.read(cartProvider.notifier).addItem(
                                dish: dish,
                                selectedOptions: Map.from(_selectedOptions),
                                selectedOptionNames: Map.from(_selectedOptionNames),
                                extraPriceCents: extraCents,
                                quantity: effectiveQuantity,
                              );
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: EmberColors.surfaceElevated,
                              content: Text('Added ${dish.name} ($effectiveQuantity) to your cart.'),
                              action: SnackBarAction(
                                label: 'VIEW CART',
                                textColor: EmberColors.primary,
                                onPressed: () => context.go('/cart'),
                              ),
                            ),
                          );
                        }
                      : null,
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
}
