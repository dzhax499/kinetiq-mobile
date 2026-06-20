import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../models/pcd_filter.dart';

/// Service for applying PCD (Pengolahan Citra Digital) filters
/// Uses ColorFilter matrices and ImageFilter for real-time rendering
class ImageFilterService {
  /// Get the ImageFilter (blur) from filter list
  static ui.ImageFilter? getBlurFilter(List<PCDFilter> filters) {
    for (final f in filters) {
      if (f.type == PCDFilterType.blur) {
        return f.imageFilter;
      }
    }
    return null;
  }

  /// Build a Paint with all applicable filters
  static Paint buildFilterPaint(List<PCDFilter> appliedFilters) {
    final paint = Paint();

    // Apply color filters in order
    final matrices = <List<double>>[];
    for (final filter in appliedFilters) {
      final matrix = _getMatrix(filter.type);
      if (matrix != null) {
        matrices.add(matrix);
      }
      if (filter.type == PCDFilterType.blur) {
        paint.imageFilter =
            ui.ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0);
      }
    }

    if (matrices.isNotEmpty) {
      var result = List<double>.from(matrices.first);
      for (int i = 1; i < matrices.length; i++) {
        result = _multiplyMatrix(result, matrices[i]);
      }
      paint.colorFilter = ColorFilter.matrix(result);
    }

    return paint;
  }

  /// Get the raw color matrix for a filter type
  static List<double>? _getMatrix(PCDFilterType type) {
    switch (type) {
      case PCDFilterType.grayscale:
        return [
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0, 0, 0, 1, 0,
        ];
      case PCDFilterType.invert:
        return [
          -1, 0, 0, 0, 255,
          0, -1, 0, 0, 255,
          0, 0, -1, 0, 255,
          0, 0, 0, 1, 0,
        ];
      case PCDFilterType.sepia:
        return [
          0.393, 0.769, 0.189, 0, 0,
          0.349, 0.686, 0.168, 0, 0,
          0.272, 0.534, 0.131, 0, 0,
          0, 0, 0, 1, 0,
        ];
      case PCDFilterType.brightness:
        return [
          1.3, 0, 0, 0, 30,
          0, 1.3, 0, 0, 30,
          0, 0, 1.3, 0, 30,
          0, 0, 0, 1, 0,
        ];
      case PCDFilterType.contrast:
        return [
          1.5, 0, 0, 0, -60,
          0, 1.5, 0, 0, -60,
          0, 0, 1.5, 0, -60,
          0, 0, 0, 1, 0,
        ];
      case PCDFilterType.sharpen:
        return [
          1.4, -0.1, -0.1, 0, 10,
          -0.1, 1.4, -0.1, 0, 10,
          -0.1, -0.1, 1.4, 0, 10,
          0, 0, 0, 1, 0,
        ];
      case PCDFilterType.edgeDetection:
        return [
          2.0, -0.5, -0.5, 0, -128,
          -0.5, 2.0, -0.5, 0, -128,
          -0.5, -0.5, 2.0, 0, -128,
          0, 0, 0, 1, 0,
        ];
      case PCDFilterType.threshold:
        return [
          4.0, 0, 0, 0, -500,
          0, 4.0, 0, 0, -500,
          0, 0, 4.0, 0, -500,
          0, 0, 0, 1, 0,
        ];
      case PCDFilterType.emboss:
        return [
          0.8, 0.2, 0, 0, 50,
          0, 0.8, 0.2, 0, 50,
          0.2, 0, 0.8, 0, 50,
          0, 0, 0, 1, 0,
        ];
      default:
        return null;
    }
  }

  /// Multiply two 4x5 color matrices
  static List<double> _multiplyMatrix(List<double> a, List<double> b) {
    final result = List<double>.filled(20, 0);

    for (int i = 0; i < 4; i++) {
      for (int j = 0; j < 5; j++) {
        double sum = 0;
        for (int k = 0; k < 4; k++) {
          sum += a[i * 5 + k] * b[k * 5 + j];
        }
        if (j == 4) {
          sum += a[i * 5 + 4];
        }
        result[i * 5 + j] = sum;
      }
    }

    return result;
  }

  /// Generate the "corrupted" image description based on applied filters
  static String getFilterDescription(List<PCDFilter> filters) {
    if (filters.isEmpty) return 'Gambar asli (tanpa filter)';
    return filters.map((f) => f.name).join(' → ');
  }
}
