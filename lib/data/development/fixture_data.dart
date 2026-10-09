import '../../models/dish.dart';
import '../../models/customization.dart';
import '../../models/order.dart';
import '../../models/cart_item.dart';
import '../../models/inventory_item.dart';

class FixtureData {
  static final List<Dish> sampleDishes = [
    Dish(
      id: 'd1',
      name: 'Ember Signature Wagyu Burger',
      category: 'Main Course',
      description: 'Aged A5 Japanese Wagyu patty, caramelized onion jam, melted artisan cheddar, and secret truffle ember glaze on toasted brioche.',
      basePriceCents: 2450, // $24.50
      imageUrl: 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=600&auto=format&fit=crop',
      model3dId: 'd1',
      isAvailable: true,
      stockCount: 8,
      isFeatured: true,
      ingredients: ['A5 Wagyu Beef', 'Caramelized Onion', 'Aged Cheddar', 'Brioche Bun', 'Truffle Ember Glaze'],
      customizationGroups: [
        const CustomizationGroup(
          id: 'g_portion',
          name: 'Portion Size',
          isRequired: true,
          options: [
            CustomizationOption(id: 'opt_p1', name: 'Classic Single', priceDeltaCents: 0),
            CustomizationOption(id: 'opt_p2', name: 'Double Patty', priceDeltaCents: 850),
            CustomizationOption(id: 'opt_p3', name: 'Junior Portion', priceDeltaCents: -400),
          ],
        ),
        const CustomizationGroup(
          id: 'g_sauce',
          name: 'Signature Sauce',
          isRequired: true,
          options: [
            CustomizationOption(id: 'opt_s1', name: 'Secret Ember Sauce', priceDeltaCents: 0),
            CustomizationOption(id: 'opt_s2', name: 'Truffle Mayo', priceDeltaCents: 250),
            CustomizationOption(id: 'opt_s3', name: 'Smoky BBQ', priceDeltaCents: 150),
            CustomizationOption(id: 'opt_s4', name: 'Spicy Sriracha', priceDeltaCents: 150),
          ],
        ),
        const CustomizationGroup(
          id: 'g_cheese',
          name: 'Artisan Cheese',
          isRequired: false,
          options: [
            CustomizationOption(id: 'opt_c1', name: 'Melted Cheddar', priceDeltaCents: 0),
            CustomizationOption(id: 'opt_c2', name: 'Melted Cheddar Extra', priceDeltaCents: 300),
            CustomizationOption(id: 'opt_c3', name: 'Smoked Gouda', priceDeltaCents: 350),
            CustomizationOption(id: 'opt_c4', name: 'None', priceDeltaCents: 0),
          ],
        ),
        const CustomizationGroup(
          id: 'g_toppings',
          name: 'Extra Toppings',
          isRequired: false,
          options: [
            CustomizationOption(id: 'opt_t1', name: 'Crispy Bacon', priceDeltaCents: 350),
            CustomizationOption(id: 'opt_t2', name: 'Sautéed Mushrooms', priceDeltaCents: 250),
            CustomizationOption(id: 'opt_t3', name: 'Fried Egg', priceDeltaCents: 200),
          ],
        ),
      ],
    ),
    Dish(
      id: 'd2',
      name: 'Artisan Truffle & Wild Mushroom Pizza',
      category: 'Wood-Fired Pizza',
      description: 'Slow-fermented sourdough, black truffle cream, wild forest mushrooms, fior di latte mozzarella, and fresh thyme.',
      basePriceCents: 2800, // $28.00
      imageUrl: 'https://images.unsplash.com/photo-1513104890138-7c749659a591?w=600&auto=format&fit=crop',
      model3dId: 'd2',
      isAvailable: true,
      stockCount: 12,
      isFeatured: true,
      ingredients: ['Sourdough', 'Black Truffle Cream', 'Wild Mushrooms', 'Fior di Latte', 'Fresh Thyme'],
      customizationGroups: [
        const CustomizationGroup(
          id: 'g_pizza_size',
          name: 'Size',
          isRequired: true,
          options: [
            CustomizationOption(id: 'opt_pz1', name: 'Medium 11"', priceDeltaCents: 0),
            CustomizationOption(id: 'opt_pz2', name: 'Large 14"', priceDeltaCents: 600),
          ],
        ),
        const CustomizationGroup(
          id: 'g_pizza_base',
          name: 'Base Sauce',
          isRequired: true,
          options: [
            CustomizationOption(id: 'opt_pb1', name: 'Black Truffle Cream', priceDeltaCents: 0),
            CustomizationOption(id: 'opt_pb2', name: 'Classic Tomato', priceDeltaCents: 0),
            CustomizationOption(id: 'opt_pb3', name: 'Pesto Base', priceDeltaCents: 200),
          ],
        ),
      ],
    ),
    Dish(
      id: 'd3',
      name: 'Wood-Grilled Wagyu Ribeye Steak',
      category: 'Grill & Steaks',
      description: 'Prime 300g Wagyu ribeye grilled over white oak charcoal, served with marrow butter and charred rosemary.',
      basePriceCents: 4500, // $45.00
      imageUrl: 'https://images.unsplash.com/photo-1558030006-450675393462?w=600&auto=format&fit=crop',
      model3dId: 'd3',
      isAvailable: true,
      stockCount: 5,
      isFeatured: true,
      ingredients: ['Wagyu Ribeye 300g', 'Bone Marrow Butter', 'Charred Rosemary', 'Sea Salt'],
      customizationGroups: [
        const CustomizationGroup(
          id: 'g_steak_cut',
          name: 'Cut Size',
          isRequired: true,
          options: [
            CustomizationOption(id: 'opt_st1', name: '300g Standard', priceDeltaCents: 0),
            CustomizationOption(id: 'opt_st2', name: '500g Feast', priceDeltaCents: 2200),
          ],
        ),
        const CustomizationGroup(
          id: 'g_steak_butter',
          name: 'Finish Butter',
          isRequired: true,
          options: [
            CustomizationOption(id: 'opt_sb1', name: 'Herb Garlic Butter', priceDeltaCents: 0),
            CustomizationOption(id: 'opt_sb2', name: 'Truffle Butter', priceDeltaCents: 400),
          ],
        ),
        const CustomizationGroup(
          id: 'g_steak_side',
          name: 'Included Side',
          isRequired: true,
          options: [
            CustomizationOption(id: 'opt_side1', name: 'Truffle Fries', priceDeltaCents: 0),
            CustomizationOption(id: 'opt_side2', name: 'Charred Asparagus', priceDeltaCents: 200),
          ],
        ),
      ],
    ),
    Dish(
      id: 'd4',
      name: 'Smoky Tonkotsu Ramen Supreme',
      category: 'Soups & Bowls',
      description: '24-hour simmered pork bone broth, hand-crafted wheat noodles, slow-braised chashu pork belly, ajitsuke tamago egg.',
      basePriceCents: 2150, // $21.50
      imageUrl: 'https://images.unsplash.com/photo-1569718212165-3a8278d5f624?w=600&auto=format&fit=crop',
      model3dId: 'd4',
      isAvailable: true,
      stockCount: 15,
      isFeatured: false,
      ingredients: ['Tonkotsu Broth', 'Wheat Noodles', 'Chashu Pork Belly', 'Ajitsuke Egg', 'Black Garlic Oil'],
      customizationGroups: [
        const CustomizationGroup(
          id: 'g_ramen_broth',
          name: 'Broth Style',
          isRequired: true,
          options: [
            CustomizationOption(id: 'opt_rb1', name: 'Classic Rich Tonkotsu', priceDeltaCents: 0),
            CustomizationOption(id: 'opt_rb2', name: 'Spicy Miso', priceDeltaCents: 150),
            CustomizationOption(id: 'opt_rb3', name: 'Black Garlic Oil', priceDeltaCents: 200),
          ],
        ),
      ],
    ),
    Dish(
      id: 'd5',
      name: 'Ember Dark Chocolate Molten Lava Cake',
      category: 'Desserts',
      description: 'Valrhona 70% dark chocolate cake with a molten truffle center, accompanied by Madagascar vanilla bean ice cream.',
      basePriceCents: 1400, // $14.00
      imageUrl: 'https://images.unsplash.com/photo-1606313564200-e75d5e30476c?w=600&auto=format&fit=crop',
      model3dId: 'd5',
      isAvailable: true,
      stockCount: 1, // Competed portion test fixture!
      isFeatured: true,
      ingredients: ['70% Valrhona Chocolate', 'Madagascar Vanilla Bean', 'Gold Leaf', 'Raspberry Coulis'],
      customizationGroups: [
        const CustomizationGroup(
          id: 'g_dessert_portion',
          name: 'Serving Option',
          isRequired: true,
          options: [
            CustomizationOption(id: 'opt_des1', name: 'Solo Cake', priceDeltaCents: 0),
            CustomizationOption(id: 'opt_des2', name: 'Vanilla Bean Ice Cream', priceDeltaCents: 350),
          ],
        ),
      ],
    ),
  ];

  static List<InventoryItem> initialInventory = sampleDishes.map((dish) {
    return InventoryItem(
      dishId: dish.id,
      dishName: dish.name,
      category: dish.category,
      availablePortions: dish.stockCount,
      isAvailable: dish.isAvailable,
      updatedAt: DateTime.now(),
    );
  }).toList();

  static List<OrderModel> sampleOrders = [];
}
