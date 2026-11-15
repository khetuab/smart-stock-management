import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../app/routes/app_routes.dart';
import '../../../app/themes/app_theme.dart';
import '../../../core/utils/error_helper.dart';
import '../../../data/models/media_post_model.dart';
import '../../../data/services/channel_feed_service.dart';
import '../../../data/services/youtube_service.dart';
import '../../controllers/media_controller.dart';
import '../../controllers/social_links_controller.dart';
import '../../widgets/mejlis_kit.dart';
import '../../widgets/app_kits_collection.dart';
import '../media/media_feed_screen.dart';

/// ─────────────────────────────────────────────────────────────────────────
///  MEDIA HUB — the re-imagined social media bar.
///
///  Opens as a full page whose top shows the shop's social channels as
///  animated tabs. Pressing a tab shows that platform's content:
///   • Store Feed  — every post created in the app (photos & videos)
///   • YouTube     — the channel's latest uploads fetched LIVE through the
///                   YouTube Data API (channel handle + free API key are
///                   configured by the owner in Social Links), falling back
///                   to tagged in-app posts + an "Open Channel" button.
///   • TikTok / Instagram / Facebook / Telegram — tagged in-app posts
///                   (photo or video) mirroring what was posted there, plus
///                   a one-tap "Open Channel" button (these platforms don't
///                   expose public feed APIs).
/// ─────────────────────────────────────────────────────────────────────────
class MediaHubScreen extends StatefulWidget {
  const MediaHubScreen({super.key});

  @override
  State<MediaHubScreen> createState() => _MediaHubScreenState();
}

class _MediaHubScreenState extends State<MediaHubScreen> {
  final MediaController media = MediaController.to;
  final SocialLinksController social = SocialLinksController.to;

  final RxString activeTab = 'tiktok'.obs;
  final ScrollController _tabScroll = ScrollController();

  static const List<_HubTab> _tabs = [
    _HubTab('tiktok', faIcon: FontAwesomeIcons.tiktok),
    _HubTab('instagram', faIcon: FontAwesomeIcons.instagram),
    _HubTab('youtube', faIcon: FontAwesomeIcons.youtube),
    _HubTab('telegram', faIcon: FontAwesomeIcons.telegram),
    _HubTab('facebook', faIcon: FontAwesomeIcons.facebook),
    _HubTab('shop', icon: Icons.storefront_rounded),
  ];

  @override
  void initState() {
    super.initState();
    media.loadPosts();
    social.loadLinks();

    // Optional deep-link: home "Follow our channels" chips open the hub
    // directly on the tapped platform tab.
    final args = Get.arguments;
    if (args is Map && args['tab'] is String) {
      final tab = args['tab'] as String;
      if (_tabs.any((t) => t.id == tab)) activeTab.value = tab;
    }
  }

  @override
  void dispose() {
    _tabScroll.dispose();
    super.dispose();
  }

