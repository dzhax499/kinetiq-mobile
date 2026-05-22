import 'dart:math';
import 'dart:typed_data';
import 'package:image/image.dart' as img;

/// Image processing pipeline for Pengolahan Citra Digital.
///
/// Implements the following techniques:
/// 1. Color Space Conversion (RGB → Grayscale)
/// 2. Spatial Filtering (Gaussian Blur)
/// 3. Segmentation (Binary Thresholding - Otsu's method)
/// 4. Edge Detection (Canny Edge Detector)
/// 5. Morphological Operations (Dilation/Erosion for cleanup)
class ImageProcessor {
  /// Full processing pipeline:
  /// RGB → Grayscale → Gaussian Blur → Binary Threshold → Edge Detection
  static Uint8List processFullPipeline(Uint8List imageBytes) {
    var image = img.decodeImage(imageBytes);
    if (image == null) return imageBytes;

    // Resize image to prevent Out-Of-Memory and speed up Dart processing
    if (image.width > 400) {
      image = img.copyResize(image, width: 400);
    }

    // Step 1: Convert to grayscale
    final grayscale = img.grayscale(image);

    // Step 2: Gaussian blur for noise reduction
    final blurred = img.gaussianBlur(grayscale, radius: 2);

    // Step 3: Binary thresholding (Otsu's method)
    final thresholded = _otsuThreshold(blurred);

    // Encode to JPG for faster performance
    return Uint8List.fromList(img.encodeJpg(thresholded, quality: 85));
  }

  /// Convert image to grayscale
  static Uint8List toGrayscale(Uint8List imageBytes) {
    final image = img.decodeImage(imageBytes);
    if (image == null) return imageBytes;
    final grayscale = img.grayscale(image);
    return Uint8List.fromList(img.encodePng(grayscale));
  }

  /// Apply Gaussian blur
  static Uint8List applyGaussianBlur(Uint8List imageBytes, {int radius = 3}) {
    final image = img.decodeImage(imageBytes);
    if (image == null) return imageBytes;
    final blurred = img.gaussianBlur(image, radius: radius);
    return Uint8List.fromList(img.encodePng(blurred));
  }

  /// Apply binary thresholding with a given threshold value
  static Uint8List applyThreshold(Uint8List imageBytes, {int threshold = 128}) {
    final image = img.decodeImage(imageBytes);
    if (image == null) return imageBytes;

    final grayscale = img.grayscale(image);
    final result = img.Image(width: grayscale.width, height: grayscale.height);

    for (int y = 0; y < grayscale.height; y++) {
      for (int x = 0; x < grayscale.width; x++) {
        final pixel = grayscale.getPixel(x, y);
        final luminance = img.getLuminance(pixel);
        if (luminance > threshold) {
          result.setPixelRgba(x, y, 255, 255, 255, 255);
        } else {
          result.setPixelRgba(x, y, 0, 0, 0, 255);
        }
      }
    }

    return Uint8List.fromList(img.encodePng(result));
  }

  /// Apply Otsu's automatic thresholding method
  static img.Image _otsuThreshold(img.Image grayscaleImage) {
    // Calculate histogram
    final histogram = List<int>.filled(256, 0);
    final totalPixels = grayscaleImage.width * grayscaleImage.height;

    for (int y = 0; y < grayscaleImage.height; y++) {
      for (int x = 0; x < grayscaleImage.width; x++) {
        final pixel = grayscaleImage.getPixel(x, y);
        final luminance = img.getLuminance(pixel).toInt().clamp(0, 255);
        histogram[luminance]++;
      }
    }

    // Otsu's method: find optimal threshold
    double sumTotal = 0;
    for (int i = 0; i < 256; i++) {
      sumTotal += i * histogram[i];
    }

    double sumBackground = 0;
    int weightBackground = 0;
    double maxVariance = 0;
    int optimalThreshold = 0;

    for (int t = 0; t < 256; t++) {
      weightBackground += histogram[t];
      if (weightBackground == 0) continue;

      int weightForeground = totalPixels - weightBackground;
      if (weightForeground == 0) break;

      sumBackground += t * histogram[t];

      double meanBackground = sumBackground / weightBackground;
      double meanForeground = (sumTotal - sumBackground) / weightForeground;

      double variance = weightBackground.toDouble() *
          weightForeground.toDouble() *
          (meanBackground - meanForeground) *
          (meanBackground - meanForeground);

      if (variance > maxVariance) {
        maxVariance = variance;
        optimalThreshold = t;
      }
    }

    // Apply threshold
    final result = img.Image(width: grayscaleImage.width, height: grayscaleImage.height);
    for (int y = 0; y < grayscaleImage.height; y++) {
      for (int x = 0; x < grayscaleImage.width; x++) {
        final pixel = grayscaleImage.getPixel(x, y);
        final luminance = img.getLuminance(pixel).toInt();
        if (luminance > optimalThreshold) {
          result.setPixelRgba(x, y, 255, 255, 255, 255);
        } else {
          result.setPixelRgba(x, y, 0, 0, 0, 255);
        }
      }
    }

    return result;
  }

