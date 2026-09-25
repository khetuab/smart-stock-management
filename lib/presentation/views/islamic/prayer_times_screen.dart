import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/islamic_controller.dart';
import '../../widgets/app_kits_collection.dart';
import '../../widgets/islamic_sliver_appbar.dart';

class PrayerTimesScreen extends GetView<IslamicController> {
  const PrayerTimesScreen({super.key});

  static const _prayerNames = ['Fajr', 'Sunrise', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];
  static const _prayerIcons = [
    Icons.wb_twilight_rounded,
    Icons.wb_sunny_rounded,
    Icons.wb_sunny_rounded,
    Icons.wb_sunny_outlined,
    Icons.wb_twilight_rounded,
    Icons.nights_stay_rounded,
  ];

  /// Returns the index of the next upcoming prayer by comparing each
  /// time against the clock right now — replaces the previous hardcoded
  /// "index == 0 // For demo" placeholder, which never actually reflected
  /// the current time of day.
  int? _nextPrayerIndex(Map<String, String> times) {
    final now = TimeOfDay.now();
    final nowMinutes = now.hour * 60 + now.minute;
    int? best;
    int bestDelta = 24 * 60;
    for (int i = 0; i < _prayerNames.length; i++) {
      final raw = times[_prayerNames[i]];
      if (raw == null) continue;
      final parts = raw.split(':');
      if (parts.length < 2) continue;
      final h = int.tryParse(parts[0]) ?? 0;
      final m = int.tryParse(parts[1]) ?? 0;
      final minutes = h * 60 + m;
      final delta = minutes - nowMinutes;
      if (delta >= 0 && delta < bestDelta) {
        bestDelta = delta;
        best = i;
      }
    }
    return best;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Obx(() {
        final nextIdx = _nextPrayerIndex(controller.prayerTimes);
        final nextLabel = nextIdx != null
            ? '${_prayerNames[nextIdx]} · ${controller.prayerTimes[_prayerNames[nextIdx]]}'
            : null;

        return CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          slivers: [
            IslamicSliverAppBar(
              title: 'prayerTimes'.tr,
              icon: Icons.wb_twilight_rounded,
              trailing: nextLabel != null
                  ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${'nextPrayer'.tr} · $nextLabel',
                  style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w700),
                ),
              )
                  : null,
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                  onPressed: controller.fetchPrayerTimes,
                ),
                const SizedBox(width: 8),
              ],
            ),

            if (controller.isLoading.value)
              const SliverFillRemaining(child: Center(child: CircularProgressIndicator.adaptive()))
            else if (controller.prayerTimes.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AppEmptyState(
                        icon: Icons.access_time_rounded,
                        title: 'loadingPrayerTimes'.tr,
                        subtitle: controller.errorMessage.value,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(onPressed: controller.fetchPrayerTimes, child: Text('retry'.tr)),
                    ],
                  ),
                ),
              )
            else ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                    child: Row(
                      children: [
                        Icon(Icons.location_on_rounded, color: scheme.primary, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            controller.currentLocation.value.isNotEmpty
                                ? controller.currentLocation.value
                                : 'loadingLocation'.tr,
                            style: TextStyle(fontSize: 12.5, color: scheme.onSurfaceVariant),
                          ),
                        ),
                        Text(
                          DateTime.now().toLocal().toString().split(' ')[0],
                          style: TextStyle(fontSize: 11.5, color: scheme.onSurfaceVariant.withOpacity(0.7)),
                        ),
                      ],
                    ),
                  ),
                ),
                // prayer_times_screen.dart — inside the SliverToBoxAdapter that shows location

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                    child: Column(
                      children: [
                        TextField(
                          onChanged: controller.searchCity,
                          decoration: InputDecoration(
                            hintText: 'searchCityHint'.tr, // e.g. "Search city..."
                            prefixIcon: const Icon(Icons.search_rounded),
                            suffixIcon: controller.isManualLocation.value
                                ? IconButton(
                              icon: const Icon(Icons.my_location_rounded),
                              onPressed: controller.useCurrentLocation,
                              tooltip: 'useCurrentLocation'.tr,
                            )
                                : null,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            isDense: true,
                          ),
                        ),
                        Obx(() {
                          if (controller.citySuggestions.isEmpty) return const SizedBox.shrink();
                          return Container(
                            margin: const EdgeInsets.only(top: 4),
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Theme.of(context).dividerColor),
                            ),
                            child: ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: controller.citySuggestions.length,
                              separatorBuilder: (_, __) => const Divider(height: 1),
                              itemBuilder: (context, i) {
                                final s = controller.citySuggestions[i];
                                return ListTile(
                                  dense: true,
                                  leading: const Icon(Icons.location_city_rounded, size: 20),
                                  title: Text(s.displayName, style: const TextStyle(fontSize: 13)),
                                  onTap: () => controller.selectCity(s),
                                );
                              },
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                  sliver: SliverList.separated(
                    itemCount: _prayerNames.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final name = _prayerNames[index];
                      final icon = _prayerIcons[index];
                      final time = controller.prayerTimes[name] ?? '--:--';
                      final isNext = index == nextIdx;

                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isNext ? scheme.primary.withOpacity(0.10) : Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isNext ? scheme.primary.withOpacity(0.35) : Theme.of(context).dividerColor,
                          ),
                          boxShadow: isNext
                              ? [BoxShadow(color: scheme.primary.withOpacity(0.15), blurRadius: 12, offset: const Offset(0, 4))]
                              : null,
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(color: scheme.primary.withOpacity(0.12), shape: BoxShape.circle),
                              child: Icon(icon, color: scheme.primary, size: 22),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: isNext ? FontWeight.bold : FontWeight.w600,
                                      color: isNext ? scheme.primary : scheme.onSurface,
                                    ),
                                  ),
                                  if (isNext)
                                    Text('nextPrayer'.tr,
                                        style: TextStyle(fontSize: 11, color: scheme.primary, fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                            Text(
                              time,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: isNext ? scheme.primary : scheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.info_outline_rounded, size: 14, color: scheme.onSurfaceVariant),
                        const SizedBox(width: 8),
                        Text('prayerTimesLocationNote'.tr,
                            style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
                      ],
                    ),
                  ),
                ),
              ],
          ],
        );
      }),
    );
  }
}