  void _openChannel(String platform) {
    final links = social.linksFor(platform);
    if (links.isEmpty) {
      Get.snackbar('Not available', 'channelNotConfigured'.tr, snackPosition: SnackPosition.BOTTOM);
      return;
    }
    if (links.length == 1) {
      _launch(links.first);
      return;
    }
    Get.bottomSheet(
      SafeArea(
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              for (final l in links)
                ListTile(
                  leading: const Icon(Icons.open_in_new_rounded),
                  title: Text(
                    l.replaceFirst(RegExp(r'^https?://(www\.)?'), ''),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () {
                    Get.back();
                    _launch(l);
                  },
                ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  void _launch(String url) {
    final formatted = url.startsWith('http') ? url : 'https://$url';
    final uri = Uri.tryParse(formatted);
    if (uri != null) launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      floatingActionButton: Obx(() {
        // Admin shortcut: compose a post for the ACTIVE platform.
        if (!Get.find<MediaController>().isAdmin) return const SizedBox.shrink();
        return FloatingActionButton.extended(
          onPressed: () => Get.toNamed(AppRoutes.createPostScreen,
              arguments: {'platform': activeTab.value == 'whatsapp' ? 'shop' : activeTab.value}),
          icon: const Icon(Icons.add_rounded),
          label: Text('postHere'.tr),
          backgroundColor: MejlisPalette.gold,
          foregroundColor: const Color(0xFF2A2104),
        );
      }),
      body: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        slivers: [
          // ── Painted header ──
          SliverAppBar(
            pinned: true,
            expandedHeight: 168,
            backgroundColor: scheme.primary,
            iconTheme: const IconThemeData(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: false,
              titlePadding: const EdgeInsets.only(left: 56, bottom: 14),
              title: Text(
                'mediaHub'.tr,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                  shadows: [Shadow(color: Colors.black38, blurRadius: 8)],
                ),
              ),
              background: const MejlisHeaderBackground(showSkyline: true),
            ),
          ),

          // ── Animated platform tab bar ──
          SliverToBoxAdapter(
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                border: Border(
                  bottom: BorderSide(color: MejlisPalette.gold.withOpacity(0.25)),
                ),
              ),
              child:
                 SizedBox(
                  height: 74,
                  child: ListView.separated(
                    controller: _tabScroll,
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    itemCount: _tabs.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 6),
                    itemBuilder: (context, i) {
                      final tab = _tabs[i];
                      final selected = activeTab.value == tab.id;
                      return GestureDetector(
                        onTap: () {
                          activeTab.value = tab.id;
                          setState(() {});
                          // Keep the selected chip visible with an ease scroll.
                          final target = (i * 78.0) - 80;
                          if (_tabScroll.hasClients) {
                            _tabScroll.animateTo(
                              target.clamp(0.0, _tabScroll.position.maxScrollExtent),
                              duration: const Duration(milliseconds: 380),
                              curve: Curves.easeInOutCubic,
                            );
                          }
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 280),
                          curve: Curves.easeOutCubic,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            gradient: selected ? MejlisPalette.goldGradient : null,
                            color: selected
                                ? null
                                : Theme.of(context).brightness == Brightness.dark
                                ? Colors.white.withOpacity(0.05)
                                : MejlisPalette.emerald.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: selected ? Colors.transparent : MejlisPalette.gold.withOpacity(0.3),
                            ),
                            boxShadow: selected
                                ? [BoxShadow(color: MejlisPalette.gold.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 4))]
                                : null,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _tabIcon(tab, selected),
                              const SizedBox(height: 4),
                              Text(
                                _tabLabel(tab.id),
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                                  color: selected
                                      ? const Color(0xFF2A2104)
                                      : Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

            ).animate().fadeIn(duration: 300.ms),
          ),

          // ── Content ──
          // ── Content ──
          // NOTE: no Obx here. The sections contain their own Obx widgets,
          // and nesting Obx inside Obx (GetX => HeavyWidget => observable)
          // is what throws "improper use of a GetX". Rebuild this subtree
          // via setState when the tab changes instead.
          _ContentForTab(
            tab: activeTab.value,
            openChannel: _openChannel,
            openVideo: _openVideo,
            tabLabel: _tabLabel,
          ),
        ],
      ),
    );
  }

  Widget _tabIcon(_HubTab tab, bool selected) {
    final color = selected
        ? const Color(0xFF2A2104)
        : (tab.id == 'shop' ? MejlisPalette.emerald : _platformColor(tab.id));

    // Material icons use Icon; Font Awesome icons (FaIconData) need FaIcon.
    if (tab.faIcon != null) {
      return FaIcon(tab.faIcon!, size: 18, color: color);
    }
    return Icon(tab.icon ?? Icons.link_rounded, size: 18, color: color);
  }

  Color _platformColor(String id) {
    switch (id) {
      case 'youtube':
        return const Color(0xFFFF0000);
      case 'tiktok':
        return const Color(0xFF25F4EE);
      case 'instagram':
        return const Color(0xFFE1306C);
      case 'facebook':
        return const Color(0xFF1877F2);
      case 'telegram':
        return const Color(0xFF229ED9);
      default:
        return MejlisPalette.emerald;
    }
  }

  String _tabLabel(String id) {
    switch (id) {
      case 'shop':
        return 'storeFeed'.tr;
      case 'youtube':
        return 'YouTube';
      case 'tiktok':
        return 'TikTok';
      case 'instagram':
        return 'Instagram';
      case 'facebook':
        return 'Facebook';
      case 'telegram':
        return 'Telegram';
      default:
        return id;
    }
  }

  Widget _contentFor(BuildContext context, String tab) {
    switch (tab) {
      case 'youtube':
        return _YouTubeSection(
          openChannel: () => _openChannel('youtube'),
          onOpenVideo: _openVideo,
        );
      case 'tiktok':
      case 'instagram':
      case 'facebook':
      case 'telegram':
        return _PlatformSection(
          platform: tab,
          label: _tabLabel(tab),
          openChannel: () => _openChannel(tab),
        );
      default:
        return _StoreFeedSection();
    }
  }

  void _openVideo(YouTubeVideo video) {
    final uri = Uri.parse(video.watchUrl);
    launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

/// A tab is either a Material icon ([icon]) or a Font Awesome icon
/// ([faIcon]). In font_awesome_flutter 10.8+ these are different types.
class _HubTab {
  final String id;
  final IconData? icon;
  final FaIconData? faIcon;
  const _HubTab(this.id, {this.icon, this.faIcon});
}

// ─────────────────────────── STORE FEED TAB ───────────────────────────

class _StoreFeedSection extends StatelessWidget {
  final MediaController controller = MediaController.to;

   _StoreFeedSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value && controller.posts.isEmpty) {
        return const SliverFillRemaining(
          child: Center(child: CircularProgressIndicator.adaptive()),
        );
      }
      if (controller.posts.isEmpty) {
        return SliverFillRemaining(
          hasScrollBody: false,
          child: AppEmptyState(
            icon: Icons.photo_library_outlined,
            title: 'No media posts yet'.tr,
            subtitle: 'Check back soon for latest arrivals and videos.'.tr,
          ),
        );
      }
      return SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
                (context, index) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: MediaPostCard(post: controller.posts[index], isAdmin: controller.isAdmin),
            ),
            childCount: controller.posts.length,
          ),
        ),
      );
    });
  }
}

