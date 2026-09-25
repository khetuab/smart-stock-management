import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../controllers/social_links_controller.dart';

/// A vertical stack of social links, always visible, positioned
/// bottom-left above the bottom nav bar. No toggle — the admin decides
/// what shows up (via SocialLinksController) simply by filling in or
/// clearing a link, so there's never a dead icon sitting on screen.
class SocialMediaRail extends StatelessWidget {
  const SocialMediaRail({super.key});

  static const Map<String, FaIconData> _icons = {
    'whatsapp': FontAwesomeIcons.whatsapp,
    'telegram': FontAwesomeIcons.telegram,
    'instagram': FontAwesomeIcons.instagram,
    'facebook': FontAwesomeIcons.facebook,
    'tiktok': FontAwesomeIcons.tiktok,
    'youtube': FontAwesomeIcons.youtube,
  };

  Future<void> _open(BuildContext context, String rawUrl) async {
    final trimmedUrl = rawUrl.trim();
    if (trimmedUrl.isEmpty) return;

    // Ensure the URL has a scheme prefix to prevent launcher component failure
    final formattedUrl = (trimmedUrl.startsWith('http://') || trimmedUrl.startsWith('https://'))
        ? trimmedUrl
        : 'https://$trimmedUrl';

    final uri = Uri.tryParse(formattedUrl);

    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open link'.tr)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Obx(() {
      final links = SocialLinksController.to.activeLinks;
      if (links.isEmpty) return const SizedBox.shrink();

      return Column(
        mainAxisSize: MainAxisSize.min,
        children: links.map((entry) {
          final icon = _icons[entry.key];
          if (icon == null) return const SizedBox.shrink();

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Material(
              color: scheme.primary.withAlpha(150),
              shape: const CircleBorder(),
              elevation: 3,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => _open(context, entry.value),
                child: Padding(
                  padding: const EdgeInsets.all(11),
                  child: FaIcon(icon, size: 18, color: scheme.onPrimary),
                ),
              ),
            ),
          );
        }).toList(),
      );
    });
  }
}