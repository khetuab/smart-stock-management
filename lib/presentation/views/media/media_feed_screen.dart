// lib/presentation/views/media/media_feed_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';
import '../../controllers/dashboard_controller.dart';
import '../../controllers/media_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../widgets/app_kits_collection.dart';
import '../../widgets/customer_bottom_nar_bar.dart';
import '../../widgets/social_media_row.dart';
import 'create_post_screen.dart';

class MediaFeedScreen extends GetView<MediaController> {
  const MediaFeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final auth = Get.find<AuthController>();

    return Scaffold(
      bottomNavigationBar: const CustomerBottomNavBar(currentIndex: 2),
      appBar: AppBar(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 2,
        title: Text(
          'Store Stories & Media'.tr,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh'.tr,
            onPressed: controller.refresh,
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: auth.isAdmin
          ? FloatingActionButton.extended(
        onPressed: () => Get.to(() => const CreatePostScreen()),
        icon: const Icon(Icons.add_a_photo_rounded),
        label: Text('New Post'.tr),
        elevation: 4,
      )
          : null,
      body: Column(
        children: [
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value && controller.posts.isEmpty) {
                return const Center(child: CircularProgressIndicator.adaptive());
              }

              if (controller.posts.isEmpty) {
                return Center(
                  child: AppEmptyState(
                    icon: Icons.video_collection_outlined,
                    title: 'No media posts yet'.tr,
                    subtitle: auth.isAdmin
                        ? 'Share a photo or video to engage customers.'.tr
                        : 'Check back soon for latest arrivals and videos.'.tr,
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: controller.refresh,
                child: ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
                  itemCount: controller.posts.length,
                  itemBuilder: (context, index) {
                    final post = controller.posts[index];
                    return _PostCard(post: post, isAdmin: auth.isAdmin)
                        .animate()
                        .fadeIn(delay: (40 * index).ms, duration: 300.ms)
                        .slideY(begin: 0.05, end: 0);
                  },
                ),
              );
            }),
          ),
          const SocialMediaRow(),
        ],
      ),
    );
  }
}

class _PostCard extends StatefulWidget {
  final dynamic post;
  final bool isAdmin;
  const _PostCard({required this.post, required this.isAdmin});