// ─────────────────────────── YOUTUBE TAB ───────────────────────────

class _YouTubeSection extends StatefulWidget {
  final VoidCallback openChannel;
  final ValueChanged<YouTubeVideo> onOpenVideo;

  const _YouTubeSection({
    super.key,
    required this.openChannel,
    required this.onOpenVideo,
  });

  @override
  State<_YouTubeSection> createState() => _YouTubeSectionState();
}

class _YouTubeSectionState extends State<_YouTubeSection> {
  final SocialLinksController social = SocialLinksController.to;
  final MediaController media = MediaController.to;
  final YouTubeService _service = YouTubeService();

  List<YouTubeVideo>? _videos;
  bool _loading = false;
  String _error = '';
  String? _loadedForHandle;

  @override
  void initState() {
    super.initState();
    _maybeFetch();
  }

  Future<void> _maybeFetch({bool force = false}) async {
    final handle = social.youtubeHandle.value.trim();
    final key = social.youtubeApiKey.value.trim();
    if (handle.isEmpty || key.isEmpty) return;

    if (!force && _loadedForHandle == handle && _videos != null) return;

    setState(() {
      _loading = true;
      _error = '';
    });
    try {
      final ref = YouTubeService.extractChannelRef(handle) ?? handle;
      final playlist = await _service.resolveUploadsPlaylist(channelRef: ref, apiKey: key);
      final videos = await _service.fetchVideos(uploadsPlaylistId: playlist, apiKey: key);
      if (!mounted) return;
      setState(() {
        _videos = videos;
        _loadedForHandle = handle;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final configured = social.canFetchYouTubeFeed;

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Channel hero
            MejlisCard(
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF0000).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Center(
                      child: FaIcon(FontAwesomeIcons.youtube, color: Color(0xFFFF0000), size: 24),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ourYouTubeChannel'.tr,
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: scheme.onSurface),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          social.youtubeHandle.value.isEmpty
                              ? 'tapToVisitChannel'.tr
                              : social.youtubeHandle.value,
                          style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  IconButton.filled(
                    onPressed: widget.openChannel,
                    style: IconButton.styleFrom(backgroundColor: const Color(0xFFFF0000)),
                    icon: const Icon(Icons.open_in_new_rounded, size: 18, color: Colors.white),
                  ),
                ],
              ),
            ).mejlisEnter(),

            const SizedBox(height: 18),

            // Live channel videos
            const _LiveFeed(platform: 'youtube'),

            // Tagged posts (photos/videos posted to the YouTube tab)
            _TaggedPostsSection(platform: 'youtube', title: 'channelPosts'.tr),
          ],
        ),
      ),
    );
  }

  Widget _buildVideos(ColorScheme scheme) {
    if (_loading) {
      return const SizedBox(
        height: 160,
        child: Center(child: CircularProgressIndicator.adaptive()),
      );
    }
    if (_error.isNotEmpty) {
      return MejlisCard(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.red),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'youtubeFeedError'.tr,
                style: TextStyle(fontSize: 12.5, color: scheme.onSurfaceVariant),
              ),
            ),
          ],
        ),
      );
    }
    final videos = _videos ?? const <YouTubeVideo>[];
    if (videos.isEmpty) {
      return Text(
        'noVideosYet'.tr,
        style: TextStyle(fontSize: 12.5, color: scheme.onSurfaceVariant),
      );
    }
    return SizedBox(
      height: 220,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: videos.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          final v = videos[i];
          return _VideoCard(
            video: v,
            onTap: () => widget.onOpenVideo(v),
          ).mejlisEnter(delayMs: i * 40);
        },
      ),
    );
  }
}

