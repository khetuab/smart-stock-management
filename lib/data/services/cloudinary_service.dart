import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import '../../config/cloudinary_config.dart';
import 'video_compressor.dart';

class CloudinaryService {
  static final CloudinaryService _instance = CloudinaryService._internal();
  factory CloudinaryService() => _instance;

  CloudinaryService._internal() {
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 30);
  }

  final Dio _dio = Dio();

  /// Core Upload Method using XFile (Cross-platform for Web, Android, iOS, Desktop)
  Future<String?> uploadXFile({
    required XFile xFile,
    String? folder = 'store_logos',
    bool isPublic = true,
  }) async {
    try {
      print('Uploading image to Cloudinary...');

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final bytes = await xFile.readAsBytes();
      print('File size: ${bytes.length} bytes');

      // Create MultipartFile from bytes — works everywhere (Web & Mobile)
      final multipartFile = MultipartFile.fromBytes(
        bytes,
        filename: '${timestamp}.jpg',
        contentType: DioMediaType.parse('image/jpeg'),
      );

      // Prepare form data
      final formData = FormData.fromMap({
        'file': multipartFile,
        'upload_preset': CloudinaryConfig.uploadPreset,
        'folder': folder ?? 'store_logos',
        'public_id': timestamp.toString(),
        'resource_type': 'image',
      });

      print('Uploading to: ${CloudinaryConfig.uploadUrl}');
      print('Folder: ${folder ?? 'store_logos'}');

      // Upload to Cloudinary
      final response = await _dio.post(
        CloudinaryConfig.uploadUrl,
        data: formData,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
          },
          validateStatus: (status) {
            return status != null && status < 500;
          },
        ),
      );

      print('Cloudinary response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = response.data is String
            ? jsonDecode(response.data)
            : response.data as Map<String, dynamic>;

        final secureUrl = data['secure_url'] as String?;
        print('Upload successful: $secureUrl');
        return secureUrl;
      } else {
        final errorData = response.data is String
            ? jsonDecode(response.data)
            : response.data as Map<String, dynamic>?;

        final errorMessage = errorData?['error']?['message'] ?? 'Unknown error';
        print('Cloudinary upload failed: $errorMessage');
        throw Exception('Cloudinary upload failed: $errorMessage');
      }
    } on DioException catch (e) {
      print('Dio error uploading to Cloudinary: ${e.message}');
      print('Response data: ${e.response?.data}');
      print('Response status: ${e.response?.statusCode}');
      return null;
    } catch (e) {
      print('Error uploading image to Cloudinary: $e');
      return null;
    }
  }

  // Upload image from camera
  Future<String?> uploadFromCamera({
    String? folder = 'store_logos',
    bool isPublic = true,
  }) async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: CloudinaryConfig.maxWidth.toDouble(),
        maxHeight: CloudinaryConfig.maxHeight.toDouble(),
        imageQuality: CloudinaryConfig.imageQuality,
      );

      if (image == null) return null;

      return await uploadXFile(
        xFile: image,
        folder: folder,
        isPublic: isPublic,
      );
    } catch (e) {
      print('Error capturing image: $e');
      return null;
    }
  }

  // Upload image from gallery
  Future<String?> uploadFromGallery({
    String? folder = 'store_logos',
    bool isPublic = true,
  }) async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: CloudinaryConfig.maxWidth.toDouble(),
        maxHeight: CloudinaryConfig.maxHeight.toDouble(),
        imageQuality: CloudinaryConfig.imageQuality,
      );

      if (image == null) return null;

      return await uploadXFile(
        xFile: image,
        folder: folder,
        isPublic: isPublic,
      );
    } catch (e) {
      print('Error picking image from gallery: $e');
      return null;
    }
  }

  /// Picks a video from the gallery, compresses it toward [maxSizeMb] if
  /// it's larger than that (mobile/desktop only — see video_compressor.dart),
  /// then uploads it to Cloudinary's *video* endpoint. Returns null if the
  /// user cancelled the picker. Throws if the file is too large on web
  /// (where there's no native compressor to shrink it) or if the upload
  /// itself fails, so the caller can show a clear message either way.
  Future<String?> uploadVideoFromGallery({
    String? folder = 'media_posts',
    int maxSizeMb = 10,
    void Function(double progress)? onCompressionProgress,
  }) async {
    final picker = ImagePicker();
    final video = await picker.pickVideo(source: ImageSource.gallery);
    if (video == null) return null;

    return uploadVideoXFile(
      xFile: video,
      folder: folder,
      maxSizeMb: maxSizeMb,
      onCompressionProgress: onCompressionProgress,
    );
  }

  Future<String?> uploadVideoXFile({
    required XFile xFile,
    String? folder = 'media_posts',
    int maxSizeMb = 10,
    void Function(double progress)? onCompressionProgress,
  }) async {
    final sizeMb = (await xFile.length()) / (1024 * 1024);
    String uploadPath = xFile.path;

    if (sizeMb > maxSizeMb) {
      if (kIsWeb) {
        // light_compressor_v2 doesn't support web (no native encoder to
        // call into from the browser) — there's nothing to shrink it with,
        // so surface a clear message instead of silently uploading a huge
        // file or failing with a cryptic Cloudinary error.
        throw Exception(
          'This video is ${sizeMb.toStringAsFixed(1)}MB. Please choose a '
              'video under ${maxSizeMb}MB — automatic compression isn\'t '
              'available in the web app.',
        );
      }
      print('Video is ${sizeMb.toStringAsFixed(1)}MB — compressing toward ${maxSizeMb}MB before upload...');
      uploadPath = await compressVideoIfNeeded(
        xFile.path,
        maxSizeMb: maxSizeMb,
        onProgress: onCompressionProgress,
      );
    }

    try {
      final uploadFile = uploadPath == xFile.path ? xFile : XFile(uploadPath);
      final bytes = await uploadFile.readAsBytes();
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      final multipartFile = MultipartFile.fromBytes(
        bytes,
        filename: '$timestamp.mp4',
        contentType: DioMediaType.parse('video/mp4'),
      );

      final formData = FormData.fromMap({
        'file': multipartFile,
        'upload_preset': CloudinaryConfig.uploadPreset,
        'folder': folder ?? 'media_posts',
        'public_id': timestamp.toString(),
        'resource_type': 'video',
      });

      print('Uploading video to: ${CloudinaryConfig.videoUploadUrl}');

      final response = await _dio.post(
        CloudinaryConfig.videoUploadUrl,
        data: formData,
        options: Options(
          headers: {'Content-Type': 'multipart/form-data'},
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data is String
            ? jsonDecode(response.data)
            : response.data as Map<String, dynamic>;
        final secureUrl = data['secure_url'] as String?;
        print('Video upload successful: $secureUrl');
        return secureUrl;
      } else {
        final errorData = response.data is String
            ? jsonDecode(response.data)
            : response.data as Map<String, dynamic>?;
        final message = errorData?['error']?['message'] ?? 'Unknown error';
        throw Exception('Cloudinary video upload failed: $message');
      }
    } on DioException catch (e) {
      print('Dio error uploading video: ${e.message}');
      throw Exception('Network error while uploading video: ${e.message}');
    }
  }

  /// Cloudinary auto-generates a JPEG frame for any uploaded video at the
  /// same public path with a `.jpg` extension — this just builds that URL
  /// so a video post can show a static thumbnail before playback starts.
  String getVideoThumbnailUrl(String videoUrl) {
    try {
      final uri = Uri.parse(videoUrl);
      final path = uri.path;
      final lastDot = path.lastIndexOf('.');
      final newPath = '${lastDot == -1 ? path : path.substring(0, lastDot)}.jpg';
      return uri.replace(path: newPath).toString();
    } catch (_) {
      return videoUrl;
    }
  }

  Future<bool> deleteImage(String publicId) => _destroy(publicId, resourceType: 'image');

  Future<bool> deleteVideo(String publicId) => _destroy(publicId, resourceType: 'video');

  Future<bool> _destroy(String publicId, {required String resourceType}) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final signature = _generateSignature({'public_id': publicId, 'timestamp': timestamp});

      final response = await _dio.post(
        'https://api.cloudinary.com/v1_1/${CloudinaryConfig.cloudName}/$resourceType/destroy',
        data: {
          'public_id': publicId,
          'api_key': CloudinaryConfig.apiKey,
          'timestamp': timestamp,
          'signature': signature,
        },
        options: Options(
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      final result = response.data is Map ? response.data['result'] : null;
      return response.statusCode == 200 && (result == 'ok' || result == 'not found');
    } catch (e) {
      print('Error deleting $resourceType: $e');
      return false;
    }
  }

  /// Cloudinary's signed-request scheme: every parameter *except* `file`,
  /// `api_key`, `signature`, `resource_type` and `cloud_name` is sorted
  /// alphabetically, joined as `key=value&key=value...`, the api secret is
  /// appended directly (no separator), and the whole thing is SHA-1 hashed.
  ///
  /// The previous implementation returned a hardcoded placeholder string
  /// here, which meant every delete request was silently rejected by
  /// Cloudinary as an invalid signature — deleteImage() never actually
  /// worked. This is the real implementation.
  String _generateSignature(Map<String, dynamic> params) {
    final sortedKeys = params.keys.toList()..sort();
    final toSign = sortedKeys.map((k) => '$k=${params[k]}').join('&');
    final bytes = utf8.encode('$toSign${CloudinaryConfig.apiSecret}');
    return sha1.convert(bytes).toString();
  }

  /// Reconstructs a Cloudinary public_id (including its folder, if any)
  /// from a delivery URL — e.g. `.../upload/v1712345678/media_posts/17123.mp4`
  /// becomes `media_posts/17123`. The previous version only kept the last
  /// path segment, silently dropping the folder — which meant a delete call
  /// for anything uploaded with a `folder:` (i.e. everything in this app)
  /// would target the wrong public_id even if the signature had been valid.
  String extractPublicId(String url) {
    try {
      final uri = Uri.parse(url);
      final segments = List<String>.from(uri.pathSegments);

      final uploadIndex = segments.indexOf('upload');
      var relevant = uploadIndex == -1 ? segments : segments.sublist(uploadIndex + 1);

      // Drop a leading version segment like "v1712345678", if present.
      if (relevant.isNotEmpty && RegExp(r'^v\d+$').hasMatch(relevant.first)) {
        relevant = relevant.sublist(1);
      }
      if (relevant.isEmpty) return '';

      final last = relevant.last;
      final lastDot = last.lastIndexOf('.');
      final nameWithoutExt = lastDot == -1 ? last : last.substring(0, lastDot);

      return [...relevant.sublist(0, relevant.length - 1), nameWithoutExt].join('/');
    } catch (e) {
      print('Error extracting public ID: $e');
      return '';
    }
  }

  // Get optimized image URL
  String getOptimizedUrl(String url, {int width = 400, int height = 400}) {
    try {
      final uri = Uri.parse(url);
      final path = uri.path;
      final newPath = path.replaceFirst(
        'upload/',
        'upload/w_$width,h_$height,c_fill,f_webp,q_auto/',
      );
      return uri.replace(path: newPath).toString();
    } catch (e) {
      return url;
    }
  }
}