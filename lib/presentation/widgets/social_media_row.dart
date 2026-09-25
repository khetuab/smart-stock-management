// lib/presentation/widgets/social_media_row.dart

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../controllers/social_links_controller.dart';

/// A horizontal row of the same social links used by [SocialMediaRail],
/// meant to sit as a footer below a scrollable list (e.g. the media feed)
/// rather than float over content. Same icon set, same data source
/// ([SocialLinksController.to.activeLinks]) — an admin adding/clearing a
/// link updates both places automatically.
class SocialMediaRow extends StatelessWidget {
  const SocialMediaRow({super.key});

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

      return Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          border: Border(top: BorderSide(color: scheme.outlineVariant.withOpacity(0.3))),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Follow us'.tr,
              style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: links.map((entry) {
                final icon = _icons[entry.key];
                if (icon == null) return const SizedBox.shrink();

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Material(
                    color: scheme.primary.withOpacity(0.1),
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => _open(context, entry.value),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: FaIcon(icon, size: 22, color: scheme.primary),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      );
    });
  }
}