import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// Jenis filter pengolahan citra digital
enum PCDFilterType {
  grayscale,
  blur,
  sharpen,
  edgeDetection,
  brightness,
  contrast,
  invert,
  threshold,
  sepia,
  emboss,
}

class PCDFilter {
  final int id;
  final String name;
  final String description;
  final PCDFilterType type;
  final IconData icon;
  final Color color;

  const PCDFilter({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.icon,
    required this.color,
  });

  /// Returns the ColorFilter matrix for real-time preview
  /// Returns null if the filter needs pixel-level processing
  ColorFilter? get colorFilter {
    switch (type) {
      case PCDFilterType.grayscale:
        return const ColorFilter.matrix(<double>[
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0, 0, 0, 1, 0,
        ]);
      case PCDFilterType.invert:
        return const ColorFilter.matrix(<double>[
          -1, 0, 0, 0, 255,
          0, -1, 0, 0, 255,
          0, 0, -1, 0, 255,
          0, 0, 0, 1, 0,
        ]);
      case PCDFilterType.sepia:
        return const ColorFilter.matrix(<double>[
          0.393, 0.769, 0.189, 0, 0,
          0.349, 0.686, 0.168, 0, 0,
          0.272, 0.534, 0.131, 0, 0,
          0, 0, 0, 1, 0,
        ]);
      case PCDFilterType.brightness:
        return const ColorFilter.matrix(<double>[
          1.3, 0, 0, 0, 30,
          0, 1.3, 0, 0, 30,
          0, 0, 1.3, 0, 30,
          0, 0, 0, 1, 0,
        ]);
      case PCDFilterType.contrast:
        return const ColorFilter.matrix(<double>[
          1.5, 0, 0, 0, -60,
          0, 1.5, 0, 0, -60,
          0, 0, 1.5, 0, -60,
          0, 0, 0, 1, 0,
        ]);
      default:
        return null; // Needs ImageFilter or pixel processing
    }
  }

  /// Returns an ImageFilter for blur
  ui.ImageFilter? get imageFilter {
    switch (type) {
      case PCDFilterType.blur:
        return ui.ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0);
      default:
        return null;
    }
  }

  static const List<PCDFilter> allFilters = [
    PCDFilter(
      id: 0,
      name: 'Grayscale',
      description: 'Mengubah gambar menjadi abu-abu',
      type: PCDFilterType.grayscale,
      icon: Icons.gradient,
      color: Color(0xFF9E9E9E),
    ),
    PCDFilter(
      id: 1,
      name: 'Gaussian Blur',
      description: 'Mengaburkan gambar dengan filter Gaussian',
      type: PCDFilterType.blur,
      icon: Icons.blur_on,
      color: Color(0xFF42A5F5),
    ),
    PCDFilter(
      id: 2,
      name: 'Sharpen',
      description: 'Mempertajam detail gambar',
      type: PCDFilterType.sharpen,
      icon: Icons.auto_fix_high,
      color: Color(0xFFFF7043),
    ),
    PCDFilter(
      id: 3,
      name: 'Edge Detection',
      description: 'Mendeteksi tepi objek dalam gambar',
      type: PCDFilterType.edgeDetection,
      icon: Icons.border_style,
      color: Color(0xFF66BB6A),
    ),
    PCDFilter(
      id: 4,
      name: 'Brightness',
      description: 'Meningkatkan kecerahan gambar',
      type: PCDFilterType.brightness,
      icon: Icons.brightness_6,
      color: Color(0xFFFFEE58),
    ),
    PCDFilter(
      id: 5,
      name: 'Contrast',
      description: 'Meningkatkan kontras gambar',
      type: PCDFilterType.contrast,
      icon: Icons.contrast,
      color: Color(0xFFAB47BC),
    ),
    PCDFilter(
      id: 6,
      name: 'Invert',
      description: 'Membalik warna gambar (negatif)',
      type: PCDFilterType.invert,
      icon: Icons.invert_colors,
      color: Color(0xFF26C6DA),
    ),
    PCDFilter(
      id: 7,
      name: 'Threshold',
      description: 'Mengubah gambar menjadi hitam putih murni',
      type: PCDFilterType.threshold,
      icon: Icons.tonality,
      color: Color(0xFF78909C),
    ),
    PCDFilter(
      id: 8,
      name: 'Sepia',
      description: 'Memberi efek klasik kecoklatan',
      type: PCDFilterType.sepia,
      icon: Icons.filter_vintage,
      color: Color(0xFFD4A574),
    ),
    PCDFilter(
      id: 9,
      name: 'Emboss',
      description: 'Memberi efek timbul pada gambar',
      type: PCDFilterType.emboss,
      icon: Icons.texture,
      color: Color(0xFF8D6E63),
    ),
  ];

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is PCDFilter && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
