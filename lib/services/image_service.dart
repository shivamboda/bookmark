import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

/// Image processing and picking service for book covers.
///
/// Features:
/// - Picks photos using web-compatible ImagePicker (supports mobile gallery and desktop/web file picker)
/// - Downscales to maximum 600px on the longest dimension (preserving aspect ratio)
/// - Compresses to JPEG at 80% quality (typically 30KB - 70KB file size)
/// - Prevents browser IndexedDB storage from exhausting limits
/// - Graceful error handling for corrupt or oversized files
class ImageService {
  ImageService._();

  static final ImagePicker _picker = ImagePicker();

  /// Maximum dimension on the long side (width or height)
  static const int maxDimension = 600;

  /// Target JPEG compression quality
  static const int jpegQuality = 80;

  /// Picks an image from the device photo library, resizes, and compresses it.
  ///
  /// Returns compressed JPEG bytes, or null if cancelled or failed.
  static Future<Uint8List?> pickAndProcessCoverImage() async {
    try {
      final XFile? file = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200, // Pre-constraint hint to system picker
        maxHeight: 1200,
      );

      if (file == null) return null;

      final rawBytes = await file.readAsBytes();
      return processCoverBytes(rawBytes);
    } catch (e) {
      debugPrint('ImageService: Error picking image: $e');
      rethrow;
    }
  }

  /// Downscales raw image bytes to max 600px on the longest side
  /// and compresses to JPEG at 80% quality.
  ///
  /// Works across all platforms including Flutter Web and tests.
  static Uint8List? processCoverBytes(Uint8List rawBytes) {
    try {
      final decoded = img.decodeImage(rawBytes);
      if (decoded == null) {
        debugPrint('ImageService: Unable to decode image bytes.');
        return null;
      }

      img.Image processed = decoded;

      // Downscale if width or height exceeds 600px
      if (decoded.width > maxDimension || decoded.height > maxDimension) {
        if (decoded.width >= decoded.height) {
          processed = img.copyResize(
            decoded,
            width: maxDimension,
            interpolation: img.Interpolation.average,
          );
        } else {
          processed = img.copyResize(
            decoded,
            height: maxDimension,
            interpolation: img.Interpolation.average,
          );
        }
      }

      // Encode as JPEG at 80% quality
      final jpgBytes = img.encodeJpg(processed, quality: jpegQuality);
      return Uint8List.fromList(jpgBytes);
    } catch (e) {
      debugPrint('ImageService: Error processing image bytes: $e');
      return null;
    }
  }
}
