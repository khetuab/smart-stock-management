import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../app/routes/app_routes.dart';
import '../../app/themes/app_theme.dart';
import '../../data/models/store_location_model.dart';
import '../controllers/locations_controller.dart';
import 'ethiopia_map_widget.dart';
import 'mejlis_kit.dart';

/// "Find Us Across Ethiopia" — the illustrated map section shown on the
/// customer home screen right below the promo banner. Pan & zoom the
/// country, tap any pin to reveal that branch's details, call or get
/// directions in one tap.
class LocationShowcaseWidget extends StatefulWidget {
  const LocationShowcaseWidget({super.key});

  @override
  State<LocationShowcaseWidget> createState() => _LocationShowcaseWidgetState();
}

class _LocationShowcaseWidgetState extends State<LocationShowcaseWidget> {
  String? _selectedId;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final controller = LocationsController.to;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GoldSectionHeader(
          title: 'findUsAcrossEthiopia',
          subtitle: 'tapAPinToSeeBranchDetails',
          icon: Icons.map_rounded,
          trailing: IconButton(
            tooltip: 'contactUs'.tr,
            onPressed: () => Get.toNamed(AppRoutes.contactUs),
            icon: Icon(Icons.headset_mic_rounded, color: MejlisPalette.gold),
          ),
        ).mejlisEnter(delayMs: 40),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: MejlisCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                SizedBox(
                  height: 380,
                  child: Obx(() {
                    final locations = controller.displayLocations;
                    if (controller.isLoading.value && locations.isEmpty) {
                      return const Center(
                        child: CircularProgressIndicator.adaptive(),
                      );
                    }
                    return EthiopiaMapWidget(
                      locations: locations,
                      selectedId: _selectedId,
                      onSelect: (loc) => setState(() => _selectedId = loc.id),
                    );
                  }),
                ),
                const Divider(height: 1),
                _LocationDetailCard(selectedId: _selectedId),
              ],
            ),
          ),
        ).mejlisEnter(delayMs: 120),

        const SizedBox(height: 8),
        Center(
          child: TextButton.icon(
            onPressed: () => Get.toNamed(AppRoutes.contactUs),
            icon: Icon(
              Icons.store_mall_directory_rounded,
              size: 18,
              color: scheme.primary,
            ),
            label: Text(
              'seeAllBranchesContactUs'.tr,
              style: TextStyle(
                color: scheme.primary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ).mejlisEnter(delayMs: 180),
      ],
    );
  }
}

class _LocationDetailCard extends StatelessWidget {
  final String? selectedId;
  const _LocationDetailCard({required this.selectedId});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final controller = LocationsController.to;

    return Obx(() {
      final all = controller.displayLocations;
      if (all.isEmpty) return const SizedBox.shrink();

      StoreLocation? selected;
      if (selectedId != null) {
        for (final l in all) {
          if (l.id == selectedId) {
            selected = l;
            break;
          }
        }
      }
      final loc = selected ?? controller.mainBranch ?? all.first;

      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: Theme.of(context).brightness == Brightness.dark
                ? const [
              Color(0xFF1B3760),
              Color(0xFF102442),
            ]
                : [Colors.white, const Color(0xFFFCF7EA)],
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: MejlisPalette.goldGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.store_rounded,
                    color: Color(0xFF2A2104),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              loc.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                                color: scheme.onSurface,
                              ),
                            ),
                          ),
                          if (loc.isMain) ...[
                            const SizedBox(width: 6),
                            const GoldBadge(label: 'HQ'),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        [
                          loc.city,
                          loc.region,
                        ].where((s) => s.isNotEmpty).join(', '),
                        style: TextStyle(
                          fontSize: 12.5,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (loc.address.isNotEmpty) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(
                    Icons.location_on_rounded,
                    size: 15,
                    color: MejlisPalette.goldDark,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      loc.address,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            if (loc.hours.isNotEmpty) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(
                    Icons.schedule_rounded,
                    size: 15,
                    color: MejlisPalette.goldDark,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      loc.hours,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 14),
            Row(
              children: [
                if (loc.phone.isNotEmpty)
                  Expanded(
                    child: _ActionTile(
                      icon: Icons.call_rounded,
                      label: 'callBranch'.tr,
                      onTap: () async {
                        final uri = Uri(scheme: 'tel', path: loc.phone);
                        if (await canLaunchUrl(uri)) launchUrl(uri);
                      },
                    ),
                  ),
                if (loc.phone.isNotEmpty) const SizedBox(width: 10),
                Expanded(
                  child: _ActionTile(
                    icon: Icons.directions_rounded,
                    label: 'directions'.tr,
                    onTap: () async {
                      final uri = Uri.parse(loc.mapsUrl);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(
                          uri,
                          mode: LaunchMode.externalApplication,
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: MejlisPalette.emerald.withOpacity(0.08),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 17, color: MejlisPalette.goldLight),
              const SizedBox(width: 7),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: MejlisPalette.gold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
