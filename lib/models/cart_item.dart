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
    return CartItem(
      id: json['id'] as String,
      dish: Dish.fromJson(json['dish'] as Map<String, dynamic>),
      selectedOptions: Map<String, String>.from(json['selectedOptions'] as Map),
      selectedOptionNames: Map<String, String>.from(json['selectedOptionNames'] as Map),
      extraPriceCents: json['extraPriceCents'] as int,
      quantity: json['quantity'] as int? ?? 1,
    );
  }
}
