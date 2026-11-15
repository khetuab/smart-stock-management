import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/themes/app_theme.dart';
import '../../controllers/social_links_controller.dart';

class AdminSocialLinksScreen extends StatefulWidget {
  const AdminSocialLinksScreen({super.key});

  @override
  State<AdminSocialLinksScreen> createState() => _AdminSocialLinksScreenState();
}

class _AdminSocialLinksScreenState extends State<AdminSocialLinksScreen> {
  bool _obscureApiKey = true;

  // WhatsApp stays a single number.
  late final TextEditingController whatsappCtrl;
  late final TextEditingController youtubeHandleCtrl;
  late final TextEditingController youtubeApiKeyCtrl;

  // Every other platform supports several links.
  late final _LinkList youtubeList, telegramList, instagramList, facebookList, tiktokList;
  late final _LinkList tiktokFeedList, instagramFeedList, facebookFeedList;

  @override
  void initState() {
    super.initState();
    final controller = SocialLinksController.to;

    whatsappCtrl = TextEditingController(
      text: controller.whatsapp.value.isNotEmpty ? controller.whatsapp.value : 'https://wa.me/',
    );

    youtubeList = _LinkList('https://youtube.com/', controller.youtube.value);
    telegramList = _LinkList('https://t.me/', controller.telegram.value);
    instagramList = _LinkList('https://instagram.com/', controller.instagram.value);
    facebookList = _LinkList('https://facebook.com/', controller.facebook.value);
    tiktokList = _LinkList('https://tiktok.com/@', controller.tiktok.value);

    tiktokFeedList = _LinkList('https://', controller.tiktokFeed.value);
    instagramFeedList = _LinkList('https://', controller.instagramFeed.value);
    facebookFeedList = _LinkList('https://', controller.facebookFeed.value);

    youtubeHandleCtrl = TextEditingController(text: controller.youtubeHandle.value);
    youtubeApiKeyCtrl = TextEditingController(text: controller.youtubeApiKey.value);
  }