  @override
  State<_PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<_PostCard> {
  VideoPlayerController? _videoController;
  bool _initialized = false;
  bool _muted = false;
  bool _isPlaying = false;

  bool get _isVideo => widget.post.isVideo == true;

  String get _postId => (widget.post.id ?? widget.post.mediaUrl).toString();

  Key get _visibilityKey => Key('media_post_$_postId');

  MediaController get _mediaController => MediaController.to;

  @override
  void dispose() {
    // Stop VisibilityDetector from tracking/firing callbacks for this key —
    // without this it can still schedule a timer that fires after we're
    // disposed, causing "setState() called after dispose()".
    VisibilityDetectorController.instance.forget(_visibilityKey);

    _mediaController.notifyVideoStopped(_postId);
    _videoController?.removeListener(_onControllerUpdate);
    _videoController?.pause();
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _initController() async {
    if (_videoController != null || !_isVideo) return;
    final controller = VideoPlayerController.networkUrl(Uri.parse(widget.post.mediaUrl))
      ..setLooping(true);
    _videoController = controller;
    try {
      await controller.initialize();
      if (!mounted) {
        controller.dispose();
        _videoController = null;
        return;
      }
      setState(() => _initialized = true);
      controller.addListener(_onControllerUpdate);
    } catch (e) {
      debugPrint('Video init failed: $e');
      _videoController = null;
    }
  }

  void _onControllerUpdate() {
    if (!mounted) return;
    final isVideoPlaying = _videoController?.value.isPlaying ?? false;
    if (_isPlaying != isVideoPlaying) {
      setState(() => _isPlaying = isVideoPlaying);
    }
  }

  void _disposeController() {
    final c = _videoController;
    _videoController = null;
    _initialized = false;
    _isPlaying = false;
    _mediaController.notifyVideoStopped(_postId);
    c?.removeListener(_onControllerUpdate);
    c?.pause();
    c?.dispose();
  }

  void _onVisibilityChanged(VisibilityInfo info) {
    // The callback can fire after this State is already disposed (it's
    // scheduled via a timer, not synchronously torn down with the widget).
    if (!mounted) return;
    if (!_isVideo) return;

    final visible = info.visibleFraction > 0.3;

    if (visible) {
      if (_videoController == null) {
        _initController();
      }
    } else {
      if (_videoController != null) {
        _disposeController();
        setState(() {});
      }
    }
  }


  // ==================== SINGLE-VIDEO PLAYBACK ====================
  /// Called by the coordinator when another card starts playing — pauses
  /// this one without re-notifying the coordinator (avoids a loop).
  void _pauseFromCoordinator() {
    if (_videoController != null && _videoController!.value.isPlaying) {
      _videoController?.pause();
      _videoController?.setVolume(0);
    }
  }

  void _togglePlayPause() {
    if (_videoController == null || !_initialized) return;
    setState(() {
      if (_videoController!.value.isPlaying) {
        _videoController?.pause();
        _mediaController.notifyVideoStopped(_postId);
      } else {
        // Tell the coordinator first, so any other currently-playing card
        // pauses before this one starts.
        _mediaController.notifyVideoPlaying(_postId, _pauseFromCoordinator);
        _videoController?.play();
        _videoController?.setVolume(_muted ? 0 : 1);
      }
    });
  }

  void _toggleMute() {
    if (_videoController == null) return;
    setState(() {
      _muted = !_muted;
      _videoController?.setVolume(_muted ? 0 : 1);
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dashboard = Get.find<DashboardController>();
    final mediaController = MediaController.to;
    final post = widget.post;

    return VisibilityDetector(
      key: _visibilityKey,
      onVisibilityChanged: _onVisibilityChanged,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: scheme.outlineVariant.withOpacity(0.4)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Store / Author Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: scheme.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                      image: dashboard.storeLogo.value.isNotEmpty
                          ? DecorationImage(image: NetworkImage(dashboard.storeLogo.value), fit: BoxFit.cover)
                          : null,
                    ),
                    child: dashboard.storeLogo.value.isEmpty
                        ? Icon(Icons.storefront_rounded, size: 18, color: scheme.primary)
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post.postedBy.isNotEmpty ? post.postedBy : (dashboard.storeName.value.isNotEmpty ? dashboard.storeName.value : 'Official Store'.tr),
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: scheme.onSurface),
                        ),
                        Text(
                          'Store Update'.tr,
                          style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  if (widget.isAdmin)
                    IconButton(
                      icon: Icon(Icons.more_horiz_rounded, color: scheme.onSurfaceVariant),
                      onPressed: () => mediaController.deletePost(post),
                    ),
                ],
              ),
            ),

            // Media Showcase Frame
            AspectRatio(
              aspectRatio: 1,
              child: Container(
                color: Colors.black,
                child: _isVideo ? _buildVideoPlayer() : _buildPhoto(post.mediaUrl),
              ),
            ),

            // Content Caption Section Below Video/Photo
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (post.caption.isNotEmpty) ...[
                    Text(
                      post.caption,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.4,
                        color: scheme.onSurface,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  if (post.hasLinkedProduct) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: scheme.primaryContainer.withOpacity(0.35),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: scheme.primary.withOpacity(0.2)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.shopping_bag_outlined, size: 18, color: scheme.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              post.productName,
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: scheme.primary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Icon(Icons.arrow_forward_ios_rounded, size: 12, color: scheme.primary),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhoto(String url) {
    return Image.network(
      url,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return Container(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: const Center(child: CircularProgressIndicator.adaptive()),
        );
      },
      errorBuilder: (context, error, stack) => Container(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: const Center(child: Icon(Icons.broken_image_outlined, size: 40)),
      ),
    );
  }

  Widget _buildVideoPlayer() {
    if (!_initialized || _videoController == null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          _buildPhoto(widget.post.thumbnailUrl.isNotEmpty ? widget.post.thumbnailUrl : widget.post.mediaUrl),
          Container(color: Colors.black38),
          const Center(child: CircularProgressIndicator(color: Colors.white)),
        ],
      );
    }

    final duration = _videoController!.value.duration;
    final position = _videoController!.value.position;

    return GestureDetector(
      onTap: _togglePlayPause,
      child: Stack(
        fit: StackFit.expand,
        children: [
          FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: _videoController!.value.size.width,
              height: _videoController!.value.size.height,
              child: VideoPlayer(_videoController!),
            ),
          ),

          // Play Overlay Icon Animated
          AnimatedOpacity(
            opacity: !_isPlaying ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 200),
            child: Container(
              color: Colors.black26,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white38, width: 1.5),
                  ),
                  child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 36),
                ),
              ),
            ),
          ),

          // Top Right Audio Control
          Positioned(
            top: 12,
            right: 12,
            child: GestureDetector(
              onTap: _toggleMute,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(50),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white24),
                ),
                child: Icon(
                  _muted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ),

          // Bottom Video Control Bar & Timeline
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(10, 20, 10, 6),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black87, Colors.transparent],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Text(
                        _formatDuration(position),
                        style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                      const Expanded(child: SizedBox()),
                      Text(
                        _formatDuration(duration),
                        style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  VideoProgressIndicator(
                    _videoController!,
                    allowScrubbing: true,
                    colors: VideoProgressColors(
                      playedColor: Theme.of(context).colorScheme.primary,
                      bufferedColor: Colors.white30,
                      backgroundColor: Colors.white12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}