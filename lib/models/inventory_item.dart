class InventoryItem {
  final String dishId;
  final String dishName;
  final String category;
  final int availablePortions;
  final bool isAvailable;
  final DateTime updatedAt;

  const InventoryItem({
    required this.dishId,
    required this.dishName,
    required this.category,
    required this.availablePortions,
    required this.isAvailable,
    required this.updatedAt,
  });

  bool get isLowStock => availablePortions > 0 && availablePortions <= 5;
  bool get isSoldOut => !isAvailable || availablePortions <= 0;

  InventoryItem copyWith({
    String? dishId,
    String? dishName,
    String? category,
    int? availablePortions,
    bool? isAvailable,
    DateTime? updatedAt,
  }) {
    return InventoryItem(
      dishId: dishId ?? this.dishId,
      dishName: dishName ?? this.dishName,
      category: category ?? this.category,
      availablePortions: availablePortions ?? this.availablePortions,
      isAvailable: isAvailable ?? this.isAvailable,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'dishId': dishId,
        'dishName': dishName,
        'category': category,
        'availablePortions': availablePortions,
        'isAvailable': isAvailable,
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory InventoryItem.fromJson(Map<String, dynamic> json) {
    return InventoryItem(
      dishId: json['dishId'] as String,
      dishName: json['dishName'] as String,
      category: json['category'] as String,
      availablePortions: json['availablePortions'] as int,
      isAvailable: json['isAvailable'] as bool,
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}