  @override
  void dispose() {
    whatsappCtrl.dispose();
    for (final l in [
      youtubeList, telegramList, instagramList, facebookList, tiktokList,
      tiktokFeedList, instagramFeedList, facebookFeedList,
    ]) {
      l.dispose();
    }
    youtubeHandleCtrl.dispose();
    youtubeApiKeyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = SocialLinksController.to;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text('Social Media Links'.tr)),
      body: Obx(() {
        if (controller.isLoading.value &&
            controller.whatsapp.value.isEmpty &&
            controller.telegram.value.isEmpty) {
          return const Center(child: CircularProgressIndicator.adaptive());
        }
        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Shown to customers on the shop-front. Leave a field empty to hide that icon entirely.'.tr,
                style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 20),

              // WhatsApp: single field
              _LinkField(
                icon: Icons.chat_bubble_outline_rounded,
                label: 'WhatsApp'.tr,
                defaultPrefix: 'https://wa.me/',
                controller: whatsappCtrl,
              ),
              const SizedBox(height: 14),

              // Multi-link platforms
              _MultiLinkField(icon: Icons.send_outlined, label: 'Telegram'.tr, list: telegramList),
              const SizedBox(height: 14),
              _MultiLinkField(icon: Icons.play_circle, label: 'Youtube'.tr, list: youtubeList),
              const SizedBox(height: 14),
              _MultiLinkField(icon: Icons.camera_alt_outlined, label: 'Instagram'.tr, list: instagramList),
              const SizedBox(height: 14),
              _MultiLinkField(icon: Icons.facebook_outlined, label: 'Facebook'.tr, list: facebookList),
              const SizedBox(height: 14),
              _MultiLinkField(icon: Icons.music_note_outlined, label: 'TikTok'.tr, list: tiktokList),
              const SizedBox(height: 24),

              // ── Media Hub: latest posts feed (TikTok / Instagram / Facebook) ──
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: MejlisPalette.emerald.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: MejlisPalette.emerald.withOpacity(0.25)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'postsFeedSetup'.tr,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'postsFeedSetupHint'.tr,
                      style: TextStyle(fontSize: 11.5, color: scheme.onSurfaceVariant, height: 1.4),
                    ),
                    const SizedBox(height: 12),
                    _MultiLinkField(
                      icon: Icons.music_note_outlined,
                      label: 'TikTok feed URL',
                      list: tiktokFeedList,
                    ),
                    const SizedBox(height: 8),
                    _MultiLinkField(
                      icon: Icons.camera_alt_outlined,
                      label: 'Instagram feed URL',
                      list: instagramFeedList,
                    ),
                    const SizedBox(height: 8),
                    _MultiLinkField(
                      icon: Icons.facebook_outlined,
                      label: 'Facebook feed URL',
                      list: facebookFeedList,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── Media Hub: live YouTube channel feed configuration ──
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: MejlisPalette.emerald.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: MejlisPalette.emerald.withOpacity(0.25)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.podcasts_rounded, color: Color(0xFFFF0000), size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'youtubeFeedSetup'.tr,
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'youtubeFeedSetupHint'.tr,
                      style: TextStyle(fontSize: 11.5, color: scheme.onSurfaceVariant, height: 1.4),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: youtubeHandleCtrl,
                      keyboardType: TextInputType.url,
                      decoration: InputDecoration(
                        labelText: 'youtubeChannelHandle'.tr,
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                        hintText: '@SadatMejlis',
                        prefixIcon: const Icon(Icons.alternate_email_rounded, size: 19),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: youtubeApiKeyCtrl,
                      keyboardType: TextInputType.text,
                      obscureText: _obscureApiKey,
                      decoration: InputDecoration(
                        labelText: 'youtubeApiKey'.tr,
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                        hintText: 'AIza...',
                        prefixIcon: const Icon(Icons.key_rounded, size: 19),
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureApiKey ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                            size: 19,
                          ),
                          onPressed: () => setState(() => _obscureApiKey = !_obscureApiKey),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: scheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: controller.isLoading.value
                      ? null
                      : () {
                    // If WhatsApp still holds only the default prefix, save as empty.
                    final whatsapp = whatsappCtrl.text.trim() == 'https://wa.me/'
                        ? ''
                        : whatsappCtrl.text.trim();

                    controller.saveLinks(
                      whatsapp: whatsapp,
                      telegram: telegramList.joined,
                      instagram: instagramList.joined,
                      facebook: facebookList.joined,
                      tiktok: tiktokList.joined,
                      youtube: youtubeList.joined,
                      youtubeHandle: youtubeHandleCtrl.text.trim(),
                      youtubeApiKey: youtubeApiKeyCtrl.text.trim(),
                      tiktokFeed: tiktokFeedList.joined,
                      instagramFeed: instagramFeedList.joined,
                      facebookFeed: facebookFeedList.joined,
                    );
                  },
                  child: controller.isLoading.value
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                      : Text('Save'.tr, style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

/// A growable list of link fields for one platform.
class _LinkList {
  final String prefix;
  final List<TextEditingController> fields = [];
  final List<TextEditingController> _removed = [];

  _LinkList(this.prefix, String stored) {
    final parts = SocialLinksController.split(stored);
    for (final p in parts.isEmpty ? [prefix] : parts) {
      fields.add(_make(p));
    }
  }

  TextEditingController _make(String text) {
    final c = TextEditingController(text: text);
    c.addListener(() {
      // Keep a valid scheme but allow any host (so pasted www. links work).
      if (!c.text.startsWith('http')) {
        c.value = TextEditingValue(
          text: prefix,
          selection: TextSelection.collapsed(offset: prefix.length),
        );
      }
    });
    return c;
  }

  void add() => fields.add(_make(prefix));
  void removeAt(int i) => _removed.add(fields.removeAt(i));

  /// 'a|b', ignoring fields still holding only the default prefix.
  String get joined => fields
      .map((c) => c.text.trim())
      .where((t) => t.isNotEmpty && t != prefix)
      .join('|');

  void dispose() {
    for (final c in [...fields, ..._removed]) {
      c.dispose();
    }
  }
}

class _MultiLinkField extends StatefulWidget {
  final IconData icon;
  final String label;
  final _LinkList list;
  const _MultiLinkField({required this.icon, required this.label, required this.list});

  @override
  State<_MultiLinkField> createState() => _MultiLinkFieldState();
}

class _MultiLinkFieldState extends State<_MultiLinkField> {
  @override
  Widget build(BuildContext context) {
    final list = widget.list;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < list.fields.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: list.fields[i],
                    keyboardType: TextInputType.url,
                    decoration: InputDecoration(
                      labelText: list.fields.length > 1 ? '${widget.label} ${i + 1}' : widget.label,
                      floatingLabelBehavior: FloatingLabelBehavior.always,
                      prefixIcon: Icon(widget.icon),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
                if (list.fields.length > 1)
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline_rounded),
                    onPressed: () => setState(() => list.removeAt(i)),
                  ),
              ],
            ),
          ),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextButton.icon(
            onPressed: () => setState(list.add),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: Text('Add another'.tr),
          ),
        ),
      ],
    );
  }
}

/// Single-link field with a protected prefix (used for WhatsApp).
class _LinkField extends StatefulWidget {
  final IconData icon;
  final String label;
  final String defaultPrefix;
  final TextEditingController controller;

  const _LinkField({
    required this.icon,
    required this.label,
    required this.defaultPrefix,
    required this.controller,
  });

  @override
  State<_LinkField> createState() => _LinkFieldState();
}

class _LinkFieldState extends State<_LinkField> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_enforcePrefix);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_enforcePrefix);
    super.dispose();
  }

  void _enforcePrefix() {
    final text = widget.controller.text;
    final prefix = widget.defaultPrefix;

    // Prevent the user from backspacing into or destroying the protocol prefix.
    if (!text.startsWith(prefix)) {
      widget.controller.value = TextEditingValue(
        text: prefix,
        selection: TextSelection.collapsed(offset: prefix.length),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      keyboardType: TextInputType.url,
      decoration: InputDecoration(
        labelText: widget.label,
        floatingLabelBehavior: FloatingLabelBehavior.always,
        prefixIcon: Icon(widget.icon),
        border: const OutlineInputBorder(),
      ),
    );
  }
}