import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import '../../../app/themes/app_theme.dart';
import '../../../data/models/store_location_model.dart';
import '../../controllers/contact_controller.dart';
import '../../controllers/locations_controller.dart';
import '../../controllers/social_links_controller.dart';
import '../../widgets/ethiopia_map_widget.dart';
import '../../widgets/mejlis_kit.dart';

/// ─────────────────────────────────────────────────────────────────────────
///  CONTACT US — "Talk to the Mejlis"
///
///  • Animated illustrated Ethiopia map with the live branch pins.
///  • ALL registered branches listed as cards (HQ first): call, directions
///    and "show on map" in one tap each. Tapping a card — or a pin on the
///    map — sends the map camera to that branch.
///  • Phone / WhatsApp / Telegram quick-contact strip.
///  • Direct email form (prefilled mailto + archived to ContactMessages
///    sheet so the owner can read messages in the admin inbox).
/// ─────────────────────────────────────────────────────────────────────────
class ContactUsScreen extends StatefulWidget {
  const ContactUsScreen({super.key});

  @override
  State<ContactUsScreen> createState() => _ContactUsScreenState();
}

class _ContactUsScreenState extends State<ContactUsScreen> {
  String? _selectedId;
  final GlobalKey _mapKey = GlobalKey();

  /// Select a branch (the map camera flies to it) and scroll the map into view.
  void _showOnMap(StoreLocation loc) {
    setState(() => _selectedId = loc.id);
    final ctx = _mapKey.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 550),
        curve: Curves.easeInOutCubic,
        alignment: 0.05,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ContactController(), permanent: true);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: CustomScrollView(
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
                'contactUs'.tr,
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
                  const MejlisHeaderBackground(showSkyline: true),
                  Positioned(
                    left: 20,
                    right: 20,
                    bottom: 46,
                    child: Text(
                      'contactUsSubtitle'.tr,
                      style: const TextStyle(color: Colors.white70, fontSize: 12.5),
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Illustrated map ──
                  GoldSectionHeader(
                    title: 'visitOurShowrooms'.tr,
                    subtitle: 'tapAPinToSeeBranchDetails'.tr,
                    icon: Icons.map_rounded,
                  ).mejlisEnter(delayMs: 0),

                  SizedBox(
                    key: _mapKey,
                    height: 330,
                    child: Obx(() {
                      final locations = LocationsController.to.displayLocations;
                      return MejlisCard(
                        padding: EdgeInsets.zero,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: EthiopiaMapWidget(
                            locations: locations,
                            compact: false,
                            selectedId: _selectedId,
                            onSelect: (loc) => setState(() => _selectedId = loc.id),
                          ),
                        ),
                      );
                    }),
                  ).mejlisEnter(delayMs: 60),

                  const SizedBox(height: 22),

                  // ── All registered branches ──
                  Obx(() {
                    final all = [...LocationsController.to.displayLocations]
                      ..sort((a, b) => (b.isMain ? 1 : 0) - (a.isMain ? 1 : 0));
                    if (all.isEmpty) return const SizedBox.shrink();

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GoldSectionHeader(
                          title: 'Our Branches'.tr,
                          subtitle: '${all.length} ${'branches'.tr}',
                          icon: Icons.store_mall_directory_rounded,
                        ).mejlisEnter(delayMs: 80),
                        for (int i = 0; i < all.length; i++)
                          _BranchCard(
                            location: all[i],
                            selected: all[i].id == _selectedId,
                            onShowOnMap: () => _showOnMap(all[i]),
                            onCall: all[i].phone.isEmpty
                                ? null
                                : () => controller.callNumber(all[i].phone),
                            onDirections: () => controller.openDirections(all[i]),
                          ).mejlisEnter(delayMs: 100 + i * 50),
                      ],
                    );
                  }),

                  const SizedBox(height: 14),

                  // ── Quick contact strip ──
                  GoldSectionHeader(
                    title: 'directContact'.tr,
                    icon: Icons.headset_mic_rounded,
                  ).mejlisEnter(delayMs: 100),
                  Obx(() {
                    final social = SocialLinksController.to;
                    final loc = LocationsController.to.mainBranch;
                    return Row(
                      children: [
                        if (loc != null && loc.phone.isNotEmpty)
                          Expanded(
                            child: _ContactTile(
                              icon: Icons.call_rounded,
                              label: 'callUs'.tr,
                              value: loc.phone,
                              onTap: () => controller.callNumber(loc.phone),
                            ).mejlisEnter(delayMs: 120),
                          ),
                        if (loc != null && loc.phone.isNotEmpty) const SizedBox(width: 10),
                        if (social.whatsapp.value.isNotEmpty)
                          Expanded(
                            child: _ContactTile(
                              icon: Icons.chat_rounded,
                              label: 'whatsapp'.tr,
                              value: 'chatWithUs'.tr,
                              onTap: () => controller.openWhatsApp(social.whatsapp.value),
                            ).mejlisEnter(delayMs: 160),
                          ),
                        if (social.whatsapp.value.isNotEmpty) const SizedBox(width: 10),
                        if (social.telegram.value.isNotEmpty)
                          Expanded(
                            child: _ContactTile(
                              icon: Icons.send_rounded,
                              label: 'telegram'.tr,
                              value: 'chatWithUs'.tr,
                              onTap: () => controller.openTelegram(social.telegram.value),
                            ).mejlisEnter(delayMs: 200),
                          ),
                      ],
                    );
                  }),

                  const SizedBox(height: 26),
                  Center(child: OrnamentDivider(width: 190)),
                  const SizedBox(height: 20),

                  // ── Email form ──
                  GoldSectionHeader(
                    title: 'sendUsMessage'.tr,
                    subtitle: 'emailFormHint'.tr,
                    icon: Icons.mail_rounded,
                  ).mejlisEnter(delayMs: 280),

                  Obx(() {
                    if (controller.isSent.value) {
                      return MejlisCard(
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: const BoxDecoration(
                                gradient: MejlisPalette.goldGradient,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.check_rounded, color: Color(0xFF2A2104), size: 30),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              'messageSent'.tr,
                              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: scheme.onSurface),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'messageSentHint'.tr,
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 12.5, color: scheme.onSurfaceVariant),
                            ),
                            const SizedBox(height: 14),
                            TextButton(
                              onPressed: () => controller.clearForm(),
                              child: Text('sendAnother'.tr),
                            ),
                          ],
                        ),
                      ).mejlisEnter();
                    }

                    return MejlisCard(
                      child: Obx(() => Column(
                        children: [
                          _LabeledField(
                            label: 'yourName'.tr,
                            icon: Icons.person_rounded,
                            error: controller.nameError.value,
                            onChanged: (v) => controller.name.value = v,
                          ),
                          const SizedBox(height: 12),
                          _LabeledField(
                            label: 'yourEmail'.tr,
                            icon: Icons.alternate_email_rounded,
                            keyboard: TextInputType.emailAddress,
                            error: controller.emailError.value,
                            onChanged: (v) => controller.email.value = v,
                          ),
                          const SizedBox(height: 12),
                          _LabeledField(
                            label: 'yourPhone'.tr,
                            icon: Icons.call_rounded,
                            keyboard: TextInputType.phone,
                            optional: true,
                            onChanged: (v) => controller.phone.value = v,
                          ),
                          const SizedBox(height: 12),
                          _LabeledField(
                            label: 'subject'.tr,
                            icon: Icons.title_rounded,
                            optional: true,
                            onChanged: (v) => controller.subject.value = v,
                          ),
                          const SizedBox(height: 12),
                          _LabeledField(
                            label: 'message'.tr,
                            icon: Icons.message_rounded,
                            maxLines: 4,
                            error: controller.messageError.value,
                            onChanged: (v) => controller.message.value = v,
                          ),
                          const SizedBox(height: 18),
                          controller.isSending.value
                              ? const Center(child: CircularProgressIndicator.adaptive())
                              : MejlisGoldButton(
                            label: 'sendMessage'.tr,
                            icon: Icons.send_rounded,
                            onTap: controller.sendMessage,
                          ),
                        ],
                      )),
                    ).mejlisEnter(delayMs: 320);
                  }),

                  const SizedBox(height: 20),

                  Text(
                    'weReplyWithin24h'.tr,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontStyle: FontStyle.italic,
                      color: scheme.onSurfaceVariant,
                    ),
                  ).mejlisEnter(delayMs: 360),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// One registered branch: name, place, address, hours + 3 quick actions.