class _VideoCard extends StatelessWidget {
  final YouTubeVideo video;
  final VoidCallback onTap;

  const _VideoCard({required this.video, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 240,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: MejlisPalette.gold.withOpacity(0.25)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  SizedBox(
                    height: 135,
                    width: double.infinity,
                    child: video.thumbnailUrl.isNotEmpty
                        ? Image.network(
                      video.thumbnailUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.black12,
                        child: const Center(
                          child: FaIcon(FontAwesomeIcons.youtube, size: 34, color: Colors.red),
                        ),
                      ),
                    )
                        : Container(
                      color: Colors.black12,
                      child: const Center(
                        child: FaIcon(FontAwesomeIcons.youtube, size: 34, color: Colors.red),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: Center(
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.92),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 30),
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      video.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                        color: scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _relativeDate(video.publishedAt),
                      style: TextStyle(fontSize: 10.5, color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _relativeDate(String iso) {
    final d = DateTime.tryParse(iso);
    if (d == null) return '';
    final diff = DateTime.now().difference(d);
    if (diff.inDays < 1) return 'today'.tr;
    if (diff.inDays < 30) return '${diff.inDays} ${'daysAgo'.tr}';
    if (diff.inDays < 365) return '${(diff.inDays / 30).floor()} ${'monthsAgo'.tr}';
    return '${(diff.inDays / 365).floor()} ${'yearsAgo'.tr}';
  }
}

// ─────────────────────── OTHER PLATFORM TABS ───────────────────────

class _PlatformSection extends StatelessWidget {
  final String platform;
  final String label;
  final VoidCallback openChannel;

  const _PlatformSection({
    super.key,
    required this.platform,
    required this.label,
    required this.openChannel,
  });

  Color get _brandColor {
    switch (platform) {
      case 'tiktok':
        return Colors.black;
      case 'instagram':
        return const Color(0xFFE1306C);
      case 'facebook':
        return const Color(0xFF1877F2);
      case 'telegram':
        return const Color(0xFF229ED9);
      default:
        return MejlisPalette.emerald;
    }
  }

  FaIconData get _icon {
    switch (platform) {
      case 'tiktok':
        return FontAwesomeIcons.tiktok;
      case 'instagram':
        return FontAwesomeIcons.instagram;
      case 'facebook':
        return FontAwesomeIcons.facebook;
      case 'telegram':
        return FontAwesomeIcons.telegram;
      default:
        return FontAwesomeIcons.link;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Channel hero
            MejlisCard(
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: platform == 'instagram'
                          ? const LinearGradient(
                        begin: Alignment.bottomLeft,
                        end: Alignment.topRight,
                        colors: [Color(0xFFFEDA75), Color(0xFFD62976), Color(0xFF4F5BD5)],
                      )
                          : null,
                      color: platform == 'instagram' ? null : _brandColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: FaIcon(
                        _icon,
                        color: platform == 'instagram'
                            ? Colors.white
                            : _brandColor,
                        size: 24,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$label — ${'ourChannel'.tr}',
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: scheme.onSurface),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'seeFullChannelHint'.tr,
                          style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  IconButton.filled(
                    onPressed: openChannel,
                    style: IconButton.styleFrom(
                      backgroundColor: _brandColor == Colors.black ? Colors.black87 : _brandColor,
                    ),
                    icon: const Icon(Icons.open_in_new_rounded, size: 18, color: Colors.white),
                  ),
                ],
              ),
            ).mejlisEnter(),

            _LiveFeed(platform: platform),
            const SizedBox(height: 4),
            const SizedBox(height: 18),
            _TaggedPostsSection(platform: platform, title: label),
          ],
        ),
      ),
    );
  }
}

/// Grid/list of in-app posts tagged with a platform (photos & videos,
/// rendered with the same card as the store feed).
class _TaggedPostsSection extends StatelessWidget {
  final String platform;
  final String title;
  const _TaggedPostsSection({required this.platform, required this.title});

