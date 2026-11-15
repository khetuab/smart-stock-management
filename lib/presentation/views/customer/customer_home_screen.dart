import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import '../../../app/routes/app_routes.dart';
import '../../../app/themes/app_theme.dart';
import '../../controllers/product_controller.dart';
import '../../controllers/dashboard_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../widgets/app_kits_collection.dart';
import '../../widgets/customer_bottom_nar_bar.dart';
import '../../widgets/customer_product_card.dart';
import '../../widgets/location_showcase_widget.dart';
import '../../widgets/mejlis_kit.dart';
import '../../widgets/promotion_banner_carousel.dart';
import '../../widgets/secret_owner_access.dart';
import '../orders/create_order_screen.dart';

/// ─────────────────────────────────────────────────────────────────────────
///  CUSTOMER HOME — the Arabian Mejlis shop-front.
///
///  • Illustrated emerald header: arabesque lattice, mosque skyline,
///    swaying lanterns, gold arches.
///  • Promo banner carousel (unchanged behaviour).
///  • NEW: "Find Us Across Ethiopia" — the illustrated zoomable map with
///    every branch pinned (right below the promo banner, as specified).
///  • "Follow Our Channels" strip → opens the new Media Hub.
///  • Category chips + animated product grid (business logic untouched).
/// ─────────────────────────────────────────────────────────────────────────
class CustomerHomeScreen extends GetView<ProductController> {
  const CustomerHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dashboard = Get.find<DashboardController>();

    return Scaffold(
      bottomNavigationBar: const CustomerBottomNavBar(currentIndex: 0),
      floatingActionButton: FloatingActionButton(
        heroTag: 'home_media_hub',
        onPressed: () => Get.toNamed(AppRoutes.mediaHub),
        backgroundColor: MejlisPalette.gold,
        child: const Icon(Icons.play_circle_fill_rounded, color: Color(0xFF2A2104), size: 30),
      ),
      body: RefreshIndicator(
        onRefresh: () => controller.loadProducts(),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          slivers: [
            // ── Illustrated Mejlis header ──
            SliverAppBar(
              leading: Obx(
                    () => Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: SecretOwnerAccess(
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withOpacity(0.4), width: 1),
                        image: dashboard.storeLogo.value.isNotEmpty
                            ? DecorationImage(
                            image: NetworkImage(dashboard.storeLogo.value), fit: BoxFit.cover)
                            : null,
                      ),
                      child: dashboard.storeLogo.value.isEmpty
                          ? const Icon(Icons.storefront_rounded, color: Colors.white)
                          : null,
                    ),
                  ),
                ),
              ),
              expandedHeight: 235,
              floating: false,
              pinned: true,
              elevation: 0,
              scrolledUnderElevation: 4,
              surfaceTintColor: scheme.surface,
              backgroundColor: scheme.primary,
              iconTheme: const IconThemeData(color: Colors.white),
              flexibleSpace: FlexibleSpaceBar(
                centerTitle: false,
                titlePadding: const EdgeInsets.only(left: 56, bottom: 14),
                title: Obx(
                      () => Text(
                    dashboard.storeName.value.isEmpty ? 'Our Shop'.tr : dashboard.storeName.value,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                      shadows: [Shadow(color: Colors.black38, blurRadius: 8, offset: Offset(0, 2))],
                    ),
                  ),
                ),
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    const MejlisHeaderBackground(),
                    Positioned(
                      left: 20,
                      right: 20,
                      bottom: 50,
                      child: Text(
                        'Browse our latest products and place an order in seconds.'.tr,
                        style: const TextStyle(color: Colors.white70, fontSize: 12.5),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                IconButton(
                  tooltip: 'contactUs'.tr,
                  onPressed: () => Get.toNamed(AppRoutes.contactUs),
                  icon: const Icon(Icons.headset_mic_rounded),
                ),
                IconButton(
                  tooltip: 'settings'.tr,
                  onPressed: () => Get.toNamed(AppRoutes.customerSettings),
                  icon: const Icon(Icons.settings_rounded),
                ),
              ],
            ),

