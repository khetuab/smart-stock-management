import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../app/themes/app_theme.dart';
import '../../controllers/contact_controller.dart';
import '../../widgets/mejlis_kit.dart';

/// Admin — inbox of customer messages sent from the Contact Us screen
/// (archived in the new 'ContactMessages' sheet). Reply by phone or email.
class AdminContactInboxScreen extends StatelessWidget {
  const AdminContactInboxScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ContactController(), permanent: true);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text('contactInbox'.tr)),
      body: RefreshIndicator(
        onRefresh: controller.loadInbox,
        child: Obx(() {
          if (controller.inboxLoading.value && controller.inbox.isEmpty) {
            return const Center(child: CircularProgressIndicator.adaptive());
          }
          if (controller.inbox.isEmpty) {
            return ListView(
              children: [
                const SizedBox(height: 120),
                Icon(Icons.inbox_rounded, size: 60, color: MejlisPalette.gold.withOpacity(0.6)),
                const SizedBox(height: 14),
                Center(
                  child: Text(
                    'inboxEmpty'.tr,
                    style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
                  ),
                ),
              ],
            );
          }
          return ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 30),
            itemCount: controller.inbox.length,
            itemBuilder: (context, i) {
              final m = controller.inbox[i];
              return MejlisCard(
                margin: const EdgeInsets.only(bottom: 12),
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
                          child: Center(
                            child: Text(
                              m.name.isNotEmpty ? m.name[0].toUpperCase() : '?',
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF2A2104),
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                m.name,
                                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: scheme.onSurface),
                              ),
                              Text(
                                m.createdAt.length > 16 ? m.createdAt.substring(0, 16).replaceFirst('T', ' · ') : m.createdAt,
                                style: TextStyle(fontSize: 10.5, color: scheme.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (m.subject.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(
                        m.subject,
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: scheme.onSurface),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Text(
                      m.message,
                      style: TextStyle(fontSize: 12.5, height: 1.5, color: scheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        if (m.phone.isNotEmpty)
                          OutlinedButton.icon(
                            onPressed: () => controller.callNumber(m.phone),
                            icon: const Icon(Icons.call_rounded, size: 16),
                            label: Text('call'.tr, style: const TextStyle(fontSize: 12)),
                          ),
                        const SizedBox(width: 10),
                        OutlinedButton.icon(
                          onPressed: () async {
                            final uri = Uri(scheme: 'mailto', path: m.email);
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(uri);
                            }
                          },
                          icon: const Icon(Icons.mail_outline_rounded, size: 16),
                          label: Text('replyByEmail'.tr, style: const TextStyle(fontSize: 12)),
                        ),
                        const Spacer(),
                        Text(
                          m.email,
                          style: TextStyle(fontSize: 10.5, color: MejlisPalette.goldDark),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        }),
      ),
    );
  }
}
