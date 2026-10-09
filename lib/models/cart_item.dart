import 'dish.dart';

class CartItem {
  final String id;
  final Dish dish;
  final Map<String, String> selectedOptions; // groupId -> optionId
  final Map<String, String> selectedOptionNames; // groupId -> optionName
  final int extraPriceCents;
  final int quantity;

  const CartItem({
    required this.id,
    required this.dish,
    required this.selectedOptions,
    required this.selectedOptionNames,
    required this.extraPriceCents,
    this.quantity = 1,
  });

  int get unitPriceCents => dish.basePriceCents + extraPriceCents;
  int get totalPriceCents => unitPriceCents * quantity;

  CartItem copyWith({
    String? id,
    Dish? dish,
    Map<String, String>? selectedOptions,
    Map<String, String>? selectedOptionNames,
    int? extraPriceCents,
    int? quantity,
  }) {
    return CartItem(
      id: id ?? this.id,
      dish: dish ?? this.dish,
      selectedOptions: selectedOptions ?? this.selectedOptions,
      selectedOptionNames: selectedOptionNames ?? this.selectedOptionNames,
      extraPriceCents: extraPriceCents ?? this.extraPriceCents,
      quantity: quantity ?? this.quantity,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'dishId': dish.id,
        'dish': dish.toJson(),
        'selectedOptions': selectedOptions,
        'selectedOptionNames': selectedOptionNames,
        'extraPriceCents': extraPriceCents,
        'unitPriceCents': unitPriceCents,
        'quantity': quantity,
        'totalPriceCents': totalPriceCents,
      };

  factory CartItem.fromJson(Map<String, dynamic> json) {
    final dishData = json['dish'] is Map<String, dynamic>
        ? json['dish'] as Map<String, dynamic>
        : <String, dynamic>{
            'id': json['dishId'] ?? 'dish',
            'name': 'Gourmet Dish',
            'category': 'Main Course',
            'description': '',
            'basePriceCents': json['unitPriceCents'] ?? 2000,
            'imageUrl': 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=600&auto=format&fit=crop',
            'model3dId': json['dishId'] ?? 'd1',
            'stockCount': 10,
            'ingredients': <String>[],
            'customizationGroups': <Map<String, dynamic>>[],
          };

    return CartItem(
      id: json['id'] as String? ?? 'cart_${json['dishId'] ?? '1'}',
      dish: Dish.fromJson(dishData),
      selectedOptions: json['selectedOptions'] != null
          ? Map<String, String>.from(json['selectedOptions'] as Map)
          : const {},
      selectedOptionNames: json['selectedOptionNames'] != null
          ? Map<String, String>.from(json['selectedOptionNames'] as Map)
          : const {},
      extraPriceCents: json['extraPriceCents'] as int? ?? 0,
      quantity: json['quantity'] as int? ?? 1,
    );
  }
}
