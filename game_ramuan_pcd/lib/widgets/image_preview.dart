import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../models/pcd_filter.dart';
import '../services/image_filter_service.dart';
import '../utils/constants.dart';

/// Widget that displays a procedurally generated image with PCD filters applied
class ImagePreview extends StatefulWidget {
  final List<PCDFilter> appliedFilters;
  final int seed;
  final double width;
  final double height;
  final bool showFilterLabel;

  const ImagePreview({
    super.key,
    required this.appliedFilters,
    this.seed = 42,
    this.width = 300,
    this.height = 200,
    this.showFilterLabel = true,
  });

  @override
  State<ImagePreview> createState() => _ImagePreviewState();
}

class _ImagePreviewState extends State<ImagePreview>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSizes.borderRadiusLg),
            border: Border.all(color: AppColors.cardBorder, width: 2),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.2),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppSizes.borderRadiusLg - 2),
            child: Stack(
              children: [
                // Base procedural image with filters applied
                CustomPaint(
                  size: Size(widget.width, widget.height),
                  painter: _ProceduralImagePainter(
                    seed: widget.seed,
                    appliedFilters: widget.appliedFilters,
                  ),
                ),
                // Shimmer overlay
                Positioned.fill(
                  child: IgnorePointer(
                    child: AnimatedOpacity(
                      opacity: widget.appliedFilters.isEmpty ? 0.0 : 0.15,
                      duration: const Duration(milliseconds: 500),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment(
                              -1 + _shimmerController.value * 3,
                              -0.3,
                            ),
                            end: Alignment(
                              -1 + _shimmerController.value * 3 + 1,
                              0.3,
                            ),
                            colors: [
                              Colors.transparent,
                              Colors.white.withValues(alpha: 0.15),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                // Filter label
                if (widget.showFilterLabel && widget.appliedFilters.isNotEmpty)
                  Positioned(
                    bottom: 8,
                    left: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        ImageFilterService.getFilterDescription(
                            widget.appliedFilters),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// AnimatedWidget helper
class AnimatedBuilder extends AnimatedWidget {
  final Widget Function(BuildContext, Widget?) builder;
  final Widget? child;

  const AnimatedBuilder({
    super.key,
    required Animation<double> animation,
    required this.builder,
    this.child,
  }) : super(listenable: animation);

  @override
  Widget build(BuildContext context) => builder(context, child);
}

/// Procedural image painter that generates a deterministic scene
class _ProceduralImagePainter extends CustomPainter {
  final int seed;
  final List<PCDFilter> appliedFilters;

  _ProceduralImagePainter({
    required this.seed,
    required this.appliedFilters,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final random = Random(seed);

    // Get filter paint
    final filterPaint = appliedFilters.isNotEmpty
        ? ImageFilterService.buildFilterPaint(appliedFilters)
        : Paint();

    // Save and apply filter layer
    canvas.saveLayer(Rect.fromLTWH(0, 0, size.width, size.height), filterPaint);

    // --- Draw procedural scene ---

    // Background gradient (sky)
    final bgPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(0, 0),
        Offset(0, size.height),
        [
          Color.fromRGBO(60 + random.nextInt(50), 100 + random.nextInt(80),
              180 + random.nextInt(75), 1.0),
          Color.fromRGBO(180 + random.nextInt(75), 120 + random.nextInt(80),
              60 + random.nextInt(50), 1.0),
        ],
      );
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // Sun / Moon
    final sunPaint = Paint()
      ..color = Color.fromRGBO(
        255,
        200 + random.nextInt(55),
        50 + random.nextInt(100),
        0.9,
      );
    final sunX = size.width * (0.2 + random.nextDouble() * 0.6);
    final sunY = size.height * (0.1 + random.nextDouble() * 0.25);
    canvas.drawCircle(Offset(sunX, sunY), 25 + random.nextDouble() * 15, sunPaint);

    // Sun rays
    final rayPaint = Paint()
      ..color = sunPaint.color.withValues(alpha: 0.3)
      ..strokeWidth = 2;
    for (int i = 0; i < 8; i++) {
      final angle = i * pi / 4;
      canvas.drawLine(
        Offset(sunX + cos(angle) * 30, sunY + sin(angle) * 30),
        Offset(sunX + cos(angle) * 50, sunY + sin(angle) * 50),
        rayPaint,
      );
    }

    // Mountains
    final mountainPaint = Paint();
    for (int i = 0; i < 3; i++) {
      final shade = 40 + i * 25 + random.nextInt(20);
      mountainPaint.color =
          Color.fromRGBO(shade, shade + 15, shade + 5, 1.0);
      final path = Path();
      final baseY = size.height * (0.45 + i * 0.1);
      path.moveTo(0, baseY + random.nextDouble() * 20);
      for (double x = 0; x <= size.width; x += size.width / 6) {
        path.lineTo(
          x,
          baseY - random.nextDouble() * (60 - i * 15) + random.nextDouble() * 20,
        );
      }
      path.lineTo(size.width, size.height);
      path.lineTo(0, size.height);
      path.close();
      canvas.drawPath(path, mountainPaint);
    }

    // Ground
    final groundPaint = Paint()
      ..color = Color.fromRGBO(
        30 + random.nextInt(30),
        80 + random.nextInt(60),
        30 + random.nextInt(30),
        1.0,
      );
    canvas.drawRect(
      Rect.fromLTWH(
          0, size.height * 0.72, size.width, size.height * 0.28),
      groundPaint,
    );

    // Trees
    for (int i = 0; i < 5 + random.nextInt(4); i++) {
      final treeX = random.nextDouble() * size.width;
      final treeY = size.height * (0.55 + random.nextDouble() * 0.25);
      final trunkHeight = 30.0 + random.nextDouble() * 30;
      final crownRadius = 15.0 + random.nextDouble() * 20;

      // Trunk
      final trunkPaint = Paint()
        ..color = Color.fromRGBO(
          80 + random.nextInt(40),
          50 + random.nextInt(30),
          20 + random.nextInt(20),
          1.0,
        );
      canvas.drawRect(
        Rect.fromLTWH(treeX - 4, treeY - trunkHeight, 8, trunkHeight),
        trunkPaint,
      );

      // Crown
      final crownPaint = Paint()
        ..color = Color.fromRGBO(
          20 + random.nextInt(40),
          100 + random.nextInt(100),
          20 + random.nextInt(40),
          0.9,
        );
      canvas.drawCircle(
        Offset(treeX, treeY - trunkHeight - crownRadius * 0.5),
        crownRadius,
        crownPaint,
      );
    }

    // Stars/clouds
    for (int i = 0; i < 8 + random.nextInt(5); i++) {
      final starPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.5 + random.nextDouble() * 0.5);
      canvas.drawCircle(
        Offset(
          random.nextDouble() * size.width,
          random.nextDouble() * size.height * 0.35,
        ),
        1.5 + random.nextDouble() * 2,
        starPaint,
      );
    }

    // Flowers on ground
    final flowerColors = [
      Colors.red, Colors.yellow, Colors.pink, Colors.orange, Colors.purple
    ];
    for (int i = 0; i < 6 + random.nextInt(5); i++) {
      final fx = random.nextDouble() * size.width;
      final fy = size.height * 0.75 + random.nextDouble() * (size.height * 0.2);
      final flowerPaint = Paint()
        ..color = flowerColors[random.nextInt(flowerColors.length)];
      canvas.drawCircle(Offset(fx, fy), 4 + random.nextDouble() * 3, flowerPaint);
      // Center
      canvas.drawCircle(
        Offset(fx, fy),
        2,
        Paint()..color = Colors.yellow,
      );
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _ProceduralImagePainter old) {
    return old.seed != seed || old.appliedFilters != appliedFilters;
  }
}
