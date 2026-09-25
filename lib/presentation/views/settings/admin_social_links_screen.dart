import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/social_links_controller.dart';

class AdminSocialLinksScreen extends StatefulWidget {
  const AdminSocialLinksScreen({super.key});

  @override
  State<AdminSocialLinksScreen> createState() => _AdminSocialLinksScreenState();
}

class _AdminSocialLinksScreenState extends State<AdminSocialLinksScreen> {
  late final TextEditingController whatsappCtrl;
  late final TextEditingController youtubeCtrl;
  late final TextEditingController telegramCtrl;
  late final TextEditingController instagramCtrl;
  late final TextEditingController facebookCtrl;
  late final TextEditingController tiktokCtrl;

  @override
  void initState() {
    super.initState();
    final controller = SocialLinksController.to;

    // Use existing stored value, or fallback to default editable URL
    whatsappCtrl = TextEditingController(
      text: controller.whatsapp.value.isNotEmpty ? controller.whatsapp.value : 'https://wa.me/',
    );
    // Use existing stored value, or fallback to default editable URL
    youtubeCtrl = TextEditingController(
      text: controller.youtube.value.isNotEmpty ? controller.youtube.value : 'https://youtube.com/',
    );
    telegramCtrl = TextEditingController(
      text: controller.telegram.value.isNotEmpty ? controller.telegram.value : 'https://t.me/',
    );
    instagramCtrl = TextEditingController(
      text: controller.instagram.value.isNotEmpty ? controller.instagram.value : 'https://instagram.com/',
    );
    facebookCtrl = TextEditingController(
      text: controller.facebook.value.isNotEmpty ? controller.facebook.value : 'https://facebook.com/',
    );
    tiktokCtrl = TextEditingController(
      text: controller.tiktok.value.isNotEmpty ? controller.tiktok.value : 'https://tiktok.com/@',
    );
  }

  @override
  void dispose() {
    whatsappCtrl.dispose();
    youtubeCtrl.dispose();
    telegramCtrl.dispose();
    instagramCtrl.dispose();
    facebookCtrl.dispose();
    tiktokCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = SocialLinksController.to;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text('Social Media Links'.tr)),
      body: Obx(() {
        if (controller.isLoading.value && controller.whatsapp.value.isEmpty && controller.telegram.value.isEmpty) {
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
              _LinkField(
                icon: Icons.chat_bubble_outline_rounded,
                label: 'WhatsApp'.tr,
                defaultPrefix: 'https://wa.me/',
                controller: whatsappCtrl,
              ),
              const SizedBox(height: 14),
              _LinkField(
                icon: Icons.send_outlined,
                label: 'Telegram'.tr,
                defaultPrefix: 'https://t.me/',
                controller: telegramCtrl,
              ),
              const SizedBox(height: 14),
              _LinkField(
                icon: Icons.play_circle,
                label: 'Youtube'.tr,
                defaultPrefix: 'https://youtube.com/',
                controller: youtubeCtrl,
              ),
              const SizedBox(height: 14),
              _LinkField(
                icon: Icons.camera_alt_outlined,
                label: 'Instagram'.tr,
                defaultPrefix: 'https://instagram.com/',
                controller: instagramCtrl,
              ),
              const SizedBox(height: 14),
              _LinkField(
                icon: Icons.facebook_outlined,
                label: 'Facebook'.tr,
                defaultPrefix: 'https://facebook.com/',
                controller: facebookCtrl,
              ),
              const SizedBox(height: 14),
              _LinkField(
                icon: Icons.music_note_outlined,
                label: 'TikTok'.tr,
                defaultPrefix: 'https://tiktok.com/@',
                controller: tiktokCtrl,
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: scheme.primary, padding: const EdgeInsets.symmetric(vertical: 14)),
                  onPressed: controller.isLoading.value
                      ? null
                      : () {
                    // Clean up fields: if user hasn't added anything beyond default prefix, save as empty
                    final whatsapp = whatsappCtrl.text.trim() == 'https://wa.me/' ? '' : whatsappCtrl.text.trim();
                    final telegram = telegramCtrl.text.trim() == 'https://t.me/' ? '' : telegramCtrl.text.trim();
                    final instagram = instagramCtrl.text.trim() == 'https://instagram.com/' ? '' : instagramCtrl.text.trim();
                    final facebook = facebookCtrl.text.trim() == 'https://facebook.com/' ? '' : facebookCtrl.text.trim();
                    final tiktok = tiktokCtrl.text.trim() == 'https://tiktok.com/@' ? '' : tiktokCtrl.text.trim();
                    final youtube = youtubeCtrl.text.trim() == 'https://youtube.com/@' ? '' : youtubeCtrl.text.trim();

                    controller.saveLinks(
                      whatsapp: whatsapp,
                      telegram: telegram,
                      instagram: instagram,
                      facebook: facebook,
                      tiktok: tiktok,
                      youtube: youtube
                    );
                  },
                  child: controller.isLoading.value
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
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

    // Prevent user from backspacing into or destroying the protocol prefix
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