            // ── Search ──
            // NOTE: .animate() is applied to the Padding (a box widget),
            // never to the SliverToBoxAdapter itself.
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: TextField(
                  onChanged: controller.searchProducts,
                  decoration: InputDecoration(
                    hintText: 'searchProducts'.tr,
                    prefixIcon: const Icon(Icons.search_rounded),
                    filled: true,
                    fillColor: Theme.of(context).brightness == Brightness.dark
                        ? scheme.surfaceContainerHigh
                        : scheme.surfaceContainerHighest.withOpacity(0.5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ).animate().fadeIn(duration: 350.ms),
            ),

            // ── Promo banner (unchanged) ──
            // ── Promo banner (appears 3 seconds after the page opens) ──
            // ── Promo banner ──
            const SliverToBoxAdapter(
              child: DelayedReveal(
                delay: Duration(seconds: 5),
                child: PromotionBannerCarousel(),
              ),
            ),

// ── Spacing ──
            const SliverToBoxAdapter(
              child: SizedBox(height: 8),
            ),

// ── Ethiopia locations map ──
            const SliverToBoxAdapter(
              child: LocationShowcaseWidget(),
            ),

// ── Spacing ──
            const SliverToBoxAdapter(
              child: SizedBox(height: 8),
            ),

// ── Follow our channels ──
            SliverToBoxAdapter(
              child: _MediaChannelsStrip(),
            ),

// ── Spacing ──
            const SliverToBoxAdapter(
              child: SizedBox(height: 8),
            ),
            // ── Category chips ──
            SliverToBoxAdapter(
              child: SizedBox(
                height: 46,
                child: Obx(() {
                  final categories = controller.categories.toList();
                  final selected = controller.selectedCategory.value;
                  return ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final category = categories[index];
                      final isSelected = category == selected;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () => controller.filterByCategory(category),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 260),
                            curve: Curves.easeOutCubic,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              gradient: isSelected ? MejlisPalette.goldGradient : null,
                              color: isSelected
                                  ? null
                                  : Theme.of(context).brightness == Brightness.dark
                                  ? scheme.surfaceContainerHigh
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? Colors.transparent
                                    : MejlisPalette.gold.withOpacity(0.35),
                              ),
                              boxShadow: isSelected
                                  ? [
                                BoxShadow(
                                  color: MejlisPalette.gold.withOpacity(0.35),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                )
                              ]
                                  : null,
                            ),
                            child: Text(
                              category,
                              style: TextStyle(
                                color: isSelected ? const Color(0xFF2A2104) : scheme.onSurface,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                }),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 8)),

            // ── Product grid ──
            Obx(() {
              if (controller.isLoading.value) {
                return const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator.adaptive()),
                );
              }

              final products = controller.filteredProducts;
              if (products.isEmpty) {
                return SliverFillRemaining(
                  hasScrollBody: false,
                  child: AppEmptyState(
                    icon: Icons.storefront_outlined,
                    title: 'No products available'.tr,
                    subtitle: 'Check back soon — new items are added regularly.'.tr,
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.7,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  delegate: SliverChildBuilderDelegate(
                        (context, index) {
                      final product = products[index];
                      return CustomerProductCard(
                        product: product,
                      ).animate().fadeIn(delay: (30 * index).ms, duration: 250.ms);
                    },
                    childCount: products.length,
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

/// "Follow Our Channels" — horizontal brand chips that deep-link into the
/// Media Hub on the matching tab.
class _MediaChannelsStrip extends StatelessWidget {
  const _MediaChannelsStrip();

  static const Map<String, FaIconData> _icons = {
    'youtube': FontAwesomeIcons.youtube,
    'tiktok': FontAwesomeIcons.tiktok,
    'instagram': FontAwesomeIcons.instagram,
    'facebook': FontAwesomeIcons.facebook,
    'telegram': FontAwesomeIcons.telegram,
  };

  Color _color(String id) {
    switch (id) {
      case 'youtube':
        return const Color(0xFFFF0000);
      case 'tiktok':
        return const Color(0xFF111111);
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

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GoldSectionHeader(
          title: 'followOurChannels'.tr,
          subtitle: 'mediaHubSubtitle'.tr,
          icon: Icons.smart_display_rounded,
          trailing: IconButton(
            tooltip: 'openMediaHub'.tr,
            onPressed: () => Get.toNamed(AppRoutes.mediaHub),
            icon: const Icon(Icons.arrow_forward_rounded, color: MejlisPalette.goldDark, size: 20),
          ),
        ),
        SizedBox(
          height: 68,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            physics: const BouncingScrollPhysics(),
            children: [
              _ChannelChip(
                icon: Icon(Icons.storefront_rounded, size: 19, color: MejlisPalette.emerald),
                label: 'storeFeed'.tr,
                onTap: () => Get.toNamed(AppRoutes.mediaHub),
              ).mejlisEnter(delayMs: 0),
              ..._icons.keys.map(
                    (id) => _ChannelChip(
                  icon: FaIcon(_icons[id]!, size: 18, color: _color(id)),
                  label: id.substring(0, 1).toUpperCase() + id.substring(1),
                  onTap: () => Get.toNamed(AppRoutes.mediaHub, arguments: {'tab': id}),
                ).mejlisEnter(delayMs: 40),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ChannelChip extends StatelessWidget {
  final Widget icon;
  final String label;
  final VoidCallback onTap;

  const _ChannelChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: MejlisPalette.gold.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            icon,
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Keeps [child] hidden (and taking no space) for [delay], then fades it in
/// while its height smoothly expands, so the content below slides down
/// instead of jumping.
class DelayedReveal extends StatefulWidget {
  final Duration delay;
  final Widget child;

  const DelayedReveal({
    super.key,
    required this.child,
    this.delay = const Duration(seconds: 3),
  });

  @override
  State<DelayedReveal> createState() => _DelayedRevealState();
}

class _DelayedRevealState extends State<DelayedReveal> {
  Timer? _timer;
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer(widget.delay, () {
      if (mounted) setState(() => _visible = true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOut,
        opacity: _visible ? 1 : 0,
        // Offstage = built (so images/data can preload) but takes no space
        // and isn't painted until the delay is over.
        child: Offstage(offstage: !_visible, child: widget.child),
      ),
    );
  }
}