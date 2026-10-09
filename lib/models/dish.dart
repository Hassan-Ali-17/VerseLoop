import 'customization.dart';

class Dish {
  final String id;
  final String name;
  final String category;
  final String description;
  final int basePriceCents;
  final String imageUrl;
  final String model3dId; // e.g. 'd1', 'd2', 'd3', 'd4', 'd5'
  final bool isAvailable;
  final int stockCount;
  final bool isFeatured;
  final List<String> ingredients;
  final List<CustomizationGroup> customizationGroups;

  const Dish({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.basePriceCents,
    required this.imageUrl,
    required this.model3dId,
    this.isAvailable = true,
    required this.stockCount,
    this.isFeatured = false,
    required this.ingredients,
    required this.customizationGroups,
  });

  Dish copyWith({
    String? id,
    String? name,
    String? category,
    String? description,
    int? basePriceCents,
    String? imageUrl,
    String? model3dId,
    bool? isAvailable,
    int? stockCount,
    bool? isFeatured,
    List<String>? ingredients,
    List<CustomizationGroup>? customizationGroups,
  }) {
    return Dish(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      description: description ?? this.description,
      basePriceCents: basePriceCents ?? this.basePriceCents,
      imageUrl: imageUrl ?? this.imageUrl,
      model3dId: model3dId ?? this.model3dId,
      isAvailable: isAvailable ?? this.isAvailable,
      stockCount: stockCount ?? this.stockCount,
      isFeatured: isFeatured ?? this.isFeatured,
      ingredients: ingredients ?? this.ingredients,
      customizationGroups: customizationGroups ?? this.customizationGroups,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'category': category,
        'description': description,
        'basePriceCents': basePriceCents,
        'imageUrl': imageUrl,
        'model3dId': model3dId,
        'isAvailable': isAvailable,
        'stockCount': stockCount,
        'isFeatured': isFeatured,
        'ingredients': ingredients,
        'customizationGroups': customizationGroups.map((g) => g.toJson()).toList(),
      };

  factory Dish.fromJson(Map<String, dynamic> json) {
    return Dish(
      id: json['id'] as String? ?? 'dish',
      name: json['name'] as String? ?? 'Gourmet Dish',
      category: json['category'] as String? ?? 'Main Course',
      description: json['description'] as String? ?? '',
      basePriceCents: json['basePriceCents'] as int? ?? 0,
      imageUrl: json['imageUrl'] as String? ?? '',
      model3dId: json['model3dId'] as String? ?? (json['id'] as String? ?? 'd1'),
      isAvailable: json['isAvailable'] as bool? ?? true,
      stockCount: json['stockCount'] as int? ?? 0,
      isFeatured: json['isFeatured'] as bool? ?? false,
      ingredients: json['ingredients'] != null
          ? List<String>.from(json['ingredients'] as List)
          : const [],
      customizationGroups: (json['customizationGroups'] as List<dynamic>?)
              ?.map((e) => CustomizationGroup.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }
}