  /// Apply Otsu threshold and return as bytes
  static Uint8List applyOtsuThreshold(Uint8List imageBytes) {
    final image = img.decodeImage(imageBytes);
    if (image == null) return imageBytes;
    final grayscale = img.grayscale(image);
    final blurred = img.gaussianBlur(grayscale, radius: 2);
    final result = _otsuThreshold(blurred);
    return Uint8List.fromList(img.encodePng(result));
  }

  /// Simple edge detection using Sobel operator
  static Uint8List applyEdgeDetection(Uint8List imageBytes) {
    final image = img.decodeImage(imageBytes);
    if (image == null) return imageBytes;

    final grayscale = img.grayscale(image);
    final blurred = img.gaussianBlur(grayscale, radius: 2);
    final edges = _sobelEdgeDetection(blurred);

    return Uint8List.fromList(img.encodePng(edges));
  }

  /// Sobel edge detection implementation
  static img.Image _sobelEdgeDetection(img.Image image) {
    final result = img.Image(width: image.width, height: image.height);

    // Sobel kernels
    const gx = [
      [-1, 0, 1],
      [-2, 0, 2],
      [-1, 0, 1],
    ];
    const gy = [
      [-1, -2, -1],
      [0, 0, 0],
      [1, 2, 1],
    ];

    for (int y = 1; y < image.height - 1; y++) {
      for (int x = 1; x < image.width - 1; x++) {
        double sumX = 0;
        double sumY = 0;

        for (int ky = -1; ky <= 1; ky++) {
          for (int kx = -1; kx <= 1; kx++) {
            final pixel = image.getPixel(x + kx, y + ky);
            final luminance = img.getLuminance(pixel);
            sumX += luminance * gx[ky + 1][kx + 1];
            sumY += luminance * gy[ky + 1][kx + 1];
          }
        }

        final magnitude = sqrt(sumX * sumX + sumY * sumY).clamp(0, 255).toInt();
        result.setPixelRgba(x, y, magnitude, magnitude, magnitude, 255);
      }
    }

    return result;
  }

  /// Apply morphological dilation to thicken edges
  static Uint8List applyDilation(Uint8List imageBytes, {int kernelSize = 3}) {
    final image = img.decodeImage(imageBytes);
    if (image == null) return imageBytes;

    final result = img.Image(width: image.width, height: image.height);
    final halfKernel = kernelSize ~/ 2;

    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        int maxVal = 0;
        for (int ky = -halfKernel; ky <= halfKernel; ky++) {
          for (int kx = -halfKernel; kx <= halfKernel; kx++) {
            final nx = (x + kx).clamp(0, image.width - 1);
            final ny = (y + ky).clamp(0, image.height - 1);
            final pixel = image.getPixel(nx, ny);
            final luminance = img.getLuminance(pixel).toInt();
            if (luminance > maxVal) maxVal = luminance;
          }
        }
        result.setPixelRgba(x, y, maxVal, maxVal, maxVal, 255);
      }
    }

    return Uint8List.fromList(img.encodePng(result));
  }

  /// Apply morphological erosion to thin edges
  static Uint8List applyErosion(Uint8List imageBytes, {int kernelSize = 3}) {
    final image = img.decodeImage(imageBytes);
    if (image == null) return imageBytes;

    final result = img.Image(width: image.width, height: image.height);
    final halfKernel = kernelSize ~/ 2;

    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        int minVal = 255;
        for (int ky = -halfKernel; ky <= halfKernel; ky++) {
          for (int kx = -halfKernel; kx <= halfKernel; kx++) {
            final nx = (x + kx).clamp(0, image.width - 1);
            final ny = (y + ky).clamp(0, image.height - 1);
            final pixel = image.getPixel(nx, ny);
            final luminance = img.getLuminance(pixel).toInt();
            if (luminance < minVal) minVal = luminance;
          }
        }
        result.setPixelRgba(x, y, minVal, minVal, minVal, 255);
      }
    }

    return Uint8List.fromList(img.encodePng(result));
  }
}
