import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/ember_theme.dart';
import '../../core/formatting/currency_formatter.dart';
import '../../core/widgets/ember_badge.dart';
import '../../core/widgets/error_panel.dart';
import '../../core/widgets/loading_skeleton.dart';
import '../../data/providers/app_providers.dart';
import '../../models/dish.dart';

class MenuSearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';
  void setQuery(String query) => state = query;
}

final menuSearchQueryProvider = NotifierProvider<MenuSearchQueryNotifier, String>(MenuSearchQueryNotifier.new);

class SelectedCategoryNotifier extends Notifier<String> {
  @override
  String build() => 'All';
  void setCategory(String category) => state = category;
}

final selectedCategoryProvider = NotifierProvider<SelectedCategoryNotifier, String>(SelectedCategoryNotifier.new);

class MenuScreen extends ConsumerWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final menuRepo = ref.watch(menuRepositoryProvider);
    final dishesAsync = ref.watch(dishesProvider);
    final query = ref.watch(menuSearchQueryProvider);
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final cartState = ref.watch(cartProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back to Discover',
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/discover');
            }
          },
        ),
        title: Text('Restaurant Menu', style: Theme.of(context).textTheme.headlineMedium),
        actions: [
          IconButton(
            icon: const Icon(Icons.receipt_long, color: EmberColors.textMain),
            tooltip: 'View Orders / Cart',
            onPressed: () => context.go('/cart'),
          ),
          IconButton(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.shopping_bag_outlined, color: EmberColors.textMain),
                if (cartState.itemCount > 0)
                  Positioned(
                    right: -4,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: EmberColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${cartState.itemCount}',
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: EmberColors.background),
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: () => context.go('/cart'),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: Column(
        children: [
          // Filter & Search Header
          Container(
            color: EmberColors.surface,
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Search Input
                TextField(
                  onChanged: (val) => ref.read(menuSearchQueryProvider.notifier).setQuery(val),
                  decoration: InputDecoration(
                    hintText: 'Search dishes, ingredients, or flavors...',
                    prefixIcon: const Icon(Icons.search, color: EmberColors.textMuted),
                    suffixIcon: query.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: EmberColors.textMuted),
                            onPressed: () => ref.read(menuSearchQueryProvider.notifier).setQuery(''),
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 12),

                // Category Chips
                FutureBuilder<List<String>>(
                  future: menuRepo.getCategories(),
                  builder: (context, snapshot) {
                    final categories = snapshot.data ?? ['All', 'Main Course', 'Wood-Fired Pizza', 'Grill & Steaks', 'Soups & Bowls', 'Desserts'];
                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: categories.map((cat) {
                          final isSelected = selectedCategory == cat;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: FilterChip(
                              label: Text(cat),
                              selected: isSelected,
                              onSelected: (_) {
                                ref.read(selectedCategoryProvider.notifier).setCategory(cat);
                              },
                              selectedColor: EmberColors.primary,
                              backgroundColor: EmberColors.background,
                              labelStyle: TextStyle(
                                color: isSelected ? EmberColors.background : EmberColors.textMain,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                fontSize: 13,
                              ),
                              side: BorderSide(
                                color: isSelected ? EmberColors.primary : EmberColors.border,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          // Dishes List Grid
          Expanded(
            child: dishesAsync.when(
              loading: () => ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: 4,
                itemBuilder: (context, index) => const Padding(
                  padding: EdgeInsets.only(bottom: 12.0),
                  child: LoadingSkeletonCard(),
                ),
              ),
              error: (err, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: ErrorPanel(
                    message: 'Failed to load menu dishes. Please retry.',
                    onRetry: () => ref.read(dishesProvider.notifier).refreshDishes(),
                  ),
                ),
              ),
              data: (allDishes) {
                final dishes = allDishes.where((dish) {
                  final matchesQuery = query.isEmpty ||
                      dish.name.toLowerCase().contains(query.toLowerCase()) ||
                      dish.description.toLowerCase().contains(query.toLowerCase()) ||
                      dish.ingredients.any((ing) => ing.toLowerCase().contains(query.toLowerCase()));
                  final matchesCategory = selectedCategory == 'All' || dish.category == selectedCategory;
                  return matchesQuery && matchesCategory;
                }).toList();

                if (dishes.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.search_off, size: 48, color: EmberColors.textMuted),
                        SizedBox(height: 12),
                        Text(
                          'No dishes found matching your search',
                          style: TextStyle(fontSize: 16, color: EmberColors.textMuted),
                        ),
                      ],
                    ),
                  );
                }

                return LayoutBuilder(
                  builder: (context, constraints) {
                    final crossAxisCount = constraints.maxWidth > 900 ? 3 : (constraints.maxWidth > 600 ? 2 : 1);
                    final isSingleColumn = crossAxisCount == 1;
                    return GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        childAspectRatio: isSingleColumn ? (constraints.maxWidth < 420 ? 2.6 : 3.0) : 0.78,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      itemCount: dishes.length,
                      itemBuilder: (context, index) {
                        final dish = dishes[index];
                        return _buildMenuDishCard(context, dish, isHorizontal: isSingleColumn);
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuDishCard(BuildContext context, Dish dish, {bool isHorizontal = false}) {
    return InkWell(
      onTap: dish.isAvailable && dish.stockCount > 0 ? () => context.go('/dish/${dish.id}') : null,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        decoration: BoxDecoration(
          color: EmberColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: dish.isAvailable && dish.stockCount > 0 ? EmberColors.border : EmberColors.border.withOpacity(0.4),
          ),
        ),
        child: isHorizontal
            ? Row(
                children: [
                  SizedBox(
                    width: 125,
                    height: double.infinity,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.horizontal(left: Radius.circular(10)),
                          child: Image.network(
                            dish.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(color: EmberColors.surfaceElevated),
                          ),
                        ),
                        Positioned(
                          top: 8,
                          left: 8,
                          child: EmberBadge.stockStatus(isAvailable: dish.isAvailable, portions: dish.stockCount),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                dish.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: EmberColors.textMain),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                dish.description,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 12, color: EmberColors.textMuted),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                CurrencyFormatter.formatCents(dish.basePriceCents),
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: EmberColors.primary),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: dish.isAvailable && dish.stockCount > 0
                                      ? EmberColors.primary
                                      : EmberColors.border,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  dish.isAvailable && dish.stockCount > 0 ? 'Customize 3D →' : 'Sold Out',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: dish.isAvailable && dish.stockCount > 0
                                        ? EmberColors.background
                                        : EmberColors.textMuted,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 5,
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
                          child: EmberBadge.stockStatus(isAvailable: dish.isAvailable, portions: dish.stockCount),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 5,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                dish.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: EmberColors.textMain),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                dish.description,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 12, color: EmberColors.textMuted),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                CurrencyFormatter.formatCents(dish.basePriceCents),
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: EmberColors.primary),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: dish.isAvailable && dish.stockCount > 0
                                      ? EmberColors.primary
                                      : EmberColors.border,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  dish.isAvailable && dish.stockCount > 0 ? 'Customize 3D →' : 'Sold Out',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: dish.isAvailable && dish.stockCount > 0
                                        ? EmberColors.background
                                        : EmberColors.textMuted,
                                  ),
                                ),
                              ),
                            ],
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
}