  @override
  Widget build(BuildContext context) {
    final media = MediaController.to;
    final scheme = Theme.of(context).colorScheme;

    return Obx(() {
      final posts = media.postsForPlatform(platform);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(color: MejlisPalette.gold, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Text(
                '$title · ${'fromTheShop'.tr}',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: scheme.onSurface),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (posts.isEmpty)
            Text(
              'noPlatformPostsYet'.tr,
              style: TextStyle(fontSize: 12.5, color: scheme.onSurfaceVariant),
            )
          else
            ...posts.map((p) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: MediaPostCard(post: p, isAdmin: media.isAdmin),
            )),
        ],
      );
    });
  }
}

/// Friendly configuration hint (admin gets a shortcut, customers a note).
class _SetupHintCard extends StatelessWidget {
  final bool isAdmin;
  final String text;
  final VoidCallback? onSetup;

  const _SetupHintCard({required this.isAdmin, required this.text, this.onSetup});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return MejlisCard(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: MejlisPalette.goldGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.key_rounded, size: 20, color: Color(0xFF2A2104)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 12.5, color: scheme.onSurfaceVariant, height: 1.35),
            ),
          ),
          if (isAdmin && onSetup != null)
            TextButton(
              onPressed: onSetup,
              child: Text('setUp'.tr, style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
        ],
      ),
    );
  }
}

class _ContentForTab extends StatelessWidget {
  final String tab;
  final void Function(String) openChannel;
  final void Function(YouTubeVideo) openVideo;
  final String Function(String) tabLabel;

  const _ContentForTab({
    required this.tab,
    required this.openChannel,
    required this.openVideo,
    required this.tabLabel,
  });

  @override
  Widget build(BuildContext context) {
    switch (tab) {
      case 'youtube':
        return _YouTubeSection(
          key: ValueKey(tab),
          openChannel: () => openChannel('youtube'),
          onOpenVideo: openVideo,
        );
      case 'tiktok':
      case 'instagram':
      case 'facebook':
      case 'telegram':
        return _PlatformSection(
          key: ValueKey(tab),
          platform: tab,
          label: tabLabel(tab),
          openChannel: () => openChannel(tab),
        );
      default:
        return _StoreFeedSection(key: ValueKey(tab));
    }
  }
}

class _LiveFeed extends StatefulWidget {
  final String platform;
  const _LiveFeed({required this.platform});

  @override
  State<_LiveFeed> createState() => _LiveFeedState();
}

class _LiveFeedState extends State<_LiveFeed> {
  final social = SocialLinksController.to;
  final _service = ChannelFeedService();
  late final Worker _worker;

  List<FeedResult> _results = [];
  int _selected = 0; // which channel tab is open
  bool _loading = false;

  List<String> get _sources => social.feedSourcesFor(widget.platform);

  FeedResult? get _current {
    if (_results.isEmpty) return null;
    return _results[_selected < _results.length ? _selected : 0];
  }

  // Image shape per platform, so posts keep natural proportions.
  double get _imageAspect {
    switch (widget.platform) {
      case 'youtube':   return 16 / 9;
      case 'instagram': return 4 / 5;
      case 'tiktok':    return 3 / 4;
      case 'telegram':  return 4 / 3;
      default:          return 1; // facebook
    }
  }

  bool get _useGrid => const {'instagram', 'tiktok', 'facebook'}.contains(widget.platform);

  @override
  void initState() {
    super.initState();
    _worker = ever(social.feedRxFor(widget.platform), (_) => _load());
    _load();
  }

  @override
  void dispose() {
    _worker.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final sources = _sources;
    if (sources.isEmpty) {
      if (mounted) setState(() { _results = []; _selected = 0; _loading = false; });
      return;
    }
    setState(() => _loading = true);
    final results = await _service.fetchEach(
      widget.platform,
      sources,
      youtubeApiKey: social.youtubeApiKey.value.trim(),
    );
    if (!mounted) return;
    setState(() {
      _results = results;
      if (_selected >= results.length) _selected = 0;
      _loading = false;
    });
  }

  String _ago(DateTime? d) {
    if (d == null) return '';
    final diff = DateTime.now().difference(d);
    if (diff.inDays < 1) return 'today'.tr;
    if (diff.inDays < 30) return '${diff.inDays} ${'daysAgo'.tr}';
    if (diff.inDays < 365) return '${(diff.inDays / 30).floor()} ${'monthsAgo'.tr}';
    return '${(diff.inDays / 365).floor()} ${'yearsAgo'.tr}';
  }

