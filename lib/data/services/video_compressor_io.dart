import 'dart:io';
import 'package:light_compressor_v2/light_compressor_v2.dart';

/// Compresses [sourcePath] toward [maxSizeMb] if it's currently larger than
/// that, using each platform's native hardware encoder (MediaCodec on
/// Android, AVFoundation on iOS) — no bundled FFmpeg binary.
///
/// Falls back to returning the original, uncompressed path if compression
/// fails or is cancelled, rather than blocking the post entirely — an
/// oversized-but-successful upload is better than no upload at all, and the
/// caller can still surface the size to the user beforehand.
Future<String> compressVideoIfNeeded(
    String sourcePath, {
      required int maxSizeMb,
      void Function(double progress)? onProgress,
    }) async {
  final sourceFile = File(sourcePath);
  final sizeMb = (await sourceFile.length()) / (1024 * 1024);
  if (sizeMb <= maxSizeMb) return sourcePath;

  final subscription = LightCompressor().onProgressUpdated.listen((p) {
    onProgress?.call((p as num).toDouble() / 100);
  });

  try {
    final result = await LightCompressor().compressVideo(
      path: sourcePath,
      videoQuality: VideoQuality.medium,
      video: Video(
        videoName: 'compressed.mp4',
        targetSizeMb: maxSizeMb,
        twoPass: true, // re-encodes once more only if the first pass overshot
      ),
      // No isSharedStorage/saveAt set → the plugin writes to app-private
      // storage (roughly where destinationPath used to point) instead of
      // the shared Movies/Gallery.
      android: AndroidConfig(),
      ios: IOSConfig(),
    );

    if (result is OnSuccess) {
      return result.destinationPath;
    }
    // OnFailure or OnCancelled — fall back to the original file.
    return sourcePath;
  } finally {
    await subscription.cancel();
  }
}