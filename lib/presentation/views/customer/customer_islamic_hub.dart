import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_stock/presentation/widgets/customer_bottom_nar_bar.dart';
import '../../../app/themes/app_theme.dart';
import '../../controllers/islamic_controller.dart';
import '../../widgets/mejlis_kit.dart';
import '../islamic/islamic_hub_body.dart';

/// Customer Islamic Center — identical experience to the admin hub, with
/// the customer bottom navigation. See [IslamicHubBody] for the redesign.
class IslamicHubScreenc extends GetView<IslamicController> {
  const IslamicHubScreenc({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<IslamicController>();
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      bottomNavigationBar: const CustomerBottomNavBar(currentIndex: 4),
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