  /// Channel's own name when the feed provides one, otherwise "Channel 1/2/…".
  String _channelLabel(int i) {
    final name = _results[i].name;
    return name.isNotEmpty ? name : '${'channel'.tr} ${i + 1}';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (_sources.isEmpty) {
      final needsFeedUrl = const {'tiktok', 'instagram', 'facebook'}.contains(widget.platform);
      if (needsFeedUrl && social.isAdmin) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 18),
          child: _SetupHintCard(isAdmin: true, text: 'feedUrlHint'.tr),
        );
      }
      return const SizedBox.shrink();
    }

    final current = _current;
    Widget body;
    if (_loading) {
      body = const SizedBox(height: 120, child: Center(child: CircularProgressIndicator.adaptive()));
    } else if (current == null) {
      body = const SizedBox.shrink();
    } else if (current.error != null) {
      body = MejlisCard(
        padding: const EdgeInsets.all(14),
        child: Text(
          // Customers get a short message; the admin sees the real reason.
          ErrorHelper.friendly(current.error!),
          style: TextStyle(fontSize: 12.5, color: scheme.onSurfaceVariant),
        ),
      );
    } else if (current.items.isEmpty) {
      body = Text('noVideosYet'.tr, style: TextStyle(fontSize: 12.5, color: scheme.onSurfaceVariant));
    } else if (widget.platform == 'youtube') {
      body = SizedBox(
        height: 230,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          itemCount: current.items.length,
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemBuilder: (_, i) => _card(current.items[i], 240, scheme),
        ),
      );
    } else if (_useGrid) {
      body = _grid(current.items, scheme);
    } else {
      // Telegram: full-width list
      body = Column(
        children: current.items.take(20).map((i) => Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: _card(i, double.infinity, scheme, titleLines: 6),
        )).toList(),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text('latestUploads'.tr,
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: scheme.onSurface)),
            const Spacer(),
            IconButton(
              onPressed: _load,
              icon: const Icon(Icons.refresh_rounded, size: 20),
              color: scheme.primary,
            ),
          ]),
          if (_results.length > 1) ...[
            _channelTabs(scheme),
            const SizedBox(height: 12),
          ],
          body,
        ],
      ),
    );
  }

  /// One chip per channel (only shown when the platform has 2+ channels).
  Widget _channelTabs(ColorScheme scheme) {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _results.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final selected = i == _selected;
          return GestureDetector(
            onTap: () => setState(() => _selected = i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              constraints: const BoxConstraints(maxWidth: 190),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: selected ? MejlisPalette.goldGradient : null,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: selected ? Colors.transparent : MejlisPalette.gold.withOpacity(0.35),
                ),
              ),
              child: Text(
                _channelLabel(i),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  color: selected ? const Color(0xFF2A2104) : scheme.onSurface,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Two-column layout: cards keep their natural height, nothing overflows.
  Widget _grid(List<FeedItem> list, ColorScheme scheme) {
    final items = list.take(20).toList();
    final left = <Widget>[];
    final right = <Widget>[];
    for (var i = 0; i < items.length; i++) {
      final card = Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: _card(items[i], double.infinity, scheme, titleLines: 3),
      );
      (i.isEven ? left : right).add(card);
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: Column(children: left)),
        const SizedBox(width: 10),
        Expanded(child: Column(children: right)),
      ],
    );
  }

  Widget _card(FeedItem item, double width, ColorScheme scheme, {int titleLines = 2}) {
    final ago = _ago(item.date);

    return GestureDetector(
      onTap: () => launchUrl(Uri.parse(item.url), mode: LaunchMode.externalApplication),
      child: Container(
        width: width,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: MejlisPalette.gold.withOpacity(0.25)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (item.imageUrl.isNotEmpty)
                AspectRatio(
                  aspectRatio: _imageAspect,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        item.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: Colors.black12,
                          child: const Center(
                            child: Icon(Icons.image_not_supported_outlined, color: Colors.black38),
                          ),
                        ),
                      ),
                      if (item.isVideo)
                        const Center(
                          child: Icon(Icons.play_circle_fill_rounded, color: Colors.white, size: 44),
                        ),
                    ],
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (item.title.isNotEmpty)
                      Text(
                        item.title,
                        maxLines: titleLines,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: scheme.onSurface,
                        ),
                      ),
                    if (ago.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(ago, style: TextStyle(fontSize: 10.5, color: scheme.onSurfaceVariant)),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}