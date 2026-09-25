import 'app_config.dart';

class CloudinaryConfig {
  static const String cloudName = AppConfig.cloudinaryCloudName;
  static const String apiKey = AppConfig.cloudinaryApiKey;
  static const String apiSecret = AppConfig.cloudinaryApiSecret;
  static const String uploadPreset = AppConfig.cloudinaryUploadPreset;
  static const String baseUrl = 'https://api.cloudinary.com/v1_1/$cloudName';
  static const String uploadUrl = '$baseUrl/image/upload';
  // Cloudinary requires resource type as part of the upload URL path itself
  // (not just a form field) — image and video are genuinely different
  // endpoints.
  static const String videoUploadUrl = '$baseUrl/video/upload';

  // Image quality and transformations
  static const int imageQuality = 80;
  static const int maxWidth = 800;
  static const int maxHeight = 800;
  static const String imageFormat = 'webp';
}