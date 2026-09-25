import 'dart:async';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import '../../data/models/promotion_model.dart';
import '../controllers/promotion_controller.dart';

/// Auto-scrolling banner carousel shown at the top of CustomerHomeScreen.
/// Renders nothing at all when there are no live promotions — no empty
/// placeholder taking up space.
class PromotionBannerCarousel extends StatefulWidget {
  const PromotionBannerCarousel({super.key});

  @override
  State<PromotionBannerCarousel> createState() => _PromotionBannerCarouselState();
}

class _PromotionBannerCarouselState extends State<PromotionBannerCarousel> {
  final PageController _pageController = PageController();
  Timer? _timer;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 10), (_) {
      final banners = PromotionController.to.liveBanners;
      if (banners.isEmpty || !_pageController.hasClients) return;
      _currentIndex = (_currentIndex + 1) % banners.length;
      _pageController.animateToPage(
        _currentIndex,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final banners = PromotionController.to.liveBanners;
      if (banners.isEmpty) return const SizedBox.shrink();

      // Account for left and right padding (8 + 8 = 16) to make the container square
      final squareDimension = MediaQuery.of(context).size.width - 16;

      return Padding(
        padding: const EdgeInsets.fromLTRB(8, 12, 8, 4),
        child: Column(
          children: [
            SizedBox(
              height: squareDimension,
              width: squareDimension,
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (i) => setState(() => _currentIndex = i),
                itemCount: banners.length,
                itemBuilder: (context, index) {
                  final promo = banners[index];

                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    PromotionController.to.trackView(promo);
                  });

                  return _BannerCard(promo: promo);
                },
              ),
            ),
            if (banners.length > 1) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(banners.length, (i) {
                  final active = i == _currentIndex;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: active ? 18 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: active
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).dividerColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
            ],
          ],
        ),
      );
    });
  }
}

class _BannerCard extends StatelessWidget {
  final PromotionModel promo;
  const _BannerCard({required this.promo});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => PromotionController.to.handleTap(promo),
        child: Stack(
          fit: StackFit.expand,
          children: [
            promo.imageUrl.isNotEmpty
                ? Image.network(
              promo.imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  Container(color: scheme.surfaceContainerHighest),
            )
                : Container(color: scheme.primary.withOpacity(0.15)),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withOpacity(0.65)],
                    stops: const [0.4, 1.0],
                  ),
                ),
              ),
            ),
            if (promo.hasDiscount)
              Positioned(
                top: 10,
                left: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: scheme.error,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${promo.discountPercentage.toStringAsFixed(0)}% OFF',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
            Positioned(
              left: 14,
              right: 14,
              bottom: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    promo.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  if (promo.description.isNotEmpty)
                    Text(
                      promo.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                ],
              ),
            ),
            if (promo.linkType != 'none')
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: promo.linkColor, shape: BoxShape.circle),
                  // Fix: Use FaIcon instead of Icon casting
                  child: FaIcon(promo.linkIcon as FaIconData?, size: 14, color: Colors.white),
                ),
              ),
          ],
        ),
      ),
    );
  }
}