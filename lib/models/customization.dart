class CustomizationOption {
  final String id;
  final String name;
  final int priceDeltaCents; // minor currency units (cents)
  final bool isAvailable;

  const CustomizationOption({
    required this.id,
    required this.name,
    required this.priceDeltaCents,
    this.isAvailable = true,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'priceDeltaCents': priceDeltaCents,
        'isAvailable': isAvailable,
      };

  factory CustomizationOption.fromJson(Map<String, dynamic> json) {
    return CustomizationOption(
      id: json['id'] as String,
      name: json['name'] as String,
      priceDeltaCents: json['priceDeltaCents'] as int,
      isAvailable: json['isAvailable'] as bool? ?? true,
    );
  }
}

class CustomizationGroup {
  final String id;
  final String name;
  final bool isRequired;
  final bool allowsMultiple;
  final List<CustomizationOption> options;

  const CustomizationGroup({
    required this.id,
    required this.name,
    this.isRequired = false,
    this.allowsMultiple = false,
    required this.options,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'isRequired': isRequired,
        'allowsMultiple': allowsMultiple,
        'options': options.map((o) => o.toJson()).toList(),
      };

  factory CustomizationGroup.fromJson(Map<String, dynamic> json) {
    return CustomizationGroup(
      id: json['id'] as String,
      name: json['name'] as String,
      isRequired: json['isRequired'] as bool? ?? false,
      allowsMultiple: json['allowsMultiple'] as bool? ?? false,
      options: (json['options'] as List<dynamic>)
          .map((e) => CustomizationOption.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
