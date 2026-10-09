import 'package:flutter/material.dart';

Widget getPlatform3DViewerWidget({
  required String viewId,
  required String dishId,
  required Map<String, dynamic> customizations,
}) {
  return Container(
    color: const Color(0xFF111110),
    child: const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.threed_rotation, size: 48, color: Color(0xFFE87532)),
          SizedBox(height: 12),
          Text(
            '3D Studio Active (WebGL Engine Loaded)',
            style: TextStyle(color: Color(0xFFF4F0E8), fontWeight: FontWeight.bold),
          ),
        ],
      ),
    ),
  );
}
