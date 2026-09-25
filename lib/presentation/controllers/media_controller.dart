// lib/presentation/controllers/media_controller.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/utils/helpers.dart';
import '../../data/models/media_post_model.dart';
import '../../data/services/google_sheets_service.dart';
import '../../data/services/cloudinary_service.dart';
import 'auth_controller.dart';

class MediaController extends GetxController {
  final GoogleSheetsService _sheets = GoogleSheetsService();
  final CloudinaryService _cloudinary = CloudinaryService();

  AuthController get _auth => Get.find<AuthController>();
  bool get isAdmin => _auth.isAdmin;

  var posts = <MediaPost>[].obs;
  var isLoading = false.obs;
  var isUploading = false.obs;
  var feedIsActive = true.obs;
  // 0.0–1.0 while a video is being compressed before upload; the network
  // upload itself doesn't report granular progress, so this covers the part
  // that actually takes noticeable time on a large clip.
  var uploadProgress = 0.0.obs;

  static const int maxVideoSizeMb = 10;

  static const List<String> _headers = [
    'id', 'type', 'mediaUrl', 'thumbnailUrl', 'caption',
    'productId', 'productName', 'postedBy', 'createdAt',
  ];

  static MediaController get to {
    if (Get.isRegistered<MediaController>()) return Get.find<MediaController>();
    return Get.put(MediaController(), permanent: true);
  }

  // ==================== SINGLE-VIDEO PLAYBACK COORDINATOR ====================
  // Only one video across the whole feed (and app) should ever be playing at
  // once — both for a sane UX (no overlapping audio) and, critically, to
  // avoid opening multiple concurrent hardware decoder sessions, which on
  // some devices (MediaTek especially) triggers a GPU device loss and
  // freezes the whole app surface.
  String? _activePlayingId;
  VoidCallback? _activePauseCallback;

  /// A post card calls this right before it starts playing. Any other card
  /// that's currently playing gets told to pause first.
  void notifyVideoPlaying(String postId, VoidCallback pauseCallback) {
    if (_activePlayingId != null && _activePlayingId != postId) {
      _activePauseCallback?.call();
    }
    _activePlayingId = postId;
    _activePauseCallback = pauseCallback;
  }

  /// A post card calls this when it pauses or is disposed, so the
  /// coordinator doesn't hold a stale reference to it.
  void notifyVideoStopped(String postId) {
    if (_activePlayingId == postId) {
      _activePlayingId = null;
      _activePauseCallback = null;
    }
  }

  @override
  void onInit() {
    super.onInit();
    loadPosts();
  }

  Future<void> _ensureHeadersExist() async {
    final existing = await _sheets.getSheetDataWithHeaders('MediaPosts');
    if (existing.isEmpty) {
      await _sheets.writeToSheet(sheetName: 'MediaPosts', values: [_headers]);
    }
  }

