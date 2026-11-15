import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/themes/app_theme.dart';
import '../../controllers/islamic_controller.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../../widgets/mejlis_kit.dart';
import 'islamic_hub_body.dart';

/// Admin Islamic Center — full redesign of the Islamic features hub.
/// The heavy lifting (illustrated header, next-prayer countdown ring,
/// prayer pills, animated feature grid) lives in [IslamicHubBody] which
/// is shared with the customer variant so both stay identical.
class IslamicHubScreen extends GetView<IslamicController> {
  const IslamicHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<IslamicController>();
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      bottomNavigationBar: const BottomNavBar(currentIndex: 4),
      body: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 230,
            backgroundColor: scheme.primary,
            iconTheme: const IconThemeData(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: false,
              titlePadding: const EdgeInsets.only(left: 56, bottom: 14),
              title: Text(
                'islamicCenter'.tr,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                  shadows: [Shadow(color: Colors.black38, blurRadius: 8)],
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  const MejlisHeaderBackground(),
                  Positioned(
                    left: 20,
                    right: 20,
                    bottom: 46,
                    child: Obx(
                      () => Row(
                        children: [
                          const Icon(Icons.brightness_3_rounded, size: 15, color: MejlisPalette.goldLight),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              controller.hijriDate.value.isEmpty ? '…' : controller.hijriDate.value,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const IslamicHubBody(),
        ],
      ),
    );
  }
}
