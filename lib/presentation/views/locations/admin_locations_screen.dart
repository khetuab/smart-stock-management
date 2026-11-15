import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import '../../../app/themes/app_theme.dart';
import '../../../data/models/store_location_model.dart';
import '../../controllers/locations_controller.dart';
import '../../widgets/ethiopia_map_widget.dart';
import '../../widgets/maps_location_picker.dart';
import '../../widgets/mejlis_kit.dart';

/// Admin — manage the branches pinned on the illustrated Ethiopia map.
/// Saves into the new 'StoreLocations' Google Sheet (purely additive).
class AdminLocationsScreen extends StatelessWidget {
  const AdminLocationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(LocationsController(), permanent: true);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showLocationForm(context, controller),
        icon: const Icon(Icons.add_location_alt_rounded),
        label: Text('addLocation'.tr),
        backgroundColor: MejlisPalette.gold,
        foregroundColor: const Color(0xFF2A2104),
      ),
      body: RefreshIndicator(
        onRefresh: controller.loadLocations,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          slivers: [
            SliverAppBar(
              pinned: true,
              expandedHeight: 190,
              backgroundColor: scheme.primary,
              iconTheme: const IconThemeData(color: Colors.white),
              flexibleSpace: FlexibleSpaceBar(
                centerTitle: false,
                titlePadding: const EdgeInsets.only(left: 56, bottom: 14),
                title: Text(
                  'storeLocations'.tr,
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
                    DecoratedBox(
                      decoration: BoxDecoration(gradient: MejlisPalette.emeraldGradient),
                    ),
                    CustomPaint(
                      painter: ArabesquePainter(lineColor: Colors.white, opacity: 0.09),
                    ),
                    const Positioned(
                      top: 10,
                      right: 24,
                      child: HangingLantern(size: 26),
                    ),
                    Positioned(
                      left: 20,
                      right: 20,
                      bottom: 46,
                      child: Text(
                        'storeLocationsSubtitle'.tr,
                        style: const TextStyle(color: Colors.white70, fontSize: 12.5),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Obx(() {
                  if (controller.isLoading.value && controller.locations.isEmpty) {
                    return const SizedBox(
                      height: 300,
                      child: Center(child: CircularProgressIndicator.adaptive()),
                    );
                  }
                  if (controller.locations.isEmpty) {
                    return MejlisCard(
                      child: Column(
                        children: [
                          Icon(Icons.info_outline_rounded, color: MejlisPalette.gold, size: 34),
                          const SizedBox(height: 10),
                          Text(
                            'noLocationsSaved'.tr,
                            textAlign: TextAlign.center,
                            style: TextStyle(fontWeight: FontWeight.w700, color: scheme.onSurface),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'mockLocationsShownHint'.tr,
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12.5, color: scheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    );
                  }
                  return Column(
                    children: [
                      for (int i = 0; i < controller.locations.length; i++)
                        _LocationTile(
                          location: controller.locations[i],
                          onEdit: () => _showLocationForm(context, controller, existing: controller.locations[i]),
                        ).mejlisEnter(delayMs: i * 50),
                    ],
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLocationForm(BuildContext context, LocationsController controller, {StoreLocation? existing}) {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final cityCtrl = TextEditingController(text: existing?.city ?? '');
    final regionCtrl = TextEditingController(text: existing?.region ?? '');
    final phoneCtrl = TextEditingController(text: existing?.phone ?? '');
    final hoursCtrl = TextEditingController(text: existing?.hours ?? '');
    final addressCtrl = TextEditingController(text: existing?.address ?? '');
    final latCtrl = TextEditingController(text: existing?.lat.toString() ?? '');
    final lngCtrl = TextEditingController(text: existing?.lng.toString() ?? '');
    final isMain = (existing?.isMain ?? false).obs;

    // Decimal + negative-friendly keyboard for coordinates.
    const coordKeyboard = TextInputType.numberWithOptions(decimal: true, signed: true);

    Get.bottomSheet(
      // Lifts the whole sheet above the keyboard while typing.
      Builder(
        builder: (sheetContext) => AnimatedPadding(
          duration: const Duration(milliseconds: 150),
          padding: EdgeInsets.only(bottom: MediaQuery.of(sheetContext).viewInsets.bottom),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.88,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 42,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 14),
                        decoration: BoxDecoration(
                          color: MejlisPalette.gold.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Text(
                      existing == null ? 'addLocation'.tr : 'editLocation'.tr,
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 16),

                    // City presets — one tap fills an approximate lat/lng
                    Text('quickPickCity'.tr, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 38,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: kCityPresets.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, i) {
                          final preset = kCityPresets[i];
                          return ActionChip(
                            label: Text(preset['city']!, style: const TextStyle(fontSize: 12)),
                            backgroundColor: MejlisPalette.emerald.withOpacity(0.08),
                            side: BorderSide(color: MejlisPalette.emerald.withOpacity(0.3)),
                            onPressed: () {
                              cityCtrl.text = preset['city']!;
                              regionCtrl.text = preset['region']!;
                              latCtrl.text = preset['lat']!;
                              lngCtrl.text = preset['lng']!;
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 14),

                    // NEW — exact point from Google Maps / GPS
                    MapsLocationPicker(
                      latCtrl: latCtrl,
                      lngCtrl: lngCtrl,
                      nameCtrl: nameCtrl,
                      cityCtrl: cityCtrl,
                    ),
                    const SizedBox(height: 14),

                    _Field(controller: nameCtrl, label: 'branchName'.tr, icon: Icons.store_rounded),
                    const SizedBox(height: 10),
                    Row(children: [
                      Expanded(child: _Field(controller: cityCtrl, label: 'city'.tr, icon: Icons.location_city_rounded)),
                      const SizedBox(width: 10),
                      Expanded(child: _Field(controller: regionCtrl, label: 'region'.tr, icon: Icons.map_rounded)),
                    ]),
                    const SizedBox(height: 10),
                    Row(children: [
                      Expanded(child: _Field(controller: latCtrl, label: 'latitude'.tr, icon: Icons.north_rounded, keyboard: coordKeyboard)),
                      const SizedBox(width: 10),
                      Expanded(child: _Field(controller: lngCtrl, label: 'longitude'.tr, icon: Icons.east_rounded, keyboard: coordKeyboard)),
                    ]),
                    const SizedBox(height: 10),
                    _Field(controller: phoneCtrl, label: 'phone'.tr, icon: Icons.call_rounded, keyboard: TextInputType.phone),
                    const SizedBox(height: 10),
                    _Field(controller: hoursCtrl, label: 'openingHours'.tr, icon: Icons.schedule_rounded),
                    const SizedBox(height: 10),
                    _Field(controller: addressCtrl, label: 'address'.tr, icon: Icons.pin_drop_rounded, maxLines: 2),
                    const SizedBox(height: 8),

                    Obx(() => SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: Text('mainBranch'.tr),
                      subtitle: Text('mainBranchHint'.tr, style: const TextStyle(fontSize: 12)),
                      value: isMain.value,
                      activeColor: MejlisPalette.gold,
                      onChanged: (v) => isMain.value = v,
                    )),

                    const SizedBox(height: 16),
                    MejlisGoldButton(
                      label: existing == null ? 'addLocation'.tr : 'saveChanges'.tr,
                      icon: Icons.check_rounded,
                      onTap: () {
                        final lat = double.tryParse(latCtrl.text.trim());
                        final lng = double.tryParse(lngCtrl.text.trim());
                        final name = nameCtrl.text.trim();
                        final city = cityCtrl.text.trim();

                        if (name.isEmpty || city.isEmpty || lat == null || lng == null) {
                          Get.snackbar('Missing info', 'fillAllLocationFields'.tr,
                              colorText: Colors.red, snackPosition: SnackPosition.BOTTOM);
                          return;
                        }
                        if (!EthiopiaProjection.isInsideEthiopia(lat, lng)) {
                          Get.snackbar('Outside Ethiopia', 'coordinatesOutsideEthiopia'.tr,
                              colorText: Colors.red, snackPosition: SnackPosition.BOTTOM);
                          return;
                        }

                        if (existing == null) {
                          controller.addLocation(
                            name: name,
                            city: city,
                            region: regionCtrl.text.trim(),
                            lat: lat,
                            lng: lng,
                            phone: phoneCtrl.text.trim(),
                            hours: hoursCtrl.text.trim(),
                            address: addressCtrl.text.trim(),
                            isMain: isMain.value,
                          );
                        } else {
                          controller.updateLocation(existing.copyWith(
                            name: name,
                            city: city,
                            region: regionCtrl.text.trim(),
                            lat: lat,
                            lng: lng,
                            phone: phoneCtrl.text.trim(),
                            hours: hoursCtrl.text.trim(),
                            address: addressCtrl.text.trim(),
                            isMain: isMain.value,
                          ));
                        }
                        Get.back();
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }
}

class _LocationTile extends StatelessWidget {
  final StoreLocation location;
  final VoidCallback onEdit;

  const _LocationTile({required this.location, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final controller = Get.find<LocationsController>();

    return MejlisCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: location.isMain ? MejlisPalette.goldGradient : null,
              color: location.isMain ? null : MejlisPalette.emerald.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              location.isMain ? Icons.star_rounded : Icons.store_rounded,
              color: location.isMain ? const Color(0xFF2A2104) : MejlisPalette.emerald,
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
                        location.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontWeight: FontWeight.w700, color: scheme.onSurface, fontSize: 14.5),
                      ),
                    ),
                    if (location.isMain) ...[
                      const SizedBox(width: 6),
                      const GoldBadge(label: 'HQ'),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  // 4 decimals ≈ 11 m, so two nearby branches stay distinguishable
                  '${location.city}${location.region.isNotEmpty ? ', ${location.region}' : ''} · ${location.lat.toStringAsFixed(4)}, ${location.lng.toStringAsFixed(4)}',
                  style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_rounded, size: 20),
            color: scheme.primary,
            onPressed: onEdit,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, size: 20),
            color: scheme.error,
            onPressed: () => controller.deleteLocation(location),
          ),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType keyboard;
  final int maxLines;

  const _Field({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboard = TextInputType.text,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboard,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label.tr,
        prefixIcon: Icon(icon, size: 19),
      ),
    );
  }
}

/// One-tap coordinate presets for major Ethiopian cities (city centre —
/// use the Google Maps picker above for the exact shop position).
const List<Map<String, String>> kCityPresets = [
  {'city': 'Addis Ababa', 'region': 'Addis Ababa', 'lat': '9.0305', 'lng': '38.7449'},
  {'city': 'Adama', 'region': 'Oromia', 'lat': '8.5408', 'lng': '39.2708'},
  {'city': 'Dire Dawa', 'region': 'Dire Dawa', 'lat': '9.5931', 'lng': '41.8661'},
  {'city': 'Bahir Dar', 'region': 'Amhara', 'lat': '11.5936', 'lng': '37.3908'},
  {'city': 'Gondar', 'region': 'Amhara', 'lat': '12.6095', 'lng': '37.4664'},
  {'city': 'Mekelle', 'region': 'Tigray', 'lat': '13.4967', 'lng': '39.4753'},
  {'city': 'Hawassa', 'region': 'Sidama', 'lat': '7.0608', 'lng': '38.4784'},
  {'city': 'Jimma', 'region': 'Oromia', 'lat': '7.6751', 'lng': '36.8336'},
  {'city': 'Dessie', 'region': 'Amhara', 'lat': '11.1333', 'lng': '39.6333'},
  {'city': 'Jijiga', 'region': 'Somali', 'lat': '9.3500', 'lng': '42.8000'},
  {'city': 'Arba Minch', 'region': 'South Ethiopia', 'lat': '6.0333', 'lng': '37.5500'},
  {'city': 'Bale Robe', 'region': 'Oromia', 'lat': '7.1167', 'lng': '40.0000'},
  {'city': 'Harar', 'region': 'Harari', 'lat': '9.3114', 'lng': '42.1281'},
  {'city': 'Nekemte', 'region': 'Oromia', 'lat': '9.0878', 'lng': '36.5500'},
  {'city': 'Assosa', 'region': 'Benishangul-Gumuz', 'lat': '10.0667', 'lng': '34.5333'},
  {'city': 'Semera', 'region': 'Afar', 'lat': '11.7936', 'lng': '40.9958'},
  {'city': 'Gambela', 'region': 'Gambela', 'lat': '8.2500', 'lng': '34.5833'},
  {'city': 'Moyale', 'region': 'Oromia', 'lat': '3.5269', 'lng': '39.0544'},
  {'city': 'Woldia', 'region': 'Amhara', 'lat': '11.8333', 'lng': '39.6167'},
  {'city': 'Shashamane', 'region': 'Oromia', 'lat': '7.2000', 'lng': '38.6000'},
];