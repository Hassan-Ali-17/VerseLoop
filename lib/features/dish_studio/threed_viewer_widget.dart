import 'package:flutter/material.dart';
import '../../app/theme/ember_theme.dart';
import 'web_view_stub.dart' if (dart.library.html) 'web_view_impl.dart';

class ThreeDViewerWidget extends StatelessWidget {
  final String dishId;
  final Map<String, String> selectedOptions;

  const ThreeDViewerWidget({
    super.key,
    required this.dishId,
    required this.selectedOptions,
  });

  Map<String, dynamic> _buildCustomizationsPayload() {
    return {
      'portion': selectedOptions['g_portion'] ?? selectedOptions['g_pizza_size'] ?? selectedOptions['g_steak_cut'] ?? selectedOptions['g_dessert_portion'] ?? '',
      'sauce': selectedOptions['g_sauce'] ?? selectedOptions['g_pizza_base'] ?? selectedOptions['g_steak_butter'] ?? selectedOptions['g_ramen_broth'] ?? '',
      'cheese': selectedOptions['g_cheese'] ?? '',
      'toppings': selectedOptions.values.toList(),
      'side': selectedOptions['g_steak_side'] ?? '',
    };
  }

  @override
  Widget build(BuildContext context) {
    final viewId = 'threed-studio-${dishId.hashCode}';
    return Container(
      color: EmberColors.background,
      child: getPlatform3DViewerWidget(
        viewId: viewId,
        dishId: dishId,
        customizations: _buildCustomizationsPayload(),
      ),
    );
  }
}