class _BranchCard extends StatelessWidget {
  final StoreLocation location;
  final bool selected;
  final VoidCallback onShowOnMap;
  final VoidCallback? onCall; // null when the branch has no phone
  final VoidCallback onDirections;

  const _BranchCard({
    required this.location,
    required this.selected,
    required this.onShowOnMap,
    required this.onCall,
    required this.onDirections,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final loc = location;
    final place = [loc.city, loc.region].where((s) => s.isNotEmpty).join(', ');

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        boxShadow: selected
            ? [
          BoxShadow(
            color: MejlisPalette.gold.withOpacity(0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ]
            : null,
        border: Border.all(
          color: selected ? MejlisPalette.gold : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: MejlisCard(
        padding: const EdgeInsets.all(14),
        child: InkWell(
          onTap: onShowOnMap,
          borderRadius: BorderRadius.circular(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: loc.isMain ? MejlisPalette.goldGradient : null,
                      color: loc.isMain ? null : MejlisPalette.emerald.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(
                      loc.isMain ? Icons.star_rounded : Icons.store_rounded,
                      color: loc.isMain ? const Color(0xFF2A2104) : MejlisPalette.emerald,
                      size: 22,
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
                                  fontSize: 14.5,
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
                        if (place.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            place,
                            style: TextStyle(fontSize: 12.5, color: scheme.onSurfaceVariant),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              if (loc.address.isNotEmpty) ...[
                const SizedBox(height: 10),
                _InfoRow(icon: Icons.location_on_rounded, text: loc.address),
              ],
              if (loc.hours.isNotEmpty) ...[
                const SizedBox(height: 6),
                _InfoRow(icon: Icons.schedule_rounded, text: loc.hours),
              ],
              if (loc.phone.isNotEmpty) ...[
                const SizedBox(height: 6),
                _InfoRow(icon: Icons.call_rounded, text: loc.phone),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  if (onCall != null) ...[
                    Expanded(
                      child: _BranchAction(
                        icon: Icons.call_rounded,
                        label: 'callBranch'.tr,
                        onTap: onCall!,
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: _BranchAction(
                      icon: Icons.directions_rounded,
                      label: 'directions'.tr,
                      onTap: onDirections,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _BranchAction(
                      icon: Icons.map_rounded,
                      label: 'Show on map'.tr,
                      onTap: onShowOnMap,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Icon(icon, size: 15, color: MejlisPalette.goldDark),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 12.5, color: scheme.onSurfaceVariant),
          ),
        ),
      ],
    );
  }
}

class _BranchAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _BranchAction({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: MejlisPalette.emerald.withOpacity(0.08),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: MejlisPalette.emerald),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: MejlisPalette.emerald,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ContactTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  const _ContactTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          gradient: isDark
              ? const LinearGradient(colors: [
            Color(0xFF1B3760),
            Color(0xFF102442),
          ],)
              : const LinearGradient(colors: [Color(0xFFFFFDF7), Color(0xFFFBF5E8)]),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: MejlisPalette.gold.withOpacity(0.4)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                gradient: MejlisPalette.emeraldGradient,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 17, color: Colors.white),
            ),
            const SizedBox(height: 7),
            Text(
              label.tr,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: scheme.onSurface),
            ),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 9.5, color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _LabeledField extends StatelessWidget {
  final String label;
  final IconData icon;
  final TextInputType keyboard;
  final int maxLines;
  final bool optional;
  final String error;
  final ValueChanged<String> onChanged;

  const _LabeledField({
    required this.label,
    required this.icon,
    this.keyboard = TextInputType.text,
    this.maxLines = 1,
    this.optional = false,
    this.error = '',
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          keyboardType: keyboard,
          maxLines: maxLines,
          onChanged: onChanged,

          decoration: InputDecoration(
            labelText: optional ? '$label (${'optional'.tr})' : label.tr,
            prefixIcon: Icon(icon, size: 19),
            errorText: error.isEmpty ? null : error,
          ),
        ),
      ],
    );
  }
}