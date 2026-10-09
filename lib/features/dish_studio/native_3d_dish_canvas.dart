import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../app/theme/ember_theme.dart';

/// Interactive Native 3D Dish Canvas Engine
/// Features:
/// - True 3D projection (pitch, yaw, perspective)
/// - Interactive touch / mouse drag rotation (360 degrees)
/// - Pinch / button zoom controls
/// - Depth-sorted multi-layered geometric rendering
/// - Real-time synchronization with meal customization options
/// - Dynamic lighting, shading, drop shadows, and steam/ember particles
class Native3dDishCanvas extends StatefulWidget {
  final String dishId;
  final Map<String, String> selectedOptions;

  const Native3dDishCanvas({
    super.key,
    required this.dishId,
    required this.selectedOptions,
  });

  @override
  State<Native3dDishCanvas> createState() => _Native3dDishCanvasState();
}

class _Native3dDishCanvasState extends State<Native3dDishCanvas>
    with SingleTickerProviderStateMixin {
  double _yaw = 0.45; // Horizontal rotation angle (radians)
  double _pitch = 0.55; // Vertical tilt angle (radians)
  double _zoom = 1.0;
  bool _isAutoRotating = true;

  late AnimationController _animationController;
  Offset _lastFocalPoint = Offset.zero;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..addListener(() {
        if (_isAutoRotating) {
          setState(() {
            _yaw = (_yaw + 0.008) % (2 * math.pi);
          });
        }
      });
    _animationController.repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _resetCamera() {
    setState(() {
      _yaw = 0.45;
      _pitch = 0.55;
      _zoom = 1.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 3D Canvas with Gesture Controls
        GestureDetector(
          onScaleStart: (details) {
            _lastFocalPoint = details.focalPoint;
            if (_isAutoRotating) {
              setState(() => _isAutoRotating = false);
            }
          },
          onScaleUpdate: (details) {
            setState(() {
              if (details.scale != 1.0) {
                _zoom = (_zoom * details.scale).clamp(0.6, 2.2);
              } else {
                final delta = details.focalPoint - _lastFocalPoint;
                _yaw = (_yaw + delta.dx * 0.012) % (2 * math.pi);
                _pitch = (_pitch + delta.dy * 0.012).clamp(0.15, 1.35);
              }
              _lastFocalPoint = details.focalPoint;
            });
          },
          child: Container(
            color: const Color(0xFF111110),
            width: double.infinity,
            height: double.infinity,
            child: CustomPaint(
              painter: _Dish3DPainter(
                dishId: widget.dishId,
                selectedOptions: widget.selectedOptions,
                yaw: _yaw,
                pitch: _pitch,
                zoom: _zoom,
                time: _animationController.value,
              ),
            ),
          ),
        ),

        // 3D Viewport HUD Overlay Controls
        Positioned(
          bottom: 16,
          right: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xDD1B1B19),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF30302C)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildCtrlButton(
                  icon: _isAutoRotating ? Icons.pause_circle_outline : Icons.play_circle_outline,
                  tooltip: _isAutoRotating ? 'Pause Auto-Rotate' : 'Resume Auto-Rotate',
                  onTap: () => setState(() => _isAutoRotating = !_isAutoRotating),
                  isActive: _isAutoRotating,
                ),
                const SizedBox(width: 4),
                _buildCtrlButton(
                  icon: Icons.zoom_in,
                  tooltip: 'Zoom In',
                  onTap: () => setState(() => _zoom = (_zoom + 0.15).clamp(0.6, 2.2)),
                ),
                const SizedBox(width: 4),
                _buildCtrlButton(
                  icon: Icons.zoom_out,
                  tooltip: 'Zoom Out',
                  onTap: () => setState(() => _zoom = (_zoom - 0.15).clamp(0.6, 2.2)),
                ),
                const SizedBox(width: 4),
                _buildCtrlButton(
                  icon: Icons.refresh,
                  tooltip: 'Reset Camera',
                  onTap: _resetCamera,
                ),
              ],
            ),
          ),
        ),

        // Hint Overlay (Drag to Rotate 360°)
        Positioned(
          top: 14,
          right: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xBB1B1B19),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFF30302C)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.touch_app, size: 14, color: EmberColors.primary),
                SizedBox(width: 4),
                Text(
                  'Drag 360° • Pinch Zoom',
                  style: TextStyle(fontSize: 11, color: EmberColors.textMuted),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCtrlButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: isActive ? EmberColors.primary.withOpacity(0.2) : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            icon,
            size: 18,
            color: isActive ? EmberColors.primary : const Color(0xFFF4F0E8),
          ),
        ),
      ),
    );
  }
}

