import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import '../../config/cloudinary_config.dart';

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

  // Delete image from Cloudinary
  Future<bool> deleteImage(String publicId) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      final response = await _dio.post(
        'https://api.cloudinary.com/v1_1/${CloudinaryConfig.cloudName}/image/destroy',
        data: {
          'public_id': publicId,
          'api_key': CloudinaryConfig.apiKey,
          'timestamp': timestamp,
          'signature': _generateSignature(publicId, timestamp),
        },
        options: Options(
          validateStatus: (status) {
            return status != null && status < 500;
          },
        ),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error deleting image: $e');
      return false;
    }
  }

  // Generate signature for deletion
  String _generateSignature(String publicId, int timestamp) {
    final toSign = 'public_id=$publicId&timestamp=$timestamp${CloudinaryConfig.apiSecret}';
    return 'signature_placeholder';
  }

  // Extract public ID from URL
  String extractPublicId(String url) {
    try {
      final uri = Uri.parse(url);
      final segments = uri.pathSegments;
      final lastSegment = segments.last;
      final publicId = lastSegment.split('.').first;
      return publicId;
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