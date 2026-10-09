import 'package:flutter/material.dart';
import '../../app/theme/ember_theme.dart';
import 'native_3d_dish_canvas.dart';

class ThreeDViewerWidget extends StatelessWidget {
  final String dishId;
  final Map<String, String> selectedOptions;

  const ThreeDViewerWidget({
    super.key,
    required this.dishId,
    required this.selectedOptions,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: EmberColors.background,
      child: Native3dDishCanvas(
        dishId: dishId,
        selectedOptions: selectedOptions,
      ),
    );
  }
}