/// Custom 3D Projection & Dish Geometry Painter
class _Dish3DPainter extends CustomPainter {
  final String dishId;
  final Map<String, String> selectedOptions;
  final double yaw;
  final double pitch;
  final double zoom;
  final double time;

  _Dish3DPainter({
    required this.dishId,
    required this.selectedOptions,
    required this.yaw,
    required this.pitch,
    required this.zoom,
    required this.time,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2 + 20);

    // 1. Draw Drop Shadow on table surface
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.55)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 28);
    canvas.drawOval(
      Rect.fromCenter(
        center: center.translate(0, 75 * zoom),
        width: 260 * zoom,
        height: 110 * zoom * math.sin(pitch),
      ),
      shadowPaint,
    );

    // 2. Draw 3D Serving Platter / Board
    _drawPlatter(canvas, center);

    // 3. Render Dish-Specific 3D Multi-Layer Geometry
    switch (dishId) {
      case 'd1':
        _draw3DWagyuBurger(canvas, center);
        break;
      case 'd2':
        _draw3DArtisanPizza(canvas, center);
        break;
      case 'd3':
        _draw3DSteak(canvas, center);
        break;
      case 'd4':
        _draw3DRamen(canvas, center);
        break;
      case 'd5':
        _draw3DLavaCake(canvas, center);
        break;
      default:
        _draw3DWagyuBurger(canvas, center);
    }

    // 4. Draw Rising Steam / Heat Particles for hot gourmet dishes
    _drawSteamParticles(canvas, center);
  }

  // --- 3D Projection Helper ---
  Offset _project(double x, double y, double z, Offset center) {
    // Rotate by Yaw around Y-axis
    final cosY = math.cos(yaw);
    final sinY = math.sin(yaw);
    final rotX = x * cosY - z * sinY;
    final rotZ = x * sinY + z * cosY;

    // Rotate by Pitch around X-axis
    final cosP = math.cos(pitch);
    final sinP = math.sin(pitch);
    final rotY = y * cosP - rotZ * sinP;
    final depthZ = y * sinP + rotZ * cosP;

    // Perspective projection
    final fov = 350.0;
    final scale = (fov / (fov + depthZ * 0.45)) * zoom;

    return Offset(
      center.dx + rotX * scale,
      center.dy + rotY * scale,
    );
  }

  // --- 3D Serving Platter ---
  void _drawPlatter(Canvas canvas, Offset center) {
    final platterRadius = 135.0;
    final platterHeight = 12.0;

    // Bottom Rim
    final bottomPath = Path();
    final topPath = Path();
    const segments = 36;

    final bottomPoints = <Offset>[];
    final topPoints = <Offset>[];

    for (int i = 0; i <= segments; i++) {
      final angle = (i / segments) * 2 * math.pi;
      final px = platterRadius * math.cos(angle);
      final pz = platterRadius * math.sin(angle);
      bottomPoints.add(_project(px, platterHeight, pz, center));
      topPoints.add(_project(px, 0, pz, center));
    }

    bottomPath.moveTo(bottomPoints.first.dx, bottomPoints.first.dy);
    topPath.moveTo(topPoints.first.dx, topPoints.first.dy);
    for (int i = 1; i <= segments; i++) {
      bottomPath.lineTo(bottomPoints[i].dx, bottomPoints[i].dy);
      topPath.lineTo(topPoints[i].dx, topPoints[i].dy);
    }

    // Rim side shading
    final rimPaint = Paint()
      ..shader = LinearGradient(
        colors: [const Color(0xFF24221F), const Color(0xFF383531), const Color(0xFF1D1B18)],
      ).createShader(Rect.fromCenter(center: center, width: 300, height: 100));

    // Connect top and bottom points for side cylinder rim
    final sidePath = Path();
    for (int i = 0; i < segments; i++) {
      sidePath.moveTo(topPoints[i].dx, topPoints[i].dy);
      sidePath.lineTo(topPoints[i + 1].dx, topPoints[i + 1].dy);
      sidePath.lineTo(bottomPoints[i + 1].dx, bottomPoints[i + 1].dy);
      sidePath.lineTo(bottomPoints[i].dx, bottomPoints[i].dy);
      sidePath.close();
    }
    canvas.drawPath(sidePath, rimPaint);

    // Top surface platter (dark artisan ceramic)
    final topPaint = Paint()
      ..shader = RadialGradient(
        colors: [const Color(0xFF2C2A26), const Color(0xFF1E1D1A), const Color(0xFF161513)],
      ).createShader(Rect.fromCenter(center: center, width: 280, height: 160));
    canvas.drawPath(topPath, topPaint);

    // Decorative golden accent rim ring
    final goldRingPaint = Paint()
      ..color = const Color(0xFFE87532).withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawPath(topPath, goldRingPaint);
  }

  // ==========================================================================
  // DISH 1: EMBER SIGNATURE WAGYU BURGER (3D Layered Cylinder/Mesh)
  // ==========================================================================
  void _draw3DWagyuBurger(Canvas canvas, Offset center) {
    final isDouble = selectedOptions['g_portion'] == 'opt_p2';
    final isJunior = selectedOptions['g_portion'] == 'opt_p3';
    final cheese = selectedOptions['g_cheese'] ?? 'opt_c1';
    final sauce = selectedOptions['g_sauce'] ?? 'opt_s1';
    final hasBacon = selectedOptions.values.contains('opt_t1');
    final hasMushrooms = selectedOptions.values.contains('opt_t2');
    final hasEgg = selectedOptions.values.contains('opt_t3');

    // Layer 1: Bottom Brioche Bun
    _draw3DCylinder(
      canvas: canvas,
      center: center,
      yBase: 0,
      height: 16,
      radius: 65,
      topColor: const Color(0xFFD49A5B),
      sideColor: const Color(0xFFB57C3D),
    );

    // Layer 2: Sauce Bottom Bed
    Color sauceColor = const Color(0xFFB03A2E); // Secret Ember
    if (sauce == 'opt_s2') sauceColor = const Color(0xFFF7F2E7); // Truffle Mayo
    if (sauce == 'opt_s3') sauceColor = const Color(0xFF5D2E14); // BBQ
    if (sauce == 'opt_s4') sauceColor = const Color(0xFFE74C3C); // Sriracha

    _draw3DCylinder(
      canvas: canvas,
      center: center,
      yBase: -16,
      height: 4,
      radius: 60,
      topColor: sauceColor,
      sideColor: sauceColor.withOpacity(0.85),
    );

    // Layer 3: Wagyu Beef Patty 1
    double currentY = -20;
    final pattyHeight = isJunior ? 12.0 : 18.0;
    _draw3DPatty(canvas, center, currentY, pattyHeight, 68);
    currentY -= pattyHeight;

    // Optional Cheese Layer Drooping Over Patty
    if (cheese != 'opt_c4') {
      Color cheeseColor = const Color(0xFFFFB800);
      if (cheese == 'opt_c3') cheeseColor = const Color(0xFFE6C762); // Gouda
      _draw3DMeltedCheese(canvas, center, currentY, 72, cheeseColor);
      currentY -= 4;
    }

    // Optional Second Patty (Double Wagyu!)
    if (isDouble) {
      _draw3DPatty(canvas, center, currentY, 18, 68);
      currentY -= 18;
      // Second melted cheese layer
      if (cheese != 'opt_c4') {
        _draw3DMeltedCheese(canvas, center, currentY, 70, const Color(0xFFFFB800));
        currentY -= 4;
      }
    }

    // Optional Toppings
    if (hasBacon) {
      _draw3DCrispyBacon(canvas, center, currentY);
      currentY -= 6;
    }

    if (hasMushrooms) {
      _draw3DMushrooms(canvas, center, currentY);
      currentY -= 6;
    }

    if (hasEgg) {
      _draw3DFriedEgg(canvas, center, currentY);
      currentY -= 8;
    }

    // Lettuce Ruffles & Tomato Slices
    _draw3DLettuce(canvas, center, currentY);
    currentY -= 8;
    _draw3DTomato(canvas, center, currentY);
    currentY -= 8;

    // Top Brioche Bun (Dome) with Sesame Seeds
    _draw3DBunDome(canvas, center, currentY, 68, 28);
  }

  void _draw3DPatty(Canvas canvas, Offset center, double yBase, double height, double radius) {
    _draw3DCylinder(
      canvas: canvas,
      center: center,
      yBase: yBase,
      height: height,
      radius: radius,
      topColor: const Color(0xFF422518),
      sideColor: const Color(0xFF2E190E),
      drawGrillMarks: true,
    );
  }

  void _draw3DMeltedCheese(Canvas canvas, Offset center, double yBase, double radius, Color color) {
    final cheesePath = Path();
    const segments = 24;
    for (int i = 0; i <= segments; i++) {
      final angle = (i / segments) * 2 * math.pi;
      // Irregular drooping wavy edges
      final r = radius + 6 * math.sin(angle * 5 + yaw);
      final pt = _project(r * math.cos(angle), yBase + 4 * math.sin(angle * 3), r * math.sin(angle), center);
      if (i == 0) {
        cheesePath.moveTo(pt.dx, pt.dy);
      } else {
        cheesePath.lineTo(pt.dx, pt.dy);
      }
    }
    cheesePath.close();

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawPath(cheesePath, paint);
  }

  void _draw3DCrispyBacon(Canvas canvas, Offset center, double yBase) {
    final baconPaint = Paint()..color = const Color(0xFF78281F)..style = PaintingStyle.fill;
    final strip1 = Path()
      ..moveTo(_project(-50, yBase, -15, center).dx, _project(-50, yBase, -15, center).dy)
      ..lineTo(_project(50, yBase, 15, center).dx, _project(50, yBase, 15, center).dy)
      ..lineTo(_project(46, yBase + 2, 28, center).dx, _project(46, yBase + 2, 28, center).dy)
      ..lineTo(_project(-54, yBase + 2, -2, center).dx, _project(-54, yBase + 2, -2, center).dy)
      ..close();
    canvas.drawPath(strip1, baconPaint);
  }

  void _draw3DMushrooms(Canvas canvas, Offset center, double yBase) {
    final shroomPaint = Paint()..color = const Color(0xFF5D4037);
    for (int i = 0; i < 4; i++) {
      final ang = i * (math.pi / 2) + 0.3;
      final pt = _project(35 * math.cos(ang), yBase, 35 * math.sin(ang), center);
      canvas.drawCircle(pt, 9 * zoom, shroomPaint);
    }
  }

  void _draw3DFriedEgg(Canvas canvas, Offset center, double yBase) {
    final whitePaint = Paint()..color = const Color(0xFFFAFAFA);
    final yolkPaint = Paint()..color = const Color(0xFFFF9800);
    final eggPath = Path();
    for (int i = 0; i <= 16; i++) {
      final ang = (i / 16) * 2 * math.pi;
      final r = 50 + 5 * math.sin(ang * 4);
      final pt = _project(r * math.cos(ang), yBase, r * math.sin(ang), center);
      if (i == 0) {
        eggPath.moveTo(pt.dx, pt.dy);
      } else {
        eggPath.lineTo(pt.dx, pt.dy);
      }
    }
    canvas.drawPath(eggPath, whitePaint);
    canvas.drawCircle(_project(0, yBase - 3, 0, center), 14 * zoom, yolkPaint);
  }

  void _draw3DLettuce(Canvas canvas, Offset center, double yBase) {
    final lettucePath = Path();
    const segments = 24;
    for (int i = 0; i <= segments; i++) {
      final angle = (i / segments) * 2 * math.pi;
      final r = 74 + 7 * math.sin(angle * 8);
      final pt = _project(r * math.cos(angle), yBase, r * math.sin(angle), center);
      if (i == 0) {
        lettucePath.moveTo(pt.dx, pt.dy);
      } else {
        lettucePath.lineTo(pt.dx, pt.dy);
      }
    }
    lettucePath.close();

    final paint = Paint()..color = const Color(0xFF4CAF50);
    canvas.drawPath(lettucePath, paint);
  }

  void _draw3DTomato(Canvas canvas, Offset center, double yBase) {
    final tomatoPaint = Paint()..color = const Color(0xFFE53935);
    final pt1 = _project(-20, yBase, -10, center);
    final pt2 = _project(20, yBase, 10, center);
    canvas.drawCircle(pt1, 26 * zoom, tomatoPaint);
    canvas.drawCircle(pt2, 26 * zoom, tomatoPaint);
  }

  void _draw3DBunDome(Canvas canvas, Offset center, double yBase, double radius, double domeHeight) {
    final domePath = Path();
    const rings = 8;
    const slices = 24;

    for (int r = 0; r < rings; r++) {
      final v1 = r / rings;
      final v2 = (r + 1) / rings;
      final rad1 = radius * math.cos(v1 * (math.pi / 2));
      final rad2 = radius * math.cos(v2 * (math.pi / 2));
      final h1 = yBase - domeHeight * math.sin(v1 * (math.pi / 2));
      final h2 = yBase - domeHeight * math.sin(v2 * (math.pi / 2));

      final ringPath = Path();
      for (int s = 0; s <= slices; s++) {
        final ang = (s / slices) * 2 * math.pi;
        final pt = _project(rad1 * math.cos(ang), h1, rad1 * math.sin(ang), center);
        if (s == 0) {
          ringPath.moveTo(pt.dx, pt.dy);
        } else {
          ringPath.lineTo(pt.dx, pt.dy);
        }
      }
      ringPath.close();

      final brightness = 0.8 + 0.2 * (1.0 - v1);
      final ringColor = Color.lerp(const Color(0xFFB57C3D), const Color(0xFFE5A665), brightness)!;
      canvas.drawPath(ringPath, Paint()..color = ringColor);
    }

    // Sesame Seeds on bun top
    final seedPaint = Paint()..color = const Color(0xFFFFFDD0);
    final seedAngles = [0.2, 0.8, 1.4, 2.1, 2.8, 3.6, 4.3, 5.0, 5.8];
    for (var a in seedAngles) {
      final sPt = _project(32 * math.cos(a + yaw), yBase - 22, 32 * math.sin(a + yaw), center);
      canvas.drawOval(Rect.fromCenter(center: sPt, width: 4 * zoom, height: 2.5 * zoom), seedPaint);
    }
  }

  // ==========================================================================
  // DISH 2: ARTISAN TRUFFLE & WILD MUSHROOM PIZZA (3D Disc & Crust)
  // ==========================================================================
  void _draw3DArtisanPizza(Canvas canvas, Offset center) {
    final isLarge = selectedOptions['g_pizza_size'] == 'opt_pz2';
    final baseSauce = selectedOptions['g_pizza_base'] ?? 'opt_pb1';
    final radius = isLarge ? 115.0 : 92.0;

    // Wood Pizza Board
    _draw3DCylinder(
      canvas: canvas,
      center: center,
      yBase: 0,
      height: 8,
      radius: radius + 15,
      topColor: const Color(0xFF6E5034),
      sideColor: const Color(0xFF4A341F),
    );

    // Pizza Crust Rim
    _draw3DCylinder(
      canvas: canvas,
      center: center,
      yBase: -8,
      height: 14,
      radius: radius,
      topColor: const Color(0xFFD49A5B),
      sideColor: const Color(0xFFB57738),
    );

    // Pizza Sauce Base
    Color sauceColor = const Color(0xFFDDD7CC); // Truffle Cream
    if (baseSauce == 'opt_pb2') sauceColor = const Color(0xFFB03A2E); // Tomato
    if (baseSauce == 'opt_pb3') sauceColor = const Color(0xFF27AE60); // Pesto

    _draw3DCylinder(
      canvas: canvas,
      center: center,
      yBase: -16,
      height: 3,
      radius: radius - 14,
      topColor: sauceColor,
      sideColor: sauceColor.withOpacity(0.9),
    );

    // Mozzarella Cheese dollops & Wild Mushrooms
    final cheesePaint = Paint()..color = const Color(0xFFFFFFF0);
    final shroomPaint = Paint()..color = const Color(0xFF4A3728);
    final herbPaint = Paint()..color = const Color(0xFF2E7D32);

    for (int i = 0; i < 8; i++) {
      final ang = i * (math.pi / 4) + 0.2;
      final dist = (radius - 28) * (0.4 + 0.5 * (i % 2));
      final pt = _project(dist * math.cos(ang), -18, dist * math.sin(ang), center);
      canvas.drawCircle(pt, 12 * zoom, cheesePaint);
      canvas.drawOval(Rect.fromCenter(center: pt.translate(3, -2), width: 14 * zoom, height: 9 * zoom), shroomPaint);
      canvas.drawCircle(pt.translate(-5, 4), 2.5 * zoom, herbPaint);
    }
  }

  // ==========================================================================
  // DISH 3: WOOD-GRILLED WAGYU RIBEYE STEAK (3D Skillet & Charred Ribeye)
  // ==========================================================================
  void _draw3DSteak(Canvas canvas, Offset center) {
    final isFeast = selectedOptions['g_steak_cut'] == 'opt_st2';
    final finishButter = selectedOptions['g_steak_butter'] ?? 'opt_sb1';
    final side = selectedOptions['g_steak_side'] ?? 'opt_side1';

    // Cast Iron Skillet
    _draw3DCylinder(
      canvas: canvas,
      center: center,
      yBase: 0,
      height: 14,
      radius: 120,
      topColor: const Color(0xFF1E1E1E),
      sideColor: const Color(0xFF111111),
    );

    // Thick Ribeye Cut
    final steakWidth = isFeast ? 85.0 : 68.0;
    final steakPath = Path();
    final corners = [
      Offset(-steakWidth, -35),
      Offset(steakWidth * 0.8, -40),
      Offset(steakWidth, 25),
      Offset(-steakWidth * 0.7, 35),
    ];
    for (int i = 0; i < corners.length; i++) {
      final pt = _project(corners[i].dx, -16, corners[i].dy, center);
      if (i == 0) {
        steakPath.moveTo(pt.dx, pt.dy);
      } else {
        steakPath.lineTo(pt.dx, pt.dy);
      }
    }
    steakPath.close();

    // Seared dark steak surface
    canvas.drawPath(steakPath, Paint()..color = const Color(0xFF381F15));

    // Grill marks
    final grillPaint = Paint()..color = const Color(0xFF1A0C06)..strokeWidth = 3 * zoom;
    for (int i = -2; i <= 2; i++) {
      final p1 = _project(-50 + i * 22, -16, -30, center);
      final p2 = _project(-20 + i * 22, -16, 30, center);
      canvas.drawLine(p1, p2, grillPaint);
    }

    // Melting Butter on Steak Top
    Color butterColor = const Color(0xFFFFD54F); // Herb Garlic
    if (finishButter == 'opt_sb2') butterColor = const Color(0xFF8D6E63); // Truffle Butter
    final butterPt = _project(0, -22, 0, center);
    canvas.drawCircle(butterPt, 11 * zoom, Paint()..color = butterColor);
    // Charred Rosemary Sprig
    final sprigP1 = _project(-18, -24, 8, center);
    final sprigP2 = _project(24, -24, -8, center);
    canvas.drawLine(sprigP1, sprigP2, Paint()..color = const Color(0xFF2E7D32)..strokeWidth = 3 * zoom);

    // Side Dish: Truffle Fries or Asparagus
    if (side == 'opt_side1') {
      // Golden Truffle Fries stack
      final fryPaint = Paint()..color = const Color(0xFFF9A825)..strokeWidth = 4 * zoom;
      for (int i = 0; i < 6; i++) {
        final fp1 = _project(60, -18, -25 + i * 8, center);
        final fp2 = _project(95, -18, -20 + i * 8, center);
        canvas.drawLine(fp1, fp2, fryPaint);
      }
    } else {
      // Charred Asparagus spears
      final aspPaint = Paint()..color = const Color(0xFF33691E)..strokeWidth = 5 * zoom;
      for (int i = 0; i < 4; i++) {
        final ap1 = _project(65, -18, -20 + i * 12, center);
        final ap2 = _project(100, -18, -15 + i * 12, center);
        canvas.drawLine(ap1, ap2, aspPaint);
      }
    }
  }

  // ==========================================================================
  // DISH 4: SMOKY TONKOTSU RAMEN SUPREME (3D Ramen Bowl, Broth, Chashu, Egg)
  // ==========================================================================
  void _draw3DRamen(Canvas canvas, Offset center) {
    final broth = selectedOptions['g_ramen_broth'] ?? 'opt_rb1';

    // Ceramic Ramen Bowl Rim
    _draw3DCylinder(
      canvas: canvas,
      center: center,
      yBase: 0,
      height: 48,
      radius: 95,
      topColor: const Color(0xFF263238),
      sideColor: const Color(0xFF102027),
    );

    // Broth Style Color
    Color brothColor = const Color(0xFFE0C49B); // Tonkotsu
    if (broth == 'opt_rb2') brothColor = const Color(0xFFD84315); // Spicy Miso
    if (broth == 'opt_rb3') brothColor = const Color(0xFF3E2723); // Black Garlic Oil

    _draw3DCylinder(
      canvas: canvas,
      center: center,
      yBase: -36,
      height: 6,
      radius: 86,
      topColor: brothColor,
      sideColor: brothColor.withOpacity(0.85),
    );

    // Rolled Chashu Pork Belly Slices
    final chashuPt1 = _project(-32, -42, -15, center);
    final chashuPt2 = _project(-22, -42, 18, center);
    canvas.drawCircle(chashuPt1, 24 * zoom, Paint()..color = const Color(0xFF8D6E63));
    canvas.drawCircle(chashuPt1, 16 * zoom, Paint()..color = const Color(0xFFD7CCC8));
    canvas.drawCircle(chashuPt2, 22 * zoom, Paint()..color = const Color(0xFF8D6E63));

    // Ajitsuke Ramen Soft-Boiled Egg (Half)
    final eggPt = _project(26, -42, -10, center);
    canvas.drawOval(Rect.fromCenter(center: eggPt, width: 28 * zoom, height: 20 * zoom), Paint()..color = const Color(0xFFFFF9C4));
    canvas.drawCircle(eggPt.translate(-2, 0), 9 * zoom, Paint()..color = const Color(0xFFFF6F00)); // Runny golden yolk

    // Nori Seaweed Sheet
    final noriPt1 = _project(40, -42, 35, center);
    final noriPt2 = _project(55, -65, 45, center);
    canvas.drawLine(noriPt1, noriPt2, Paint()..color = const Color(0xFF1B2E1E)..strokeWidth = 18 * zoom);

    // Green Scallions
    for (int i = 0; i < 8; i++) {
      final scPt = _project(10 + i * 4, -42, 10 + (i % 3) * 6, center);
      canvas.drawCircle(scPt, 2.5 * zoom, Paint()..color = const Color(0xFF4CAF50));
    }
  }

  // ==========================================================================
  // DISH 5: EMBER DARK CHOCOLATE MOLTEN LAVA CAKE (Lava & Vanilla Ice Cream)
  // ==========================================================================
  void _draw3DLavaCake(Canvas canvas, Offset center) {
    final servingOption = selectedOptions['g_dessert_portion'] ?? 'opt_des1';
    final hasIceCream = servingOption == 'opt_des2';

    // Dark Slate Platter
    _draw3DCylinder(
      canvas: canvas,
      center: center,
      yBase: 0,
      height: 8,
      radius: 110,
      topColor: const Color(0xFF212121),
      sideColor: const Color(0xFF141414),
    );

    // Molten Lava Cake Body
    _draw3DCylinder(
      canvas: canvas,
      center: center,
      yBase: -8,
      height: 38,
      radius: 46,
      topColor: const Color(0xFF2C1B18),
      sideColor: const Color(0xFF1E110E),
    );

    // Glossy Molten Lava Center
    final lavaPt = _project(0, -46, 0, center);
    canvas.drawCircle(lavaPt, 18 * zoom, Paint()..color = const Color(0xFF140806));

    // Lava drip cascading down
    final dripP1 = _project(0, -46, 0, center);
    final dripP2 = _project(32, -12, 12, center);
    canvas.drawLine(dripP1, dripP2, Paint()..color = const Color(0xFF140806)..strokeWidth = 9 * zoom);

    // Gold Leaf Flake
    canvas.drawCircle(lavaPt.translate(-5, -4), 4 * zoom, Paint()..color = const Color(0xFFFFD700));

    // Optional Madagascar Vanilla Bean Ice Cream Scoop
    if (hasIceCream) {
      final creamPt = _project(-58, -14, -18, center);
      // Ice cream melting puddle
      canvas.drawOval(
        Rect.fromCenter(center: creamPt.translate(0, 8), width: 44 * zoom, height: 26 * zoom),
        Paint()..color = const Color(0xFFFFFDE7),
      );
      // Scoop
      canvas.drawCircle(creamPt, 18 * zoom, Paint()..color = const Color(0xFFFFF9E6));
      // Vanilla specks
      for (int i = 0; i < 6; i++) {
        canvas.drawCircle(creamPt.translate(-6 + i * 3, -4 + (i % 2) * 5), 1.2 * zoom, Paint()..color = const Color(0xFF3E2723));
      }
    }

    // Raspberry Coulis drizzle
    final coulisPaint = Paint()..color = const Color(0xFFC2185B)..strokeWidth = 3 * zoom;
    for (int i = 0; i < 5; i++) {
      final c1 = _project(-30 + i * 15, -8, 40, center);
      final c2 = _project(-20 + i * 15, -8, 55, center);
      canvas.drawLine(c1, c2, coulisPaint);
    }
  }

  // --- Utility: 3D Cylinder Generator ---
  void _draw3DCylinder({
    required Canvas canvas,
    required Offset center,
    required double yBase,
    required double height,
    required double radius,
    required Color topColor,
    required Color sideColor,
    bool drawGrillMarks = false,
  }) {
    const segments = 28;
    final bottomPts = <Offset>[];
    final topPts = <Offset>[];

    final yTop = yBase - height;

    for (int i = 0; i <= segments; i++) {
      final ang = (i / segments) * 2 * math.pi;
      final x = radius * math.cos(ang);
      final z = radius * math.sin(ang);
      bottomPts.add(_project(x, yBase, z, center));
      topPts.add(_project(x, yTop, z, center));
    }

    // Side surface
    final sidePath = Path();
    for (int i = 0; i < segments; i++) {
      sidePath.moveTo(topPts[i].dx, topPts[i].dy);
      sidePath.lineTo(topPts[i + 1].dx, topPts[i + 1].dy);
      sidePath.lineTo(bottomPts[i + 1].dx, bottomPts[i + 1].dy);
      sidePath.lineTo(bottomPts[i].dx, bottomPts[i].dy);
      sidePath.close();
    }
    canvas.drawPath(sidePath, Paint()..color = sideColor);

    // Top surface
    final topPath = Path();
    topPath.moveTo(topPts.first.dx, topPts.first.dy);
    for (int i = 1; i <= segments; i++) {
      topPath.lineTo(topPts[i].dx, topPts[i].dy);
    }
    topPath.close();
    canvas.drawPath(topPath, Paint()..color = topColor);

    if (drawGrillMarks) {
      final grillPaint = Paint()..color = Colors.black.withOpacity(0.5)..strokeWidth = 2.5 * zoom;
      for (int i = -2; i <= 2; i++) {
        final p1 = _project(-radius * 0.7 + i * 18, yTop, -radius * 0.5, center);
        final p2 = _project(-radius * 0.3 + i * 18, yTop, radius * 0.5, center);
        canvas.drawLine(p1, p2, grillPaint);
      }
    }
  }

  // --- Utility: Animated Gourmet Steam Particles ---
  void _drawSteamParticles(Canvas canvas, Offset center) {
    if (dishId == 'd5') return; // Desserts don't emit hot steam

    final steamPaint = Paint()
      ..color = Colors.white.withOpacity(0.18)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    for (int i = 0; i < 5; i++) {
      final t = (time + i * 0.2) % 1.0;
      final steamY = -50 - t * 90;
      final steamX = math.sin(t * 6 + i) * 22;
      final pt = _project(steamX, steamY, 0, center);
      final rad = (8 + t * 14) * zoom;
      canvas.drawCircle(pt, rad, steamPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _Dish3DPainter oldDelegate) {
    return oldDelegate.yaw != yaw ||
        oldDelegate.pitch != pitch ||
        oldDelegate.zoom != zoom ||
        oldDelegate.time != time ||
        oldDelegate.selectedOptions != selectedOptions ||
        oldDelegate.dishId != dishId;
  }
}