  Future<void> loadPosts() async {
    try {
      isLoading.value = true;
      await _sheets.init();
      await _sheets.createSheetIfNotExists('MediaPosts');
      await _ensureHeadersExist();

      final data = await _sheets.getSheetDataWithHeaders('MediaPosts');
      final all = _parsePosts(data);
      // Newest first.
      all.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      posts.value = all;
    } catch (e) {
      debugPrint('Error loading media posts: $e');
      Get.snackbar('Error', 'Failed to load posts', colorText: Colors.red, snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }

  List<MediaPost> _parsePosts(Map<String, List<dynamic>> data) {
    final list = <MediaPost>[];
    if (data.isEmpty) return list;

    List<dynamic> col(String key) => data[key] ?? [];
    String at(List<dynamic> c, int i) => i < c.length ? (c[i]?.toString() ?? '') : '';

    final ids = col('id');
    final types = col('type');
    final mediaUrls = col('mediaUrl');
    final thumbnailUrls = col('thumbnailUrl');
    final captions = col('caption');
    final productIds = col('productId');
    final productNames = col('productName');
    final postedBys = col('postedBy');
    final createdAts = col('createdAt');

    for (int i = 0; i < ids.length; i++) {
      if (at(ids, i).isEmpty) continue;
      list.add(MediaPost(
        id: at(ids, i),
        type: at(types, i).isEmpty ? 'photo' : at(types, i),
        mediaUrl: at(mediaUrls, i),
        thumbnailUrl: at(thumbnailUrls, i),
        caption: at(captions, i),
        productId: at(productIds, i),
        productName: at(productNames, i),
        postedBy: at(postedBys, i),
        createdAt: at(createdAts, i),
      ));
    }
    return list;
  }

  List<dynamic> _rowFor(MediaPost p) => [
    p.id, p.type, p.mediaUrl, p.thumbnailUrl, p.caption,
    p.productId, p.productName, p.postedBy, p.createdAt,
  ];

  Future<void> createPhotoPost({
    required String caption,
    String? productId,
    String? productName,
  }) async {
    if (!isAdmin) return;
    try {
      isUploading.value = true;
      final url = await _cloudinary.uploadFromGallery(folder: 'media_posts');
      if (url == null) return; // user cancelled the picker

      await _savePost(
        type: 'photo',
        mediaUrl: url,
        thumbnailUrl: url,
        caption: caption,
        productId: productId,
        productName: productName,
      );
    } catch (e) {
      Get.snackbar('Error', 'Failed to create post: $e', colorText: Colors.red, snackPosition: SnackPosition.BOTTOM);
    } finally {
      isUploading.value = false;
    }
  }

  Future<void> createVideoPost({
    required String caption,
    String? productId,
    String? productName,
  }) async {
    if (!isAdmin) return;
    try {
      isUploading.value = true;
      uploadProgress.value = 0;

      final url = await _cloudinary.uploadVideoFromGallery(
        folder: 'media_posts',
        maxSizeMb: maxVideoSizeMb,
        onCompressionProgress: (p) => uploadProgress.value = p,
      );
      if (url == null) return; // user cancelled the picker

      final thumbnail = _cloudinary.getVideoThumbnailUrl(url);
      await _savePost(
        type: 'video',
        mediaUrl: url,
        thumbnailUrl: thumbnail,
        caption: caption,
        productId: productId,
        productName: productName,
      );
    } catch (e) {
      Get.snackbar('Error', '$e', colorText: Colors.red, snackPosition: SnackPosition.BOTTOM, duration: const Duration(seconds: 4));
    } finally {
      isUploading.value = false;
      uploadProgress.value = 0;
    }
  }

  Future<void> _savePost({
    required String type,
    required String mediaUrl,
    required String thumbnailUrl,
    required String caption,
    String? productId,
    String? productName,
  }) async {
    await _sheets.init();
    await _sheets.createSheetIfNotExists('MediaPosts');
    await _ensureHeadersExist();

    final post = MediaPost(
      id: Helpers.generateId(),
      type: type,
      mediaUrl: mediaUrl,
      thumbnailUrl: thumbnailUrl,
      caption: caption.trim(),
      productId: productId ?? '',
      productName: productName ?? '',
      postedBy: _auth.username.value,
      createdAt: DateTime.now().toIso8601String(),
    );

    await _sheets.appendToSheet(sheetName: 'MediaPosts', rowData: _rowFor(post));
    posts.insert(0, post);

    Get.snackbar('Posted!', 'Your post is now live.', colorText: Colors.green, snackPosition: SnackPosition.BOTTOM);
  }

  Future<void> deletePost(MediaPost post) async {
    if (!isAdmin) return;

    final confirm = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Delete Post'),
        content: const Text('This will remove the post for everyone. Continue?'),
        actions: [
          TextButton(onPressed: () => Get.back(result: false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Get.back(result: true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    notifyVideoStopped(post.id);

    try {
      posts.removeWhere((p) => p.id == post.id);

      await _sheets.init();
      await _sheets.clearSheet('MediaPosts');
      await _rewriteAllPostsToSheet();

      // Best-effort — the post is already gone from the feed either way,
      // and Cloudinary storage cost for one leftover clip/photo is trivial
      // compared to blocking the delete on it.
      final publicId = _cloudinary.extractPublicId(post.mediaUrl);
      if (publicId.isNotEmpty) {
        if (post.isVideo) {
          await _cloudinary.deleteVideo(publicId);
        } else {
          await _cloudinary.deleteImage(publicId);
        }
      }

      Get.snackbar('Deleted', 'Post removed.', colorText: Colors.green, snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      await loadPosts(); // re-sync if the sheet write failed
      Get.snackbar('Error', 'Failed to delete post: $e', colorText: Colors.red, snackPosition: SnackPosition.BOTTOM);
    }
  }

  Future<void> _rewriteAllPostsToSheet() async {
    final values = [_headers, ...posts.map(_rowFor)];
    await _sheets.writeToSheet(sheetName: 'MediaPosts', values: values);
  }

  Future<void> refresh() => loadPosts();
}