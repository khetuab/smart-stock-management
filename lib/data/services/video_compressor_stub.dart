/// Default/fallback implementation — used whenever neither `dart:io` nor a
/// platform-specific compressor is available (i.e. web). There's no native
/// video transcoder to call into here, so this just hands the source path
/// straight back; the caller (CloudinaryService) is responsible for
/// rejecting an oversized file on this platform instead of silently
/// uploading something huge.
Future<String> compressVideoIfNeeded(
    String sourcePath, {
      required int maxSizeMb,
      void Function(double progress)? onProgress,
    }) async {
  return sourcePath;
}